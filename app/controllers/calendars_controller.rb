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
  before_action :require_user

  def show
    get_context
    get_all_pertinent_contexts(include_groups: true, favorites_first: true, cross_shard: true)
    @manage_contexts = @contexts.select { |c|
      c.grants_right?(@current_user, session, :manage_calendar)
    }.map(&:asset_string)
    @feed_url = feeds_calendar_url((@context_enrollment || @context).feed_code)
    if params[:include_contexts]
      @selected_contexts = params[:include_contexts].split(",")
    elsif @current_user.preferences[:selected_calendar_contexts]
      @selected_contexts = @current_user.preferences[:selected_calendar_contexts]
    end
    @wrap_titles = @domain_root_account && @domain_root_account.feature_enabled?(:wrap_calendar_event_titles)
    # somewhere there's a bad link that doesn't separate parameters properly.
    # make sure we don't do a find on a non-numeric id.
    if params[:event_id] && params[:event_id] =~ Api::ID_REGEX && (event = CalendarEvent.where(id: params[:event_id]).first) && event.start_at
      @active_event_id = event.id
      @view_start = event.start_at.in_time_zone.strftime("%Y-%m-%d")
    end
    @contexts_json = @contexts.map do |context|
      ag_permission = false
      if context.respond_to?(:appointment_groups) && context.grants_right?(@current_user, session, :manage_calendar)
        ag = AppointmentGroup.new(:contexts => [context])
        ag.update_contexts_and_sub_contexts
        if ag.grants_right? @current_user, session, :create
          ag_permission = {:all_sections => true}
        else
          section_ids = context.section_visibilities_for(@current_user).map { |v| v[:course_section_id] }
          ag_permission = {:all_sections => false, :section_ids => section_ids} if section_ids.any?
        end
      end
      info = {
        :name => context.nickname_for(@current_user),
        :asset_string => context.asset_string,
        :id => context.id,
        :url => named_context_url(context, :context_url),
        :create_calendar_event_url => context.respond_to?("calendar_events") ? named_context_url(context, :context_calendar_events_url) : '',
        :create_assignment_url => context.respond_to?("assignments") ? named_context_url(context, :api_v1_context_assignments_url) : '',
        :create_appointment_group_url => context.respond_to?("appointment_groups") ? api_v1_appointment_groups_url() : '',
        :new_calendar_event_url => context.respond_to?("calendar_events") ? named_context_url(context, :new_context_calendar_event_url) : '',
        :new_assignment_url => context.respond_to?("assignments") ? named_context_url(context, :new_context_assignment_url) : '',
        :calendar_event_url => context.respond_to?("calendar_events") ? named_context_url(context, :context_calendar_event_url, '{{ id }}') : '',
        :assignment_url => context.respond_to?("assignments") ? named_context_url(context, :api_v1_context_assignment_url, '{{ id }}') : '',
        :assignment_override_url => context.respond_to?(:assignments) ? api_v1_assignment_override_url(:course_id => context.id, :assignment_id => '{{ assignment_id }}', :id => '{{ id }}') : '',
        :appointment_group_url => context.respond_to?("appointment_groups") ? api_v1_appointment_groups_url(:id => '{{ id }}') : '',
        :can_create_calendar_events => context.respond_to?("calendar_events") && CalendarEvent.new.tap{|e| e.context = context}.grants_right?(@current_user, session, :create),
        :can_create_assignments => context.respond_to?("assignments") && Assignment.new.tap{|a| a.context = context}.grants_right?(@current_user, session, :create),
        :assignment_groups => context.respond_to?("assignments") ? context.assignment_groups.active.pluck(:id, :name).map {|id, name| { :id => id, :name => name } } : [],
        :can_create_appointment_groups => ag_permission,
        :can_update_todo_date => context.grants_right?(@current_user, session, :manage),
        :can_update_discussion_topic => context.grants_right?(@current_user, session, :moderate_forum),
        :can_update_wiki_page => context.grants_right?(@current_user, session, :manage_wiki),
        :concluded => (context.is_a? Course) ? context.concluded? : false
      }
      if context.respond_to?("course_sections")
        info[:course_sections] = context.course_sections.active.pluck(:id, :name).map do |id, name|
          hash = { :id => id, :asset_string => "course_section_#{id}", :name => name}
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
      end
      if ag_permission && ag_permission[:all_sections] && context.respond_to?("group_categories")
        info[:group_categories] = context.group_categories.active.pluck(:id, :name).map {|id, name| { :id => id, :asset_string => "group_category_#{id}", :name => name } }
      end
      info
    end
    StringifyIds.recursively_stringify_ids(@contexts_json)
    js_env(@hash) if @hash
  end
end
