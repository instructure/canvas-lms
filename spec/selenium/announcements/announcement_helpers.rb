#
# Copyright (C) 2016 Instructure, Inc.
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

require_relative '../common'

shared_context "announcements_page_shared_context" do
  let(:unauthorized_message) { '#unauthorized_message' }
  let(:announcements_page) { "/courses/#{@course.id}/announcements" }
  let(:permissions_page) { "/account/#{@account.id}/permissions" }
  let(:course_section_tabs) { '#section-tabs' }
  let(:announcement_link) { '.announcements' }
  let(:announcement_message) { '.discussion-summary.ellipsis:contains("Announcement 1 detail")' }
  let(:stream_announcement) { '.title:contains("Announcement")' }
  let(:announcement_title) { '.content_summary:contains("Announcement 1")' }
  let(:course_page_disabled_notice) { "That page has been disabled for this course" }
end


module AnnouncementHelpers
  def new_announcement(course)
    course.announcements.create!(title: "Announcement 1", message: "Announcement 1 detail")
  end

  def disable_view_announcements(course, context_role)
    course.root_account.role_overrides.create!(permission: 'read_announcements',
                                                role: context_role, enabled: false)
  end

  def enable_view_announcements(course, context_role)
    course.root_account.role_overrides.create!(permission: 'read_announcements',
                                                role: context_role, enabled: true)
  end

  def view_announcement_detail
    fj(stream_announcement).click()
    fj(announcement_title).click()
  end
end

