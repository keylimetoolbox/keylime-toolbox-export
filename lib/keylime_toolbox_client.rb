# frozen_string_literal: true

require "json"
require "rest-client"

# Read data from the Keylime Toolbox API.
class KeylimeToolboxClient
  attr_reader :logger

  def initialize(logger:)
    @logger = logger
  end

  def sites
    return @sites if @sites
    @sites = []
    groups.each do |group|
      @sites += json_list("/site_groups/#{group['slug']}/sites")
    end
    @sites.uniq!
    @sites
  end

  def dates(site_slug)
    json_list("/sites/#{site_slug}/data_points").map do |point|
      point["date"]
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

  def data(path, params)
    response = safe_get(path, params)
    response.body if response
  end

  private

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
    @groups ||= json_list("/site_groups")
  rescue RestClient::Unauthorized
    warn "Invalid credentials for the Keylime Toolbox API. Set KEYLIME_TOOLBOX_EMAIL and KEYLIME_TOOLBOX_TOKEN " \
         "environment variables. You can find these at https://app.keylime.io/settings/profile."
    exit(-1)
  end

  def search_appearances(site_slug, date)
    json_list("/sites/#{site_slug}/search_appearances", date: date.to_s)
  rescue RestClient::NotFound
    []
  end

  def search_appearance_requests(path, date, appearances)
    appearances.map do |appearance|
      [path, {date: date.to_s, search_appearance: appearance}]
    end
  end

  def json_list(path, params = {})
    response = safe_get(path, params, accept: :json)
    return [] unless response
    JSON.parse(response.body)
  end

  def safe_get(path, params, options = {})
    response = retry_get(path, params, options)
    return response if response.code == 200

    logger.error("Got #{response.code} reading #{response.request.url}")
    return nil
  rescue StandardError => e
    logger.error("Got #{e.class.name} reading #{path} #{params.inspect}")
    return nil
  end

  def retry_get(path, params, options = {})
    Retriable.with_context(:keylime_toolbox_api) do
      client[path].get(options.merge(params: params)) { |resp, _req, _result| resp }
    end
  end
end
