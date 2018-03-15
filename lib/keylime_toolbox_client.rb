# frozen_string_literal: true

require "json"
require "rest-client"

# Read data from the Keylime Toolbox API.
class KeylimeToolboxClient
  def initialize(logger)
    @logger = logger
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

    return response.body if response.code == 200

    logger.error("Got #{response.code} reading #{response.request.url}")
    return nil
  rescue StandardError => e
    logger.error("Got #{e.class.name} reading #{path} #{params.inspect}")
    return nil
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
    @groups ||= JSON.parse(client["/site_groups"].get(accept: :json).body)
  rescue RestClient::Unauthorized
    warn "Invalid credentials for the Keylime Toolbox API. Set KEYLIME_TOOLBOX_EMAIL and KEYLIME_TOOLBOX_TOKEN " \
         "environment variables. You can find these at https://app.keylime.io/settings/profile."
    exit(-1)
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

  def safe_get(path, params)
    client[path].get(params: params) { |resp, _req, _result| resp }
  end
end
