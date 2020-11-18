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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/courses/_recent_feedback" do
  before do
    course_with_student(active_all: true)
    assign(:current_user, @user)
    submission_model
  end

  it 'shows the context when asked to' do
    @assignment.grade_student(@user, grade: 7, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: {is_hidden: false, show_context: true}

    expect(response.body).to include(@course.short_name)
  end

  it "doesn't show the context when not asked to" do
    @assignment.grade_student(@user, grade: 7, grader: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", contexts: [@course], object: @submission, locals: {is_hidden: false}

    expect(response.body).to_not include(@course.name)
  end

  it 'shows the comment' do
    @assignment.update_submission(@user, comment: 'bunch of random stuff', commenter: @teacher)
    @submission.reload

    render partial: "courses/recent_feedback", object: @submission, locals: {is_hidden: false}

    expect(response.body).to include('bunch of random stuff')
  end

  it 'shows the grade' do
    @assignment.update!(points_possible: 5782394)
    @assignment.grade_student(@user, grade: 5782394, grader: @teacher)
    @submission.reload

    render :partial => "courses/recent_feedback", object: @submission, locals: {is_hidden: false}

    expect(response.body).to include("5,782,394 out of 5,782,394")
  end

  it 'shows the grade and the comment' do
    @assignment.update!(points_possible: 25734)
    @assignment.grade_student(@user, grade: 25734, grader: @teacher)
    @assignment.update_submission(@user, comment: 'something different', commenter: @teacher)
    @submission.reload

    render :partial => "courses/recent_feedback", object: @submission, locals: {is_hidden: false}

    expect(response.body).to include("25,734 out of 25,734")
    expect(response.body).to include('something different')
  end
end
