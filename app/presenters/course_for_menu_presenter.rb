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

  DASHBOARD_CARD_TABS = [
    Course::TAB_DISCUSSIONS, Course::TAB_ASSIGNMENTS,
    Course::TAB_ANNOUNCEMENTS, Course::TAB_FILES
  ].freeze

  def initialize(course, available_section_tabs, user = nil, context = nil)
    @course = course
    @user = user
    @context = context
    @available_section_tabs = (available_section_tabs || []).select do |tab|
      DASHBOARD_CARD_TABS.include?(tab[:id])
    end
  end
  attr_reader :course, :available_section_tabs

  def to_h
    {
      longName: "#{course.name} - #{course.short_name}",
      shortName: course.nickname_for(@user),
      originalName: course.name,
      courseCode: course.course_code,
      assetString: course.asset_string,
      href: course_path(course, invitation: course.read_attribute(:invitation)),
      term: term || nil,
      subtitle: subtitle,
      id: course.id,
      image: course.feature_enabled?(:course_card_images) ? course.image : nil,
      position: (@context && @context.feature_enabled?(:dashcard_reordering)) ? @user.dashboard_positions[course.asset_string] : nil,
      links: available_section_tabs.map do |tab|
        presenter = SectionTabPresenter.new(tab, course)
        presenter.to_h
      end

    }
  end

  private
  def role
    Role.get_role_by_id(Shard.relative_id_for(course.primary_enrollment_role_id, course.shard, Shard.current)) ||
      Enrollment.get_built_in_role_for_type(course.primary_enrollment_type)
  end

  def subtitle
    label = if course.primary_enrollment_state == 'invited'
      before_label('#shared.menu_enrollment.labels.invited_as', 'invited as')
    else
      before_label('#shared.menu_enrollment.labels.enrolled_as', 'enrolled as')
    end
    [ label, role.try(:label) ].join(' ')
  end

  def term
    course.enrollment_term.name unless course.enrollment_term.default_term?
  end
end
