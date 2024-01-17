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

class CalendarsController < ApplicationController
  include Api::V1::Conferences
  include CalendarConferencesHelper

  before_action :require_user

  def show
    get_context
    @show_account_calendars = @current_user.all_account_calendars.any?
    get_all_pertinent_contexts(include_groups: true, include_accounts: @show_account_calendars, favorites_first: true, cross_shard: true)
    @manage_contexts = @contexts.select do |c|
      c.grants_right?(@current_user, session, :manage_calendar)
    end.map(&:asset_string)
    @feed_url = feeds_calendar_url((@context_enrollment || @context).feed_code)

    @account_calendar_events_seen = @current_user.get_preference(:account_calendar_events_seen)
    @viewed_auto_subscribed_account_calendars = @current_user.get_preference(:viewed_auto_subscribed_account_calendars) || []
    @selected_contexts = if params[:include_contexts]
                           params[:include_contexts].split(",")
                         else
                           viewed_auto_sub_cal_asset_strings = @current_user.all_account_calendars.select { |c| @viewed_auto_subscribed_account_calendars.include? c.global_id }.pluck(:asset_string)
                           all_auto_sub_cals = @current_user.all_account_calendars.select { |c| c[:account_calendar_subscription_type] == "auto" }.pluck(:asset_string)
                           unseen_auto_sub_cals = all_auto_sub_cals - viewed_auto_sub_cal_asset_strings
                           current_user_selected_cals = @current_user.get_preference(:selected_calendar_contexts)
                           unless current_user_selected_cals.nil?
                             current_user_selected_cals = Array(current_user_selected_cals)
                             @current_user.set_preference(:selected_calendar_contexts, ((current_user_selected_cals || []) + unseen_auto_sub_cals).uniq)
                           end
                           @current_user.get_preference(:selected_calendar_contexts)
                         end

    # somewhere there's a bad link that doesn't separate parameters properly.
    # make sure we don't do a find on a non-numeric id.
    if params[:event_id] && params[:event_id] =~ Api::ID_REGEX && (event = CalendarEvent.where(id: params[:event_id]).first) && event.start_at
      @active_event_id = event.id
      @view_start = event.start_at.in_time_zone.strftime("%Y-%m-%d")
    end
    @contexts_json = @contexts.map do |context|
      ag_permission = false
      if context.respond_to?(:appointment_groups) && context.grants_right?(@current_user, session, :manage_calendar)
        ag = AppointmentGroup.new(contexts: [context])
        ag.update_contexts_and_sub_contexts
        if ag.grants_right? @current_user, session, :create
          ag_permission = { all_sections: true }
        else
          all_course_sections = CourseSection.find(context.section_visibilities_for(@current_user).pluck(:course_section_id).map { |cs_id| Shard.global_id_for(cs_id, context.shard) })
          section_ids = all_course_sections.select { |cs| cs.grants_right?(@current_user, session, :manage_calendar) }.pluck(:id)
          ag_permission = { all_sections: false, section_ids: } if section_ids.any?
        end
      end
      info = {
        name: context.nickname_for(@current_user),
        asset_string: context.asset_string,
        id: context.id,
        type: context.class.to_s.downcase,
        url: named_context_url(context, :context_url),
        create_calendar_event_url: context.respond_to?(:calendar_events) ? named_context_url(context, :context_calendar_events_url) : "",
        create_assignment_url: context.respond_to?(:assignments) ? named_context_url(context, :api_v1_context_assignments_url) : "",
        create_appointment_group_url: context.respond_to?(:appointment_groups) ? api_v1_appointment_groups_url : "",
        new_calendar_event_url: context.respond_to?(:calendar_events) ? named_context_url(context, :new_context_calendar_event_url) : "",
        new_assignment_url: context.respond_to?(:assignments) ? named_context_url(context, :new_context_assignment_url) : "",
        calendar_event_url: context.respond_to?(:calendar_events) ? named_context_url(context, :context_calendar_event_url, "{{ id }}") : "",
        assignment_url: context.respond_to?(:assignments) ? named_context_url(context, :api_v1_context_assignment_url, "{{ id }}") : "",
        assignment_override_url: context.respond_to?(:assignments) ? api_v1_assignment_override_url(course_id: context.id, assignment_id: "{{ assignment_id }}", id: "{{ id }}") : "",
        appointment_group_url: context.respond_to?(:appointment_groups) ? api_v1_appointment_groups_url(id: "{{ id }}") : "",
        can_create_calendar_events: context.respond_to?(:calendar_events) && CalendarEvent.new.tap { |e| e.context = context }.grants_right?(@current_user, session, :create),
        can_create_assignments: context.respond_to?(:assignments) && Assignment.new.tap { |a| a.context = context }.grants_right?(@current_user, session, :create),
        assignment_groups: context.respond_to?(:assignments) ? context.assignment_groups.active.pluck(:id, :name).map { |id, name| { id:, name: } } : [],
        can_create_appointment_groups: ag_permission,
        user_is_student: context.grants_right?(@current_user, :participate_as_student),
        can_update_todo_date: context.grants_any_right?(@current_user, session, :manage_content, :manage_course_content_edit),
        can_update_discussion_topic: context.grants_right?(@current_user, session, :moderate_forum),
        can_update_wiki_page: context.grants_right?(@current_user, session, :update),
        concluded: context.is_a?(Course) ? context.concluded? : false,
        k5_course: context.is_a?(Course) && context.elementary_enabled?,
        k5_account: context.is_a?(Account) && context.enable_as_k5_account?,
        course_pacing_enabled: context.is_a?(Course) && @domain_root_account.feature_enabled?(:course_paces) && context.enable_course_paces,
        user_is_observer: context.is_a?(Course) && context.enrollments.where(user_id: @current_user).first&.observer?,
        default_due_time: context.is_a?(Course) && context.default_due_time,
        can_view_context: context.grants_right?(@current_user, session, :read),
        allow_observers_in_appointment_groups: context.is_a?(Course) && context.account.allow_observers_in_appointment_groups?,
      }
      if context.is_a?(Course)
        info[:course_conclude_at] = context.restrict_enrollments_to_course_dates ? context.conclude_at : context.enrollment_term.end_at
      end
      if context.respond_to?(:course_sections) && !context.is_a?(Account)
        info[:course_sections] = context.course_sections.active.pluck(:id, :name).map do |id, name|
          hash = { id:, asset_string: "course_section_#{id}", name: }
          if ag_permission
            hash[:can_create_ag] = ag_permission[:all_sections] || ag_permission[:section_ids].include?(id)
          end
          hash
        end
      end
      if context.is_a? Course
        post_to_sis = Assignment.sis_grade_export_enabled?(context)
        sis_name = AssignmentUtil.post_to_sis_friendly_name(context)
        max_name_length_required_for_account = AssignmentUtil.name_length_required_for_account?(context)
        max_name_length = AssignmentUtil.assignment_max_name_length(context)
        due_date_required_for_account = AssignmentUtil.due_date_required_for_account?(context)

        @hash = {
          POST_TO_SIS: post_to_sis,
          SIS_NAME: sis_name,
          MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT: max_name_length_required_for_account,
          MAX_NAME_LENGTH: max_name_length,
          DUE_DATE_REQUIRED_FOR_ACCOUNT: due_date_required_for_account
        }
      elsif context.is_a? Account
        info[:auto_subscribe] = context.account_calendar_subscription_type == "auto"
        info[:viewed_auto_subscribed_account_calendars] = @viewed_auto_subscribed_account_calendars.include?(context.global_id)
      end
      if ag_permission && ag_permission[:all_sections] && context.respond_to?(:group_categories)
        info[:group_categories] = context.group_categories.active.pluck(:id, :name).map { |id, name| { id:, asset_string: "group_category_#{id}", name: } }
      end
      info
    end
    # NOTE: which account calendars the user will have now seen
    @current_user.set_preference(:viewed_auto_subscribed_account_calendars, @contexts.select { |c| c.class.to_s.downcase == "account" && c.account_calendar_subscription_type == "auto" }.map(&:global_id))

    StringifyIds.recursively_stringify_ids(@contexts_json)
    content_for_head helpers.auto_discovery_link_tag(:atom, @feed_url + ".atom", { title: t(:feed_title, "Course Calendar Atom Feed") })
    js_env(@hash) if @hash

    calendar_contexts = (@contexts + [@domain_root_account]).uniq
    add_conference_types_to_js_env(calendar_contexts)

    enrollment_types_tags = @current_user.participating_enrollments.pluck(:type).uniq.map { |type| "enrollment_type:#{type}" }
    InstStatsd::Statsd.increment("calendar.visit", tags: enrollment_types_tags)
  end
end
