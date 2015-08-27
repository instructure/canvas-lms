require_relative '../errors'
module Canvas
  class Errors

    # This is a class for taking the common context
    # found in the request/response cycle for an exception
    # and turning it into a pleasent hash for Canvas::Errors
    # to make use of.
    class Info

      attr_reader :req, :account, :user, :rci, :type

      def initialize(request, root_account, user, opts={})
        @req = request
        @account = root_account
        @user = user
        @rci = opts.fetch(:request_context_id, RequestContextGenerator.request_id)
        @type = opts.fetch(:type, nil)
      end

      # The ideal hash format to pass to Canvas::Errors.capture().
      #
      # If you're trying to find a way to transform some other common
      # context, this is a decent model to follow.
      def to_h
        {
          tags: {
            account_id: @account.try(:global_id)
          },
          extra: {
            request_context_id: @rci,
            request_method: @req.request_method_symbol,
            format: @req.format,
            user_agent: @req.headers['User-Agent'],
            user_id: @user.try(:global_id),
            type: @type
          }.merge(self.class.useful_http_env_stuff_from_request(@req))
        }
      end

      USEFUL_ENV = [
        "HTTP_ACCEPT",
        "HTTP_ACCEPT_ENCODING",
        "HTTP_HOST",
        "HTTP_REFERER",
        "HTTP_USER_AGENT",
        "PATH_INFO",
        "QUERY_STRING",
        "REMOTE_HOST",
        "REQUEST_METHOD",
        "REQUEST_PATH",
        "REQUEST_URI",
        "SERVER_NAME",
        "SERVER_PORT",
        "SERVER_PROTOCOL",
      ].freeze

      def self.useful_http_env_stuff_from_request(req)
        stuff = req.env.slice(*USEFUL_ENV)
        req_stuff = stuff.merge(filtered_request_params(req, stuff['QUERY_STRING']))
        Marshal.load(Marshal.dump(req_stuff))
      end

      def self.filtered_request_params(req, query_string)
        f = LoggingFilter
        {
          # ActionDispatch::Request#remote_ip has proxy smarts
          'REMOTE_ADDR' => req.remote_ip,
          'QUERY_STRING' => (f.filter_query_string("?" + (query_string || ''))),
          'REQUEST_URI' => f.filter_uri(req.url),
          'path_parameters' => f.filter_params(req.path_parameters.dup).inspect,
          'query_parameters' => f.filter_params(req.query_parameters.dup).inspect,
          'request_parameters' => f.filter_params(req.request_parameters.dup).inspect,
        }
      end
      private_class_method :filtered_request_params
    end
  end
end
