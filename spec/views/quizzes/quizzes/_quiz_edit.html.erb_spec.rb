#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../views_helper')

describe "/quizzes/quizzes/_quiz_edit" do
  before do
    course_with_student
    view_context
    assign(:quiz, @course.quizzes.create!)
    assign(:js_env, {quiz_max_combination_count: 200})
  end

  it "should render" do
    render :partial => "quizzes/quizzes/quiz_edit"
    expect(response).not_to be_nil
  end

  it 'should include conditional content if configured' do
    ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
    render :partial => "quizzes/quizzes/quiz_edit"
    expect(response.body).to match /conditional_release/
  end

  it 'should not include conditional content if not configured' do
    ConditionalRelease::Service.stubs(:enabled_in_context?).returns(false)
    render :partial => "quizzes/quizzes/quiz_edit"
    expect(response.body).not_to match /conditional_release/
  end

  it 'should include quiz details' do
    render :partial => "quizzes/quizzes/quiz_edit"
    expect(response.body).to match /options_tab/
  end

  it 'should include quiz questions' do
    render :partial => "quizzes/quizzes/quiz_edit"
    expect(response.body).to match /questions_tab/
  end

  it 'should warn about existing submission data' do
    assign(:has_student_submissions, true)
    render :partial => "quizzes/quizzes/quiz_edit"
    expect(response.body).to match /student_submissions_warning/
  end

  it 'should not warn if no existing data' do
    assign(:has_student_submissions, false)
    render :partial => "quizzes/quizzes/quiz_edit"
    expect(response.body).not_to match /student_submissions_warning/
  end
end
