# Compiles all of the subject URIs + labels used

out = File.open("/home/deploy/subject-analysis-#{Time.zone.now.strftime('%Y%m%d')}.csv", 'w')
res = ActiveFedora::SolrService.get('*:*', rows: 0, facet: 'on', 'facet.field': 'subject_ssim', 'facet.limit': 500_000)
subjects = res.dig('facet_counts', 'facet_fields', 'subject_ssim')
csv = CSV.new(out, headers: true)
csv << ['uri', 'label', 'count']

subjects.each_slice(2) do |uri, count|
  csv << {
    'uri' => uri,
    'label' => ::Spot::ControlledVocabularies::Base.new(uri)&.fetch&.rdf_label&.first,
    'count' => count
  }
end

csv.close
