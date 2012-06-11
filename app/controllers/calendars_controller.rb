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
  before_filter :check_preferred_calendar, :only => [ :show, :show2 ]

  def show
    get_context
    if @context != @current_user
      # we used to have calendar pages under contexts, like
      # /courses/X/calendar, but these all redirect to /calendar now.
      # we shouldn't have any of these URLs anymore, but let's leave in this
      # fail-safe in case somebody has a bookmark or something.
      return redirect_to(calendar_url_for([@context]))
    end
    get_all_pertinent_contexts(true) # passing true has it return groups too.
    build_calendar_dates

    respond_to do |format|
      format.html do
        @events = []
        @undated_events = []
        @show_left_side = false
        @calendar_event = @contexts[0].calendar_events.new
        @contexts.each do |context|
          log_asset_access("dashboard_calendar:#{context.asset_string}", "calendar", 'other')
        end
        render :action => "show"
      end
      # this  unless @dont_render_again stuff is ugly but I wanted to send back a 304 but it started giving me "Double Render errors"
      format.json do
        events = calendar_events_for_request_format
        render :json => events unless @dont_render_again
      end
      format.ics {
        events = calendar_events_for_request_format
        render :text => events unless @dont_render_again
      }
    end
  end

  def show2
    get_context
    get_all_pertinent_contexts(true) # passing true has it return groups too.
    @manage_contexts = @contexts.select{|c| c.grants_right?(@current_user, session, :manage_calendar) }.map(&:asset_string)
    @feed_url = feeds_calendar_url((@context_enrollment || @context).feed_code)
    @selected_contexts = params[:include_contexts].split(",") if params[:include_contexts]
    if params[:event_id] && (event = CalendarEvent.find_by_id(params[:event_id])) && event.start_at
      @active_event_id = event.id
      @view_start = event.start_at.in_time_zone.strftime("%Y-%m-%d")
    end
    @contexts_json = @contexts.map do |context|
      if context.respond_to? :appointment_groups
        ag = AppointmentGroup.new(:contexts => [context])
        ag.update_contexts_and_sub_contexts
        can_create_ags = ag.grants_right? @current_user, session, :create
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
        :assignment_url => context.respond_to?("assignments") ? named_context_url(context, :context_assignment_url, '{{ id }}') : '',
        :appointment_group_url => context.respond_to?("appointment_groups") ? api_v1_appointment_groups_url(:id => '{{ id }}') : '',
        :can_create_calendar_events => context.respond_to?("calendar_events") && context.calendar_events.new.grants_right?(@current_user, session, :create),
        :can_create_assignments => context.respond_to?("assignments") && context.assignments.new.grants_right?(@current_user, session, :create),
        :assignment_groups => context.respond_to?("assignments") ? context.assignment_groups.active.scoped(:select => "id, name").map {|g| { :id => g.id, :name => g.name } } : [],
        :can_create_appointment_groups => can_create_ags
      }
      if context.respond_to?("course_sections")
        info[:course_sections] = context.course_sections.active.scoped(:select => "id, name").map {|cs| { :id => cs.id, :asset_string => cs.asset_string, :name => cs.name } }
      end
      if info[:can_create_appointment_groups] && context.respond_to?("group_categories")
        info[:group_categories] = context.group_categories.active.scoped(:select => "id, name").map {|gc| { :id => gc.id, :asset_string => gc.asset_string, :name => gc.name } }
      end
      info
    end
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

  def build_calendar_dates
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
      @month = params[:month].to_i
      @month = !@month || @month == 0 ? @today.month : @month
      @year = params[:year].to_i
      @year = !@year || @year == 0 ? @today.year : @year

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


  def public_feed
    return unless get_feed_context
    get_all_pertinent_contexts

    @events = []
    @contexts.each do |context|
      @assignments = context.assignments.active.find(:all) if context.respond_to?("assignments")
      @events.concat context.calendar_events.active.find(:all)
      @events.concat @assignments || []
      @events = @events.sort_by{ |e| [(e.start_at || Time.now), e.title] }
    end
    @contexts.each do |context|
      log_asset_access("calendar_feed:#{context.asset_string}", "calendar", 'other')
    end
    respond_to do |format|
      format.ics do
        render :text => @events.to_ics(t('ics_title', "%{course_or_group_name} Calendar (Canvas)", :course_or_group_name => @context.name),
          case
            when @context.is_a?(Course)
              t('ics_description_course', "Calendar events for the course, %{course_name}", :course_name => @context.name)
            when @context.is_a?(Group)
              t('ics_description_group', "Calendar events for the group, %{group_name}", :group_name => @context.name)
            when @context.is_a?(User)
              t('ics_description_user', "Calendar events for the user, %{user_name}", :user_name => @context.name)
            else
              t('ics_description', "Calendar events for %{context_name}", :context_name => @context.name)
          end)
      end
      format.atom do
        feed = Atom::Feed.new do |f|
          f.title = t :feed_title, "%{course_or_group_name} Calendar Feed", :course_or_group_name => @context.name
          f.links << Atom::Link.new(:href => calendar_url_for(@context), :rel => 'self')
          f.updated = Time.now
          f.id = calendar_url_for(@context)
        end
        @events.each do |e|
          feed.entries << e.to_atom
        end
        render :text => feed.to_xml
      end
    end
  end

  def switch_calendar
    if @domain_root_account.enable_scheduler?
      if params[:preferred_calendar] == '2' &&
        @current_user.preferences.delete(:use_calendar1)
      else
        @current_user.preferences[:use_calendar1] = true
      end
      @current_user.save!
    end
    check_preferred_calendar(true)
  end

  def check_preferred_calendar(always_redirect=false)
    preferred_calendar = 'show'
    preferred_calendar = 'show2' if @domain_root_account.enable_scheduler? && !@current_user.preferences[:use_calendar1]
    if always_redirect || params[:action] != preferred_calendar
      redirect_to({ :action => preferred_calendar, :anchor => ' ' }.merge(params.slice(:include_contexts, :event_id)))
      return false
    end
    if @domain_root_account.enable_scheduler?
      if preferred_calendar == 'show'
        add_crumb @template.link_to(t(:use_new_calendar, "Try out the new calendar"), switch_calendar_url('2'), :method => :post), nil, :id => 'change_calendar_version_link_holder'
      else
        add_crumb @template.link_to(t(:use_old_calendar, "Go back to the old calendar"), switch_calendar_url('1'), :method => :post), nil, :id => 'change_calendar_version_link_holder'
      end
    end
  end
  protected :check_preferred_calendar
end
