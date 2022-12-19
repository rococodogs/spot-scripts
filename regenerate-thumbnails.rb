# frozen_string_literal: true
offset = 0
targets = []

query = 'has_model_ssim:Publication'
args = { fl: ['id', 'thumbnail_path_ss'], rows: 500 }

total = ActiveFedora::SolrService.count(query, args)

while offset < total
  puts "checking #{offset} - #{offset + 500} of #{total}"
  results = ActiveFedora::SolrService.query(query, args.merge(start: offset))
  without_thumbnails = results
                        .select { |doc| doc['thumbnail_path_ss'].start_with?('/assets/work') }
                        .map { |doc| doc['id'] }
  targets.concat(without_thumbnails)

  offset += 500
end

targets.each do |id|
  puts "re-characterizing #{id}"
  pub = Publication.find(id)

  file_set = pub.file_sets.first
  file = file_set&.files&.first

  unless file_set.nil? || file.nil?
    CharacterizeJob.perform_later(file_set, file.id)
    next
  end

  # delete the file-set
  files_path = begin
    if file_set&.import_url
      file_set.import_url.gsub(/releases\/[^\/]+/, 'current').gsub('%EF%80%A2', '*').gsub(/^file\:/, '')
    else
      file_id = pub.identifier.find { |id| id.start_with?('lafayette:') }
      "/var/www/spot/current/tmp/ingest/#{file_id.tr(':', '*')}/data/files"
    end
  end

  files = Dir.glob(files_path)

  # uhhhh just move on i guess?
  next if files.empty?

  pub.file_sets.each(&:destroy)

  user = User.find_by(email: pub.depositor)
  user ||= User.find_by(email: 'dss@lafayette.edu')
  attributes = { remote_files: files.map { |f| { url: "file:#{f}", file_name: File.basename(f) } } }

  env = Hyrax::Actors::Environment.new(pub, Ability.new(user), attributes)

  stack = Hyrax::Actors::CreateWithRemoteFilesActor.new(Hyrax::Actors::Terminator.new)
  stack.update(env)
end
