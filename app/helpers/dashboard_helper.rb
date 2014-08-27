#
# Copyright (C) 2012 Instructure, Inc.
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

module DashboardHelper
  def accessible_message_icon_text(icon)
    case icon
    when "warning"
      I18n.t('#global_message_icons.warning', "warning")
    when "error"
      I18n.t('#global_message_icons.error', "error")
    when "information"
      I18n.t('#global_message_icons.information', "information")
    when "question"
      I18n.t('#global_message_icons.question', "question")
    when "calendar"
      I18n.t('#global_message_icons.calendar', "calendar")
    when "announcement"
      I18n.t('#global_message_icons.announcement', "announcement")
    when "invitation"
      I18n.t('#global_message_icons.invitation', "invitation")
    else
      raise "Unknown dashboard message icon type"
    end
  end

  def show_welcome_message?
    @current_user.present? &&
      @current_user.cached_current_enrollments(:include_enrollment_uuid => session[:enrollment_uuid], :preload_courses => true).select(&:active?).empty?
  end

  def welcome_message
    if @current_user.cached_current_enrollments(:include_future => true).present?
      t('#users.welcome.unpublished_courses_message', <<-BODY)
        You've enrolled in one or more courses that have not started yet. Once
        those courses are available, you will see information about them here
        and in the top navigation. In the meantime, feel free to sign up for
        more courses or set up your profile.
      BODY
    else
      t('#users.welcome.no_courses_message', <<-BODY)
        You don't have any courses, so this page won't be very exciting for now.
        Once you've created or signed up for courses, you'll start to see
        conversations from all of your classes.
      BODY
    end
  end

  def activity_category_links(category, items)
    max_contexts = 4
    contexts = items.map{ |i| [i.context.name, i.context.linked_to] }.uniq
    contexts_count = contexts.count

    # use the "and x more..." phrasing if > max_contexts contexts
    if contexts_count > max_contexts
      contexts = contexts.take(max_contexts)
      contexts << [I18n.t('helpers.dashboard_helper.x_more', "%{x} more...", :x => contexts_count - max_contexts), nil]
    end

    contexts.map do |name, url|
      url = nil if category == 'Conversation'
      url.present? ? "<a href=\"#{url}\">#{h(name)}</a>" : h(name)
    end.to_sentence.html_safe
  end

  def category_details_label(category)
    case category
    when "Announcement"
      return I18n.t('helpers.dashboard_helper.announcement_details', "Announcement Details")
    when "Conversation"
      return I18n.t('helpers.dashboard_helper.conversation_details', "Conversation Details")
    when "Assignment"
      return I18n.t('helpers.dashboard_helper.assignment_details', "Assignment Details")
    when "DiscussionTopic"
      return I18n.t('helpers.dashboard_helper.discussion_details', "Discussion Details")
    when "AssessmentRequest"
      return I18n.t('helpers.dashboard_helper.peer_review_details', "Peer Review Details")
    else
      raise "Unknown activity category"
    end
  end

  def activity_category_title(category, items)
    case category
    when "Announcement"
      return I18n.t('helpers.dashboard_helper.x_new_in_announcements',
               { :one => "*1* Announcement", :other => "*%{count}* Announcements" },
               { :count => items.size, :wrapper => '<b class="count">\1</b>' })
    when "Conversation"
      return I18n.t('helpers.dashboard_helper.x_new_in_conversations',
               { :one => "*1* Conversation Message", :other => "*%{count}* Conversation Messages" },
               { :count => items.size, :wrapper => '<b class="count">\1</b>' })
    when "Assignment"
      return I18n.t('helpers.dashboard_helper.x_new_in_assignments',
               { :one => "*1* Assignment Notification", :other => "*%{count}* Assignment Notifications" },
               { :count => items.size, :wrapper => '<b class="count">\1</b>' })
    when "DiscussionTopic"
      return I18n.t('helpers.dashboard_helper.x_new_in_discussions',
               { :one => "*1* Discussion", :other => "*%{count}* Discussions" },
               { :count => items.size, :wrapper => '<b class="count">\1</b>' })
    when "AssessmentRequest"
      return I18n.t('helpers.dashboard_helper.x_new_in_peer_reviews',
               { :one => "*1* Peer Review", :other => "*%{count}* Peer Reviews" },
               { :count => items.size, :wrapper => '<b class="count">\1</b>' })
    else
      raise "Unknown activity category"
    end
  end

end
