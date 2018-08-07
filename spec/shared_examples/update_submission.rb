#
# Copyright (C) 2018 - present Instructure, Inc.
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

RSpec.shared_examples 'a submission update action' do |controller|
  describe "PUT update" do
    it "should require authorization" do
      course_with_student(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
      @params = {course_id: @course.id, assignment_id: @assignment.id, submission: {comment: "some comment"}}.merge(@resource_pair)
      put :update, params: @params
      assert_unauthorized
    end

    it "should require the right student" do
      course_with_student_logged_in(active_all: true)
      @user2 = User.create!(name: "some user")
      @course.enroll_user(@user2)
      @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user2)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user2.id }
      @params = {course_id: @course.id, assignment_id: @assignment.id, submission: {comment: "some comment"}}.merge(@resource_pair)
      put :update, params: @params
      assert_unauthorized
    end

    it "should allow updating homework to add comments" do
      course_with_student_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
      @params = {course_id: @course.id, assignment_id: @assignment.id, submission: {comment: "some comment"}}.merge(@resource_pair)
      put :update, params: @params
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to be 1
      expect(assigns[:submission].submission_comments.first.comment).to eql("some comment")
    end

    it "should allow a non-enrolled admin to add comments" do
      course_with_student_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      site_admin_user
      user_session(@user)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @student.id }
      @params = {course_id: @course.id, assignment_id: @assignment.id, submission: {comment: "some comment"}}.merge(@resource_pair)
      put :update, params: @params
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to be 1
      expect(assigns[:submission].submission_comments.first.comment).to eql("some comment")
      expect(assigns[:submission].submission_comments.first).not_to be_hidden
    end

    it "should allow a non-enrolled admin to add comments on a submission to muted assignment" do
      course_with_student_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      @assignment.muted = true
      @assignment.save!
      site_admin_user
      user_session(@user)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @student.id }
      @params = {course_id: @course.id, assignment_id: @assignment.id, submission: {comment: "some comment"}}.merge(@resource_pair)
      put :update, params: @params
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to be 1
      expect(assigns[:submission].submission_comments.first.comment).to eql("some comment")
      expect(assigns[:submission].submission_comments.first).to be_hidden
    end

    it "should comment as the current user for all submissions in the group" do
      course_with_student_logged_in(active_all: true)
      @u1 = @user
      student_in_course(course: @course)
      @u2 = @user
      @assignment = @course.assignments.create!(
        title: "some assignment",
        submission_types: "online_url,online_upload",
        group_category: GroupCategory.create!(name: "groups", context: @course),
        grade_group_students_individually: true
      )
      @group = @assignment.group_category.groups.create!(name: 'g1', context: @course)
      @group.users << @u1
      @group.users << @user
      @submission = @u1.submissions.find_by!(assignment: @assignment)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @u1.id }
      @params = { course_id: @course.id, assignment_id: @assignment.id, submission: { comment: "some comment", group_comment: '1' } }.merge(@resource_pair)
      put :update, params: @params
      subs = @assignment.submissions
      expect(subs.size).to eq 2
      subs.each do |s|
        expect(s.submission_comments.size).to eq 1
        expect(s.submission_comments.first.author).to eq @u1
      end
    end

    it "should allow attaching files to the comment" do
      course_with_student_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      data1 = fixture_file_upload("docs/doc.doc", "application/msword", true)
      data2 = fixture_file_upload("docs/txt.txt", "text/plain", true)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
      @params = {
        course_id: @course.id,
        assignment_id: @assignment.id,
        submission: {comment: "some comment"},
        attachments: {"0" => {uploaded_data: data1}, "1" => {uploaded_data: data2}}
      }.merge(@resource_pair)

      put :update, params: @params
      expect(response).to be_redirect
      expect(assigns[:submission]).to eql(@submission)
      expect(assigns[:submission].submission_comments.length).to be 1
      expect(assigns[:submission].submission_comments.first.comment).to eql("some comment")
      expect(assigns[:submission].submission_comments.first.attachments.length).to be 2
      expect(assigns[:submission].submission_comments.first.attachments.map(&:display_name)).to be_include("doc.doc")
      expect(assigns[:submission].submission_comments.first.attachments.map(&:display_name)).to be_include("txt.txt")
    end

    it "should store comment files in instfs if instfs is enabled" do
      allow(InstFS).to receive(:enabled?).and_return(true)
      uuid = "1234-abcd"
      allow(InstFS).to receive(:direct_upload).and_return(uuid)
      course_with_student_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      data = fixture_file_upload("docs/txt.txt", "text/plain", true)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
      @params = {
        course_id: @course.id,
        assignment_id: @assignment.id,
        submission: { comment: "some comment" },
        attachments: { "0" => {uploaded_data: data } }
      }.merge(@resource_pair)

      put :update, params: @params
      expect(assigns[:submission].submission_comments.first.attachments.first.instfs_uuid).to eql(uuid)
    end

    describe 'allows a teacher to add draft comments to a submission' do
      before(:each) do
        course_with_teacher(active_all: true)
        @student = student_in_course.user
        assignment = @course.assignments.create!(title: 'Assignment #1', submission_types: 'online_url,online_upload')
        @submission = @student.submissions.find_by!(assignment: assignment)

        user_session(@teacher)
        @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @student.id }
        @test_params = {
          course_id: @course.id,
          assignment_id: assignment.id,
          submission: {
            comment: 'Comment #1',
          }
        }.merge(@resource_pair)
      end

      it 'when draft_comment is true' do
        test_params = @test_params
        test_params[:submission][:draft_comment] = true

        expect { put :update, params: test_params }.to change { SubmissionComment.draft.count }.by(1)
      end

      it 'except when draft_comment is nil' do
        test_params = @test_params
        test_params[:submission].delete(:draft_comment)

        expect { put :update, params: test_params }.to change(SubmissionComment, :count).by(1)
        expect { put :update, params: test_params }.not_to change { SubmissionComment.draft.count }
      end

      it 'except when draft_comment is false' do
        test_params = @test_params
        test_params[:submission][:draft_comment] = false

        expect { put :update, params: test_params }.to change(SubmissionComment, :count).by(1)
        expect { put :update, params: test_params }.not_to change { SubmissionComment.draft.count }
      end
    end

    describe "renders json" do
      before do
        course_with_student_and_submitted_homework
        @submission.update!(score: 10)
      end

      let(:body) { JSON.parse(response.body)['submission'] }

      it "renders json with scores for teachers" do
        user_session(@teacher)
        @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
        @params = { course_id: @course.id, assignment_id: @assignment.id, submission: {student_entered_score: '2'} }.merge(@resource_pair)
        put :update, params: @params, format: :json
        expect(body['id']).to eq @submission.id
        expect(body['score']).to eq 10
        expect(body['grade']).to eq '10'
        expect(body['published_grade']).to eq '10'
        expect(body['published_score']).to eq 10
      end

      it "renders json with scores for students" do
        user_session(@student)
        @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
        @params = { course_id: @course.id, assignment_id: @assignment.id, submission: {student_entered_score: '2'} }.merge(@resource_pair)
        put :update, params: @params, format: :json
        expect(body['id']).to eq @submission.id
        expect(body['score']).to eq 10
        expect(body['grade']).to eq '10'
        expect(body['published_grade']).to eq '10'
        expect(body['published_score']).to eq 10
      end

      it "renders json with scores for teachers on muted assignments" do
        @assignment.update!(muted: true)
        @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
        @params = { course_id: @course.id, assignment_id: @assignment.id, submission: {student_entered_score: '2'} }.merge(@resource_pair)
        put :update, params: @params, format: :json
        expect(body['id']).to eq @submission.id
        expect(body['score']).to eq 10
        expect(body['grade']).to eq '10'
        expect(body['published_grade']).to eq '10'
        expect(body['published_score']).to eq 10
      end

      it "renders json without scores for students on muted assignments" do
        user_session(@student)
        @assignment.update!(muted: true)
        @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
        @params = { course_id: @course.id, assignment_id: @assignment.id, submission: {student_entered_score: '2'} }.merge(@resource_pair)
        put :update, params: @params, format: :json
        expect(body['id']).to eq @submission.id
        expect(body['score']).to be nil
        expect(body['grade']).to be nil
        expect(body['published_grade']).to be nil
        expect(body['published_score']).to be nil
      end
    end

    it "should allow setting 'student_entered_grade'" do
      course_with_student_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment",
                                                submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
      @params = { course_id: @course.id, assignment_id: @assignment.id, submission: {student_entered_score: '2'} }.merge(@resource_pair)
      put :update, params: @params, format: :json
      expect(@submission.reload.student_entered_score).to eq 2.0
    end

    it "should round 'student_entered_grade'" do
      course_with_student_logged_in(active_all: true)
      @assignment = @course.assignments.create!(title: "some assignment",
                                                submission_types: "online_url,online_upload")
      @submission = @assignment.submit_homework(@user)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
      @params = { course_id: @course.id, assignment_id: @assignment.id, submission: {student_entered_score: '2.0000000020'} }.merge(@resource_pair)
      put :update, params: @params, format: :json
      expect(@submission.reload.student_entered_score).to eq 2.0
    end

    it 'changing student_entered_grade for a quiz does not change the workflow_state of a submission' do
      course_with_student_logged_in(active_all: true)
      assignment = @course.assignments.create!(workflow_state: :published, submission_types: :online_quiz)
      quiz = Quizzes::Quiz.find_by!(assignment_id: assignment)
      quiz_submission = quiz.generate_submission(@user).complete!
      quiz_submission.update_column(:workflow_state, :pending_review)
      @submission = @student.submissions.find_by!(assignment: assignment)
      @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
      @params = { course_id: @course.id, assignment_id: assignment.id, submission: {student_entered_score: '2'} }.merge(@resource_pair)
      put :update, params: @params, format: :json
      expect(quiz_submission.submission.reload).not_to be_pending_review
    end

    context "moderated grading" do
      before :once do
        course_with_student(active_all: true)
        @assignment = @course.assignments.create!(title: "some assignment",
          submission_types: "online_url,online_upload", moderated_grading: true, grader_count: 2)
        @submission = @assignment.submit_homework(@user)
      end

      it "should create a provisional comment" do
        @resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
        @params = {course_id: @course.id, assignment_id: @assignment.id, submission: {comment: "provisional!", provisional: true}}.merge(@resource_pair)
        user_session(@teacher)
        put :update, params: @params, format: :json

        @submission.reload
        expect(@submission.submission_comments.first).to be_nil
        expect(@submission.provisional_grade(@teacher).submission_comments.first.comment).to eq 'provisional!'

        json = JSON.parse response.body
        expect(json.first['submission']['submission_comments'].first['comment']).to eq 'provisional!'
      end

      context 'setting a provisional grade to be final' do
        before(:once) do
          @assignment.update!(final_grader: @teacher)
          @submission.find_or_create_provisional_grade!(@teacher)
          resource_pair = controller == :anonymous_submissions ? { anonymous_id: @submission.anonymous_id } : { id: @user.id }
          @params = {
            course_id: @course.id,
            assignment_id: @assignment.id,
            submission: {comment: "provisional!", provisional: true, final: true}
          }.merge(resource_pair)
        end

        let(:provisional_grade) do
          provisional_grade_id = json_parse(response.body).first.dig('submission', 'provisional_grade_id')
          ModeratedGrading::ProvisionalGrade.find_by(id: provisional_grade_id)
        end

        it 'returns success for an authorized user' do
          user_session(@teacher)
          put :update, params: @params, format: :json
          expect(response).to be_success
        end

        it 'creates a final provisional comment' do
          user_session(@teacher)
          expect { put :update, params: @params, format: :json }.to change {
            @submission.reload.provisional_grades.final.find_by(scorer: @teacher).present?
          }.from(false).to(true)
        end

        it 'allows setting the grade as final when the user is the final grader' do
          user_session(@teacher)
          put :update, params: @params, format: :json
          expect(provisional_grade).to be_final
        end

        it 'allows setting the grade as final when the user is an admin that can select final grade' do
          admin = account_admin_user(account: @course.root_account)
          user_session(admin)
          put :update, params: @params, format: :json
          expect(provisional_grade).to be_final
        end

        it 'is a bad request when the user is an admin that cannot select final grade' do
          admin = account_admin_user(account: @course.root_account)
          @course.root_account.role_overrides.create!(
            role: admin_role,
            permission: 'select_final_grade',
            enabled: false
          )
          user_session(admin)
          put :update, params: @params, format: :json
          expect(response.status).to eq 400
        end
      end
    end

    describe 'Moderated Grading' do
      before(:once) do
        course_with_student(active_all: true)
        teacher_in_course(active_all: true)

        @assignment = @course.assignments.create!(
          title: 'yet another assignment',
          moderated_grading: true,
          grader_count: 1
        )
      end

      let(:submission) { @student.submissions.find_by!(assignment: @assignment) }
      let(:submission_params) { {comment: 'hi', provisional: true, final: true } }
      let(:resource_pair) { controller == :anonymous_submissions ? { anonymous_id: submission.anonymous_id } : { id: @student.id } }
      let(:request_params) do
        { course_id: @course.id, assignment_id: @assignment.id, submission: submission_params }.merge(resource_pair)
      end

      let(:response_json) { JSON.parse(response.body) }

      describe 'provisional grade error handling' do
        it 'returns an error code of MAX_GRADERS_REACHED if a MaxGradersReachedError is raised' do
          @assignment.grade_student(@student, provisional: true, grade: 5, grader: @teacher)
          @previous_teacher = @teacher

          teacher_in_course(active_all: true)
          user_session(@teacher)

          put :update, params: request_params, format: :json

          expect(response_json.dig('errors', 'error_code')).to eq 'MAX_GRADERS_REACHED'
        end

        it 'returns a generic error if a GradeError is raised' do
          invalid_submission_params = submission_params.merge(excused: true)
          invalid_request_params = request_params.merge(submission: invalid_submission_params)
          user_session(@teacher)

          put :update, params: invalid_request_params, format: :json

          expect(response_json.dig('errors', 'base')).to be_present
        end
      end
    end
  end
end
