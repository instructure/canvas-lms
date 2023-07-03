# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class WimbaConference < WebConference
  external_url :archive,
               name: -> { t("external_urls.archive", "Archive") },
               link_text: -> { t("external_urls.archive_link", "View archive(s)") },
               restricted_to: ->(conf) { conf.active? || conf.finished? }

  def archive_external_url(user, url_id)
    urls = []
    if (res = send_request("listClass", { "filter00" => "archive_of", "filter00value" => wimba_id, "attribute" => "longname" }))
      res.delete_prefix("100 OK\n").split(/\n=END RECORD\n?/).each do |match|
        data = match.split("\n").each_with_object({}) do |line, hash|
          key, val = line.split("=", 2)
          hash[key.to_sym] = val
        end
        unless data[:longname] && data[:class_id]
          logger.error "wimba error reading archive list"
          break
        end
        if (date_info = data[:longname].match(Regexp.new(" - (\\d{2}/\\d{2}/\\d{4} \\d{2}:\\d{2})\\z")))
          # convert from wimba's local time to the user's local time
          tz       = ActiveSupport::TimeZone[config[:timezone] || config[:plugin].default_settings[:timezone]]
          new_date = nil

          Time.use_zone(tz) do
            new_date = datetime_string(DateTime.strptime(date_info[1], "%m/%d/%Y %H:%M"))
          end

          data[:longname].sub!(date_info[1], new_date)
        end
        urls << { id: data[:class_id], name: data[:longname] } unless url_id && data[:class_id] != url_id
      end
      urls.first[:url] = join_url(user, urls.first[:id]) if urls.size == 1 && touch_user(user)
    end
    urls
  end

  def server
    config[:domain]
  end

  def craft_api_url(action, opts = {})
    url = "http://#{server}/admin/api/api.pl"
    query_string = "function=#{action}"
    opts.each do |key, val|
      query_string += "&#{CGI.escape(key)}=#{CGI.escape(val.to_s)}"
    end
    url + "?" + query_string
  end

  def send_request(action, opts = {})
    headers = {}
    if action.to_s == "Init"
      url = craft_api_url("NoOp", {
                            "AuthType" => "AuthCookieHandler",
                            "AuthName" => "Horizon",
                            "credential_0" => config[:user],
                            "credential_1" => config[:password_dec]
                          })
    else
      init_session or return nil
      url = craft_api_url(action, opts)
      headers["Cookie"] = @auth_cookie
    end

    uri = URI.parse(url)
    res = nil
    # TODO: rework this so that we reuse the same tcp conn (we may call
    # send_request multiple times in the course of one browser request).
    Canvas.timeout_protection("wimba") do
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.read_timeout = 10
        5.times do # follow redirects, but not forever
          logger.debug "wimba api call: #{uri.path}?#{uri.query}"
          res = http.request_get("#{uri.path}?#{uri.query}", headers)
          if res["Set-Cookie"] && res["Set-Cookie"] =~ /AuthCookieHandler_Horizon=.*;/
            @auth_cookie = headers["Cookie"] = res["Set-Cookie"].sub(/.*(AuthCookieHandler_Horizon=.*?);.*/, "\\1")
          end
          if res.is_a?(Net::HTTPRedirection)
            url = res["location"]
            uri = URI.parse(url)
          else
            break
          end
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
  rescue
    logger.error "wimba unhandled exception #{$!}"
    nil
  end

  def touch_user(user)
    send_request("modifyUser", {
                   "target" => wimba_id(user.uuid),
                   "password_type" => "A",
                   "first_name" => user.first_name,
                   "last_name" => user.last_name
                 }) ||
      send_request("createUser", {
                     "target" => wimba_id(user.uuid),
                     "password_type" => "A",
                     "first_name" => user.first_name,
                     "last_name" => user.last_name
                   })
  end

  def add_user_to_conference(user, role = :participant)
    touch_user(user) &&
      send_request("createRole", {
                     "target" => wimba_id,
                     "user_id" => wimba_id(user.uuid),
                     "role_id" => case role
                                  when :presenter then "Instructor"
                                  when :admin then "ClassAdmin"
                                  else "Student"
                                  end
                   })
  end

  def remove_user_from_conference(user)
    send_request("deleteRole", {
                   "target" => wimba_id,
                   "user_id" => wimba_id(user.uuid)
                 })
  end

  def join_url(user, room_id = wimba_id)
    (token = get_auth_token(user)) &&
      "http://#{server}/launcher.cgi.pl?hzA=#{CGI.escape(token)}&room=#{CGI.escape(room_id)}"
  end

  def settings_url(user, room_id = wimba_id)
    (token = get_auth_token(user)) &&
      "http://#{server}/admin/class/create_manage_frameset.html.epl?hzA=#{CGI.escape(token)}&class_id=#{CGI.escape(room_id)}"
  end

  def get_auth_token(user)
    (res = send_request("getAuthToken", {
                          "target" => wimba_id(user.uuid),
                          "nickname" => user.name.gsub(/[^a-zA-Z0-9]/, "")
                        })) &&
      (token = res.split("\n").detect { |s| s.match(/^authToken/) }) &&
      token.split("=", 2).last.chomp
  end

  def admin_join_url(user, _return_to = nil)
    add_user_to_conference(user, :presenter) &&
      join_url(user)
  end

  def admin_settings_url(user, _return_to = nil)
    (initiate_conference and touch) or return nil
    add_user_to_conference(user, :admin) &&
      settings_url(user)
  end

  def participant_join_url(user, _return_to = nil)
    add_user_to_conference(user) &&
      join_url(user)
  end

  def initiate_conference
    return conference_key if conference_key

    self.conference_key = uuid
    send_request("createClass", {
                   "target" => wimba_id,
                   "longname" => title[0, 50],
                   "preview" => "0", # we want the room open by default
                   "auto_open_new_archives" => "1"
                 }) or return nil
    save
    conference_key
  end

  def init_session
    unless @auth_cookie
      send_request("Init") or return false
    end

    true
  end

  def conference_status
    active = nil
    if (res = send_request("statusClass", { "target" => wimba_id }))
      res.split(/\r?\n/).each do |str|
        key, value = str.strip.split("=", 2)
        if key == "num_users"
          return :closed unless value.to_i > 0

          active = true
        end
        next unless key == "roomlock"
        return :closed if value.to_i == 1

        active = true
      end
    end
    active ? :active : :closed
  end

  def wimba_id(id = uuid)
    # wimba ids are limited to 34 chars. assuming we are using uuids, we can put an "IN" prefix,
    # which makes distinguishing these users easier.
    "IN" + id.delete("-")[0, 32]
  end
end
