require "turnitin_api/version"

module TurnitinApi
  class OutcomesResponseTransformer

    # key
    # secret
    # turnitin_api response

    attr_accessor :outcomes_response_json, :key
    def initialize(key, secret, outcomes_response_json)
      @key = key
      @secret = secret
      @outcomes_response_json = outcomes_response_json
    end

    def response
      @response ||= make_call(outcomes_response_json['outcomes_tool_placement_url'])
    end

    # download original
    def original_submission
      yield make_call(response.body["outcome_originalfile"]["launch_url"])
    end

    # store link to report
    def originality_report_url
      response.body["outcome_originalityreport"]["launch_url"]
    end

    def originality_data
      response.body['outcome_originalityreport'].select {|k, _| %w(breakdown numeric).include?(k)}
    end

    private

    def connection
      @connection ||= Faraday.new do |conn|
        conn.request :multipart
        conn.request :url_encoded
        conn.response :json, :content_type => /\bjson$/
        conn.adapter :net_http
      end
    end

    def make_call(url)
      header = SimpleOAuth::Header.new(:post, url, {}, consumer_key: @key, consumer_secret: @secret, callback: 'about:blank')
      connection.post url, header.signed_attributes
    end

  end
end
