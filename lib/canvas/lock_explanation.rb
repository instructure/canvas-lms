#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Canvas
  module LockExplanation
    include TextHelper
    def lock_explanation(hash, type, context=nil, options={})
      include_js = options.fetch(:include_js, true)
      # Any additions to this function should also be made in javascripts/content_locks.js
      if hash[:lock_at]
        case type
        when "quiz"
          return I18n.t('messages.quiz_locked_at', "This quiz was locked %{at}.", :at => datetime_string(hash[:lock_at]))
        when "assignment"
          return I18n.t('messages.assignment_locked_at', "This assignment was locked %{at}.", :at => datetime_string(hash[:lock_at]))
        when "topic"
          return I18n.t('messages.topic_locked_at', "This topic was locked %{at}.", :at => datetime_string(hash[:lock_at]))
        when "file"
          return I18n.t('messages.file_locked_at', "This file was locked %{at}.", :at => datetime_string(hash[:lock_at]))
        when "page"
          return I18n.t('messages.page_locked_at', "This page was locked %{at}.", :at => datetime_string(hash[:lock_at]))
        else
          return I18n.t('messages.content_locked_at', "This content was locked %{at}.", :at => datetime_string(hash[:lock_at]))
        end
      elsif hash[:unlock_at]
        case type
        when "quiz"
          return I18n.t('messages.quiz_locked_until', "This quiz is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
        when "assignment"
          return I18n.t('messages.assignment_locked_until', "This assignment is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
        when "topic"
          return I18n.t('messages.topic_locked_until', "This topic is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
        when "file"
          return I18n.t('messages.file_locked_until', "This file is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
        when "page"
          return I18n.t('messages.page_locked_until', "This page is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
        else
          return I18n.t('messages.content_locked_until', "This content is locked until %{date}.", :date => datetime_string(hash[:unlock_at]))
        end
      elsif hash[:context_module]
        obj = hash[:context_module].is_a?(ContextModule) ? hash[:context_module] : OpenObject.new(hash[:context_module])
        html = if obj.workflow_state == 'unpublished'
          case type
            when "quiz"
              I18n.t('messages.quiz_unpublished_module', "This quiz is part of an unpublished module and is not available yet.")
            when "assignment"
              I18n.t('messages.assignment_unpublished_module', "This assignment is part of an unpublished module and is not available yet.")
            when "topic"
              I18n.t('messages.topic_unpublished_module', "This topic is part of an unpublished module and is not available yet.")
            when "file"
              I18n.t('messages.file_unpublished_module', "This file is part of an unpublished module and is not available yet.")
            when "page"
              I18n.t('messages.page_unpublished_module', "This page is part of an unpublished module and is not available yet.")
            else
              I18n.t('messages.content_unpublished_module', "This content is part of an unpublished module and is not available yet.")
          end
        else
          if hash[:context_module]["unlock_at"] && hash[:context_module]["unlock_at"] > Time.now
            unlock_time = datetime_string(hash[:context_module]["unlock_at"])
            case type
              when "quiz"
                I18n.t('messages.quiz_module_time_locked', "This quiz is part of the module *%{module}*, which is locked until %{time}.",
                  :module => HtmlTextHelper.escape_html(obj.name), :time => unlock_time, :wrapper => '<b>\1</b>')
              when "assignment"
                I18n.t('messages.assignment_module_time_locked', "This assignment is part of the module *%{module}*, which is locked until %{time}.",
                  :module => HtmlTextHelper.escape_html(obj.name), :time => unlock_time, :wrapper => '<b>\1</b>')
              when "topic"
                I18n.t('messages.topic_module_time_locked', "This topic is part of the module *%{module}*, which is locked until %{time}.",
                  :module => HtmlTextHelper.escape_html(obj.name), :time => unlock_time, :wrapper => '<b>\1</b>')
              when "file"
                I18n.t('messages.file_module_time_locked', "This file is part of the module *%{module}*, which is locked until %{time}.",
                  :module => HtmlTextHelper.escape_html(obj.name), :time => unlock_time, :wrapper => '<b>\1</b>')
              when "page"
                I18n.t('messages.page_module_time_locked', "This page is part of the module *%{module}*, which is locked until %{time}.",
                  :module => HtmlTextHelper.escape_html(obj.name), :time => unlock_time, :wrapper => '<b>\1</b>')
              else
                I18n.t('messages.content_module_time_locked', "This content is part of the module *%{module}*, which is locked until %{time}.",
                  :module => HtmlTextHelper.escape_html(obj.name), :time => unlock_time, :wrapper => '<b>\1</b>')
            end
          else
            case type
              when "quiz"
                I18n.t('messages.quiz_locked_module', "This quiz is part of the module *%{module}* and hasn't been unlocked yet.",
                  :module => HtmlTextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
              when "assignment"
                I18n.t('messages.assignment_locked_module', "This assignment is part of the module *%{module}* and hasn't been unlocked yet.",
                  :module => HtmlTextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
              when "topic"
                I18n.t('messages.topic_locked_module', "This topic is part of the module *%{module}* and hasn't been unlocked yet.",
                  :module => HtmlTextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
              when "file"
                I18n.t('messages.file_locked_module', "This file is part of the module *%{module}* and hasn't been unlocked yet.",
                  :module => HtmlTextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
              when "page"
                I18n.t('messages.page_locked_module', "This page is part of the module *%{module}* and hasn't been unlocked yet.",
                  :module => HtmlTextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
              else
                I18n.t('messages.content_locked_module', "This content is part of the module *%{module}* and hasn't been unlocked yet.",
                  :module => HtmlTextHelper.escape_html(obj.name), :wrapper => '<b>\1</b>')
            end
          end
        end
        if context && (obj.workflow_state != 'unpublished')

          context = context.context if context.is_a? Group
          raise "Either Context or Group context must be a Course" unless context.is_a? Course

          html << "<br/>".html_safe
          html << "<div class='spinner'></div>".html_safe
          html << I18n.t('messages.visit_modules_page', "*Visit the course modules page for information on how to unlock this content.*",
            :wrapper => "<a #{"style='display: none;'" if include_js} class='module_prerequisites_fallback' href='#{course_context_modules_url((context || obj.context), anchor: "module_#{obj.id}")}'>\\1</a>")
          html << "<a href='#{course_context_module_prerequisites_needing_finishing_path((context || obj.context).id, obj.id, hash[:asset_string])}' style='display: none;' id='module_prerequisites_lookup_link'>&nbsp;</a>".html_safe
          js_bundle :prerequisites_lookup if include_js
        end
        return html
      else
        case type
        when "quiz"
          return I18n.t('messages.quiz_locked', "This quiz is currently locked.")
        when "assignment"
          return I18n.t('messages.assignment_locked', "This assignment is currently locked.")
        when "topic"
          return I18n.t("This topic is closed for comments.")
        when "file"
          return I18n.t('messages.file_locked', "This file is currently locked.")
        when "page"
          return I18n.t('messages.page_locked', "This page is currently locked.")
        else
          return I18n.t('messages.content_locked', "This quiz is currently locked.")
        end
      end
    end
  end
end
