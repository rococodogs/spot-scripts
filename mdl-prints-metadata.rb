# frozen_string_literal: true
require_relative './export-collection-csv.rb'

mdl_prints = Collection.find('mdl-prints')
outfile = File.open("/home/deploy/mdl-prints-metadata-#{Time.zone.now.strftime('%Y%m%d')}.csv", 'w')

CollectionExporter.new(mdl_prints).export_csv(to: outfile)

