#
# Copyright (C) 2012 - present Instructure, Inc.
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

# includes Enrollment json helpers
module Api::V1::UserProfile
  include Api::V1::User

  def user_profile_json(profile, current_user, session, includes = [], context = @context)
    includes ||= []

    user = profile.user

    json = user_json(user, current_user, session, 'avatar_url', context)
    # don't unintentionally include stuff added to user_json
    json.slice! :id, :name, :short_name, :sortable_name, :sis_user_id,
                :sis_login_id, :login_id, :avatar_url, :integration_id

    json[:title] = profile.title
    json[:bio] = profile.bio
    json[:primary_email] = user.email if user.grants_right?(current_user, :read_email_addresses)
    json[:login_id] ||= user.primary_pseudonym.try(:unique_id)
    json[:integration_id] ||= user.primary_pseudonym.try(:integration_id)
    zone = user.time_zone || @domain_root_account.try(:default_time_zone) || Time.zone
    json[:time_zone] = zone.tzinfo.name
    json[:locale] = user.locale

    if user == current_user
      json[:calendar] = {:ics => "#{feeds_calendar_url(user.feed_code)}.ics"}
      json[:lti_user_id] = user.lti_context_id if user.lti_context_id.present?
    end

    if includes.include? 'user_services'
      services = user == current_user ?
        user.user_services :
        user.user_services.visible

      json[:user_services] = services.map { |s| user_service_json(s, current_user, session) }
    end

    if includes.include? 'links'
      json[:links] = profile.links.map { |l| user_profile_link_json(l, current_user, session) }
    end

    json
  end

  def user_service_json(user_service, current_user, session)
    api_json(user_service, current_user, session,
             :only => %w(service visible),
             :methods => %(service_user_link))
  end

  def user_profile_link_json(link, current_user, session)
    api_json(link, current_user, session, :only => %w(url title))
  end
end
