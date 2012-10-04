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
      @current_user.cached_current_enrollments(:include_enrollment_uuid => session[:enrollment_uuid]).empty?
  end

  def activity_category_title(category, items)
    if category == "Conversation" || @context && !@context.is_a?(User) # e.g. we're on the course dashboard
      x_new_in_category(category, items)
    else
      I18n.t('helpers.dashboard_helper.activity_category_title_with_contexts',
        "%{x_new_in_category} in %{contexts_list}",
        { :x_new_in_category => x_new_in_category(category, items), :contexts_list => contexts_list(items) })
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
    else
      raise "Unknown activity category"
    end
  end

  def x_new_in_category(category, items)
    case category
    when "Announcement"
      return I18n.t('helpers.dashboard_helper.x_new_in_announcements',
               { :one => "1 Announcement", :other => "%{count} Announcements" },
               { :count => items.size })
    when "Conversation"
      return I18n.t('helpers.dashboard_helper.x_new_in_conversations',
               { :one => "1 Conversation Message", :other => "%{count} Conversation Messages" },
               { :count => items.size })
    when "Assignment"
      return I18n.t('helpers.dashboard_helper.x_new_in_assignments',
               { :one => "1 Assignment Notification", :other => "%{count} Assignment Notifications" },
               { :count => items.size })
    when "DiscussionTopic"
      return I18n.t('helpers.dashboard_helper.x_new_in_discussions',
               { :one => "1 Discussion", :other => "%{count} Discussions" },
               { :count => items.size })
    else
      raise "Unknown activity category"
    end
  end
  private :x_new_in_category

  def contexts_list(items)
    ctx_freqs = Hash.new(0)
    items.map{ |i| [i.context.type, i.context.id] }.compact.uniq.each{ |cc| ctx_freqs[cc.first] += 1 }
    translated_ctx_freqs = ctx_freqs.to_a.sort.map{ |ctx_type, count| x_contexts(ctx_type, count) }
    translated_ctx_freqs.to_sentence
  end
  private :contexts_list

  def x_contexts(context, count)
    case context
    when "Course", "course"
      return I18n.t('helpers.dashboard_helper.x_course',
               { :one => "1 Course", :other => "%{count} Courses" },
               { :count => count })
    when "Group", "group"
      return I18n.t('helpers.dashboard_helper.x_group',
               { :one => "1 Group", :other => "%{count} Groups" },
               { :count => count })
    else
      raise "Unknown context to count: #{context}"
    end
  end
  private :x_contexts
end
