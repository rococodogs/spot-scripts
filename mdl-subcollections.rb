# frozen_string_literal: true
#
# Script to fetch MDL-prints items via keyword and add them to their respective subcollections
raw_subcollections = <<-EOL
Portraits: Before 1789 | Portraits: Before 1789
Portraits: Quenedey | Portraits: Quenedey
Portraits: Levachez | Portraits: Levachez
Portraits: Debucourt, etc. | Portraits: Debucourt, Etc.
Portraits: Weyler | Portraits: Weyler
Portraits: Jacobi (Bolt) | Portraits: Jacobi (Bolt)
Miscellaneous: Before 1800 | Portraits: Miscellaneous Before 1800
Portraits: Clary, etc. | Portraits: Clary, Etc.
Portraits: Scheffer | Portraits: Scheffer
Portraits: Gerard | Portraits: Gerard
Portraits: Maurin | Portraits: Maurin
Portraits: Julien, etc. | Portraits: Julien, Etc.
Miscellaneous: Uniform, white neck-band and collar, without bow | Portraits: Miscellaneous - Uniform, White Neck-band and Collar, Without Bow
Portraits: Bridi, etc. | Portraits: Bridi, Etc.
Miscellaneous: Uniform, fur collar, etc. | Portraits: Miscellaneous - Uniform, Fur Collar, Etc.
Portraits: Martinet, etc. | Portraits: Martinet, Etc.
Miscellaneous: 1800-1834 | Portraits: Miscellaneous - 1800-1834
Equestrian | Portraits: Equestrian
Caricatures | Caricatures
Symbolic Compositions | Symbolic Compositions
Members of Family | Members of Family
Scenes from the Life: 1776-1834 | Scenes from the Life: 1776-1834
Homes: Chavaniac and La Grange | Homes - Chavaniac and LaGrange
EOL

subcollection_map = raw_subcollections.split("\n").map { |row| row.split(/\s?\|\s?/).uniq }
mdl_col = Collection.find('mdl-prints')
mdl_col.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX

subcollection_map.each do |(keyword, col_name)|
  puts "adding items to #{col_name || keyword}"

  subcollection = Collection.where(title_tesim: col_name || keyword)&.first

  if subcollection.nil?
    puts "  Couldn't find one; moving on"
    next
  end

  subcollection.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX

  Image.where(member_of_collection_ids_ssim: mdl_col.id, keyword: keyword).each do |item|
    next if item.member_of_collection_ids.include?(subcollection.id)

    item.member_of_collections << subcollection
    item.save!
  end
end
