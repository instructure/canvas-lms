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

require_relative '../api_spec_helper'

describe 'Provisional Grades API', type: :request do
  it_behaves_like 'a provisional grades status action', :provisional_grades

  describe "select" do
    before(:once) do
      course_with_student :active_all => true
      ta_in_course :active_all => true
      @assignment = @course.assignments.build
      @assignment.grader_count = 1
      @assignment.moderated_grading = true
      @assignment.final_grader_id = @teacher.id
      @assignment.save!
      subs = @assignment.grade_student @student, :grader => @ta, :score => 0, :provisional => true
      @pg = subs.first.provisional_grade(@ta)
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/provisional_grades/#{@pg.id}/select"
      @params = { :controller => 'provisional_grades', :action => 'select',
                  :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.to_param,
                  :provisional_grade_id => @pg.to_param }
    end

    it "should fail if the student isn't in the moderation set" do
      @assignment.moderated_grading_selections.destroy_all
      json = api_call_as_user(@teacher, :put, @path, @params, {}, {}, { :expected_status => 400 })
      expect(json['message']).to eq 'student not in moderation set'
    end

    it "should select a provisional grade" do
      json = api_call_as_user(@teacher, :put, @path, @params)
      expect(json).to eq({
                           'assignment_id' => @assignment.id,
                           'student_id' => @student.id,
                           'selected_provisional_grade_id' => @pg.id
                         })
      expect(@assignment.moderated_grading_selections.where(student_id: @student.id).first.provisional_grade).to eq(@pg)
    end

    it "should use anonymous_id instead of student_id if user cannot view student names" do
      allow_any_instance_of(Assignment).to receive(:can_view_student_names?).and_return false
      json = api_call_as_user(@teacher, :put, @path, @params)
      expect(json).to eq({
                           'assignment_id' => @assignment.id,
                           'anonymous_id' => @pg.submission.anonymous_id,
                           'selected_provisional_grade_id' => @pg.id
                         })
      expect(@assignment.moderated_grading_selections.where(student_id: @student.id).first.provisional_grade).to eq(@pg)
    end

    it_behaves_like 'authorization for provisional final grade selection', :put
  end

  describe "copy_to_final_mark" do
    before(:once) do
      course_with_student :active_all => true
      ta_in_course :active_all => true
      @assignment = @course.assignments.create!(
        submission_types: 'online_text_entry',
        moderated_grading: true,
        grader_count: 1,
        final_grader_id: @teacher.id
      )
      @submission = @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'hallo')
      @pg = @submission.find_or_create_provisional_grade!(@ta, score: 80)
      @submission.add_comment(:commenter => @ta, :comment => 'huttah!', :provisional => true)

      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/provisional_grades/#{@pg.id}/copy_to_final_mark"
      @params = { :controller => 'provisional_grades', :action => 'copy_to_final_mark',
                  :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.to_param,
                  :provisional_grade_id => @pg.to_param }
    end

    it "requires moderate_grades permission" do
      api_call_as_user @student, :post, @path, @params, {}, {}, { :expected_status => 401 }
    end

    it "fails if the student isn't in the moderation set" do
      @assignment.moderated_grading_selections.where(student_id: @student).delete_all
      json = api_call_as_user @teacher, :post, @path, @params, {}, {}, { :expected_status => 400 }
      expect(json['message']).to eq 'student not in moderation set'
    end

    it "fails if the mark is already final" do
      @pg.update_attributes(:final => true)
      json = api_call_as_user @teacher, :post, @path, @params, {}, {}, { :expected_status => 400 }
      expect(json['message']).to eq 'provisional grade is already final'
    end

    it "copies the selected provisional grade" do
      json = api_call_as_user @teacher, :post, @path, @params
      final_mark = ModeratedGrading::ProvisionalGrade.find(json['provisional_grade_id'])
      expect(final_mark.score).to eq 80
      expect(final_mark.scorer).to eq @teacher
      expect(final_mark.final).to eq true

      expect(json['score']).to eq 80
      expect(json['submission_comments'].first['comment']).to eq 'huttah!'
      expect(json['crocodoc_urls']).to eq([])
    end

    it_behaves_like 'authorization for provisional final grade selection', :post
  end

  describe "publish" do
    before :once do
      course_with_student :active_all => true
      course_with_ta :course => @course, :active_all => true
      @assignment = @course.assignments.create!
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/provisional_grades/publish"
      @params = { :controller => 'provisional_grades', :action => 'publish',
                  :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.to_param }
    end

    it "requires a moderated assignment" do
      @assignment.update_attribute :final_grader_id, @teacher.id
      json = api_call_as_user(@teacher, :post, @path, @params, {}, {}, { :expected_status => 400 })
      expect(json['message']).to eq 'Assignment does not use moderated grading'
    end

    context "with moderated assignment" do
      before(:once) do
        @assignment.update_attribute :moderated_grading, true
        @assignment.update_attribute :grader_count, 2
        @assignment.update_attribute :final_grader_id, @teacher.id
      end

      it "responds with a 200 for a valid request" do
        api_call_as_user(@teacher, :post, @path, @params, {}, {}, expected_status: 200)
      end

      it "requires manage_grades permissions" do
        @course.root_account.role_overrides.create!(
          permission: :manage_grades,
          role: Role.find_by(name: 'TeacherEnrollment'),
          enabled: false
        )
        api_call_as_user(@teacher, :post, @path, @params, {}, {}, expected_status: 401)
      end

      it "fails if grades were already published" do
        @assignment.update_attribute :grades_published_at, Time.now.utc
        json = api_call_as_user(@teacher, :post, @path, @params, {}, {}, { :expected_status => 400 })
        expect(json['message']).to eq 'Assignment grades have already been published'
      end

      context 'with empty provisional grades (comments only)' do
        before(:once) do
          @submission = @assignment.submit_homework(@student, :body => "hello")
          @submission.add_comment(author: @ta, provisional: true, comment: 'A provisional comment')
          @provisional_grade = @submission.provisional_grades.first
        end

        it 'publishes an empty provisional grade for an active student' do
          api_call_as_user(@teacher, :post, @path, @params)

          expect(@assignment.reload.grades_published?).to be_truthy
          expect(@submission.reload.grade).to be_nil
        end

        it 'publishes an empty provisional grade for a student with concluded enrollment' do
          student_enrollment = @course.enrollments.find_by(user: @student)
          student_enrollment.conclude

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@assignment.reload.grades_published?).to be_truthy
          expect(@submission.reload.grade).to be_nil
        end

        it 'publishes an empty provisional grade for a student with an inactive enrollment' do
          student_enrollment = @course.enrollments.find_by(user: @student)
          student_enrollment.deactivate

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@assignment.reload.grades_published?).to be_truthy
          expect(@submission.reload.grade).to be_nil
        end
      end

      context "with provisional grades" do
        before(:once) do
          @submission = @assignment.submit_homework(@student, :body => "hello")
          @assignment.grade_student(@student, { :grader => @ta, :score => 100, :provisional => true })
        end

        it "publishes provisional grades" do
          expect(@submission.workflow_state).to eq 'submitted'
          expect(@submission.score).to be_nil
          expect(@student.messages).to be_empty

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@submission.reload.workflow_state).to eq 'graded'
          expect(@submission.grader).to eq @ta
          expect(@submission.score).to eq 100

          @assignment.reload
          expect(@assignment.grades_published_at).to be_within(1.minute.to_i).of(Time.now.utc)
        end

        it "publishes the selected provisional grade when the student is in the moderation set" do
          @submission.provisional_grade(@ta).update_attribute(:graded_at, 1.minute.ago)

          sel = @assignment.moderated_grading_selections.find_by(student: @student)

          @other_ta = user_factory :active_user => true
          @course.enroll_ta @other_ta, :enrollment_state => 'active'
          @assignment.grade_student(@student, { :grader => @other_ta, :score => 90, :provisional => true })

          sel.selected_provisional_grade_id = @submission.provisional_grade(@other_ta).id
          sel.save!

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@submission.reload.workflow_state).to eq 'graded'
          expect(@submission.grader).to eq @other_ta
          expect(@submission.score).to eq 90
        end
      end

      context "with one provisional grade" do
        it "publishes the only provisional grade if none have been explicitly selected" do
          course_with_user("TaEnrollment", course: @course, active_all: true)
          @submission = @assignment.submit_homework(@student, body: "hello")
          @assignment.grade_student(@student, grader: @ta, score: 72, provisional: true)

          api_call_as_user(@teacher, :post, @path, @params)

          expect(@submission.reload.score).to eq 72
        end
      end

      context "with multiple provisional grades" do
        before(:once) do
          course_with_user("TaEnrollment", course: @course, active_all: true)
          @second_ta = @user
        end

        it "publishes even when some submissions have no grades" do
          @submission = @assignment.submit_homework(@student, body: "hello")

          @user = @teacher
          raw_api_call(:post, @path, @params)

          expect(response.response_code).to eq(200)
          expect(@submission.reload.score).to be_nil
          expect(@assignment.reload.grades_published_at).not_to be_nil
        end

        it "does not publish if none have been explicitly selected" do
          @submission = @assignment.submit_homework(@student, body: "hello")
          @assignment.grade_student(@student, grader: @ta, score: 72, provisional: true)
          @assignment.grade_student(@student, grader: @second_ta, score: 88, provisional: true)

          @user = @teacher
          raw_api_call(:post, @path, @params)

          expect(response.response_code).to eq(422)
          expect(@submission.reload).not_to be_graded
          expect(@assignment.reload.grades_published_at).to be_nil
        end

        it "does not publish any if not all have been explicitly selected" do
          student_1 = @student
          student_2 = student_in_course(active_all: true, course: @course).user
          submission_1 = @assignment.submit_homework(student_1, body: "hello")
          submission_2 = @assignment.submit_homework(student_2, body: "hello")
          selection_1 = @assignment.moderated_grading_selections.find_by(student: student_1)
          @assignment.grade_student(student_1, grader: @ta, score: 12, provisional: true)
          @assignment.grade_student(student_1, grader: @second_ta, score: 34, provisional: true)
          @assignment.grade_student(student_2, grader: @ta, score: 56, provisional: true)
          @assignment.grade_student(student_2, grader: @second_ta, score: 78, provisional: true)

          selection_1.update_attribute(:selected_provisional_grade_id, submission_1.provisional_grade(@ta))

          @user = @teacher
          raw_api_call(:post, @path, @params)

          expect(response.response_code).to eq(422)
          expect(submission_1.reload).not_to be_graded
          expect(submission_2.reload).not_to be_graded
          expect(@assignment.reload.grades_published_at).to be_nil
        end
      end

      it_behaves_like 'authorization for provisional final grade selection', :post
    end
  end
end
