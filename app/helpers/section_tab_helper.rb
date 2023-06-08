# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module SectionTabHelper
  # This should contain all the permissions that are checked in Course#uncached_tabs_available
  PERMISSIONS_TO_PRECALCULATE = %i[
    create_conferences
    create_forum
    manage_admin_users
    manage_assignments
    manage_assignments_add
    manage_assignments_edit
    manage_assignments_delete
    manage_content
    manage_files_add
    manage_files_edit
    manage_files_delete
    manage_grades
    manage_students
    moderate_forum
    post_to_forum
    read_announcements
    read_course_content
    read_forum
    read_roster
    view_all_grades
  ].freeze

  def available_section_tabs
    @available_section_tabs ||=
      AvailableSectionTabs.new(@context, @current_user, @domain_root_account, session).to_a
  end

  def nav_name
    if active_path?("/courses")
      I18n.t("Courses Navigation Menu")
    elsif active_path?("/profile")
      I18n.t("Account Navigation Menu")
    elsif active_path?("/accounts")
      I18n.t("Admin Navigation Menu")
    elsif active_path?("/groups")
      I18n.t("Groups Navigation Menu")
    else
      I18n.t("Context Navigation Menu")
    end
  end

  def section_tabs
    @section_tabs ||=
      if @context && available_section_tabs.any?
        content_tag(:nav, { role: "navigation", "aria-label": nav_name }) do
          concat(
            content_tag(:ul, id: "section-tabs") do
              available_section_tabs.map { |tab| section_tab_tag(tab, @context, get_active_tab) }
            end
          )
        end
      end

    raw(@section_tabs)
  end

  def section_tab_tag(tab, context, active_tab)
    concat(SectionTabTag.new(tab, context, active_tab).to_html)
  end

  class AvailableSectionTabs
    include NewQuizzesFeaturesHelper

    def initialize(
      context, current_user, domain_root_account, session, precalculated_permissions = nil
    )
      @context = context
      @current_user = current_user
      @domain_root_account = domain_root_account
      @session = session
      @precalculated_permissions = precalculated_permissions
    end
    attr_reader :context, :current_user, :domain_root_account, :session

    def to_a
      return [] unless context.respond_to?(:tabs_available)

      Rails.cache.fetch(cache_key, expires_in: 1.hour) do
        if context.respond_to?(:feature_enabled?)
          new_collaborations_enabled = context.feature_enabled?(:new_collaborations)
        end

        context.tabs_available(
          current_user,
          {
            session:,
            root_account: domain_root_account,
            precalculated_permissions: @precalculated_permissions
          }
        ).select { |tab| tab_has_required_attributes?(tab) }.reject do |tab|
          if tab_is?(tab, "TAB_COLLABORATIONS")
            new_collaborations_enabled || !Collaboration.any_collaborations_configured?(@context)
          elsif tab_is?(tab, "TAB_COLLABORATIONS_NEW")
            !new_collaborations_enabled
          elsif tab_is?(tab, "TAB_CONFERENCES")
            !WebConference.config(context: @context)
          elsif Lti::ExternalToolTab.tool_for_tab(tab)&.quiz_lti?
            !new_quizzes_navigation_placements_enabled?(context)
          elsif tab_is?(tab, "TAB_PEOPLE")
            # can't manage people in template courses
            context.is_a?(Course) && context.template?
          end
        end
      end
    end

    private

    def cache_key
      k = [
        context,
        current_user,
        domain_root_account,
        Lti::NavigationCache.new(domain_root_account),
        "section_tabs_hash",
        I18n.locale
      ]
      if context.is_a?(Course) && context.elementary_homeroom_course?
        k << "homeroom_course"
      end

      k.cache_key
    end

    def tab_has_required_attributes?(tab)
      tab[:href] && tab[:label]
    end

    def tab_is?(tab, const_name)
      Api::V1::Tab.tab_is?(tab, context, const_name)
    end
  end

  class SectionTabTag
    include ActionView::Context
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    def initialize(tab, context, active_tab = nil)
      @tab = SectionTabPresenter.new(tab, context)
      @active_tab = active_tab
    end

    def a_classes
      [@tab.css_class.downcase.replace_whitespace("-")].tap do |a|
        a << "active" if @tab.active?(@active_tab)
      end
    end

    def a_title
      if @tab.hide?
        I18n.t("Disabled. Not visible to students")
      elsif @tab.unused?
        I18n.t("No content. Not visible to students")
      end
    end

    def a_aria_label
      return unless @tab.hide? || @tab.unused?

      if @tab.hide?
        I18n.t("%{label}. Disabled. Not visible to students", { label: @tab.label })
      else
        I18n.t("%{label}. No content. Not visible to students", { label: @tab.label })
      end
    end

    def a_aria_current_page
      "page" if @tab.active?(@active_tab)
    end

    def a_attributes
      {
        href: @tab.path,
        title: a_title,
        "aria-label": a_aria_label,
        "aria-current": a_aria_current_page,
        class: a_classes
      }.tap do |h|
        h[:target] = @tab.target if @tab.target?
        h["data-tooltip"] = "" if @tab.hide? || @tab.unused?
      end
    end

    def a_tag
      content_tag(:a, a_attributes) do
        concat(indicate_new)
        concat(@tab.label)
        concat(indicate_hidden)
      end
    end

    def li_classes
      %w[section].tap { |a| a << "section-hidden" if @tab.hide? || @tab.unused? }
    end

    def indicate_hidden
      return unless @tab.hide? || @tab.unused?

      "<i class='nav-icon icon-off' aria-hidden='true' role='presentation'></i>".html_safe
    end

    # include the css_class of tabs here to show a "new" pill in the nav
    # hide the "new" pill by adding the css_class to the :visited_tabs user preference
    NEW_TABS = %w[account_calendars].freeze

    def indicate_new
      return unless NEW_TABS.include? @tab.css_class

      "<span class='new-tab-indicator nav-icon' data-tabname='#{@tab.css_class}'></span>".html_safe
    end

    def to_html
      content_tag(:li, a_tag, { class: li_classes })
    end
  end
end
