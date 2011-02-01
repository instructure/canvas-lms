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

  def show
    get_context
    get_all_pertinent_contexts(true) # passing true has it return groups too.
    build_calendar_dates
    
    respond_to do |format|
      format.html do
        @events = []
        @undated_events = []
        @show_left_side = false
        # what is this doing?
        if @contexts.empty? || (@original_context && @original_context != @current_user) #authorized_action(@context, @current_user, :read)
          if @context == @current_user
            redirect_to dashboard_url
            return
          else
            @included_contexts << @original_context
            redirect_to calendar_url_for(@included_contexts.uniq)
            return
          end
        else
          @calendar_event = @contexts[0].calendar_events.new
          @contexts.each do |context|
            log_asset_access("dashboard_calendar:#{context.asset_string}", "calendar", 'other')
          end
        end
        render :action => "show" 
      end
      # this  unless @dont_render_again stuff is ugly but I wanted to send back a 304 but it started giving me "Double Render errors"
      format.json do
        events = calendar_events_for_request_format
        render :json => events unless @dont_render_again
      end
      format.xml  { 
        events = calendar_events_for_request_format
        render :xml => events unless @dont_render_again
      }
      format.ics { 
        events = calendar_events_for_request_format
        render :text => events unless @dont_render_again
      }
    end
  end
  
  def build_calendar_events
    opts = {
      :contexts => @contexts, 
      :start_at => @first_day, 
      :end_at => @last_day + 1, 
      :include_undated => !!params[:include_undated], 
      :include_forum => false, 
      :include_deleted_events => request.format == :json,
      :updated_at => @updated_at
    }
    @events = @current_user.calendar_events_for_calendar(opts) if @current_user
    if params[:include_undated] && @current_user
      @undated_events = @current_user.undated_events(opts)
    end
    @events ||= []
    @undated_events ||= []
    @events.concat(@undated_events).send("to_#{request.format.to_sym.to_s}")
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
    @today = ActiveSupport::TimeWithZone.new(Time.now, Time.zone).to_date
    @month = params[:month].to_i
    @month = !@month || @month == 0 ? @today.month : @month
    @year = params[:year].to_i
    @year = !@year || @year == 0 ? @today.year : @year
    
    first_day_of_month = Date.new(y=@year, m=@month, d=1)
    last_day_of_previous_month = first_day_of_month - 1
    @current = first_day_of_month
    last_day_of_month = (first_day_of_month >> 1) - 1
    first_day_of_next_month = last_day_of_month + 1
    @first_day = last_day_of_previous_month - last_day_of_previous_month.wday
    @last_day = first_day_of_next_month + (6 - first_day_of_next_month.wday) + 7
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
      format.ics { render :text => @events.to_ics("#{@context.name} Calendar (Canvas)", "Calendar events for the #{@context.class.to_s.downcase}, #{@context.name}") }
      feed = Atom::Feed.new do |f|
        f.title = "#{@context.name} Calendar Feed"
        f.links << Atom::Link.new(:href => calendar_url_for(@context))
        f.updated = Time.now
        f.id = calendar_url_for(@context)
      end
      @events.each do |e|
        feed.entries << e.to_atom
      end
      format.atom { render :text => feed.to_xml }
    end
  end
  
end
