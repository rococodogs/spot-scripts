# frozen_string_literal: true
#
# attach files to items without them
Publication.where(file_set_ids_ssim: nil).each do |pub|
  puts "updating #{pub.id} (#{pub.title.first})"
  # get islandora id + convert to Dir.glob path
  id = pub.identifier.find { |id| id.start_with?('lafayette:') }&.gsub(/^lafayette\:/, '')
  files = Dir.glob("/var/www/spot/current/tmp/ingest/#{id.tr(':', '*')}/data/files/*")
             .map { |path|  { url: "file:#{path}", file_name: File.basename(path) } }

  puts "  attaching #{files.count} #{'file'.pluralize(files.count)}"

  user = User.find_by(email: pub.depositor)
  user ||= User.find_by(email: 'dss@lafayette.edu') # fallback

  # create miniature actor stack
  attributes = { remote_files: files }
  env = Hyrax::Actors::Environment.new(pub, Ability.new(user), attributes)

  # call the stack
  stack = Hyrax::Actors::CreateWithRemoteFilesActor.new(Hyrax::Actors::Terminator.new)
  stack.update(env)
end
