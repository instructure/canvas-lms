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

# includes Enrollment json helpers
module Api::V1::User
  include Api::V1::Json
  include AvatarHelper

  API_USER_JSON_OPTS = {
    :only => %w(id name).freeze,
    :methods => %w(sortable_name short_name).freeze
  }.freeze

  def user_json_preloads(users, preload_email=false, opts={})
    # for User#account
    ActiveRecord::Associations::Preloader.new.preload(users, :pseudonym => :account)

    # pseudonyms for SisPseudonym
    # pseudonyms account for Pseudonym#works_for_account?
    ActiveRecord::Associations::Preloader.new.preload(users, pseudonyms: :account) if user_json_is_admin?
    if preload_email && (no_email_users = users.reject(&:email_cached?)).present?
      # communication_channels for User#email if it is not cached
      ActiveRecord::Associations::Preloader.new.preload(no_email_users, :communication_channels)
    end
    if opts[:group_memberships]
      ActiveRecord::Associations::Preloader.new.preload(users, :group_memberships)
    end
  end

  def user_json(user, current_user, session, includes = [], context = @context, enrollments = nil, excludes = [], enrollment=nil)
    includes ||= []
    excludes ||= []
    api_json(user, current_user, session, API_USER_JSON_OPTS).tap do |json|
      enrollment_json_opts = { current_grading_period_scores: includes.include?('current_grading_period_scores') }
      if includes.include?('sis_user_id') || (!excludes.include?('pseudonym') && user_json_is_admin?(context, current_user))
        include_root_account = @domain_root_account.trust_exists?
        sis_context = enrollment || @domain_root_account
        pseudonym = SisPseudonym.for(user, sis_context, type: :implicit, require_sis: false)
        enrollment_json_opts[:sis_pseudonym] = pseudonym if pseudonym&.sis_user_id
        # the sis fields on pseudonym are poorly named -- sis_user_id is
        # the id in the SIS import data, where on every other table
        # that's called sis_source_id.

        if user_can_read_sis_data?(current_user, context)
          json.merge! :sis_user_id => pseudonym&.sis_user_id,
                      :integration_id => pseudonym&.integration_id
        end

        if !excludes.include?('pseudonym') && user_json_is_admin?(context, current_user)
          json[:sis_import_id] = pseudonym&.sis_batch_id if @domain_root_account.grants_right?(current_user, session, :manage_sis)
          json[:root_account] = HostUrl.context_host(pseudonym&.account) if include_root_account

          if pseudonym && context.grants_right?(current_user, session, :view_user_logins)
            json[:login_id] = pseudonym.unique_id
          end
        end
      end

      if includes.include?('avatar_url') && user.account.service_enabled?(:avatars)
        json[:avatar_url] = avatar_url_for_user(user, blank_fallback)
      end
      if enrollments
        json[:enrollments] = enrollments.map do |enrollment|
          enrollment_json(enrollment, current_user, session, includes, enrollment_json_opts)
        end
      end
      # include a permissions check here to only allow teachers and admins
      # to see user email addresses.
      if includes.include?('email') && !excludes.include?('personal_info') && context.grants_right?(current_user, session, :read_email_addresses)
        json[:email] = user.email
      end

      if includes.include?('bio') && !excludes.include?('personal_info') && @domain_root_account.enable_profiles? && user.profile
        json[:bio] = user.profile.bio
      end

      if includes.include?('sections')
        json[:sections] = user.enrollments.
          map(&:course_section).compact.uniq.
          map(&:name).join(", ")
      end

      # make sure this only runs if user_json_preloads has
      # been called with {group_memberships: true} in opts
      if includes.include?('group_ids')
        context_group_ids = get_context_groups(context)
        json[:group_ids] = context_group_ids & group_ids(user)
      end

      json[:locale] = user.locale if includes.include?('locale')
      json[:confirmation_url] = user.communication_channels.email.first.try(:confirmation_url) if includes.include?('confirmation_url')

      if includes.include?('last_login')
        last_login = user.read_attribute(:last_login)
        if last_login.is_a?(String)
          Time.use_zone('UTC') { last_login = Time.zone.parse(last_login) }
        end
        json[:last_login] = last_login.try(:iso8601)
      end

      if includes.include?('permissions')
        json[:permissions] = {
          :can_update_name => user.user_can_edit_name?,
          :can_update_avatar => service_enabled?(:avatars)
        }
      end

      if includes.include?('terms_of_use')
        json[:terms_of_use] = !!user.preferences[:accepted_terms]
      end

      if includes.include?('custom_links')
        json[:custom_links] = roster_user_custom_links(user)
      end

      if includes.include?('time_zone')
        zone = user.time_zone || @domain_root_account.try(:default_time_zone) || Time.zone
        json[:time_zone] = zone.name
      end

      if includes.include?('lti_id')
        json[:lti_id] = user.lti_context_id
      end
    end
  end

  def users_json(users, current_user, session, includes = [], context = @context, enrollments = nil, excludes = [])

    if includes.include?('sections')
      ActiveRecord::Associations::Preloader.new.preload(users, enrollments: :course_section)
    end

    if includes.include?('group_ids') && !context.is_a?(Groups)
      ActiveRecord::Associations::Preloader.new.preload(context, :groups)
    end

    users.map{ |user| user_json(user, current_user, session, includes, context, enrollments, excludes) }
  end

  # this mini-object is used for secondary user responses, when we just want to
  # provide enough information to display a user.
  # for instance, discussion entries return this json as a sub-object.
  #
  # if parent_context is given, the html_url will be scoped to that context, so:
  #   /courses/X/users/Y
  # otherwise it'll just be:
  #   /users/Y
  # keep in mind the latter form is only accessible if the user has a public profile
  # (or if the api caller is an admin)
  #
  # if parent_context is :profile, the html_url will always be the user's
  # public profile url, regardless of @current_user permissions
  def user_display_json(user, parent_context = nil)
    return {} unless user
    participant_url = case parent_context
      when :profile
        user_profile_url(user)
      when nil, false
        user_url(user)
      else
        polymorphic_url([parent_context, user])
      end
    hash = {
      id: user.id,
      display_name: user.short_name,
      avatar_image_url: avatar_url_for_user(user, blank_fallback),
      html_url: participant_url
    }
    hash[:fake_student] = true if user.fake_student?
    hash
  end

  def anonymous_user_display_json(anonymous_id)
    {
     anonymous_id: anonymous_id,
     avatar_image_url: User.default_avatar_fallback
    }
  end

  # optimization hint, currently user only needs to pull pseudonyms from the db
  # if a site admin is making the request or they can manage_students
  def user_json_is_admin?(context = @context, current_user = @current_user)
    return false if context.nil? || current_user.nil?
    @user_json_is_admin ||= {}
    @user_json_is_admin[[context.class.name, context.global_id, current_user.global_id]] ||= (
      if context.is_a?(::UserProfile)
        permissions_context = permissions_account = @domain_root_account
      else
        permissions_context = context
        permissions_account = context.is_a?(Account) ? context : context.account
      end
      !!(
        permissions_context.grants_any_right?(current_user, :manage_students, :read_sis) ||
        permissions_account.membership_for_user(current_user) ||
        permissions_account.root_account.grants_right?(current_user, :manage_sis)
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
                              :created_at,
                              :start_at,
                              :end_at,
                              :type
                            ]

  def enrollment_json(enrollment, user, session, includes = [], opts = {})
    api_json(enrollment, user, session, :only => API_ENROLLMENT_JSON_OPTS).tap do |json|
      json[:enrollment_state] = json.delete('workflow_state')
      if enrollment.course.workflow_state == 'deleted' || enrollment.course_section.workflow_state == 'deleted'
        json[:enrollment_state] = 'deleted'
      end
      json[:role] = enrollment.role.name
      json[:role_id] = enrollment.role_id
      json[:last_activity_at] = enrollment.last_activity_at
      json[:last_attended_at] = enrollment.last_attended_at
      json[:total_activity_time] = enrollment.total_activity_time
      if enrollment.root_account.grants_right?(user, session, :manage_sis)
        json[:sis_import_id] = enrollment.sis_batch_id
      end
      if enrollment.student?
        json[:grades] = grades_hash(enrollment, user, opts)
      end
      if user_can_read_sis_data?(@current_user, enrollment.course)
        json[:sis_account_id] = enrollment.course.account.sis_source_id
        json[:sis_course_id] = enrollment.course.sis_source_id
        json[:course_integration_id] = enrollment.course.integration_id
        json[:sis_section_id] = enrollment.course_section.sis_source_id
        json[:section_integration_id] = enrollment.course_section.integration_id
        pseudonym = opts.key?(:sis_pseudonym) ? opts[:sis_pseudonym] : sis_pseudonym_for(enrollment.user, enrollment)
        json[:sis_user_id] = pseudonym.try(:sis_user_id)
      end
      json[:html_url] = course_user_url(enrollment.course_id, enrollment.user_id)
      user_includes = includes.include?('avatar_url') ? ['avatar_url'] : []
      user_includes << 'group_ids' if includes.include?('group_ids')

      json[:user] = user_json(enrollment.user, user, session, user_includes, @context, nil, []) if includes.include?(:user)
      if includes.include?('locked')
        lockedbysis = enrollment.defined_by_sis?
        lockedbysis &&= !enrollment.course.account.grants_right?(@current_user, session, :manage_account_settings)
        json[:locked] = lockedbysis
      end
      if includes.include?('observed_users') && enrollment.observer? && enrollment.associated_user && !enrollment.associated_user.deleted?
        json[:observed_user] = user_json(enrollment.associated_user, user, session, user_includes, @context, enrollment.associated_user.not_ended_enrollments.all_student.shard(enrollment).where(:course_id => enrollment.course_id))
      end
      if includes.include?('can_be_removed')
        json[:can_be_removed] = (!enrollment.defined_by_sis? || context.grants_right?(@current_user, session, :manage_account_settings)) &&
                                  enrollment.can_be_deleted_by(@current_user, @context, session)
      end
    end
  end

  private
  def grades_hash(enrollment, user, opts = {})
    grades = {
      html_url: course_student_grades_url(enrollment.course_id, enrollment.user_id)
    }

    course = enrollment.course

    if grade_permissions?(user, enrollment)
      period = grading_period(enrollment.course, opts)
      score_opts = period ? { grading_period_id: period.id } : Score.params_for_course

      grades[:current_score] = enrollment.computed_current_score(score_opts)
      grades[:current_grade] = enrollment.computed_current_grade(score_opts)
      grades[:final_score]   = enrollment.computed_final_score(score_opts)
      grades[:final_grade]   = enrollment.computed_final_grade(score_opts)
      grades[:grading_period_id] = period&.id if opts[:current_grading_period_scores]

      if course.grants_any_right?(user, :manage_grades, :view_all_grades)
        grades[:unposted_current_score] = enrollment.unposted_current_score(score_opts)
        grades[:unposted_current_grade] = enrollment.unposted_current_grade(score_opts)
        grades[:unposted_final_score]   = enrollment.unposted_final_score(score_opts)
        grades[:unposted_final_grade]   = enrollment.unposted_final_grade(score_opts)
      end
    end
    grades
  end

  def grading_period(course, opts)
    return opts[:grading_period] if opts[:grading_period]
    return nil unless opts[:current_grading_period_scores]

    GradingPeriod.current_period_for(course)
  end

  def grade_permissions?(user, enrollment)
    course = enrollment.course

    (user.id == enrollment.user_id && !course.hide_final_grades?) ||
      course.grants_any_right?(user, :manage_grades, :view_all_grades) ||
      enrollment.user.grants_right?(user, :read_as_parent)
  end

  def get_context_groups(context)
    # make sure to preload groups if using this
    context.is_a?(Group) ?
      [context.id] :
      context.groups.map(&:id)
  end

  def sis_id_context(context)
    case context
    when Account, Course
      context
    when Group
      context.context
    else
      @domain_root_account
    end
  end

  def user_can_read_sis_data?(user, context)
    sis_id_context(context).grants_right?(user, :read_sis) || @domain_root_account.grants_right?(user, :manage_sis)
  end

  def sis_pseudonym_for(user, context=@domain_root_account)
    SisPseudonym.for(user, context, type: :trusted)
  end

  def group_ids(user)
    if user.group_memberships.loaded?
      user.group_memberships.map(&:group_id)
    else
      user.group_memberships.pluck(:group_id)
    end
  end
end
