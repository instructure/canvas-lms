# frozen_string_literal: true

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

  before_action :parse_context_codes, only: [:index]
  before_action :get_dates, only: [:index]

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
  # @argument latest_only [Optional, Boolean]
  #   Only return the latest announcement for each associated context.
  #   The response will include at most one announcement for each
  #   specified context in the context_codes[] parameter.
  #   Defaults to false.
  #
  # @argument include [Optional, array]
  #   Optional list of resources to include with the response. May include
  #   a string of the name of the resource. Possible values are:
  #   "sections", "sections_user_count"
  #   if "sections" is passed, includes the course sections that are associated
  #   with the topic, if the topic is specific to certain sections of the course.
  #   If "sections_user_count" is passed, then:
  #     (a) If sections were asked for *and* the topic is specific to certain
  #         course sections sections, includes the number of users in each
  #         section. (as part of the section json asked for above)
  #     (b) Else, includes at the root level the total number of users in the
  #         topic's context (group or course) that the topic applies to.
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
    shards = courses.map(&:shard).uniq
    announcements = Shard.with_each_shard(shards) do
      scope = Announcement.where(context_type: "Course", context_id: courses)

      include_unpublished = courses.all? { |course| course.grants_right?(@current_user, :view_unpublished_items) }
      scope = if include_unpublished && !value_to_boolean(params[:active_only])
                scope.where.not(workflow_state: "deleted")
              else
                # workflow state should be 'post_delayed' if delayed_post_at is in the future, but check because other endpoints do
                scope.where(workflow_state: "active").where("delayed_post_at IS NULL OR delayed_post_at<?", Time.now.utc)
              end

      @start_date ||= 14.days.ago.beginning_of_day
      @end_date ||= @start_date + 28.days
      if value_to_boolean(params[:latest_only])
        scope = scope.ordered_between_by_context(@start_date, @end_date)
        scope = scope.select("DISTINCT ON (context_id) *")
      else
        scope = scope.ordered_between(@start_date, @end_date)
      end

      # only filter by section visibility if user has no course manage rights
      skip_section_filtering = courses.all? do |course|
        course.grants_any_right?(
          @current_user,
          :read_as_admin,
          :manage_grades,
          *RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS,
          :manage_content,
          *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
        )
      end
      scope = scope.visible_to_student_sections(@current_user) unless skip_section_filtering
      scope
    end

    @topics = Api.paginate(announcements, self, api_v1_announcements_url)

    include_params = Array(params[:include])
    text_only = value_to_boolean(params[:text_only])

    render json: discussion_topics_api_json(@topics,
                                            nil,
                                            @current_user,
                                            session,
                                            user_can_moderate: false,
                                            include_assignment: false,
                                            include_context_code: true,
                                            text_only:,
                                            include_sections: include_params.include?("sections"),
                                            include_sections_user_count: include_params.include?("sections_user_count"))
  end

  private

  def parse_context_codes
    context_codes = Array(params[:context_codes])
    if context_codes.empty?
      return render json: { message: "Missing context_codes" }, status: :bad_request
    end

    @course_ids = context_codes.inject([]) do |ids, context_code|
      klass, id = ActiveRecord::Base.parse_asset_string(context_code)
      unless klass == "Course"
        return render json: { message: "Invalid context_codes; only `course` codes are supported" },
                      status: :bad_request
      end
      ids << id
    end
  end

  def get_dates
    if params[:start_date].present?
      if Api::DATE_REGEX.match?(params[:start_date])
        @start_date ||= Time.zone.parse(params[:start_date]).beginning_of_day
      elsif Api::ISO8601_REGEX.match?(params[:start_date])
        @start_date ||= Time.zone.parse(params[:start_date])
      else
        render json: { message: "Invalid start_date" }, status: :bad_request
        return false
      end
    end

    if params[:end_date].present?
      if Api::DATE_REGEX.match?(params[:end_date])
        @end_date ||= Time.zone.parse(params[:end_date]).end_of_day
      elsif Api::ISO8601_REGEX.match?(params[:end_date])
        @end_date ||= Time.zone.parse(params[:end_date])
      else
        render json: { message: "Invalid end_date" }, status: :bad_request
        return false
      end
    end

    true
  end
end
