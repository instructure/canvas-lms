require 'date'
require 'oauth'

module Ally

  class Client

    ##
    # Creates a new Ally client
    def initialize(client_id, secret, base_url=nil)
      @client_id = client_id
      @secret = secret
      @base_url = base_url || "prod.ally.ac"
    end

    ##
    # Sign a request to the Ally API
    #
    #  - course_id:     The Canvas course id
    #  - user_id:       The Canvas user id that is executing the request
    #  - role:          The role of the user within the course
    #  - method:        The type of HTTP request that will be made to the Ally REST API (get or post)
    #  - path:          The path to the Ally REST API
    #  - parameters:    Any parameters that will be sent to the Ally REST API
    def sign(course_id, user_id, role, method, path, parameters)
      consumer = OAuth::Consumer.new(@client_id, @secret, {
        :site   => @base_url,
        :scheme => :header
      })

      # Add the Ally authentication specific parameters
      parameters["userId"] = user_id
      parameters["courseId"] = course_id
      parameters["role"] = role

      if method == "GET"
        return consumer.create_signed_request(:get, path + "?" + parameters.to_query)
      elsif method == "POST"
        return consumer.create_signed_request(:post, path, nil, {}, parameters)
      end
    end
  end
end
