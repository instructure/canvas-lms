# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
  def user_dashboard_view
    dashboard_view = @current_user&.dashboard_view
    dashboard_view = "activity" if @current_user&.preferences&.dig(:recent_activity_dashboard) && !@current_user.preferences[:dashboard_view]
    dashboard_view
  end

  def show_cards?
    user_dashboard_view == "cards"
  end

  def show_planner?
    user_dashboard_view == "planner" || k5_user?
  end

  def show_recent_activity?
    user_dashboard_view == "activity"
  end

  def show_welcome_message?
    @current_user.present? && !@current_user.has_active_enrollment?
  end

  def welcome_message
    if @current_user.has_future_enrollment?
      t("#users.welcome.unpublished_courses_message", <<~TEXT)
        You've enrolled in one or more courses that have not started yet. Once
        those courses are available, you will see information about them here
        and in the navigation on the left side. In the meantime, feel free to sign up for
        more courses or set up your profile.
      TEXT
    else
      t("#users.welcome.no_courses_message", <<~TEXT)
        You don't have any courses, so this page won't be very exciting for now.
        Once you've created or signed up for courses, you'll start to see
        conversations from all of your classes.
      TEXT
    end
  end

  def activity_category_links(category, items)
    max_contexts = 4
    contexts = items.map { |i| [i.context.name, i.context.linked_to] }.uniq
    contexts_count = contexts.count

    # use the "and x more..." phrasing if > max_contexts contexts
    if contexts_count > max_contexts
      contexts = contexts.take(max_contexts)
      contexts << [I18n.t("helpers.dashboard_helper.x_more", "%{x} more...", x: contexts_count - max_contexts), nil]
    end

    contexts.map do |name, url|
      url = nil if category == "Conversation"
      url.present? ? "<a href=\"#{url}\" aria-label=\"#{accessibility_category_label(category)} for #{h(name)}\">#{h(name)}</a>" : h(name)
    end.to_sentence.html_safe
  end

  def accessibility_category_label(category)
    case category
    when "Announcement"
      I18n.t("helpers.dashboard_helper.announcement_label", "Visit Course Announcements")
    when "Conversation"
      I18n.t("helpers.dashboard_helper.conversation_label", "Visit Conversations")
    when "Assignment"
      I18n.t("helpers.dashboard_helper.assignment_label", "Visit Course Assignments")
    when "DiscussionEntry", "DiscussionTopic"
      I18n.t("helpers.dashboard_helper.discussion_label", "Visit Course Discussions")
    when "AssessmentRequest"
      I18n.t("helpers.dashboard_helper.peer_review_label", "Visit Course Peer Reviews")
    else
      raise "Unknown activity category"
    end
  end

  def category_details_label(category)
    case category
    when "Announcement"
      I18n.t("helpers.dashboard_helper.announcement_details", "Announcement Details")
    when "Conversation"
      I18n.t("helpers.dashboard_helper.conversation_details", "Conversation Details")
    when "Assignment"
      I18n.t("helpers.dashboard_helper.assignment_details", "Assignment Details")
    when "DiscussionEntry", "DiscussionTopic"
      I18n.t("helpers.dashboard_helper.discussion_details", "Discussion Details")
    when "AssessmentRequest"
      I18n.t("helpers.dashboard_helper.peer_review_details", "Peer Review Details")
    else
      raise "Unknown activity category"
    end
  end

  def activity_category_title(category, items)
    case category
    when "Announcement"
      I18n.t("helpers.dashboard_helper.x_new_in_announcements",
             { one: "*1* Announcement", other: "*%{count}* Announcements" },
             { count: items.size, wrapper: '<b class="count">\1</b>' })
    when "Conversation"
      I18n.t("helpers.dashboard_helper.x_new_in_conversations",
             { one: "*1* Conversation Message", other: "*%{count}* Conversation Messages" },
             { count: items.size, wrapper: '<b class="count">\1</b>' })
    when "Assignment"
      I18n.t("helpers.dashboard_helper.x_new_in_assignments",
             { one: "*1* Assignment Notification", other: "*%{count}* Assignment Notifications" },
             { count: items.size, wrapper: '<b class="count">\1</b>' })
    when "DiscussionEntry", "DiscussionTopic"
      I18n.t("helpers.dashboard_helper.x_new_in_discussions",
             { one: "*1* Discussion", other: "*%{count}* Discussions" },
             { count: items.size, wrapper: '<b class="count">\1</b>' })
    when "AssessmentRequest"
      I18n.t("helpers.dashboard_helper.x_new_in_peer_reviews",
             { one: "*1* Peer Review", other: "*%{count}* Peer Reviews" },
             { count: items.size, wrapper: '<b class="count">\1</b>' })
    else
      raise "Unknown activity category"
    end
  end

  def todo_ignore_dropdown_type?(activity_type)
    [:grading, :moderation].include?(activity_type.to_sym)
  end

  def todo_ignore_api_url(activity_type, item)
    permanent = 1 unless todo_ignore_dropdown_type?(activity_type)

    api_v1_users_todo_ignore_url(item.asset_string, activity_type, { permanent: })
  end

  def todo_link_classes(activity_type)
    todo_ignore_dropdown_type?(activity_type) ? "al-trigger disable_item_link" : "disable_item_link disable-todo-item-link"
  end

  def map_courses_for_menu(courses, opts = {})
    Course.preload_menu_data_for(courses, @current_user, preload_favorites: true)
    mapped = courses.map do |course|
      presenter = CourseForMenuPresenter.new(course, @current_user, @domain_root_account, session, opts)
      presenter.to_h
    end

    mapped.sort_by { |h| h[:position] || ::CanvasSort::Last }
  end
end
