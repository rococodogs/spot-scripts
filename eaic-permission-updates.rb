# frozen_string_literal: true

# 1. create the management role
role = Role.find_or_create_by(name: 'eaic-manager')

# 2. update main eaic collection
eaic = Collection.find('east-asia-image-collection')
eaic.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
eaic.permission_template << Hyrax::PermissionTemplateAccess.create!(agent_type: 'group', agent_id: role.name, access: 'manage')
eaic.save

# 3. grant access to the items within the collection
Image.where(member_of_collection_ids: eaic.id).each do |img|
  img.edit_groups += eaic.permission_template.agent_ids_for(agent_type: 'group', access: 'manage')
  img.save!
end

# 4. update subcollections
Collection.where(member_of_collection_ids: eaic.id) do |col|
  col.reindex_extent = Hyrax::Adapters::NestingIndexAdapter::LIMITED_REINDEX
  col.permission_template << Hyrax::PermissionTemplateAccess.create!(agent_type: 'group', agent_id: role.name, access: 'manage')
  col.save!
end
