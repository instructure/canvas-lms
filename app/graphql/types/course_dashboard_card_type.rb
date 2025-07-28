# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Types
  class CourseDashboardCardLinkType < ApplicationObjectType
    graphql_name "CourseDashboardCardLink"
    description "A link on a course dashboard card"

    field :css_class, String, null: true
    field :hidden, Boolean, null: true
    field :icon, String, null: true
    field :label, String, null: true
    field :path, String, null: true
  end

  class CourseDashboardCardType < ApplicationObjectType
    include I18nUtilities
    include Rails.application.routes.url_helpers
    include UserPreferenceValue::UserMethods

    graphql_name "CourseDashboardCard"

    description "A card on the course dashboard"
    alias_method :course, :object

    field :long_name, String, null: true
    def long_name
      "#{course.name} - #{course.short_name}"
    end

    field :short_name, String, null: true
    def short_name
      Loaders::AssociationLoader.for(User, :user_preference_values).load(current_user).then do
        course.nickname_for(current_user)
      end
    end

    field :original_name, String, null: true
    def original_name
      course.name
    end

    field :course_code, String, null: true
    delegate :course_code, to: :course

    field :asset_string, String, null: true
    delegate :asset_string, to: :course

    field :href, String, null: true
    def href
      course_path(course, invitation: course.read_attribute(:invitation))
    end

    field :term, TermType, null: true
    def term
      load_association(:enrollment_term)
    end

    field :subtitle, String, null: true
    def subtitle
      label = if course.primary_enrollment_state == "invited"
                before_label("#shared.menu_enrollment.labels.invited_as", "invited as")
              else
                before_label("#shared.menu_enrollment.labels.enrolled_as", "enrolled as")
              end

      [label, course.primary_enrollment_role.try(:label)].join(" ")
    end

    field :enrollment_state, String, null: true
    def enrollment_state
      course.primary_enrollment_state
    end

    field :enrollment_type, String, null: true
    def enrollment_type
      course.primary_enrollment_type
    end

    field :observee, String, null: true
    def observee
      if course.primary_enrollment_type == "ObserverEnrollment"
        ObserverEnrollment.observed_students(course, current_user)&.keys&.map(&:name)&.join(", ")
      end
    end

    field :is_favorited, Boolean, null: true
    def is_favorited
      Loaders::AssociationLoader.for(Course, :favorites).load(course).then do |favorites|
        favorites.any? { |favorite| favorite.user_id == current_user.id }
      end
    end

    field :is_k5_subject, Boolean, null: true
    def is_k5_subject
      course.elementary_subject_course?
    end

    field :is_homeroom, Boolean, null: true
    def is_homeroom
      course.homeroom_course
    end

    field :use_classic_font, Boolean, null: true
    def use_classic_font
      course.account.use_classic_font_in_k5?
    end

    field :can_manage, Boolean, null: true
    def can_manage
      course.grants_right?(current_user, :manage_course_content_edit)
    end

    field :can_read_announcements, Boolean, null: true
    def can_read_announcements
      course.grants_right?(current_user, :read_announcements)
    end

    field :image, UrlType, null: true
    delegate :image, to: :course

    field :color, String, null: true
    def color
      course.elementary_enabled? ? course.course_color : nil
    end

    field :position, Integer, null: true
    def position
      position = current_user.dashboard_positions[course.asset_string]
      position.present? ? position.to_i : nil
    end

    field :published, Boolean, null: true
    def published
      course.published?
    end

    field :links, [CourseDashboardCardLinkType], null: true
    def links
      dashboard_card_tabs = UsersController::DASHBOARD_CARD_TABS

      tabs = course.tabs_available(current_user, {
                                     session:,
                                     only_check: dashboard_card_tabs,
                                     precalculated_permissions: {
                                       read: true
                                     },
                                     include_external: false,
                                     include_hidden_unused: false
                                   })

      tabs.map { |tab| tab_to_link(tab) }
    end

    field :can_change_course_publish_state, Boolean, null: true
    def can_change_course_publish_state
      course.grants_right?(current_user, :manage_courses_publish)
    end

    field :default_view, String, null: true
    delegate :default_view, to: :course

    field :pages_url, UrlType, null: true
    def pages_url
      polymorphic_url([course, :wiki_pages])
    end

    field :front_page_title, String, null: true
    def front_page_title
      Loaders::AssociationLoader.for(Course, :wiki).load(course).then do |wiki|
        wiki&.front_page&.title
      end
    end

    private

    def default_url_options
      { protocol: HostUrl.protocol, host: HostUrl.context_host(course.root_account) }
    end

    def tab_to_link(tab)
      {
        css_class: tab[:css_class],
        hidden: tab[:hidden] || tab[:hidden_unused],
        icon: tab[:icon],
        label: tab[:label],
        path: get_path(tab)
      }
    end

    def get_path(tab)
      href = tab[:href]
      args = tab[:args]
      args = args.symbolize_keys if href.to_s == "course_basic_lti_launch_request_path"
      args.instance_of?(Hash) ? send(href, args) : send(href, *path_args(tab))
    end

    def path_args(tab)
      tab[:args] || (tab[:no_args] && []) || course
    end
  end
end
