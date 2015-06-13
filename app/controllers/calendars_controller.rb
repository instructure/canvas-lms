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

class CalendarsController < ApplicationController
  before_filter :require_user, :except => [ :public_feed ]

  def show2
    get_context
    get_all_pertinent_contexts(include_groups: true, favorites_first: true)
    @manage_contexts = @contexts.select{|c| c.grants_right?(@current_user, session, :manage_calendar) }.map(&:asset_string)
    @feed_url = feeds_calendar_url((@context_enrollment || @context).feed_code)
    @selected_contexts = params[:include_contexts].split(",") if params[:include_contexts]
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
        :name => context.name,
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
        :assignment_groups => context.respond_to?("assignments") ? context.assignment_groups.active.select([:id, :name]).map {|g| { :id => g.id, :name => g.name } } : [],
        :can_create_appointment_groups => ag_permission
      }
      if context.respond_to?("course_sections")
        info[:course_sections] = context.course_sections.active.select([:id, :name]).map do |cs|
          hash = { :id => cs.id, :asset_string => cs.asset_string, :name => cs.name}
          if ag_permission
            hash[:can_create_ag] = ag_permission[:all_sections] || ag_permission[:section_ids].include?(cs.id)
          end
          hash
        end
      end
      if ag_permission && ag_permission[:all_sections] && context.respond_to?("group_categories")
        info[:group_categories] = context.group_categories.active.select([:id, :name]).map {|gc| { :id => gc.id, :asset_string => gc.asset_string, :name => gc.name } }
      end
      info
    end
    Api.recursively_stringify_json_ids(@contexts_json)
  end

  def build_calendar_events
    opts = {
      :contexts => @contexts,
      :start_at => @first_day,
      :end_at => @last_day + 1,
      :include_undated => !!params[:include_undated],
      :include_deleted_events => request.format == :json,
      :updated_at => @updated_at
    }
    @events = @current_user.calendar_events_for_calendar(opts) if @current_user
    if params[:include_undated] && @current_user
      @undated_events = @current_user.undated_events(opts)
    end
    @events ||= []
    @undated_events ||= []
    args = []
    format = request.format.to_sym.to_s
    if format == 'json'
      args << { :user_content => %w(description) }
      if @current_user
        args.last[:permissions] = { :user => @current_user, :session => session }
      end
    end
    @events.concat(@undated_events).send("to_#{format}", *args)
  end
  protected :build_calendar_events

  def calendar_events_for_request_format
    @updated_at = params[:last_update_at] && !params[:last_update_at].empty? && (Time.parse(params[:last_update_at]) rescue nil)
    if @updated_at
      build_calendar_events
    else #if we are rendering a request that does not have a ?last_udpated_at, then it is cacheable both server and client side.
      cache_key = ['calendar_month', request.format, @month, @year, Digest::MD5.hexdigest(@contexts.map(&:cache_key).join)[0, 10]].join('/')

      # This tries to 304 cache these on the clients browser, it is safe because it is not public, it is just for ajax requests,
      # so we dont have the back button problem we have elsewhere, and Assignments and Calendar Events will both touch their context so that cache key is always accurate.
      cancel_cache_buster
      response.etag = cache_key
      if request.fresh?(response)
        @dont_render_again = true
        head :not_modified and return
      end

      Rails.cache.fetch(cache_key) {
        build_calendar_events
      }
    end
  end
  protected :calendar_events_for_request_format

  def build_calendar_dates(event_to_focus)
    @today = Time.zone.today

    if params[:start_day] && params[:end_day]
      @first_day = Date.parse(params[:start_day])
      @last_day = Date.parse(params[:end_day])
      if @first_day.day != 1
        # TODO: this is assuming a month is asked for at a time, which is a bad assumption
        @month = (@first_day + 1.month).month
        @year = (@first_day + 1.month).year
      else
        @month = @first_day.month
        @year = @first_day.year
      end
      @current = Date.new(y = @year, m = @month, d = 1)
    else
      if event_to_focus
        use_start = event_to_focus.start_at.in_time_zone
        @month = use_start.month
        @year = use_start.year
      else
        @month = params[:month].to_i
        @month = !@month || @month == 0 ? @today.month : @month
        @year = params[:year].to_i
        @year = !@year || @year == 0 ? @today.year : @year
      end

      @first_day = Date.parse(params[:start_day]) if params[:start_day]
      @last_day = Date.parse(params[:end_day]) if params[:end_day]

      first_day_of_month = Date.new(y=@year, m=@month, d=1)
      last_day_of_previous_month = first_day_of_month - 1
      @current = first_day_of_month
      last_day_of_month = (first_day_of_month >> 1) - 1
      first_day_of_next_month = last_day_of_month + 1
      @first_day = last_day_of_previous_month - last_day_of_previous_month.wday
      @last_day = first_day_of_next_month + (6 - first_day_of_next_month.wday) + 7
    end
  end
  protected :build_calendar_dates

end
