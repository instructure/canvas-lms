# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
module BrokenLinkHelper
  def send_broken_content!
    # call when processing a 4xx error.
    # this will examine the referrer to see if we got here because of a bad link
    from_url = request.referer
    return false unless from_url

    record = Context.find_asset_by_url(from_url)
    record ||= Context.get_front_wiki_page_for_course_from_url(from_url)
    return false unless record

    body = Nokogiri::HTML5(Context.asset_body(record))
    anchor = body.css("a[href$='#{request.fullpath}']").text
    return false if anchor.blank?

    users = record.context.is_a?(Course) ? record.context.participating_admins_by_date : record.context.participating_users
    recipient_keys = users.select { |admin| record.grants_any_right?(admin, :update, :update_content) }.map(&:asset_string)
    return false unless recipient_keys.present? && recipient_keys.exclude?(@current_user.asset_string)

    notification = BroadcastPolicy.notification_finder.by_name("Content Link Error")
    error_type = error_type(record.context, request.url)
    data = { location: request.referer, url: request.url, anchor:, error_type: }
    DelayedNotification.delay_if_production(priority: Delayed::LOW_PRIORITY)
                       .process(record, notification, recipient_keys, data)
    true
  rescue
    false
  end

  def error_type(course, url)
    course_id = url.match(%r{/courses/(\d+)})&.[](1)&.to_i
    return :course_mismatch if course_id && course_id != course.id

    link_obj = Context.find_asset_by_url(url)
    return response_code_type unless link_obj

    course_validator = CourseLinkValidator.new(course)
    course_validator.check_object_status(url, object: link_obj) || response_code_type
  rescue
    :missing_item
  end

  def response_code_type
    (response.status == 401 || response.status == 403) ? :inaccessible : :missing_item
  end
end
