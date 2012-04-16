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

# includes Enrollment json helpers
module Api::V1::User
  include Api::V1::Json

  API_USER_JSON_OPTS = {
    :only => %w(id name email),
    :methods => %w(sortable_name short_name)
  }

  def user_json(user, current_user, session, includes = [], context = @context, enrollments = nil)
    includes ||= []
    api_json(user, current_user, session, API_USER_JSON_OPTS).tap do |json|
      if user_json_is_admin?(context, current_user)
        if sis_pseudonym = user.sis_pseudonym_for(@domain_root_account)
          # the sis fields on pseudonym are poorly named -- sis_user_id is
          # the id in the SIS import data, where on every other table
          # that's called sis_source_id.
          json.merge! :sis_user_id => sis_pseudonym.sis_user_id,
                      # TODO: don't send sis_login_id; it's garbage data
                      :sis_login_id => sis_pseudonym.unique_id if @domain_root_account.grants_rights?(current_user, :read_sis, :manage_sis).values.any?
        end
        if pseudonym = sis_pseudonym || user.find_pseudonym_for_account(@domain_root_account)
          json[:login_id] = pseudonym.unique_id
        end
      end
      if service_enabled?(:avatars) && includes.include?('avatar_url')
        json[:avatar_url] = avatar_image_url(User.avatar_key(user.id))
      end
      if enrollments
        json[:enrollments] = enrollments.map { |e| enrollment_json(e, current_user, session, includes) }
      end
      json[:email] = user.email if includes.include?('email')
      json[:locale] = user.locale if includes.include?('locale')
    end
  end

  # optimization hint, currently user only needs to pull pseudonyms from the db
  # if a site admin is making the request or they can manage_students
  def user_json_is_admin?(context = @context, current_user = @current_user)
    @user_json_is_admin ||= {}
    @user_json_is_admin[[context.id, current_user.id]] ||= (
      if context.is_a?(UserProfile)
        permissions_context = permissions_account = @domain_root_account
      else
        permissions_context = context
        permissions_account = context.is_a?(Account) ? context : context.account
      end
      !!(
        permissions_context.grants_right?(current_user, :manage_students) ||
        permissions_account.membership_for_user(current_user) ||
        permissions_account.root_account.grants_rights?(current_user, :manage_sis, :read_sis).values.any?
      )
    )
  end

  API_ENROLLMENT_JSON_OPTS = [:id,
                              :root_account_id,
                              :user_id,
                              :course_id,
                              :course_section_id,
                              :associated_user_id,
                              :limit_privileges_to_course_section,
                              :workflow_state,
                              :updated_at,
                              :type]

  def enrollment_json(enrollment, user, session, includes = [])
    api_json(enrollment, user, session, :only => API_ENROLLMENT_JSON_OPTS).tap do |json|
      json[:enrollment_state] = json.delete('workflow_state')
      if enrollment.student?
        json[:grades] = {
          :html_url => course_student_grades_url(enrollment.course_id, enrollment.user_id),
        }
      end
      json[:html_url] = course_user_url(enrollment.course_id, enrollment.user_id)
      user_includes = includes.include?('avatar_url') ? ['avatar_url'] : []
      json[:user] = user_json(enrollment.user, user, session, user_includes) if includes.include?(:user)
      if includes.include?('locked')
        lockedbysis = enrollment.defined_by_sis?
        lockedbysis &&= !enrollment.course.account.grants_right?(@current_user, session, :manage_account_settings)
        json[:locked] = lockedbysis
      end
    end
  end
end
