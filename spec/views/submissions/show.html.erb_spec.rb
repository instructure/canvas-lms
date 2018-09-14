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

  describe "plagiarism report" do
    let(:teacher) do
      user = User.create
      @course.enroll_teacher(user)
      user
    end

    let(:html) do
      render "submissions/show"
      Nokogiri::HTML.fragment(response.body)
    end

    before :once do
      @assignment = @course.assignments.create!(
        assignment_valid_attributes.merge(submission_types: "online_upload,online_text_entry")
      )

      @submission = @assignment.submit_homework(@user, {body: "hello there", submission_type: 'online_text_entry'})
      @submission.turnitin_data = {
        "submission_#{@submission.id}" => {
          web_overlap: 92,
          error: true,
          publication_overlap: 0,
          state: "failure",
          object_id: "123456789",
          student_overlap: 90,
          similarity_score: 92
        }
      }
    end

    before :each do
      view_context(@course, teacher)
      assign(:assignment, @assignment)
      assign(:submission, @submission)
    end

    context "for turnitin" do
      it "is present when the plagiarism report is from turnitin" do
        expect(html.css('.turnitin_score_container_caret').size).to eq 1
      end

      it "is present when the plagiarism report is blank (defaults to turnitin)" do
        @submission.turnitin_data.delete(:provider)
        expect(html.css('.turnitin_score_container_caret').size).to eq 1
      end

      it "is not present when the plagiarism report is from vericite" do
        @submission.turnitin_data[:provider] = 'vericite'
        expect(html.css('.turnitin_score_container_caret').size).to eq 0
      end
    end

    context "for vericite" do
      before :each do
        @submission.turnitin_data[:provider] = 'vericite'
      end

      it "is present when the plagiarism report is from vericite" do
        expect(html.css('.vericite_score_container_caret').size).to eq 1
      end

      it "is not present when the plagiarism report is from turnitin" do
        @submission.turnitin_data[:provider] = 'turnitin'
        expect(html.css('.vericite_score_container_caret').size).to eq 0
      end

      it "is not present when the plagiarism report is blank (defaults to turnitin)" do
        @submission.turnitin_data.delete(:provider)
        expect(html.css('.vericite_score_container_caret').size).to eq 0
      end
    end
  end

  context 'comments sidebar' do
    before :each do
      course_with_teacher
      assignment_model(course: @course)
      @submission = @assignment.submit_homework(@user)
      view_context(@course, @teacher)
      assign(:assignment, @assignment)
      assign(:submission, @submission)
    end

    it "renders if assignment is not muted" do
      @assignment.muted = false
      @assignment.anonymous_grading = true
      render 'submissions/show'
      html = Nokogiri::HTML.fragment(response.body)
      styles = html.css('.submission-details-comments').attribute('style').value.split("\;").map(&:strip)
      expect(styles).not_to include('display: none')
    end

    it "renders if assignment is muted but not anonymous or moderated" do
      @assignment.muted = true
      @assignment.anonymous_grading = false
      @assignment.moderated_grading = false
      render 'submissions/show'
      html = Nokogiri::HTML.fragment(response.body)
      styles = html.css('.submission-details-comments').attribute('style').value.split("\;").map(&:strip)
      expect(styles).not_to include('display: none')
    end

    describe 'non-owner comment visibility' do
      let(:student) { User.create! }
      let(:teacher) { User.create! }
      let(:course) { Course.create!(name: 'a course') }

      let(:muted_assignment) { course.assignments.create!(title: 'muted', muted: true) }
      let(:muted_submission) { muted_assignment.submission_for_student(student) }
      let(:unmuted_assignment) { course.assignments.create!(title: 'not muted') }
      let(:unmuted_submission) { unmuted_assignment.submission_for_student(student) }

      let(:comment_contents) do
        html = Nokogiri::HTML.fragment(response.body)
        comment_list = html.css('.submission-details-comments .comment_list')

        # Comments are structured as:
        # <div class="comment">
        #   <div class="comment">the actual comment text</div>
        #   <div class="author">author name</div>
        #   ... and so on
        # </div>
        comment_list.css('.comment .comment').map { |comment| comment.text.strip }
      end

      before(:each) do
        assign(:context, course)

        course.enroll_teacher(teacher).accept(true)
        course.enroll_student(student).accept(true)

        muted_submission.add_comment(author: student, comment: 'I did a great job!')
        muted_submission.add_comment(author: teacher, comment: 'No, you did not', hidden: true)

        unmuted_submission.add_comment(author: student, comment: 'I did a great job!')
        unmuted_submission.add_comment(author: teacher, comment: 'No, you did not')
      end

      it 'shows all comments when a teacher is viewing' do
        assign(:current_user, teacher)
        assign(:assignment, muted_assignment)
        assign(:submission, muted_submission)

        render 'submissions/show'

        expect(comment_contents).to match_array ['I did a great job!', 'No, you did not']
      end

      context 'when a student is viewing' do
        before(:each) do
          assign(:current_user, student)
        end

        it 'shows all comments if the assignment is not muted' do
          unmuted_submission.limit_comments(student)

          assign(:assignment, unmuted_assignment)
          assign(:submission, unmuted_submission)

          render 'submissions/show'
          expect(comment_contents).to match_array ['I did a great job!', 'No, you did not']
        end

        it 'shows only non-hidden comments if the assignment is muted' do
          muted_submission.limit_comments(student)

          assign(:assignment, muted_assignment)
          assign(:submission, muted_submission)

          render 'submissions/show'
          expect(comment_contents).to match_array ['I did a great job!']
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
          assessor_asset: @submission,
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
