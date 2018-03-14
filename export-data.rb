# frozen_string_literal: true

# A script to export Google Search Console data from Keylime Toolbox and write it to an S3 bucket.
#
# See README.md for details or run `./export-data.rb --help`.
require "aws-sdk-s3"
require "dotenv/load"
require "json"
require "rest-client"
require "retriable"

require_relative "lib/script_options"

VERSION = 1.0

# Export data from Keylime Toolbox API to an S3 bucket.
class ExportData
  def initialize
    parse_args
  end

  def export
    sites.each do |site|
      dates(site["slug"]).each do |date|
        requests(site["slug"], date).each do |path, params|
          transfer_file(site, date, path, params)
        end
      end
    end
  end

  private

  def transfer_file(site, date, path, params)
    response = client[path].get(params: params)
    unless response.code == 200
      log(:error, "Got #{response.code} reading #{response.request.url}")
      return
    end

    key = object_key(site["slug"], date, path, params)
    write_s3_object(key, response.body, site["url"])
  end

  def write_s3_object(key, data, url)
    # TODO: Add Retriable context for Service Unavailable and other errors
    s3.put_object(acl: "bucket-owner-full-control", bucket: @options.bucket, body: data, key: key)
    log(:info, "Wrote #{data.size} bytes for #{url} to s3://#{@options.bucket}/#{key}")
  rescue Aws::S3::Errors::PermanentRedirect
    region = @options.region || ENV["AWS_REGION"]
    warn "The S3 bucket is not in the #{region} AWS region. Correct this with the --region option."
    exit(-1)
  end

  def parse_args
    @options = ScriptOptions.parse(ARGV)
  end

  def client
    @client ||= RestClient::Resource.new(
        "https://app.keylime.io",
        headers: {
            x_user_email: ENV["KEYLIME_TOOLBOX_EMAIL"],
            x_user_token: ENV["KEYLIME_TOOLBOX_TOKEN"]
        }
    )
  end

  def groups
    @groups ||= JSON.parse(client["/site_groups"].get(accept: :json).body)
  rescue RestClient::Unauthorized
    warn "Invalid credentials for the Keylime Toolbox API. Set KEYLIME_TOOLBOX_EMAIL and KEYLIME_TOOLBOX_TOKEN " \
         "environment variables. You can find these at https://app.keylime.io/settings/profile."
    exit(-1)
  end

  def sites
    return @sites if @sites
    @sites = []
    groups.each do |group|
      @sites += JSON.parse(client["/site_groups/#{group['slug']}/sites"].get(accept: :json).body)
    end
    @sites.uniq!
    @sites
  end

  def dates(site_slug)
    JSON.parse(client["/sites/#{site_slug}/data_points"].get(accept: :json).body).map do |point|
      point["date"]
    end
  end

  def search_appearances(site_slug, date)
    JSON.parse(client["/sites/#{site_slug}/search_appearances"].get(params: {date: date.to_s}, accept: :json).body)
  rescue RestClient::NotFound
    []
  end

  def search_appearance_requests(path, date, appearances)
    appearances.map do |appearance|
      [path, {date: date.to_s, search_appearance: appearance}]
    end
  end

  def requests(site_slug, date)
    appearances = search_appearances(site_slug, date)
    queries_appearances = search_appearance_requests("/sites/#{site_slug}/gwt_downloads/queries", date, appearances)
    urls_appearances = search_appearance_requests("/sites/#{site_slug}/gwt_downloads/urls", date, appearances)
    base = [
        ["/sites/#{site_slug}/gwt_downloads/queries", {date: date.to_s}],
        ["/sites/#{site_slug}/gwt_downloads/urls", {date: date.to_s}]
    ]
    base + queries_appearances + urls_appearances
  end

  def object_key(site_slug, date, path, params)
    appearance_infix = nil
    appearance_infix = "search_appearance_#{params[:search_appearance].downcase}_" if params[:search_appearance]
    "#{@options.path}#{File.basename(path)}_#{appearance_infix}#{site_slug}_#{date}.csv"
  end

  def log(level, message)
    # TODO: Allow -v/--verbose option the restrict output based on level
    warn "#{level.to_s.upcase}: #{message}"
  end

  def s3
    options = {}
    options[:region] = @options.region if @options.region
    # TODO: Support --aws-profile option to choose a profile from the configuration file
    # options[:credentials] = Aws::SharedCredentials.new(profile_name: @options.aws_profile) if @options.aws_profile
    @s3 ||= Aws::S3::Client.new(options)
  end
end

ExportData.new.export
