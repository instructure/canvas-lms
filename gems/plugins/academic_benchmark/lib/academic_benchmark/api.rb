module AcademicBenchmark
class Api

  API_BASE_URL = "http://api.statestandards.com/services/rest/"
  BROWSE = "browse"
  SEARCH = "search"
  MAINTAIN_ACCESS = "maintainAccess"
    MA_LIST = 'list'
    MA_REMOVE = 'remove'
    MA_ADD = 'add'
  READ_TIMEOUT = 5.minutes.to_i

  def initialize(api_key, opts={})
    @api_key = api_key
    @base_url = opts[:base_url] || API_BASE_URL
  end

  def browse(opts={})
    set_defaults!(opts)
    opts[:levels] ||= 1
    get_ab_results(@base_url + BROWSE, opts)
  end

  def search(opts={})
    set_defaults!(opts)
    get_ab_results(@base_url + SEARCH, opts)
  end

  # returns a single list of all authorities across all available countries
  def list_available_authorities(format = 'json')
    res = browse({:levels => 2, :format => format})
    auths = []
    res.each do |country|
      next unless country["itm"]
      auths += country["itm"]
    end

    auths
  end

  def browse_authority(auth_code, opts={})
    opts[:authority] = auth_code
    browse(opts)
  end

  def browse_guid(guid, opts={})
    opts[:guid] = guid
    browse(opts)
  end

  def maintain_access(operation, params={})
    set_defaults!(params)
    params[:op] ||= operation
    get_ab_results(@base_url + MAINTAIN_ACCESS, params)
  end

  def list_ips
    maintain_access(MA_LIST)
  end

  def add_ip(ip, note=nil)
    maintain_access(MA_ADD, :addr => ip, :note => note)
  end

  def remove_ip(ip)
    maintain_access(MA_REMOVE, :addr => ip)
  end

  def get_ab_results(url, params={})
    res = Api.get_url(url + query_string_from_hash(params))
    if res.code.to_i == 200
      parse_ab_data(res.body)
    else
      raise APIError.new("HTTP Error: #{res.code} - #{res.body}")
    end
  end

  def parse_ab_data(json_string)
    data = JSON.parse(json_string, :max_nesting => 50)
    if data["status"] == "ok"
      return data["itm"] || data["access"] || []
    else
      if data["ab_err"]
        raise APIError.new("responseCode: #{data["ab_err"]["code"]} - #{data["ab_err"]["msg"]}")
      else
        raise APIError.new("response: #{data.to_json}")
      end
    end
  end

  def self.get_url(url)
    uri = URI(url)
    Net::HTTP.new(uri.host, uri.port).start { |http|
      http.read_timeout = READ_TIMEOUT
      http.request_get(uri.request_uri)
    }
  end

  private

  def query_string_from_hash(params)
    return "" if params.empty?
    "?".concat(params.map{|k, v| v ? "#{k}=#{CGI::escape(v.to_s)}" : nil}.compact.sort.join('&'))
  end

  def set_defaults!(opts)
    opts[:api_key] ||= @api_key
    opts[:format] ||= 'json'
  end

end
end
