#
# TestRail API binding for Ruby (API v2, available since TestRail 3.0)
#
# Learn more:
#
# http://docs.gurock.com/testrail-api2/start
# http://docs.gurock.com/testrail-api2/accessing
#
# Copyright Gurock Software GmbH
#

require 'net/http'
require 'net/https'
require 'uri'
require 'json'

module TestRail
	class APIClient
		@url = ''
		@user = ''
		@password = ''

		attr_accessor :user
		attr_accessor :password

		def initialize(base_url)
			if !base_url.match(/\/$/)
				base_url += '/'
			end
			@url = base_url + 'index.php?/api/v2/'
		end

		#
		# Send Get
		#
		# Issues a GET request (read) against the API and returns the result
		# (as Ruby hash).
		#
		# Arguments:
		#
		# uri                 The API method to call including parameters
		#                     (e.g. get_case/1)
		#
		def send_get(uri) 
			_send_request('GET', uri, nil)
		end

		#
		# Send POST
		#
		# Issues a POST request (write) against the API and returns the result
		# (as Ruby hash).
		#
		# Arguments:
		#
		# uri                 The API method to call including parameters
		#                     (e.g. add_case/1)
		# data                The data to submit as part of the request (as
		#                     Ruby hash, strings must be UTF-8 encoded)
		#
		def send_post(uri, data)
			_send_request('POST', uri, data)
		end

		private
		def _send_request(method, uri, data)
			url = URI.parse(@url + uri)
			if method == 'POST'
				request = Net::HTTP::Post.new(url.path + '?' + url.query)
				request.body = JSON.dump(data)
			else
				request = Net::HTTP::Get.new(url.path + '?' + url.query)
			end
			request.basic_auth(@user, @password)
			request.add_field('Content-Type', 'application/json')

			conn = Net::HTTP.new(url.host, url.port)
			if url.scheme == 'https'
				conn.use_ssl = true
				conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
			end
			response = conn.request(request)

			if response.body && !response.body.empty?
				result = JSON.parse(response.body)
			else
				result = {}
			end

			if response.code != '200'
				if result && result.key?('error')
					error = '"' + result['error'] + '"'
				else
					error = 'No additional error message received'
				end
				raise APIError.new('TestRail API returned HTTP %s (%s)' %
					[response.code, error])
			end
			
			result
		end
	end

	class APIError < StandardError
	end
end
