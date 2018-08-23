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
  PERMISSIONS_TO_PRECALCULATE = [
    :create_conferences,
    :manage_admin_users,
    :manage_assignments,
    :manage_content,
    :manage_files,
    :manage_grades,
    :manage_students,
    :moderate_forum,
    :post_to_forum,
    :read_announcements,
    :read_course_content,
    :read_forum,
    :read_roster,
    :view_all_grades
  ].freeze

  def available_section_tabs(context, precalculated_permissions=nil)
    AvailableSectionTabs.new(
      context, @current_user, @domain_root_account, session, precalculated_permissions
    ).to_a
  end

  def nav_name
    if active_path?('/courses')
      I18n.t('Courses Navigation Menu')
    elsif active_path?('/profile')
     I18n.t('Account Navigation Menu')
    elsif active_path?('/accounts')
      I18n.t('Admin Navigation Menu')
    elsif active_path?('/groups')
       I18n.t('Groups Navigation Menu')
    else
       I18n.t('Context Navigation Menu')
    end
  end

  def section_tabs
    @section_tabs ||= begin
      if @context && available_section_tabs(@context).any?
        content_tag(:nav, {
          :role => 'navigation',
          :'aria-label' => nav_name
        }) do
          concat(content_tag(:ul, id: 'section-tabs') do
            available_section_tabs(@context).map do |tab|
              section_tab_tag(tab, @context, @active_tab)
            end
          end)
        end
      end
    end
    raw(@section_tabs)
  end

  def section_tab_tag(tab, context, active_tab)
    concat(SectionTabTag.new(tab, context, active_tab).to_html)
  end

  class AvailableSectionTabs
    def initialize(context, current_user, domain_root_account, session, precalculated_permissions=nil)
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
        new_collaborations_enabled = context.feature_enabled?(:new_collaborations) if context.respond_to?(:feature_enabled?)

        context.tabs_available(current_user, {
          session: session,
          root_account: domain_root_account,
          precalculated_permissions: @precalculated_permissions
        }).select { |tab|
          tab_has_required_attributes?(tab)
        }.reject { |tab|
          if tab_is?(tab, 'TAB_COLLABORATIONS')
            new_collaborations_enabled ||
              !Collaboration.any_collaborations_configured?(@context)
          elsif tab_is?(tab, 'TAB_COLLABORATIONS_NEW')
            !new_collaborations_enabled
          elsif tab_is?(tab, 'TAB_CONFERENCES')
            !WebConference.config
          end
        }
      end
    end

    private
    def cache_key
      [ context, current_user, domain_root_account,
        Lti::NavigationCache.new(domain_root_account),
        "section_tabs_hash", I18n.locale
      ].cache_key
    end

    def tab_has_required_attributes?(tab)
      tab[:href] && tab[:label]
    end

    def tab_is?(tab, const_name)
      context.class.const_defined?(const_name) &&
        tab[:id] == context.class.const_get(const_name)
    end
  end

  class SectionTabTag
    include ActionView::Context
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper

    def initialize(tab, context, active_tab=nil)
      @tab = SectionTabPresenter.new(tab, context)
      @active_tab = active_tab
    end

    def a_classes
      [ @tab.css_class.downcase.replace_whitespace('-') ].tap do |a|
        a << 'active' if @tab.active?(@active_tab)
      end
    end

    def a_attributes
      { href: @tab.path,
        title: @tab.label,
        class: a_classes }.tap do |h|
        h[:target] = @tab.target if @tab.target?
      end
    end

    def a_tag
      content_tag(:a, a_attributes) do
        concat(@tab.label)
        concat(span_tag)
      end
    end

    def li_classes
      [ 'section' ].tap do |a|
        a << 'section-tab-hidden' if @tab.hide? || @tab.unused?
      end
    end

    def span_tag
      if @tab.hide? || @tab.unused?
        if @tab.hide?
          text = I18n.t('* Disabled in Course Settings')
        else
          text = I18n.t('* No content has been added')
        end
        content_tag(:span, text, {
          id: 'inactive_nav_link',
          class: 'screenreader-only'
        })
      end
    end

    def to_html
      content_tag(:li, a_tag, {
        class: li_classes
      })
    end
  end
end
