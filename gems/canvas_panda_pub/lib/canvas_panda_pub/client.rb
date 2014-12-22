#
# Copyright (C) 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'uri'
require 'jwt'
require 'json'

module CanvasPandaPub

  # Public: Used for sending pushes to PandaPub channels and generating PandaPub
  # tokens to send to clients.

  class Client
    def self.config
      res = CanvasPandaPub.plugin_settings.try(:settings)
      return nil unless res && res['base_url'] && res['application_id'] &&
                               res['key_id'] && res['key_secret']

      res['push_url'] = res['base_url'].chomp("/") + "/push"
      res.dup
    end

    def initialize
      config = CanvasPandaPub::Client.config
      @base_url = config['base_url']
      @application_id = config['application_id']
      @key_id = config['key_id']
      @key_secret = config['key_secret']
      @logger = CanvasPandaPub.logger
      @worker = CanvasPandaPub.worker
      @uri = URI.parse(@base_url)
    end

    # Post a status update to a PandaPub channel.
    #
    # The semantics of this call are this:
    #
    #  * When posting to channel X multiple times, the earlier ones may never
    #    be sent.
    #  * Calls will be throttled to some configured value.
    #
    #  This method is appropriate for sending complete updates that deprecate
    #  older updates. Consider a model that represents progress. Every time it
    #  is saved, you may want to post an update like { state: 'running', progress: 0.45 }.
    #  The last update is the only one that matters, so if you called that twice in
    #  a row really quickly with slightly different values, only the last would be
    #  delivered.
    #
    #  channel - A String representing the PandaPub channel to post to. It should
    #    not include the application id, as that will be added by the library.
    #  payload - A Hash with the payload. It will be converted to JSON with JSON.dump.

    def post_update(channel, payload)
      path = "/channel/#{@application_id}#{channel}"
      request = Net::HTTP::Post.new(path, {
        "Content-Type" => "application/json"
      })
      request.basic_auth @key_id, @key_secret

      body = JSON.dump(payload)

      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = (@uri.scheme == "https")

      unless @worker.push(channel, Proc.new { http.request(request, body) })
        @logger.warn("dropped pandapub notification for #{channel}")
      end
    end

    # Generate a token for subscribing to a channel.
    #
    # channel - A String with the channel to be subscribed to. Don't include the application
    #   id.
    # read - true if this token should allow reading from the channel.
    # write - true if this token should allow posting to the channel.
    # expires - A Date object specifying when the token should expire.
    #
    # Returns a String token.

    def generate_token(channel, read = false, write = false, expires = 1.hour.from_now)
      JWT.encode({
        keyId: @key_id,
        channel: "/#{@application_id}#{channel}",
        pub: write,
        sub: read,
        exp: expires.to_i
      }, @key_secret)
    end
  end
end
