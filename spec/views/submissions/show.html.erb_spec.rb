#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative '../../selenium/helpers/groups_common'

describe "/submissions/show" do
  include GroupsCommon

  before :once do
    course_with_student(active_all: true)
  end

  it "should render" do
    view_context
    a = @course.assignments.create!(:title => "some assignment")
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show"
    expect(response).not_to be_nil
  end

  context 'when assignment is a group assignment' do
    before :once do
      @group_category = @course.group_categories.create!(name: "Test Group Set")
      @group = @course.groups.create!(name: "a group", group_category: @group_category)
      add_user_to_group(@user, @group, true)
      @assignment = @course.assignments.create!(assignment_valid_attributes.merge(
        group_category: @group_category,
        grade_group_students_individually: true,
      ))
      @submission = @assignment.submit_homework(@user)
    end

    before :each do
      view_context
      assign(:assignment, @assignment)
      assign(:submission, @submission)
    end

    it 'shows radio buttons for an individually graded group assignment' do
      render "submissions/show"
      @html = Nokogiri::HTML.fragment(response.body)
      expect(@html.css('input[type="radio"][name="submission[group_comment]"]').size).to eq 2
      expect(@html.css('#submission_group_comment').size).to eq 1
    end

    it 'renders hidden checkbox for a group graded group assignment' do
      @assignment.grade_group_students_individually = false
      @assignment.save!
      render "submissions/show"
      @html = Nokogiri::HTML.fragment(response.body)
      expect(@html.css('input[type="radio"][name="submission[group_comment]"]').size).to eq 0
      checkbox = @html.css('#submission_group_comment')
      expect(checkbox.attr('checked').value).to eq 'checked'
      expect(checkbox.attr('style').value).to include('display:none')
    end
  end

  context 'when assignment has deducted points' do
    it 'shows the deduction and "grade" as final grade when current_user is teacher' do
      view_context(@course, @teacher)
      a = @course.assignments.create!(title: "some assignment", points_possible: 10, grading_type: 'points')
      assign(:assignment, a)
      @submission = a.submit_homework(@user)
      @submission.update(grade: 7, points_deducted: 2)
      assign(:submission, @submission)
      render "submissions/show"
      html = Nokogiri::HTML.fragment(response.body)

      expect(html.css('.late_penalty').text).to include('-2')
      expect(html.css('.published_grade').text).to include('7')
    end

    it 'shows the deduction and "published_grade" as final grade when current_user is submission user' do
      view_context(@course, @user)
      a = @course.assignments.create!(title: "some assignment", points_possible: 10, grading_type: 'points')
      assign(:assignment, a)
      @submission = a.submit_homework(@user)
      @submission.update(grade: '7', points_deducted: 2, published_grade: '6')
      assign(:submission, @submission)
      render "submissions/show"
      html = Nokogiri::HTML.fragment(response.body)

      expect(html.css('.late_penalty').text).to include('-2')
      expect(html.css('.grade').text).to include('6')
    end

    context 'and is excused' do
      it 'hides the deduction' do
        view_context(@course, @teacher)
        a = @course.assignments.create!(title: "some assignment", points_possible: 10, grading_type: 'points')
        assign(:assignment, a)
        @submission = a.submit_homework(@user)
        @submission.update(grade: 7, points_deducted: 2, excused: true)
        assign(:submission, @submission)
        render "submissions/show"
        html = Nokogiri::HTML.fragment(response.body)

        deduction_elements = html.css('.late-penalty-display')

        expect(deduction_elements).not_to be_empty
        deduction_elements.each do |deduction_element|
          expect(deduction_element.attr('style')).to include('display: none;')
        end
      end
    end
  end

  context 'when assignment has a rubric' do
    before :once do
      assignment_model(course: @course)
      rubric_association_model association_object: @assignment, purpose: 'grading'
      @submission = @assignment.submit_homework(@user)
    end

    context 'when current_user is submission user' do
      it 'does not add assessing class to rendered rubric_container' do
        view_context(@course, @student)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        classes = html.css('div.rubric_container').attribute('class').value.split(' ')
        expect(classes).not_to include('assessing')
      end
    end

    context 'when current_user is teacher' do
      it 'adds assessing class to rubric_container' do
        view_context(@course, @teacher)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
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
        assign(:assignment, @assignment)
        assign(:submission, @submission)
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
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        assign(:rubric_association, @assignment.rubric_association)

        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        rubric_link_text = html.css('.assess_submission_link')[0].text
        expect(rubric_link_text).to match(/Show Rubric/)
      end

      it 'adds assessing class to rubric_container' do
        view_context(@course, @student)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        assign(:assessment_request, @assessment_request)
        render 'submissions/show'
        html = Nokogiri::HTML.fragment(response.body)
        classes = html.css('div.rubric_container').attribute('class').value.split(' ')
        expect(classes).to include('assessing')
      end
    end
  end
end
