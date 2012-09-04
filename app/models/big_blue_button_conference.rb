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

class BigBlueButtonConference < WebConference

  def initiate_conference
    return conference_key if conference_key && !retouch?
    unless self.conference_key
      self.conference_key = "instructure_#{self.feed_code}".gsub(/[^a-zA-Z0-9_]/, "_")
      chars = ('a'..'z').to_a + ('0'..'9').to_a
      # create user/admin passwords for this conference. we may want to show
      # the admin passwords in the ui in case moderators need them for any
      # admin-specific functionality within the BBB ui (or we could provide
      # ui for them to specify the password/key)
      settings[:user_key] = 8.times.map{ chars[chars.size * rand] }.join
      settings[:admin_key] = 8.times.map{ chars[chars.size * rand] }.join until settings[:admin_key] && settings[:admin_key] != settings[:user_key]
    end
    send_request(:create, {
      :meetingID => conference_key,
      :name => title,
      :voiceBridge => "%020d" % self.global_id,
      :attendeePW => settings[:user_key],
      :moderatorPW => settings[:admin_key],
      :logoutURL => (settings[:default_return_url] || "http://www.instructure.com")
    }) or return nil
    save
    conference_key
  end

  def conference_status
    if (result = send_request(:isMeetingRunning, :meetingID => conference_key)) && result[:running] == 'true'
      :active
    else
      :closed
    end
  end

  def admin_join_url(user, return_to = "http://www.instructure.com")
    join_url(user, :admin)
  end

  def participant_join_url(user, return_to = "http://www.instructure.com")
    join_url(user)
  end

  private

  def retouch?
    # by default, BBB will remove chat rooms that have been idle for more than
    # an hour. so if an admin creates a room and then leaves, and then a user
    # tries to join more than an hour later, we need to make sure we recreate
    # the room before we redirect the user. there's no harm in "creating" a
    # room that already exists, the api will just return the room info.
    updated_at < 30.minutes.ago
  end

  def join_url(user, type = :user)
    generate_request :join,
      :fullName => user.name,
      :meetingID => conference_key,
      :password => settings[(type == :user ? :user_key : :admin_key)],
      :userID => user.id
  end

  def generate_request(action, options)
    query_string = options.to_query
    query_string << ("&checksum=" + Digest::SHA1.hexdigest(action.to_s + query_string + config[:secret_dec]))
    "http://#{config[:domain]}/bigbluebutton/api/#{action}?#{query_string}"
  end

  def send_request(action, options)
    uri = URI.parse(generate_request(action, options))
    res = nil

    Net::HTTP.start(uri.host, uri.port) do |http|
      http.read_timeout = 10
      5.times do # follow redirects, but not forever
        logger.debug "big blue button api call: #{uri.path}?#{uri.query}"
        res = http.request_get("#{uri.path}?#{uri.query}")
        break unless res.is_a?(Net::HTTPRedirection)
        url = res['location']
        uri = URI.parse(url)
      end
    end

    case res
      when Net::HTTPSuccess
        response = Nokogiri::XML(res.body).at_css("response").children.
          inject({}){ |hash, node| hash[node.name.downcase.to_sym] = node.content; hash }
        if response[:returncode] == 'SUCCESS'
          return response
        else
          logger.error "big blue button api error #{response[:message]} (#{response[:messagekey]})"
        end
      else
        logger.error "big blue button http error #{res}"
    end
    nil
  rescue Timeout::Error
    logger.error "big blue button timeout error"
    nil
  rescue
    logger.error "big blue button unhandled exception #{$!}"
    nil
  end
end
