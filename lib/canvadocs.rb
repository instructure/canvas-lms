require 'cgi'
require 'net/http'
require 'net/https'
require 'json'

module Canvadocs
  RENDER_O365 = 'office_365'
  RENDER_BOX = 'box_view'
  RENDER_CROCODOC = 'crocodoc'

  # Public: A small ruby client that wraps the Box View api.
  #
  # Examples
  #
  #   Canvadocs::API.new(:token => <token>)
  class API
    attr_accessor :token, :http, :url

    # Public: The base part of the url that is the same for all api requests.
    BASE_URL = "https://view-api.box.com/1"

    # Public: Initialize a Canvadocs api object
    #
    # opts - A hash of options with which to initialize the object
    #        :token - The api token to use to authenticate requests. Required.
    #
    # Examples
    #   crocodoc = Canvadocs::API.new(:token => <token>)
    #   # => <Canvadocs::API:<id>>
    def initialize(opts)
      self.token = opts[:token]

      _, @url = CanvasHttp.validate_url(opts[:base_url] || BASE_URL)
      @http = CanvasHttp.connection_for_uri(@url)
    end

    # -- Documents --

    # Public: Create a document with the file at the given url.
    #
    # obj - a url string
    # params - other post params
    #
    # Examples
    #
    #   upload("http://www.example.com/test.doc")
    #   # => { "id": 1234, "status": "queued" }
    #
    # Returns a hash containing the document's id and status
    def upload(obj, extra_params = {})
      params = if obj.is_a?(File)
        { file: obj }.merge(extra_params)
        raise Canvadocs::Error, "TODO: support raw files"
      else
        { url: obj.to_s }.merge(extra_params)
      end

      raw_body = api_call(:post, "documents", params)
      JSON.parse(raw_body)
    end

    # Public: Delete a document.
    #
    # id - a single document id to delete
    #
    def delete(id)
      api_call(:delete, "documents/#{id}")
    end

    # -- Sessions --

    # Public: Create a session, which is a unique id with which you can view
    # the document. Sessions expire 60 minutes after they are generated.
    #
    # id - The id of the document for the session
    #
    # Examples
    #
    #   session(1234)
    #   # => { "id": "CFAmd3Qjm_2ehBI7HyndnXKsDrQXJ7jHCuzcRv" }
    #
    # Returns a hash containing the session id
    def session(document_id, opts={})
      raw_body = api_call(:post, "sessions",
                          opts.merge(:document_id => document_id))
      JSON.parse(raw_body)
    end

    # Public: Get the url for the viewer for a session.
    #
    # session_id - The id of the session (see #session)
    #
    # Examples
    #   view("CFAmd3Qjm_2ehBI7HyndnXKsDrQXJ7jHCuzcRv_V4FAgbSmaBkF")
    #   # => https://view-api.box.com/1/sessions/#{session_id}/view?theme=dark"
    #
    # Returns a url string for viewing the session
    def view(session_id)
      "#{@url}/sessions/#{session_id}/view?theme=dark"
    end


    # -- API Glue --

    # Internal: Setup the api call, format the parameters, send the request,
    # parse the response and return it.
    #
    # method   - The http verb to use, currently :get or :post
    # endpoint - The api endpoint to hit. this is the part after
    #            +base_url+. please do not include a beginning slash.
    # params   - Parameters to send with the api call
    #
    # Examples
    #
    #   api_call(:post,
    #            "documents",
    #            { url: "http://www.example.com/test.doc" })
    #   # => { "id": 1234 }
    #
    # Returns the json parsed response body of the call
    def api_call(method, endpoint, params={})
      # dispatch to the right method, with the full path (/api/v2 + endpoint)
      request = self.send("format_#{method}", "#{@url.path}/#{endpoint}", params)
      request["Authorization"] = "Token #{token}"
      response = @http.request(request)

      unless response.code =~ /\A20./
        raise Canvadocs::Error, "HTTP Error #{response.code}: #{response.body}"
      end
      response.body
    end


    # Internal: Format and create a Net::HTTP get request, with query
    # parameters.
    #
    # path - the path to get
    # params - the params to add as query params to the path
    #
    # Examples
    #
    #   format_get("/api/v2/document/status",
    #              { :token => <token>, :uuids => <uuids> })
    #   # => <Net::HTTP::Get:<id>> for
    #   #    "/api/v2/document/status?token=<token>&uuids=<uuids>"
    #
    # Returns a Net::HTTP::Get object for the path with query params
    def format_get(path, params)
      query = params.map { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join("&")
      Net::HTTP::Get.new("#{path}?#{query}")
    end

    # Internal: Format and create a Net::HTTP post request, with form
    # parameters.
    #
    # path - the path to get
    # params - the params to add as form params to the path
    #
    # Examples
    #
    #   format_post("/api/v2/document/upload",
    #              { :token => <token>, :url => <url> })
    #   # => <Net::HTTP::Post:<id>>
    #
    # Returns a Net::HTTP::Post object for the path with json-formatted params
    def format_post(path, params)
      Net::HTTP::Post.new(path).tap { |req|
        req["Content-Type"] = "application/json"
        req.body = params.to_json
      }
    end
  end

  class Error < StandardError; end

  def self.config
    PluginSetting.settings_for_plugin(:canvadocs)
  end

  def self.enabled?
    !!config
  end

  def self.annotations_supported?
    enabled? && Canvas::Plugin.value_to_boolean(config["annotations_supported"])
  end
end
