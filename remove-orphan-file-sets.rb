# frozen_string_literal: true
#
# this will get a list of all the files in `tmp/derivatives`, convert the
# filenames to ids, check if a FileSet exists with that id, and delete the files if not

ids = Dir['tmp/derivatives/**/*.*'].map do |file_path|
  file_path.gsub(/^tmp\/derivatives\//, '').gsub(/-(access|thumbnail)\.(jpe?g|tif)$/, '').tr('/', '')
end.uniq

ids.each do |id|
  fs = FileSet.find(id)

  if fs.parent.nil?
    Rails.logger.warn("found an orphan file set (#{id}); deleting!")
    fs.destroy
  end
end
