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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/submissions/show" do
  before :once do
    course_with_student(active_all: true)
  end

  it "should render" do
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assigns[:assignment] = a
    assigns[:submission] = a.submit_homework(@user)
    render "submissions/show"
    expect(response).not_to be_nil
  end

  context 'when assignment has a rubric' do
    before :once do
      assignment_model
      rubric_association_model association_object: @assignment, purpose: 'grading'
      @submission = @assignment.submit_homework(@user)
    end

    context 'when current_user is submission user' do
      it 'does not add assessing class to rendered rubric_container' do
        view_context(@course, @student)
        assigns[:assignment] = @assignment
        assigns[:submission] = @submission
        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        classes = html.css('div.rubric_container').attribute('class').value.split(' ')
        expect(classes).not_to include('assessing')
      end
    end

    context 'when current_user is teacher' do
      it 'adds assessing class to rubric_container' do
        view_context(@course, @teacher)
        assigns[:assignment] = @assignment
        assigns[:submission] = @submission
        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        classes = html.css('div.rubric_container').attribute('class').value.split(' ')
        expect(classes).to include('assessing')
      end
    end

    context 'when current_user is an observer' do
      before :once do
        course_with_observer(course: @course)
      end

      it 'does not add assessing class to the rendered rubric_container' do
        view_context(@course, @observer)
        assigns[:assignment] = @assignment
        assigns[:submission] = @submission
        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        classes = html.css('div.rubric_container').attribute('class').value.split(' ')
        expect(classes).not_to include('assessing')
      end
    end

    context 'when current user is assessing student submission' do
      before :once do
        student_in_course(active_all: true)
        @course.workflow_state = 'available'
        @course.save!
        @assessment_request = @submission.assessment_requests.create!(
          assessor: @student,
          assessor_asset: @submission.user,
          user: @submission.user
        )
      end

      it 'shows the "Show Rubric" link after request is complete' do
        @assessment_request.complete!

        view_context(@course, @student)
        assigns[:assignment] = @assignment
        assigns[:submission] = @submission
        assigns[:rubric_association] = @submission.rubric_association_with_assessing_user_id

        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        rubric_link_text = html.css('.assess_submission_link')[0].text
        expect(rubric_link_text).to match(/Show Rubric/)
      end

      it 'adds assessing class to rubric_container' do
        view_context(@course, @student)
        assigns[:assignment] = @assignment
        assigns[:submission] = @submission
        assigns[:assessment_request] = @assessment_request
        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        classes = html.css('div.rubric_container').attribute('class').value.split(' ')
        expect(classes).to include('assessing')
      end
    end
  end
end

