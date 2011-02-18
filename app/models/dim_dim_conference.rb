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

class DimDimConference < WebConference

  def infer_conference_settings
    self.conference_key ||= "instructure_#{self.feed_code}".gsub(/[^a-zA-Z0-9_]/, "_")
  end
  
  def conference_status
    require 'net/http'
    require 'uri'
    active = nil
    begin
      url = URI.parse("http://#{config[:domain]}/dimdim/IsMeetingKeyInUse.action?key=#{self.conference_key}&roomName=#{self.conference_key}")
      req = Net::HTTP::Get.new(url.path + '?' + url.query)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }
      if res && (res.is_a?(Net::HTTPFound) || res.is_a?(Net::HTTPMovedPermanently))
        url = URI.parse(res['location'])
        req = Net::HTTP::Get.new(url.path + '?' + url.query)
        res = Net::HTTP.start(url.host, url.port) {|http|
          http.request(req)
        }
      end
      active = !!res.body.match(/true/)
    rescue => e
    end
    active ? :active : :closed
  end

  def admin_join_url(user, return_to="http://www.instructure.com")
    "http://#{config[:domain]}/dimdim/html/envcheck/connect.action?action=host&email=#{CGI::escape(user.email)}&confKey=#{self.conference_key}&attendeePwd=#{self.attendee_key}&presenterPwd=#{self.presenter_key}&displayName=#{CGI::escape(user.name)}&meetingRoomName=#{self.conference_key}&confName=#{CGI::escape(self.title)}&presenterAV=av&collabUrl=#{CGI::escape("http://#{HostUrl.context_host(self.context)}/dimdim_welcome.html")}&returnUrl=#{CGI::escape(return_to)}"
  end
  
  def participant_join_url(user, return_to="http://www.instructure.com")
    "http://#{config[:domain]}/dimdim/html/envcheck/connect.action?action=join&email=#{CGI::escape(user.email)}&confKey=#{self.conference_key}&attendeePwd=#{self.attendee_key}&displayName=#{CGI::escape(user.name)}&meetingRoomName=#{self.conference_key}"
  end
  
end
