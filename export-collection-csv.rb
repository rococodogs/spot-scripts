# frozen_string_literal: true
#
# Export a collection's item metadata as a CSV
#
# @example
#   require_relative './export-collection-csv.rb'
#
#   mdl_prints = Collection.find('mdl-prints')
#   outfile = File.open("/home/deploy/mdl-prints-metadata-#{Time.zone.now.strftime('%Y%m%d')}.csv", 'w')
#
#   CollectionExporter.export_csv(collection: mdl_prints, to: outfile)
#   outfile.close
class CollectionExporter
  attr_reader :collection

  class_attribute :solr_service
  self.solr_service = ActiveFedora::SolrService

  def self.export_csv(collection:, to:)
    new(collection).export_csv(to: to)
  end

  def initialize(collection)
    @collection = collection
  end

  def export_csv(to:)
    csv = CSV.new(to, headers: true)
    csv << headers

    documents.each do |document|
      csv << hash_from(document: document)
    end

    csv.close
  end

  private

  def collection_ids_for(document:, key:, hash:)
    hash[key] = document.member_of_collection_ids.join('|')
    hash
  end

  def collection_name_for(id:)
    @collection_name_cache ||= {}
    @collection_name_cache[id] ||= SolrDocument.find(id).title.first
    @collection_name_cache[id]
  end

  def collection_names_for(document:, key:, hash:)
    names = document.member_of_collection_ids.map { |id| collection_name_for(id: id) }
    hash[key] = names.join('|')
    hash
  end

  def documents
    results = solr_service.get("member_of_collection_ids_ssim:#{collection.id} -has_model_ssim:Collection", rows: 100_000)
    (results.dig("response", "docs") || []).map { |document| SolrDocument.new(document) }
  end

  def hash_from(document:)
    headers.reduce({}) do |out, header|
      next collection_ids_for(document: document, key: header, hash: out) if header == 'member_of_collection_ids'
      next collection_names_for(document: document, key: header, hash: out) if header == 'member_of_collections'

      values = Array.wrap(document.try(header) || [])
      out[header] = values.join("|")
      out
    end
  end

  def headers
    @headers ||= generate_headers
  end

  def fields_from_model(model)
    # using this to check if the method exists in SolrDocument
    solr_doc = SolrDocument.new
    model_properties = model.constantize.properties.keys

    model_fields = (model_properties - system_fields).reduce([]) do |fields, field|
      labeled_field = "#{field}_label"

      fields << field if solr_doc.respond_to?(field.to_sym)
      fields << labeled_field if solr_doc.respond_to?(labeled_field.to_sym)

      fields
    end

    model_fields += ['member_of_collection_ids', 'member_of_collections']
  end

  def generate_headers
    sorted_fields = models_in_collection.map { |model| fields_from_model(model) }.flatten.uniq.sort
    sorted_fields.delete('title') # delete from its sorted position bc we're inserting it at the beginning
    ['id', 'title'] + sorted_fields
  end

  def models_in_collection
    search_field = "member_of_collection_ids_ssim"
    facet_field = "has_model_ssim"
    solr_opts = {
      rows: 0,
      facet: true,
      "facet.field" => facet_field,
      "f.#{facet_field}.facet.mincount" => 1
    }

    hyrax_work_types = Hyrax.config.curation_concerns.map(&:to_s)
    solr_results = solr_service.get("#{search_field}:#{collection.id}", solr_opts)
    model_results = solr_results.dig("facet_counts", "facet_fields", facet_field)
    model_results.each_slice(2).reduce([]) { |acc, (model, _count)| acc.tap { |a| a << model if hyrax_work_types.include?(model) } }
  end

  # @todo maybe keep state?
  def system_fields
    %w[create_date modified_date head tail state]
  end
end
