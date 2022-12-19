# frozen_string_literal: true
require 'csv'
require 'date'

date = Time.zone.now.strftime('%Y%m%d')
CSV.open("/home/deploy/items-missing-rights-statements-#{date}.csv", 'wb') do |csv|
  csv << ['id', 'url', 'title']

  Publication.where(rights_statement_ssim: nil).each do |pub|
    url = Rails.application.routes.url_helpers.polymorphic_url(pub, host: 'https://new-ldr.lafayette.edu')
    csv << [pub.id, url, pub.title.first.to_s]
  end
end
