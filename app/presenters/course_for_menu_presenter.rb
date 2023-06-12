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

class CourseForMenuPresenter
  include I18nUtilities
  include Rails.application.routes.url_helpers

  def initialize(course, user = nil, context = nil, session = nil, opts = {})
    @course = course
    @user = user
    @context = context
    @session = session
    @opts = opts
  end
  attr_reader :course

  def default_url_options
    { protocol: HostUrl.protocol, host: HostUrl.context_host(@course.root_account) }
  end

  def to_h
    position = @user.dashboard_positions[course.asset_string]

    observee = if course.primary_enrollment_type == "ObserverEnrollment"
                 ObserverEnrollment.observed_students(course, @user)&.keys&.map(&:name)&.join(", ")
               end

    {
      longName: "#{course.name} - #{course.short_name}",
      shortName: course.nickname_for(@user),
      originalName: course.name,
      courseCode: course.course_code,
      assetString: course.asset_string,
      href: course_path(course, invitation: course.read_attribute(:invitation)),
      term: term || nil,
      subtitle:,
      enrollmentState: course.primary_enrollment_state,
      enrollmentType: course.primary_enrollment_type,
      observee:,
      id: course.id,
      isFavorited: course.favorite_for_user?(@user),
      isK5Subject: course.elementary_subject_course?,
      isHomeroom: course.homeroom_course,
      useClassicFont: course.account.use_classic_font_in_k5?,
      canManage: course.grants_any_right?(@user, :manage_content, :manage_course_content_edit),
      canReadAnnouncements: course.grants_right?(@user, :read_announcements),
      image: course.image,
      color: course.elementary_enabled? ? course.course_color : nil,
      position: position.present? ? position.to_i : nil,
      published: course.published?
    }.tap do |hash|
      if @opts[:tabs]
        tabs = course.tabs_available(@user, {
                                       session: @session,
                                       only_check: @opts[:tabs],
                                       precalculated_permissions: {
                                         # we can assume they can read the course at this point
                                         read: true,
                                       },
                                       include_external: false,
                                       include_hidden_unused: false,
                                     })
        hash[:links] = tabs.map do |tab|
          presenter = SectionTabPresenter.new(tab, course)
          presenter.to_h
        end
      end
      hash[:canChangeCoursePublishState] = course.grants_any_right?(@user, :change_course_state, :manage_courses_publish)
      hash[:defaultView] = course.default_view
      hash[:pagesUrl] = polymorphic_url([course, :wiki_pages])
      hash[:frontPageTitle] = course&.wiki&.front_page&.title
    end
  end

  private

  def subtitle
    label = if course.primary_enrollment_state == "invited"
              before_label("#shared.menu_enrollment.labels.invited_as", "invited as")
            else
              before_label("#shared.menu_enrollment.labels.enrolled_as", "enrolled as")
            end
    [label, course.primary_enrollment_role.try(:label)].join(" ")
  end

  def term
    course.enrollment_term.name unless course.enrollment_term.default_term?
  end
end
