# frozen_string_literal: true

# A script to export Google Search Console data from Keylime Toolbox and write it to an S3 bucket.
#
# See README.md for details or run `./export_data.rb --help`.
require_relative "lib/keylime_toolbox_client"
require_relative "lib/retriable"
require_relative "lib/s3_client"
require_relative "lib/script_options"

VERSION = 1.0

# Export data from Keylime Toolbox API to an S3 bucket.
class ExportData
  attr_reader :logger

  def initialize
    parse_args
    # TODO: Allow -v/--verbose option the restrict output based on level
    @logger = Logger.new(STDERR)
  end

  def export
    keylime_toolbox_client.sites.each do |site|
      keylime_toolbox_client.dates(site["slug"]).each do |date|
        keylime_toolbox_client.requests(site["slug"], date).each do |path, params|
          transfer_file(site, date, path, params)
        end
      end
    end
  end

  private

  def parse_args
    @options = ScriptOptions.parse(ARGV)
  end

  def transfer_file(site, date, path, params)
    data = keylime_toolbox_client.data(path, params)
    return unless data
    key = object_key(site["slug"], date, path, params)
    s3_client.write(key, data, site["url"])
  end

  def keylime_toolbox_client
    @keylime_toolbox_client ||= KeylimeToolboxClient.new(logger: logger)
  end

  def s3_client
    @s3_client ||= S3Client.new(bucket: @options.bucket, region: @options.region, logger: logger)
  end

  def object_key(site_slug, date, path, params)
    appearance_infix = nil
    appearance_infix = "search_appearance_#{params[:search_appearance].downcase}_" if params[:search_appearance]
    "#{@options.path}#{File.basename(path)}_#{appearance_infix}#{site_slug}_#{date}.csv"
  end
end

ExportData.new.export
