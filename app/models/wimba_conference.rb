#
# Copyright (C) 2011 Instructure, Inc.
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

require 'net/http'
require 'uri'

class WimbaConference < WebConference
  def server
    config[:domain]
  end

  def craft_api_url(action, opts={})
    url = "http://#{server}/admin/api/api.pl"
    query_string = "function=#{action.to_s}"
    opts.each do |key, val|
      query_string += "&#{CGI::escape(key)}=#{CGI::escape(val.to_s)}"
    end
    url + "?" + query_string
  end

  def send_request(action, opts={})
    headers = {}
    if action.to_s == 'Init'
      url = craft_api_url('NoOp', {
        'AuthType'     => 'AuthCookieHandler',
        'AuthName'     => 'Horizon',
        'credential_0' => config[:user],
        'credential_1' => config[:password_dec]
      })
    else
      init_session or return nil
      url = craft_api_url(action, opts)
      headers['Cookie'] = @auth_cookie
    end

    uri = URI.parse(url)
    res = nil
    # TODO: rework this so that we reuse the same tcp conn (we may call
    # send_request multiple times in the course of one browser request).
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      5.times do # follow redirects, but not forever
        logger.debug "wimba api call: #{uri.path}?#{uri.query}"
        res = http.request_get("#{uri.path}?#{uri.query}", headers)
        if res['Set-Cookie'] && res['Set-Cookie'] =~ /AuthCookieHandler_Horizon=.*;/
          @auth_cookie = headers['Cookie'] = res['Set-Cookie'].sub(/.*(AuthCookieHandler_Horizon=.*?);.*/, '\\1')
        end
        if res.is_a?(Net::HTTPRedirection)
          url = res['location']
          uri = URI.parse(url)
        else
          break
        end
      end
    end

    case res
      when Net::HTTPSuccess
        api_status = res.body.to_s.split("\n").first.split(" ", 2)
        if api_status[0] == "100"
          logger.debug "wimba api success: #{res.body}"
          return res.body
        end
        # any other status indicates an error
        logger.error "wimba api error #{api_status[1]} (#{api_status[0]})"
      else
        logger.error "wimba http error #{res}"
    end
    nil
  rescue Timeout::Error
    logger.error "wimba timeout error"
    nil
  rescue
    logger.error "wimba unhandled exception #{$!}"
    nil
  end

  def add_user_to_conference(user, role='participant')
    names = user.last_name_first.split(/, /, 2)
    (
      send_request('modifyUser', {
        'target' => wimba_id(user.uuid),
        'password_type' => 'A',
        'first_name' => names[1],
        'last_name' => names[0]}) ||
      send_request('createUser', {
        'target' => wimba_id(user.uuid),
        'password_type' => 'A',
        'first_name' => names[1],
        'last_name' => names[0]})
    ) &&
    send_request('createRole', {
      'target' => wimba_id,
      'user_id' => wimba_id(user.uuid),
      'role_id' => (role == 'participant' ? 'Student' : 'Instructor')
    })
  end

  def remove_user_from_conference(user)
    send_request('deleteRole', {
      'target' => wimba_id,
      'user_id' => wimba_id(user.uuid)
    })
  end

  def join_url(user)
    if (res = send_request('getAuthToken', {
        'target'    => wimba_id(user.uuid),
        'nickname' => user.name.gsub(/[^a-zA-Z0-9]/, '')
      })) && (token = res.split("\n").detect{|s| s.match(/^authToken/) })
      "http://#{server}/launcher.cgi.pl?hzA=#{CGI::escape(token.split(/=/, 2).last.chomp)}&room=#{CGI::escape(wimba_id)}"
    end
  end

  def admin_join_url(user, return_to="http://www.instructure.com")
    add_user_to_conference(user, :admin) &&
    join_url(user)
  end

  def participant_join_url(user, return_to="http://www.instructure.com")
    add_user_to_conference(user) &&
    join_url(user)
  end

  def initiate_conference
    return conference_key if conference_key
    self.conference_key = uuid
    send_request('createClass', {
      'target' => wimba_id,
      'longname' => title[0,50],
      'preview' => '0' # we want the room open by default
    }) or return nil
    save
    conference_key
  end

  def init_session
    if !@auth_cookie
      send_request('Init') or return false
    end
    true
  end

  def conference_status
    active = nil
    if res = send_request('statusClass', {'target' => wimba_id})
      res.split(/\r?\n/).each do |str|
        key, value = str.strip.split(/=/, 2)
        if key == 'num_users'
          return :closed unless value.to_i > 0
          active = true
        end
        if key == 'roomlock'
          return :closed if value.to_i == 1
          active = true
        end
      end
    end
    active ? :active : :closed
  end

  def wimba_id(id = uuid)
    # wimba ids are limited to 34 chars. assuming we are using uuids, we can put an "IN" prefix,
    # which makes distinguishing these users easier.
    "IN" + id.delete("-")[0,32]
  end

end
