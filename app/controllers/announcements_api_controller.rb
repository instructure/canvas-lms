#
# Copyright (C) 2016 - present Instructure, Inc.
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

# @API Announcements
#
# API for retrieving announcements.  This API is Announcement-specific.
# See also the Discussion Topics API, which operates on Announcements also.

class AnnouncementsApiController < ApplicationController
  include Api::V1::DiscussionTopics

  before_action :parse_context_codes, :only => [:index]
  before_action :get_dates, :only => [:index]

  # @API List announcements
  #
  # Returns the paginated list of announcements for the given courses and date range.  Note that
  # a +context_code+ field is added to the responses so you can tell which course each announcement
  # belongs to.
  #
  # @argument context_codes[] [Required]
  #   List of context_codes to retrieve announcements for (for example, +course_123+). Only courses
  #   are presently supported. The call will fail unless the caller has View Announcements permission
  #   in all listed courses.
  # @argument start_date [Optional, Date]
  #   Only return announcements posted since the start_date (inclusive).
  #   Defaults to 14 days ago. The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  # @argument end_date [Optional, Date]
  #   Only return announcements posted before the end_date (inclusive).
  #   Defaults to 28 days from start_date. The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #   Announcements scheduled for future posting will only be returned to course administrators.
  # @argument active_only [Optional, Boolean]
  #   Only return active announcements that have been published.
  #   Applies only to requesting users that have permission to view
  #   unpublished items.
  #   Defaults to false for users with access to view unpublished items,
  #   otherwise true and unmodifiable.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/announcements?context_codes[]=course_1&context_codes[]=course_2 \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     [{
  #       "id": 1,
  #       "title": "Hear ye",
  #       "message": "Henceforth, all assignments must be...",
  #       "posted_at": "2017-01-31T22:00:00Z",
  #       "delayed_post_at": null,
  #       "context_code": "course_2",
  #       ...
  #     }]
  #
  # @returns [DiscussionTopic]
  def index
    courses = api_find_all(Course, @course_ids)
    return unless courses.all? { |course| authorized_action(course, @current_user, :read_announcements) }

    scope = Announcement.where(:context_type => 'Course', :context_id => courses)

    include_unpublished = courses.all? { |course| course.grants_right?(@current_user, :view_unpublished_items) }
    scope = if include_unpublished && !value_to_boolean(params[:active_only])
      scope.where.not(:workflow_state => 'deleted')
    else
      # workflow state should be 'post_delayed' if delayed_post_at is in the future, but check because other endpoints do
      scope.where(:workflow_state => 'active').where('delayed_post_at IS NULL OR delayed_post_at<?', Time.now.utc)
    end

    @start_date ||= 14.days.ago.beginning_of_day
    @end_date ||= @start_date + 28.days
    scope = scope.where('COALESCE(delayed_post_at, posted_at) BETWEEN ? AND ?', @start_date, @end_date)
    scope = scope.order('COALESCE(delayed_post_at, posted_at) DESC')

    @topics = Api.paginate(scope, self, api_v1_announcements_url)

    text_only = value_to_boolean(params[:text_only])
    render :json => @topics.map { |topic|
             discussion_topic_api_json(topic, topic.context, @current_user, session,
               { :user_can_moderate => false, :include_assignment => false,
                 :include_context_code => true, :text_only => text_only})
           }
  end

  private

  def parse_context_codes
    context_codes = Array(params[:context_codes])
    if context_codes.empty?
      return render :json => { :message => 'Missing context_codes' }, :status => :bad_request
    end
    @course_ids = context_codes.inject([]) do |ids, context_code|
      klass, id = ActiveRecord::Base.parse_asset_string(context_code)
      unless klass == 'Course'
        return render :json => { :message => 'Invalid context_codes; only `course` codes are supported' },
                      :status => :bad_request
      end
      ids << id
    end
  end

  def get_dates
    if params[:start_date].present?
      if params[:start_date] =~ Api::DATE_REGEX
        @start_date ||= Time.zone.parse(params[:start_date]).beginning_of_day
      elsif params[:start_date] =~ Api::ISO8601_REGEX
        @start_date ||= Time.zone.parse(params[:start_date])
      else
        render :json => { :message => 'Invalid start_date' }, :status => :bad_request
        return false
      end
    end

    if params[:end_date].present?
      if params[:end_date] =~ Api::DATE_REGEX
        @end_date ||= Time.zone.parse(params[:end_date]).end_of_day
      elsif params[:end_date] =~ Api::ISO8601_REGEX
        @end_date ||= Time.zone.parse(params[:end_date])
      else
        render :json => { :message => 'Invalid end_date' }, :status => :bad_request
        return false
      end
    end

    true
  end
end
