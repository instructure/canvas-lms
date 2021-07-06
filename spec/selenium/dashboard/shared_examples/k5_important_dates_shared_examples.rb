# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../pages/k5_dashboard_common_page'
require_relative '../../../helpers/k5_common'
require_relative '../../helpers/shared_examples_common'
require_relative '../pages/k5_important_dates_section_page'

shared_examples_for 'k5 important dates' do
  include K5DashboardPageObject
  include K5DashboardCommonPageObject
  include K5Common
  include SharedExamplesCommon
  include K5ImportantDatesSectionPageObject

  before :once do
    Account.site_admin.enable_feature!(:important_dates)
  end

  it 'shows the important dates section on the dashboard' do
    get "/"

    expect(important_dates_title).to be_displayed
  end

  it 'shows an image when no important dates have been created' do
    get "/"

    expect(no_important_dates_image).to be_displayed
  end

  it 'shows an important date for an assignment' do
    assignment_title = "Electricity Homework"
    due_at = 2.days.from_now(Time.zone.now)
    assignment = create_dated_assignment(@subject_course, assignment_title, due_at)
    assignment.update!(important_dates: true)

    get "/"

    expect(important_date_subject).to include_text(@subject_course.name)
    expect(important_date_icon_exists?('IconAssignment')).to be_truthy
    expect(important_date_link).to include_text(assignment_title)
    expect(element_value_for_attr(important_date_link,'href')).to include("/courses/#{@subject_course.id}/assignments/#{assignment.id}")
  end

  it 'only shows no dates panda when important dates is not set for assignment' do
    get "/"

    assignment_title = "Electricity Homework"
    due_at = 2.days.from_now(Time.zone.now)
    create_dated_assignment(@subject_course, assignment_title, due_at)

    get "/"

    expect(no_important_dates_image).to be_displayed
  end

  it 'shows an important date for a quiz' do
    quiz_title = "Electricity Quiz"
    due_at = 2.days.from_now(Time.zone.now)
    quiz = quiz_model(course: @subject_course, title: quiz_title)
    quiz.generate_quiz_data
    quiz.due_at = due_at
    quiz.save!
    quiz_assignment = Assignment.last
    quiz_assignment.update!(important_dates: true)

    get "/"


    expect(important_date_subject).to include_text(@subject_course.name)
    expect(important_date_icon_exists?('IconQuiz')).to be_truthy
    expect(important_date_link).to include_text(quiz_title)
    expect(element_value_for_attr(important_date_link,'href')).to include("/courses/#{@subject_course.id}/assignments/#{quiz_assignment.id}")
  end

  it 'shows an important date for a graded discussion' do
    discussion_title = "Electricity Discussion"
    due_at = 2.days.from_now(Time.zone.now)
    discussion_assignment = create_dated_assignment(@subject_course, discussion_title, due_at, 10)
    @course.discussion_topics.create!(:title => discussion_title, :assignment => discussion_assignment)
    discussion_assignment.update!(important_dates: true)

    get "/"

    expect(important_date_subject).to include_text(@subject_course.name)
    expect(important_date_icon_exists?('IconDiscussion')).to be_truthy
    expect(important_date_link).to include_text(discussion_title)
    expect(element_value_for_attr(important_date_link,'href')).to include("/courses/#{@subject_course.id}/assignments/#{discussion_assignment.id}")
  end

  it 'does not show an important date assignment in the past' do
    assignment_title = "Electricity Homework"
    due_at = 2.days.ago(Time.zone.now)
    assignment = create_dated_assignment(@subject_course, assignment_title, due_at)
    assignment.update!(important_dates: true)

    get "/"

    expect(no_important_dates_image).to be_displayed
  end
end
