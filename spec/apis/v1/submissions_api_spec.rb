#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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
require_relative '../file_uploads_spec_helper'

describe 'Submissions API', type: :request do
  include Api::V1::User

  let(:params) { {} }

  before :each do
    HostUrl.stubs(:file_host_with_shard).returns(["www.example.com", Shard.default])
  end

  def submit_homework(assignment, student, opts = {:body => "test!"})
    @submit_homework_time ||= Time.zone.at(0)
    @submit_homework_time += 1.hour
    sub = assignment.find_or_create_submission(student)
    if sub.versions.size == 1
      Version.where(:id => sub.versions.first).update_all(:created_at => @submit_homework_time)
    end
    sub.workflow_state = 'submitted'
    yield(sub) if block_given?
    sub.with_versioning(:explicit => true) do
      update_with_protected_attributes!(sub, { :submitted_at => @submit_homework_time, :created_at => @submit_homework_time }.merge(opts))
    end
    sub.versions(true).each { |v| Version.where(:id => v).update_all(:created_at => v.model.created_at) }
    sub
  end

  it "does not 404 if there is no submission" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })
    expect(json.delete('id')).to eq nil
    expect(json).to eq({
      "assignment_id" => @assignment.id,
      "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}?preview=1&version=0",
      "user_id"=>student.id,
      "grade"=>nil,
      "excused" => nil,
      "grader_id"=>nil,
      "body"=>nil,
      "submitted_at"=>nil,
      "submission_history"=>[],
      "attempt"=>nil,
      "url"=>nil,
      "submission_type"=>nil,
      "submission_comments"=>[],
      "grade_matches_current_submission"=>nil,
      "score"=>nil,
      "workflow_state"=>nil,
      "late"=>false,
      "graded_at"=>nil,
    })
  end

  describe "using section ids" do
    before :once do
      @student1 = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = factory_with_protected_attributes(@course.course_sections, :sis_source_id => 'my-section-sis-id', :name => 'section2')
      @course.enroll_user(@student1, 'StudentEnrollment', :section => @section).accept!

      quiz = Quizzes::Quiz.create!(:title => 'quiz1', :context => @course)
      quiz.did_edit!
      quiz.offer!
      @a1 = quiz.assignment
      sub = @a1.find_or_create_submission(@student1)
      sub.submission_type = 'online_quiz'
      sub.workflow_state = 'submitted'
      sub.save!
    end

    it "lists submissions" do
      json = api_call(:get,
        "/api/v1/sections/#{@default_section.id}/assignments/#{@a1.id}/submissions.json",
        { :controller => 'submissions_api', :action => 'index',
          :format => 'json', :section_id => @default_section.id.to_s,
          :assignment_id => @a1.id.to_s },
        { :include => %w(submission_history submission_comments rubric_assessment) })
      expect(json.size).to eq 0

      json = api_call(:get,
        "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions.json",
        { :controller => 'submissions_api', :action => 'index',
          :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
          :assignment_id => @a1.id.to_s },
        { :include => %w(submission_history submission_comments rubric_assessment) })
      expect(json.size).to eq 1
      expect(json.first['user_id']).to eq @student1.id

      api_call(:get,
        "/api/v1/sections/#{@default_section.id}/students/submissions",
        { :controller => 'submissions_api', :action => 'for_students',
          :format => 'json', :section_id => @default_section.id.to_s },
        { :student_ids => [@student1.id] },
        {}, expected_status: 401)

      json = api_call(:get,
        "/api/v1/sections/sis_section_id:my-section-sis-id/students/submissions",
        { :controller => 'submissions_api', :action => 'for_students',
          :format => 'json', :section_id => 'sis_section_id:my-section-sis-id' },
          :student_ids => [@student1.id])
      expect(json.size).to eq 1
    end

    it "includes user" do
      json = api_call(:get,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions.json",
        { :controller => 'submissions_api', :action => 'index',
          :format => 'json', :section_id => @section.id.to_s,
          :assignment_id => @a1.id.to_s },
        { :include => %w(user) })
      expect(json.size).to eq 1
      expect(json[0]['user']).not_to be_nil
      expect(json[0]['user']['id']).to eq(@student1.id)
    end

    it "returns assignment_visible" do
      json = api_call(:get,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions.json",
        { :controller => 'submissions_api', :action => 'index',
          :format => 'json', :section_id => @section.id.to_s,
          :assignment_id => @a1.id.to_s },
        { :include => %w(visibility), :student_ids => [@student1.id] })
      expect(json[0]["assignment_visible"]).to eq true
    end

    it "posts to submissions" do
      @a1 = @course.assignments.create!({:title => 'assignment1', :grading_type => 'percent', :points_possible => 10})
      json = raw_api_call(:put,
                      "/api/v1/sections/#{@default_section.id}/assignments/#{@a1.id}/submissions/#{@student1.id}",
      { :controller => 'submissions_api', :action => 'update',
        :format => 'json', :section_id => @default_section.id.to_s,
        :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
        { :submission => { :posted_grade => '75%' } })
      assert_status(404)

      expect {
      json = api_call(:put,
                      "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
      { :controller => 'submissions_api', :action => 'update',
        :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
        :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
        { :submission => { :posted_grade => '75%' } })
        # never more than 1 job added, because it's in a Delayed::Batch
      }.to change { Delayed::Job.jobs_count(:current) }.by(1)

      expect(Submission.count).to eq 2
      @submission = Submission.order(:id).last
      expect(@submission.grader).to eq @teacher

      expect(json['score']).to eq 7.5
      expect(json['grade']).to eq '75%'
    end

    it "returns assignment_visible after posting to submissions" do
      json = api_call(:put,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/#{@student1.id}",
        { :controller => 'submissions_api', :action => 'update',
        :format => 'json', :section_id => @section.id.to_s,
        :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
        { :submission => { :posted_grade => '75%' }, :include => %w(visibility) })
      expect(json["assignment_visible"]).to eq true
      expect(json["all_submissions"][0]["assignment_visible"]).to eq true
    end

    it "should be able to handle an update without visibility when DA is on" do
      json = api_call(:put,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/#{@student1.id}",
        { :controller => 'submissions_api', :action => 'update',
        :format => 'json', :section_id => @section.id.to_s,
        :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
        { :submission => { :posted_grade => '75%' }})
      expect(json["assignment_visible"]).to be_nil
      expect(json["all_submissions"][0]["assignment_visible"]).to be_nil
      expect(json["assignment_id"]).to eq @a1.id
    end

    it "returns submissions for a section" do
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_history submission_comments rubric_assessment) })
      expect(json['user_id']).to eq @student1.id
    end

    it "does not show grades or hidden comments to students on muted assignments" do
      @a1.mute!
      @a1.grade_student(@student1, grade: 5, grader: @teacher)

      @a1.update_submission(@student1, :hidden => false, :comment => "visible comment")
      @a1.update_submission(@student1, :hidden => true, :comment => "hidden comment")

      @user = @student1
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_comments rubric_assessment) })

      %w(score published_grade published_score grade).each do |a|
        expect(json[a]).to be_nil
      end

      expect(json["submission_comments"].size).to eq 1
      expect(json["submission_comments"][0]["comment"]).to eq "visible comment"

      # should still show this stuff to the teacher
      @user = @teacher
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_comments rubric_assessment) })
      expect(json["submission_comments"].size).to eq 2
      expect(json["grade"]).to eq "5"

      # should show for an admin with no enrollments in the course
      account_admin_user
      expect(@user.enrollments).to be_empty
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_comments rubric_assessment) })
      expect(json["submission_comments"].size).to eq 2
      expect(json["grade"]).to eq "5"
    end

    context 'for a submission with a draft comment and a published comment' do
      before(:once) do
        @a1.update_submission(@student1, draft_comment: true, comment: 'Draft Answer: forty-one')
        @a1.update_submission(@student1, comment: 'Answer: forty-two')
      end

      before(:each) do
        @user = @student1

        @json = api_call(:get,
          "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
            :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
          { :include => %w(submission_comments) })
      end

      it 'returns only published comments' do
        expect(@json['submission_comments'].size).to eq(1)

        published_comments = @json['submission_comments'].select do |c|
          c['comment'] == 'Answer: forty-two'
        end

        expect(published_comments[0]['comment']).to eq('Answer: forty-two')
      end
    end

    it "does not show rubric assessments to students on muted assignments" do
      @a1.mute!
      sub = @a1.grade_student(@student1, grade: 5, grader: @teacher).first

      rubric = rubric_model(
        :user => @teacher,
        :context => @course,
        :data => larger_rubric_data
      )
      @a1.create_rubric_association(
        :rubric => rubric,
        :purpose => 'grading',
        :use_for_grading => true,
        :context => @course
      )
      @a1.rubric_association.assess(
        :assessor => @teacher,
        :user => @student1,
        :artifact => sub,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => { :points => 3 },
          :criterion_crit2 => { :points => 2, :comments => 'Hmm'}
        }
      )

      @user = @student1
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_comments rubric_assessment) })

      expect(json['rubric_assessment']).to be_nil
    end

    it "does not find sections in other root accounts" do
      acct = account_model(:name => 'other root')
      @first_course = @course
      course_factory(active_all: true, :account => acct)
      @course.default_section.update_attribute('sis_source_id', 'my-section-sis-id')
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions",
            { :controller => 'submissions_api', :action => 'index',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s })
      expect(json.size).to eq 1 # should find the submission for @first_course
      @course.default_section.update_attribute('sis_source_id', 'section-2')
      raw_api_call(:get,
            "/api/v1/sections/sis_section_id:section-2/assignments/#{@a1.id}/submissions",
            { :controller => 'submissions_api', :action => 'index',
              :format => 'json', :section_id => 'sis_section_id:section-2',
              :assignment_id => @a1.id.to_s })
      assert_status(404) # rather than 401 unauthorized
    end

    context 'submission comment attachments' do
      before :once do
        course_with_student(active_all: true)
        @assignment = @course.assignments.create! name: "blah",
          submission_types: "online_upload"
        @attachment = Attachment.create! context: @assignment,
          user: @student,
          filename: "cats.jpg",
          uploaded_data: StringIO.new("meow?")
      end

      def put_comment_attachment
        raw_api_call :put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/",
          {controller: 'submissions_api', action: 'update', format: 'json',
           course_id: @course.to_param, assignment_id: @assignment.to_param,
           user_id: @student.to_param},
          comment: {file_ids: [@attachment.id]}
      end

      it "doesn't let you attach files you don't have permission for" do
        course_with_student_logged_in(course: @course, active_all: true)
        put_comment_attachment
        assert_status(401)
      end

      it 'works' do
        put_comment_attachment
        expect(response).to be_success
        expect(@assignment.submission_for_student(@student)
        .submission_comments.first
        .attachment_ids).to eq @attachment.id.to_s
      end
    end
  end

  it "returns student discussion entries for discussion_topic assignments" do
    @student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(@student).accept!
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, {:title => 'assignment1', :submission_types => 'discussion_topic', :discussion_topic => discussion_topic_model})

    e1 = @topic.discussion_entries.create!(:message => 'main entry', :user => @user)
    se1 = @topic.discussion_entries.create!(:message => 'sub 1', :user => @student, :parent_entry => e1)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    se2 = @topic.discussion_entries.create!(:message => 'student 1', :user => @student)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    @topic.discussion_entries.create!(:message => 'another entry', :user => @user)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s })

    expect(json['discussion_entries'].sort_by { |h| h['user_id'] }).to eq(
      [{
        'id' => se1.id,
        'message' => 'sub 1',
        'user_id' => @student.id,
        'read_state' => 'unread',
        'forced_read_state' => false,
        'parent_id' => e1.id,
        'created_at' => se1.created_at.as_json,
        'updated_at' => se1.updated_at.as_json,
        'user_name' => 'User',
        'user' => user_display_json(@student, @course).stringify_keys!,
        'rating_sum' => nil,
        'rating_count' => nil,
      },
      {
        'id' => se2.id,
        'message' => 'student 1',
        'user_id' => @student.id,
        'read_state' => 'unread',
        'forced_read_state' => false,
        'parent_id' => nil,
        'created_at' => se2.created_at.as_json,
        'updated_at' => se2.updated_at.as_json,
        'user_name' => 'User',
        'user' => user_display_json(@student, @course).stringify_keys!,
        'rating_sum' => nil,
        'rating_count' => nil,
      }].sort_by { |h| h['user_id'] }
    )

    # don't include discussion entries if response_fields limits the response
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s },
          { :response_fields => SubmissionsApiController::SUBMISSION_JSON_FIELDS })
    expect(json['discussion_entries']).to be_nil

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s },
          { :exclude_response_fields => %w(discussion_entries) })
    expect(json['discussion_entries']).to be_nil
  end

  it "returns student discussion entries from child topics for group discussion_topic assignments" do
    @student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(@student).accept!
    group_category = @course.group_categories.create(:name => "Category")
    @group = @course.groups.create(:name => "Group", :group_category => group_category)
    @group.add_user(@student)
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, {:title => 'assignment1', :submission_types => 'discussion_topic', :discussion_topic => discussion_topic_model(:group_category => @group.group_category)})
    @topic.refresh_subtopics # since the DJ won't happen in time
    @child_topic = @group.discussion_topics.where(root_topic_id: @topic).first

    e1 = @child_topic.discussion_entries.create!(:message => 'main entry', :user => @user)
    se1 = @child_topic.discussion_entries.create!(:message => 'sub 1', :user => @student, :parent_entry => e1)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    se2 = @child_topic.discussion_entries.create!(:message => 'student 1', :user => @student)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    @child_topic.discussion_entries.create!(:message => 'another entry', :user => @user)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s })

    expect(json['discussion_entries'].sort_by { |h| h['user_id'] }).to eq(
      [{
        'id' => se1.id,
        'message' => 'sub 1',
        'user_id' => @student.id,
        'user_name' => 'User',
        'user' => user_display_json(@student, @course).stringify_keys!,
        'read_state' => 'unread',
        'forced_read_state' => false,
        'parent_id' => e1.id,
        'created_at' => se1.created_at.as_json,
        'updated_at' => se1.updated_at.as_json,
        'rating_sum' => nil,
        'rating_count' => nil,
      },
      {
        'id' => se2.id,
        'message' => 'student 1',
        'user_id' => @student.id,
        'user_name' => 'User',
        'user' => user_display_json(@student, @course).stringify_keys!,
        'read_state' => 'unread',
        'forced_read_state' => false,
        'parent_id' => nil,
        'created_at' => se2.created_at.as_json,
        'updated_at' => se2.updated_at.as_json,
        'rating_sum' => nil,
        'rating_count' => nil,
      }].sort_by { |h| h['user_id'] }
    )
  end

  def submission_with_comment
    @student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(@student).accept!
    @quiz = Quizzes::Quiz.create!(:title => 'quiz1', :context => @course)
    @quiz.did_edit!
    @quiz.offer!
    @assignment = @quiz.assignment
    @submission = @assignment.find_or_create_submission(@student)
    @submission.submission_type = 'online_quiz'
    @submission.workflow_state = 'submitted'
    @submission.save!
    @assignment.update_submission(@student, :comment => "i am a comment")
  end

  it "returns user display info along with submission comments" do

    submission_with_comment

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s },
          { :include => %w(submission_comments) })

    expect(json.first["submission_comments"].size).to eq 1
    comment = json.first["submission_comments"].first
    expect(comment).to have_key("author")
    expect(comment["author"]).to eq({
      "id" => @student.id,
      "display_name" => "User",
      "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student.id}",
      "avatar_image_url" => User.avatar_fallback_url(nil, request)
    })
  end

  it 'does not return user display info with anonymous submission comments' do
    reviewed = student_in_course({
      :active_all => true
    }).user
    reviewer = student_in_course({
      :active_all => true,
      :course => @course
    }).user
    assignment = assignment_model(course: @course)
    assignment.update_attribute(:anonymous_peer_reviews, true)
    expect(assignment.reload.anonymous_peer_reviews?).to be_truthy, 'precondition'

    submission = assignment.submit_homework(reviewed, body: "My Submission")
    submission_comment = submission.add_comment({
      author: reviewer,
      comment: "My comment"
    })
    expect(submission_comment.grants_right?(reviewed, :read_author)).to be_falsey,
      'precondition'

    @user = reviewed
    url = "/api/v1/courses/#{@course.id}/students/submissions.json"
    json = api_call(:get, url, {
      :controller => 'submissions_api',
      :action => 'for_students',
      :format => 'json',
      :course_id => @course.to_param,
      :assignment_ids => [ @assignment.to_param ],
      :student_ids => [ reviewed.to_param ]
    }, {
      :include => %w(submission_comments)
    })

    comment_json = json.first['submission_comments'].first
    expect(comment_json['author_id']).to be_nil
    expect(comment_json['author_name']).to match(/Anonymous/)
    expect(comment_json['author']).to be_empty
  end

  it "returns comment id along with submission comments" do

    submission_with_comment

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s },
          { :include => %w(submission_comments) })

    expect(json.first["submission_comments"].size).to eq 1
    comment = json.first["submission_comments"].first
    expect(comment).to have_key("id")
    expect(comment["id"]).to eq @submission.submission_comments.first.id
  end

  it "returns a valid preview url for quiz submissions" do
    @student = student1 = user_factory(active_all: true)
    course_with_teacher_logged_in(:active_all => true) # need to be logged in to view the preview url below
    @course.enroll_student(student1).accept!
    quiz_with_submission
    a1 = @quiz.assignment
    sub = @quiz.assignment.submissions.where(user_id: student1).first

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })

    preview_url = json.first['preview_url']
    expect(Rack::Utils.parse_query(URI(preview_url).query)['version'].to_i).to eq sub.quiz_submission_version
    get_via_redirect preview_url
    expect(response).to be_success
    expect(response.body).to match(/#{@quiz.quiz_title} Results/)
  end

  it "returns a correct submission_history for quiz submissions" do
    student1 = user_factory(active_all: true)
    course_with_teacher_logged_in(:active_all => true) # need to be logged in to view the preview url below
    @course.enroll_student(student1).accept!
    quiz = Quizzes::Quiz.create!(:title => 'quiz1', :context => @course)
    quiz.did_edit!
    quiz.offer!
    qs = quiz.generate_submission(student1)
    qs.mark_completed
    Quizzes::SubmissionGrader.new(qs).grade_submission
    qs.reload
    qs.attempt = 2
    qs.with_versioning(true, &:save)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{quiz.assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => quiz.assignment.id.to_s },
          { :include => %w(submission_history) })

    expect(json.first['submission_history'].count).to eq 2
    expect(json.first['submission_history'].first.include? "submission_data").to be_truthy
  end

  it "returns the correct submitted_at date for each quiz submission" do
    course_with_student(course: @course, active_all: true)
    quiz_with_graded_submission([multiple_answers_question_data], { user: @student })
    Timecop.travel(15.minutes.ago) do
      qs = @quiz.generate_submission(@student)
      qs.mark_completed
      Quizzes::SubmissionGrader.new(qs).grade_submission
    end
    course_with_teacher_logged_in(:course => @course, :active_all => true)
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@quiz.assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @quiz.assignment.id.to_s },
          { :include => %w(submission_history) })
    submission_dates = json.first['submission_history'].map { |hash| hash['submitted_at'] }
    expect(submission_dates.first).not_to eq(submission_dates.last)
  end

  it "allows students to retrieve their own submission" do
    student1 = user_factory(active_all: true)
    student2 = user_factory(active_all: true)

    course_with_teacher(:active_all => true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!

    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    sub1 = submit_homework(a1, student1)
    media_object(:media_id => "3232", :media_type => "audio")
    a1.update_submission(student1, {:comment => "Well here's the thing...", :media_comment_id => "3232", :media_comment_type => "audio", :commenter => @teacher})
    sub1 = a1.grade_student(student1, {:grade => '90%', :grader => @teacher}).first
    comment = sub1.submission_comments.first

    @user = student1
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                    { :controller => "submissions_api", :action => "show",
                      :format => "json", :course_id => @course.id.to_s,
                      :assignment_id => a1.id.to_s, :user_id => student1.id.to_s },
                    { :include => %w(submission_comments) })

    expect(json).to eq({
        "id"=>sub1.id,
        "grade"=>"A-",
        "excused" => sub1.excused,
        "grader_id"=>@teacher.id,
        "graded_at"=>sub1.graded_at.as_json,
        "body"=>"test!",
        "assignment_id" => a1.id,
        "submitted_at"=>"1970-01-01T01:00:00Z",
        "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=2",
        "grade_matches_current_submission"=>true,
        "attempt"=>1,
        "url"=>nil,
        "submission_type"=>"online_text_entry",
        "user_id"=>student1.id,
        "submission_comments"=>
         [{"comment"=>"Well here's the thing...",
           "media_comment" => {
             "media_id"=>"3232",
             "media_type"=>"audio",
             "content-type" => "audio/mp4",
             "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=3232&redirect=1&type=mp4",
             "display_name" => nil
           },
           "created_at"=>comment.created_at.as_json,
           "author"=>{
              "id" => @teacher.id,
              "display_name" => "User",
              "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
              "avatar_image_url" => User.avatar_fallback_url(nil, request)
           },
           "author_name"=>"User",
           "id" => comment.id,
           "author_id"=>@teacher.id}],
        "score"=>13.5,
        "workflow_state"=>"graded",
        "late"=>false})

    # can't access other students' submissions
    @user = student2
    raw_api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                    { :controller => "submissions_api", :action => "show",
                      :format => "json", :course_id => @course.id.to_s,
                      :assignment_id => a1.id.to_s, :user_id => student1.id.to_s },
                    { :include => %w(submission_comments) })
    assert_status(401)
  end

  it "returns grading information for observers" do
    @student = user_factory(active_all: true)
    e = course_with_observer(:active_all => true)
    e.associated_user_id = @student.id
    e.save!
    @course.enroll_student(@student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :points_possible => 15)
    submit_homework(a1, @student)
    a1.grade_student(@student, grade: 15, grader: @teacher)
    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{@student.id}.json",
                  { :controller => "submissions_api", :action => "show",
                    :format => "json", :course_id => @course.id.to_s,
                    :assignment_id => a1.id.to_s, :user_id => @student.id.to_s })
    expect(json["score"]).to eq 15
  end

  it "should api translate online_text_entry submissions" do
    student1 = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    should_translate_user_content(@course) do |content|
      submit_homework(a1, student1, :body => content)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                    { :controller => "submissions_api", :action => "show",
                      :format => "json", :course_id => @course.id.to_s,
                      :assignment_id => a1.id.to_s, :user_id => student1.id.to_s })
      json["body"]
    end
  end

  it "allows retrieving attachments without a session" do
    student1 = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    submit_homework(a1, student1) { |s| s.attachments = [attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => student1)] }
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })
    url = json[0]['attachments'][0]['url']
    get_via_redirect(url)
    expect(response).to be_success
    expect(response[content_type_key]).to eq 'image/png'
  end

  it "allows retrieving media comments without a session" do
    student1 = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    media_object(:media_id => "54321", :context => student1, :user => student1)
    mock_kaltura = mock('CanvasKaltura::ClientV3')
    CanvasKaltura::ClientV3.stubs(:new).returns(mock_kaltura)
    mock_kaltura.expects(:media_sources).returns([{:height => "240", :bitrate => "382", :isOriginal => "0", :width => "336", :content_type => "video/mp4",
                                                   :containerFormat => "isom", :url => "https://kaltura.example.com/some/url", :size =>"204", :fileExt=>"mp4"}])

    submit_homework(a1, student1, :media_comment_id => "54321", :media_comment_type => "video")
    stub_kaltura
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })
    url = json[0]['media_comment']['url']
    get(url)
    expect(response).to be_redirect
    expect(response['Location']).to match(%r{https://kaltura.example.com/some/url})
  end

  it "returns all submissions for an assignment" do
    student1 = user_factory(active_all: true)
    student2 = user_factory(active_all: true)

    course_with_teacher(:active_all => true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!

    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    rubric = rubric_model(:user => @user, :context => @course,
                          :data => larger_rubric_data)
    a1.create_rubric_association(:rubric => rubric, :purpose => 'grading', :use_for_grading => true, :context => @course)

    submit_homework(a1, student1)
    media_object(:media_id => "54321", :context => student1, :user => student1)
    submit_homework(a1, student1, :media_comment_id => "54321", :media_comment_type => "video")
    sub1 = submit_homework(a1, student1) { |s| s.attachments = [attachment_model(:context => student1, :folder => nil)] }

    sub2a1 = attachment_model(:context => student2, :filename => 'snapshot.png', :content_type => 'image/png')
    sub2 = submit_homework(a1, student2, :url => "http://www.instructure.com") { |s|
      s.attachment = sub2a1
    }

    media_object(:media_id => "3232", :context => student1, :user => student1, :media_type => "audio")
    a1.grade_student(student1, {:grade => '90%', :grader => @teacher})
    a1.update_submission(student1, {:comment => "Well here's the thing...", :media_comment_id => "3232", :media_comment_type => "audio", :commenter => @teacher})
    sub1.reload
    expect(sub1.submission_comments.size).to eq 1
    comment = sub1.submission_comments.first
    a1.rubric_association.assess(
          :assessor => @user, :user => student2, :artifact => sub2,
          :assessment => {:assessment_type => 'grading', :criterion_crit1 => { :points => 7 }, :criterion_crit2 => { :points => 2, :comments => 'Hmm'}})

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })

    sub1.reload
    sub2.reload

    res =
      [{"id"=>sub1.id,
        "grade"=>"A-",
        "excused" => sub1.excused,
        "grader_id"=>@teacher.id,
        "graded_at"=>sub1.graded_at.as_json,
        "body"=>"test!",
        "assignment_id" => a1.id,
        "submitted_at"=>"1970-01-01T03:00:00Z",
        "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=4",
        "grade_matches_current_submission"=>true,
        "attachments" =>
         [
           { "content-type" => "application/loser",
             "url" => "http://www.example.com/files/#{sub1.attachments.first.id}/download?download_frd=1&verifier=#{sub1.attachments.first.uuid}",
             "filename" => "unknown.loser",
             "display_name" => "unknown.loser",
             "id" => sub1.attachments.first.id,
             "folder_id" => sub1.attachments.first.folder_id,
             "size" => sub1.attachments.first.size,
             'unlock_at' => nil,
             'locked' => false,
             'hidden' => false,
             'lock_at' => nil,
             'locked_for_user' => false,
             'hidden_for_user' => false,
             'created_at' => sub1.attachments.first.reload.created_at.as_json,
             'updated_at' => sub1.attachments.first.updated_at.as_json,
             'preview_url' => nil,
             'modified_at' => sub1.attachments.first.modified_at.as_json,
             'mime_class' => sub1.attachments.first.mime_class,
             'media_entry_id' => sub1.attachments.first.media_entry_id,
             'thumbnail_url' => sub1.attachments.first.thumbnail_url },
         ],
        "submission_history"=>
         [{"id"=>sub1.id,
           "grade"=>nil,
           "excused" => nil,
           "grader_id"=>nil,
           "graded_at"=>nil,
           "body"=>"test!",
           "assignment_id" => a1.id,
           "submitted_at"=>"1970-01-01T01:00:00Z",
           "attempt"=>1,
           "url"=>nil,
           "submission_type"=>"online_text_entry",
           "user_id"=>student1.id,
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=2",
           "grade_matches_current_submission"=>nil,
           "score"=>nil,
           "workflow_state" => "submitted",
           "late"=>false},
          {"id"=>sub1.id,
           "grade"=>nil,
           "excused" => nil,
           "grader_id"=>nil,
           "graded_at"=>nil,
           "assignment_id" => a1.id,
           "media_comment" =>
            { "media_type"=>"video",
              "media_id"=>"54321",
              "content-type" => "video/mp4",
              "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=54321&redirect=1&type=mp4",
              "display_name" => nil },
           "body"=>"test!",
           "submitted_at"=>"1970-01-01T02:00:00Z",
           "attempt"=>2,
           "url"=>nil,
           "submission_type"=>"online_text_entry",
           "user_id"=>student1.id,
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=3",
           "grade_matches_current_submission"=>nil,
           "score"=>nil,
           "workflow_state" => "submitted",
           "late"=>false},
          {"id"=>sub1.id,
           "grade"=>"A-",
           "excused" => false,
           "grader_id"=>@teacher.id,
           "graded_at"=>sub1.graded_at.as_json,
           "assignment_id" => a1.id,
           "media_comment" =>
            { "media_type"=>"video",
              "media_id"=>"54321","content-type" => "video/mp4",
              "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=54321&redirect=1&type=mp4",
              "display_name" => nil },
           "attachments" =>
            [
              { "content-type" => "application/loser",
                "url" => "http://www.example.com/files/#{sub1.attachments.first.id}/download?download_frd=1&verifier=#{sub1.attachments.first.uuid}",
                "filename" => "unknown.loser",
                "display_name" => "unknown.loser",
                "id" => sub1.attachments.first.id,
                "folder_id" => sub1.attachments.first.folder_id,
                "size" => sub1.attachments.first.size,
                'unlock_at' => nil,
                'locked' => false,
                'hidden' => false,
                'lock_at' => nil,
                'locked_for_user' => false,
                'hidden_for_user' => false,
                'created_at' => sub1.attachments.first.created_at.as_json,
                'updated_at' => sub1.attachments.first.updated_at.as_json,
                'preview_url' => nil,
                'modified_at' => sub1.attachments.first.modified_at.as_json,
                'mime_class' => sub1.attachments.first.mime_class,
                'media_entry_id' => sub1.attachments.first.media_entry_id,
                'thumbnail_url' => sub1.attachments.first.thumbnail_url },
            ],
           "body"=>"test!",
           "submitted_at"=>"1970-01-01T03:00:00Z",
           "attempt"=>3,
           "url"=>nil,
           "submission_type"=>"online_text_entry",
           "user_id"=>student1.id,
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=4",
           "grade_matches_current_submission"=>true,
           "score"=>13.5,
           "workflow_state" => "graded",
           "late"=>false}],
        "attempt"=>3,
        "url"=>nil,
        "submission_type"=>"online_text_entry",
        "user_id"=>student1.id,
        "submission_comments"=>
         [{"comment"=>"Well here's the thing...",
           "media_comment" => {
             "media_type"=>"audio",
             "media_id"=>"3232",
             "content-type" => "audio/mp4",
             "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=3232&redirect=1&type=mp4",
             "display_name" => nil
           },
           "created_at"=>comment.reload.created_at.as_json,
           "author"=>{
             "id" => @teacher.id,
             "display_name" => "User",
             "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@teacher.id}",
             "avatar_image_url" => User.avatar_fallback_url(nil, request)
           },
           "author_name"=>"User",
           "id"=>comment.id,
           "author_id"=>@teacher.id}],
        "media_comment" =>
         { "media_type"=>"video",
           "media_id"=>"54321",
           "content-type" => "video/mp4",
           "url" => "http://www.example.com/users/#{@user.id}/media_download?entryId=54321&redirect=1&type=mp4",
           "display_name" => nil },
        "score"=>13.5,
        "workflow_state"=>"graded",
        "late"=>false},
       {"id"=>sub2.id,
        "grade"=>"F",
        "excused" => sub2.excused,
        "grader_id"=>@teacher.id,
        "graded_at"=>sub2.graded_at.as_json,
        "assignment_id" => a1.id,
        "body"=>nil,
        "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student2.id}?preview=1&version=2",
        "grade_matches_current_submission"=>true,
        "submitted_at"=>"1970-01-01T04:00:00Z",
        "submission_history"=>
         [{"id"=>sub2.id,
           "grade"=>"F",
           "excused" => nil,
           "grader_id"=>@teacher.id,
           "graded_at"=>sub2.graded_at.as_json,
           "assignment_id" => a1.id,
           "body"=>nil,
           "submitted_at"=>"1970-01-01T04:00:00Z",
           "attempt"=>1,
           "url"=>"http://www.instructure.com",
           "submission_type"=>"online_url",
           "user_id"=>student2.id,
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student2.id}?preview=1&version=2",
           "grade_matches_current_submission"=>true,
           "attachments" =>
            [
              {"content-type" => "image/png",
               "display_name" => "snapshot.png",
               "filename" => "snapshot.png",
               "url" => "http://www.example.com/files/#{sub2a1.id}/download?download_frd=1&verifier=#{sub2a1.uuid}",
               "id" => sub2a1.id,
               "folder_id" => sub2a1.folder_id,
               "size" => sub2a1.size,
               'unlock_at' => nil,
               'locked' => false,
               'hidden' => false,
               'lock_at' => nil,
               'locked_for_user' => false,
               'hidden_for_user' => false,
               'created_at' => sub2a1.created_at.as_json,
               'updated_at' => sub2a1.updated_at.as_json,
               'preview_url' => nil,
               'thumbnail_url' => sub2a1.thumbnail_url,
               'modified_at' => sub2a1.modified_at.as_json,
               'mime_class' => sub2a1.mime_class,
               'media_entry_id' => sub2a1.media_entry_id
              },
            ],
           "score"=>9,
           "workflow_state" => "graded",
           "late"=>false}],
        "attempt"=>1,
        "url"=>"http://www.instructure.com",
        "submission_type"=>"online_url",
        "user_id"=>student2.id,
        "attachments" =>
         [{"content-type" => "image/png",
           "display_name" => "snapshot.png",
           "filename" => "snapshot.png",
           "url" => "http://www.example.com/files/#{sub2a1.id}/download?download_frd=1&verifier=#{sub2a1.uuid}",
           "id" => sub2a1.id,
           "folder_id" => sub2a1.folder_id,
           "size" => sub2a1.size,
           'unlock_at' => nil,
           'locked' => false,
           'hidden' => false,
           'lock_at' => nil,
           'locked_for_user' => false,
           'hidden_for_user' => false,
           'created_at' => sub2a1.created_at.as_json,
           'updated_at' => sub2a1.updated_at.as_json,
           'preview_url' => nil,
           'thumbnail_url' => sub2a1.thumbnail_url,
           'modified_at' => sub2a1.modified_at.as_json,
           'mime_class' => sub2a1.mime_class,
           'media_entry_id' => sub2a1.media_entry_id
          },
         ],
        "submission_comments"=>[],
        "score"=>9,
        "rubric_assessment"=>
         {"crit2"=>{"comments"=>"Hmm", "points"=>2},
          "crit1"=>{"comments"=>nil, "points"=>7}},
        "workflow_state"=>"graded",
        "late"=>false}]
    expect(json.sort_by { |h| h['user_id'] }).to eq res.sort_by { |h| h['user_id'] }
  end

  it "paginates submissions" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!({
      :title => 'assignment1',
      :grading_type => 'points',
      :points_possible => 12
    })
    api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json", {
      :controller => 'submissions_api', :action => 'index',
      :format => 'json', :course_id => @course.to_param,
      :assignment_id => @assignment.id
    })
    expect(response.header.has_key?("Link")).to be_truthy
  end

  it "returns nothing if no assignments in the course" do
    student1 = user_factory(active_all: true)
    student2 = user_with_pseudonym(:active_all => true)
    student2.pseudonym.update_attribute(:sis_user_id, 'my-student-id')

    course_with_teacher(:active_all => true)

    enrollment1 = @course.enroll_student(student1)
    enrollment1.accept!
    enrollment2 = @course.enroll_student(student2)
    enrollment2.accept!

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param], :grouped => 1 })
    expect(json.sort_by { |h| h['user_id'] }).to eq [
      {
        'user_id' => student1.id,
        "section_id" => enrollment1.course_section_id,
        'submissions' => [],
      },
      {
        'user_id' => student2.id,
        "section_id" => enrollment2.course_section_id,
        'integration_id' => nil,
        'sis_user_id' => 'my-student-id',
        'submissions' => [],
      },
    ]

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param] })
    expect(json).to eq []
  end

  it "returns sis_user_id for user when grouped" do
    student = user_with_pseudonym(:active_all => true)
    batch = SisBatch.create(account_id: Account.default.id, workflow_state: 'imported')
    student.pseudonym.update_attribute(:sis_user_id, 'my-student-id')
    student.pseudonym.update_attribute(:sis_batch_id, batch.id)

    course_with_teacher(:active_all => true)
    @course.update_attribute(:sis_batch_id, batch.id)

    @course.enroll_student(student).accept!

    account_admin_user
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => 'all', :grouped => 'true' })
    expect(json.first['sis_user_id']).to eq 'my-student-id'
  end

  it "returns integration_id for the user when grouped" do
    student = user_with_pseudonym(:active_all => true)
    batch = SisBatch.create(account_id: Account.default.id, workflow_state: 'imported')
    student.pseudonym.update_attribute(:integration_id, 'xyz')
    student.pseudonym.update_attribute(:sis_user_id, 'my-student-id')
    student.pseudonym.update_attribute(:sis_batch_id, batch.id)

    course_with_teacher(:active_all => true)
    @course.update_attribute(:sis_batch_id, batch.id)
    @course.enroll_student(student).accept!

    account_admin_user
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => 'all', :grouped => 'true' })
    expect(json.first['integration_id']).to eq 'xyz'
  end

  it "returns vericite data if present and vericite is enabled for the assignment" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15, vericite_enabled: true)
    a1.turnitin_settings = {:originality_report_visibility => 'after_grading'}
    a1.save!
    submission = submit_homework(a1, student)
    sample_vericite_data = {
      :last_processed_attempt=>1,
      "attachment_504177"=> {
        :web_overlap=>73,
        :publication_overlap=>0,
        :error=>true,
        :student_overlap=>100,
        :state=>"failure",
        :similarity_score=>100,
        :object_id=>"123345"
      },
      provider: 'vericite'
    }
    submission.turnitin_data = sample_vericite_data
    submission.save!

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s })
    expect(json).to have_key 'vericite_data'
    sample_vericite_data.delete :last_processed_attempt
    expect(json['vericite_data']).to eq sample_vericite_data.with_indifferent_access
  end

  it "returns turnitin data if present and turnitin is enabled for the assignment" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15, turnitin_enabled: true)
    a1.turnitin_settings = {:originality_report_visibility => 'after_grading'}
    a1.save!
    submission = submit_homework(a1, student)
    sample_turnitin_data = {
      :last_processed_attempt=>1,
      "attachment_504177"=> {
        :web_overlap=>73,
        :publication_overlap=>0,
        :error=>true,
        :student_overlap=>100,
        :state=>"failure",
        :similarity_score=>100,
        :object_id=>"123345"
      }
    }
    submission.turnitin_data = sample_turnitin_data
    submission.save!

    # as teacher
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s })
    expect(json).to have_key 'turnitin_data'
    sample_turnitin_data.delete :last_processed_attempt
    expect(json['turnitin_data']).to eq sample_turnitin_data.with_indifferent_access

    # as student before graded
    @user = student
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s })
    expect(json).not_to have_key 'turnitin_data'

    # as student after grading
    a1.grade_student(student, grade: 11, grader: @teacher)
    @user = student
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s })
    expect(json).to have_key 'turnitin_data'
    expect(json['turnitin_data']).to eq sample_turnitin_data.with_indifferent_access

  end

  describe "#for_students" do
    before(:once) do
      @student1 = user_factory(active_all: true)
      @student2 = user_with_pseudonym(:active_all => true)
      @student2.pseudonym.update_attribute(:sis_user_id, 'my-student-id')

      course_with_teacher(:active_all => true)

      @course.enroll_student(@student1).accept!
      @course.enroll_student(@student2).accept!

      @a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
      @a2 = @course.assignments.create!(:title => 'assignment2', :grading_type => 'letter_grade', :points_possible => 25)

      submit_homework(@a1, @student1)
      submit_homework(@a2, @student1)
      submit_homework(@a1, @student2)
    end

    it "returns all submissions for a student", priority: "1", test_id: 2989898 do
      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.to_param] })

      expect(json.size).to eq 2
      json.each { |submission| expect(submission['user_id']).to eq @student1.id }

      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.to_param, @student2.to_param] })

      expect(json.size).to eq 3

      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.to_param, @student2.to_param],
              :assignment_ids => [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission['assignment_id']).to eq @a1.id }).to be_truthy

      # by sis user id!
      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.to_param, 'sis_user_id:my-student-id'],
              :assignment_ids => [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission['assignment_id']).to eq @a1.id }).to be_truthy

      # by sis login id!
      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.to_param, "sis_login_id:#{@student2.pseudonym.unique_id}"],
              :assignment_ids => [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission['assignment_id']).to eq @a1.id }).to be_truthy

      # concluded enrollments!
      @student2.enrollments.first.conclude
      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.to_param, "sis_login_id:#{@student2.pseudonym.unique_id}"],
              :assignment_ids => [@a1.to_param] })

      expect(json.size).to eq 2
      expect(json.all? { |submission| expect(submission['assignment_id']).to eq @a1.id }).to be_truthy
    end

    it "can return assignments based on graded_at time", priority: "1", test_id: 2989899 do
      @a2.grade_student @student1, grade: 10, grader: @teacher
      @a1.grade_student @student1, grade: 5, grader: @teacher
      @a3 = @course.assignments.create! title: "a3"
      @a3.submit_homework @student1, body: "hello"
      Submission.where(assignment_id: @a2).update_all(graded_at: 1.hour.from_now)
      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json",
            { controller: 'submissions_api', action: 'for_students',
              format: 'json', course_id: @course.to_param },
            { student_ids: [@student1.to_param],
              order: "graded_at", order_direction: "descending" })
      expect(json.map { |a| a["assignment_id"] }).to eq [@a2.id, @a1.id, @a3.id]
    end

    context 'OriginalityReport' do
      it 'includes has_originality_report if the submission has an originality_report' do
        attachment_model
        course_factory active_all: true
        student_in_course active_all: true
        teacher_in_course active_all: true
        @assignment = @course.assignments.create!(title: "some assignment",
                                                assignment_group: @group,
                                                points_possible: 12,
                                                tool_settings_tool: @tool)
        @attachment.context = @student
        @attachment.save!
        submission = @assignment.submit_homework(@student, attachments: [@attachment])
        OriginalityReport.create!(attachment: @attachment,
                                  submission: submission,
                                  workflow_state: 'pending',
                                  originality_score: 0.1)

        user_session(@teacher)
        json = api_call(:get,
                "/api/v1/courses/#{@course.id}/students/submissions.json",
                { :controller => 'submissions_api', :action => 'for_students',
                  :format => 'json', :course_id => @course.to_param },
                { :student_ids => [@student.to_param] })
        expect(json.first).to have_key 'has_originality_report'
      end

      it 'does not include has_originality_report if the submission has no originality_report' do
        attachment_model
        course_factory active_all: true
        student_in_course active_all: true
        teacher_in_course active_all: true
        @assignment = @course.assignments.create!(title: "some assignment",
                                                assignment_group: @group,
                                                points_possible: 12,
                                                tool_settings_tool: @tool)
        @attachment.context = @student
        @attachment.save!
        @assignment.submit_homework(@student, attachments: [@attachment])

        user_session(@teacher)
        json = api_call(:get,
                "/api/v1/courses/#{@course.id}/students/submissions.json",
                { :controller => 'submissions_api', :action => 'for_students',
                  :format => 'json', :course_id => @course.to_param },
                { :student_ids => [@student.to_param] })
        expect(json.first).not_to have_key 'has_originality_report'
      end
    end
  end

  context "moderated assignments" do
    before do
      student_in_course(active_all: true)
      course_with_teacher_logged_in(course: @course)
      @assignment = @course.assignments.create!(
        title: 'an assignment',
        grading_type: 'letter_grade',
        points_possible: 10
      )
      @assignment.update_attribute(:moderated_grading, true)
      submission = @assignment.submit_homework(@student, body: 'nice work')
      @provisional_grade = submission.provisional_grades.build do |grade|
        grade.scorer = @teacher
      end
      @provisional_grade.save!
    end

    context "when teacher has moderate_grades rights" do
      it "displays grades" do
        json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
          {
            controller: 'submissions_api',
            action: 'index',
            format: 'json',
            course_id: @course.id,
            assignment_id: @assignment.id
          },
          {
            include: ['provisional_grades']
          }
        )

        expect(json.first['provisional_grades']).to_not be_empty
        speedgrader_url = URI.parse(json.first['provisional_grades'].first['speedgrader_url'])
        expect(speedgrader_url.path).to eq "/courses/#{@course.id}/gradebook/speed_grader"
        expect(speedgrader_url.query).to eq "assignment_id=#{@assignment.id}"
        expect(JSON.parse(URI.decode(speedgrader_url.fragment))).to eq(
          {
            "student_id" => @student.id,
            "provisional_grade_id" => @provisional_grade.id
          }
        )
      end

      it "can include users" do
        json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
          {
            controller: 'submissions_api',
            action: 'index',
            format: 'json',
            course_id: @course.id,
            assignment_id: @assignment.id,
          },
          {
            include: ['user_summary']
          }
        )

        user = json.first['user']
        expect(user['display_name']).to eql @student.name
        expect(user['avatar_image_url']).to eql "http://www.example.com/images/messages/avatar-50.png"
        expect(user['html_url']).to eql polymorphic_url([@course, @student])
      end
    end

    context "when a TA does not have moderate_grades rights" do
      before do
        course_with_ta(course: @course)
        user_session(@ta)
      end
      it "only shows caller's provisional grade" do
        json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
          {
            controller: 'submissions_api',
            action: 'index',
            format: 'json',
            course_id: @course.id,
            assignment_id: @assignment.id
          },
          {
            include: ['provisional_grades']
          }
        )

        expect(json.first['provisional_grades']).to be_empty
      end
    end
  end

  context "for_students (differentiated_assignments)" do
    before do
      # set up course with DA and submit homework for an assignment
      # that is only visible to overrides for @section1
      @student = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @section1 = @course.course_sections.create!(name: "test section")
      @section2 = @course.course_sections.create!(name: "test section")
      student_in_section(@section1, user: @student)
      @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15, :only_visible_to_overrides => true)
      create_section_override_for_assignment(@assignment, course_section: @section1)
      submit_homework(@assignment, @student)

      user_session(@student)
    end

    def call_to_for_students(opts={})
      helper_method = if opts[:as_student]
                        [:api_call_as_user, @student]
                      elsif opts[:as_observer]
                        [:api_call_as_user, @observer]
                      else
                        [:api_call]
                      end
      args = helper_method + [:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => [@student.to_param] }]
      self.send(*args)
    end

    context "as student" do
      context "differentiated_assignments" do
        it "returns the submissons if the student is in the overriden section" do
          json = call_to_for_students(as_student: true)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission['user_id']).to eq @student.id }
        end

        it "does not return the submissons if the student is not in the overriden section and has a submission with no grade" do
          Score.where(enrollment_id: @student.enrollments).delete_all
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: nil, grader: @teacher)

          json = call_to_for_students(as_student: true)

          expect(json.size).to eq 0
        end

        it "returns the submissons if the student is not in the overriden section but has a graded submission" do
          Score.where(enrollment_id: @student.enrollments).delete_all
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: 5, grader: @teacher)

          json = call_to_for_students(as_student: true)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission['user_id']).to eq @student.id }
        end
      end
    end

    context "as an observer" do
      before {
        @observer = User.create
        observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
        observer_enrollment.update_attribute(:associated_user_id, @student.id)
      }
      context "differentiated_assignments on" do
        it "returns the submissons if the observed student is in the overriden section" do
          json = call_to_for_students(as_observer: true)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission['user_id']).to eq @student.id }
        end

        it "does not return the submissons if the observed student is not in the overriden section and has a submission with no grade" do
          Score.where(enrollment_id: @student.enrollments).delete_all
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: nil, grader: @teacher)

          json = call_to_for_students(as_observer: true)

          expect(json.size).to eq 0
        end

        it "returns the submissons if the observed student is not in the overriden section but has a graded submission" do
          Score.where(enrollment_id: @student.enrollments).delete_all
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)
          @assignment.grade_student(@student, grade: 5, grader: @teacher)

          json = call_to_for_students(as_observer: true)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission['user_id']).to eq @student.id }
        end
      end
    end

    context "as teacher" do
      context "differentiated_assignments on" do
        it "returns the submissons if the student is in the overriden section" do
          json = call_to_for_students(as_student: false)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission['user_id']).to eq @student.id }
        end

        it "returns the submissons even if the student is not in the overriden section" do
          Score.where(enrollment_id: @student.enrollments).delete_all
          @student.enrollments.each(&:destroy_permanently!)
          student_in_section(@section2, user: @student)

          json = call_to_for_students(as_student: false)

          expect(json.size).to eq 1
          json.each { |submission| expect(submission['user_id']).to eq @student.id }
        end
      end
    end
  end

  context "show (differentiated_assignments)" do
    before do
      # set up course with DA and submit homework for an assignment
      # that is only visible to overrides for @section1
      # move student to a section that cannot see assignment by default
      @student = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @section1 = @course.course_sections.create!(name: "test section")
      @section2 = @course.course_sections.create!(name: "test section")
      student_in_section(@section1, user: @student)
      @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15, :only_visible_to_overrides => true)
      create_section_override_for_assignment(@assignment, course_section: @section1)
      submit_homework(@assignment, @student)
      Score.where(enrollment_id: @student.enrollments).delete_all
      @student.enrollments.each(&:destroy_permanently!)
      student_in_section(@section2, user: @student)

      user_session(@student)
    end

    def call_to_submissions_show(opts={})
      includes = %w(submission_comments rubric_assessment)
      includes.concat(opts[:includes]) if opts[:includes]
      helper_method = opts[:as_student] ? [:api_call_as_user, @student] : [:api_call]
      args = helper_method + [:get,
            "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s },
            { :include => includes }]
      self.send(*args)
    end

    context "as teacher" do
      context "with differentiated_assignments" do
        it "returns the assignment" do
          json = call_to_submissions_show(as_student: false)

          expect(json["assignment_id"]).not_to be_nil
        end

        it "returns assignment_visible" do
          json = call_to_submissions_show(as_student: false, includes: ["visibility"])
          expect(json["assignment_visible"]).not_to be_nil
        end
      end
    end

    context "as student in a section without an override" do
      context "with differentiated_assignments" do
        it "returns an unauthorized error" do
          api_call_as_user(@student, :get,
              "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
              { :controller => 'submissions_api', :action => 'show',
                :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s },
              { :include => %w(submission_comments rubric_assessment)}, {}, expected_status: 401)
        end

        it "returns the submission if it is graded" do
          @assignment.grade_student(@student, grade: 5, grader: @teacher)
          json = call_to_submissions_show(as_student: true)

          expect(json["assignment_id"]).not_to be_nil
        end

        it "returns assignment_visible false" do
          json = call_to_submissions_show(as_student: false, includes: ["visibility"])
          expect(json["assignment_visible"]).to eq(false)
        end
      end
    end
  end

  it "returns student submissions grouped by student" do
    student1 = user_factory(active_all: true)
    student2 = user_with_pseudonym(:active_all => true)

    course_with_teacher(:active_all => true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!

    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    a2 = @course.assignments.create!(:title => 'assignment2', :grading_type => 'letter_grade', :points_possible => 25)

    submit_homework(a1, student1)
    submit_homework(a2, student1)
    submit_homework(a1, student2)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param], :grouped => '1' })

    expect(json.size).to eq 1
    expect(json.first['submissions'].size).to eq 2
    json.each { |user| expect(user['user_id']).to eq student1.id }

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param], :grouped => '1' })

    expect(json.size).to eq 2
    expect(json.map { |u| u['submissions'] }.flatten.size).to eq 3

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param],
            :assignment_ids => [a1.to_param], :grouped => '1' })

    expect(json.size).to eq 2
    json.each { |user| user['submissions'].each { |s| expect(s['assignment_id']).to eq a1.id } }
  end

  it "returns students with no submissions when grouped" do
    student1 = user_factory(active_all: true)
    student2 = user_with_pseudonym(:active_all => true)
    student2.pseudonym.update_attribute(:sis_user_id, 'my-student-id')

    course_with_teacher(:active_all => true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!

    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    a2 = @course.assignments.create!(:title => 'assignment2', :grading_type => 'letter_grade', :points_possible => 25)

    submit_homework(a1, student1)
    submit_homework(a2, student1)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param], :grouped => '1' })

    expect(json.size).to eq 2
    expect(json.detect { |u| u['user_id'] == student1.id }['submissions'].size).to eq 2
    expect(json.detect { |u| u['user_id'] == student2.id }['submissions'].size).to eq 0
  end

  context "with grading periods" do
    before :once do
      @student1 = user_factory(active_all: true)
      @student2 = user_with_pseudonym(:active_all => true)

      course_with_teacher(:active_all => true)

      @course.enroll_student(@student1).accept!
      @course.enroll_student(@student2).accept!

      gpg = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
      @gp1 = gpg.grading_periods.create!(
        title: 'first',
        weight: 50,
        start_date: 2.days.ago,
        end_date: 1.day.from_now
      )
      @gp2 = gpg.grading_periods.create!(
        title: 'second',
        weight: 50,
        start_date: 2.days.from_now,
        end_date: 1.month.from_now
      )
      a1 = @course.assignments.create!(due_at: 1.minute.from_now, :submission_types => 'online_text_entry')
      a2 = @course.assignments.create!(due_at: 1.week.from_now, :submission_types => 'online_text_entry')

      submit_homework(a1, @student1)
      submit_homework(a2, @student1) # only one in current grading period
      submit_homework(a1, @student2)
    end

    it "filters by grading period" do
      json = api_call(:get,
        "/api/v1/courses/#{@course.id}/students/submissions.json",
        { :controller => 'submissions_api', :action => 'for_students',
          :format => 'json', :course_id => @course.to_param },
        { :student_ids => [@student1.to_param, @student2.to_param], :grouped => '1',
          :grading_period_id => @gp2.to_param})
      expect(json.detect { |u| u['user_id'] == @student1.id }['submissions'].size).to eq 1
      expect(json.detect { |u| u['user_id'] == @student2.id }['submissions'].size).to eq 0
    end

    it "does not return an error when no grading_period_id is provided" do
      api_call(:get,
        "/api/v1/courses/#{@course.id}/students/submissions.json",
        { :controller => 'submissions_api', :action => 'for_students',
          :format => 'json', :course_id => @course.to_param },
        { :student_ids => [@student1.to_param, @student2.to_param], :grouped => '1' })
      expect(response).to be_ok
    end
  end

  describe "for_students non-admin" do
    before :once do
      course_with_student :active_all => true
      @student1 = @student
      @student2 = student_in_course(:active_all => true).user
      @student3 = student_in_course(:active_all => true).user
      @assignment1 = @course.assignments.create! :title => 'assignment1', :grading_type => 'points', :points_possible => 15
      @assignment2 = @course.assignments.create! :title => 'assignment2', :grading_type => 'points', :points_possible => 25
      bare_submission_model @assignment1, @student1, grade: 15, grader: @teacher, score: 15
      bare_submission_model @assignment2, @student1, grade: 25, grader: @teacher, score: 25
      bare_submission_model @assignment1, @student2, grade: 10, grader: @teacher, score: 10
      bare_submission_model @assignment2, @student2, grade: 20, grader: @teacher, score: 20
      bare_submission_model @assignment1, @student3, grade: 20, grader: @teacher, score: 20
    end

    context "teacher" do
      it "shows all submissions" do
        @user = @teacher
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => ['all'] })
        expect(json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }).to eq [
            { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 },
            { 'user_id' => @student3.id, 'assignment_id' => @assignment1.id, 'score' => 20 },
        ]
      end
    end

    context "students" do
      it "allows a student to view his own submissions" do
        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => [@student1.to_param] })
        sub_json = json.map{ |entry| entry.slice('user_id', 'assignment_id', 'score') }
          .sort_by { |entry| entry['assignment_id'] }
        expect(sub_json).to eq [
          { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
          { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 }
        ]
      end

      it "assumes the calling user if student_ids is not provided" do
        @user = @student2
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param } )
        sub_json = json.map{ |entry| entry.slice('user_id', 'assignment_id', 'score') }
          .sort_by { |entry| entry['assignment_id'] }
        expect(sub_json).to eq [
          { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
          { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 }
        ]
      end

      it "shows all possible if student_ids is ['all']" do
        @user = @student2
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => ['all'] })
        sub_json = json.map{ |entry| entry.slice('user_id', 'assignment_id', 'score') }
          .sort_by { |entry| entry['assignment_id'] }
        expect(sub_json).to eq [
          { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
          { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 }
        ]
      end

      it "supports the 'grouped' argument" do
        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json?grouped=1",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param, :grouped => '1' })
        expect(json.size).to eq 1
        expect(json[0]['user_id']).to eq @student1.id
        expect(json[0]['submissions'].map { |sub| sub.slice('assignment_id', 'score') }.sort_by { |entry| entry['assignment_id'] }).to eq [
            { 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'assignment_id' => @assignment2.id, 'score' => 25 } ]
      end

      it "does not allow a student to view another student's submissions" do
        @user = @student1
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions.json?student_ids[]=#{@student1.id}&student_ids[]=#{@student2.id}",
                 { :controller => 'submissions_api', :action => 'for_students',
                   :format => 'json', :course_id => @course.to_param,
                   :student_ids => [@student1.to_param, @student2.to_param] },
                 {}, {}, :expected_status => 401)
      end

      it "errors if too many students requested" do
        Api.stubs(:max_per_page).returns(0)
        @user = @student1
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions.json",
                 { :controller => 'submissions_api', :action => 'for_students',
                   :format => 'json', :course_id => @course.to_param },
                 { :student_ids => [@student1.to_param] }, {}, expected_status: 400)
      end

      it "allows concluded students to view their submission" do
        enrollment = @course.student_enrollments.where(user_id: @student1).first
        enrollment.conclude

        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => [@student1.to_param] })
        sub_json = json.map{ |entry| entry.slice('user_id', 'assignment_id', 'score') }
          .sort_by { |entry| entry['assignment_id'] }
        expect(sub_json).to eq [
          { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
          { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 }
        ]
      end
    end

    context "observers" do
      before :once do
        @observer = user_factory :active_all => true
        @course.enroll_user(@observer, 'ObserverEnrollment', :associated_user_id => @student1.id)
        @course.enroll_user(@observer, 'ObserverEnrollment', :allow_multiple_enrollments => true, :associated_user_id => @student2.id)
      end

      it "allows an observer to view observed students' submissions" do
        @user = @observer
        json = api_call(:get,
           "/api/v1/courses/#{@course.id}/students/submissions",
           { :controller => 'submissions_api', :action => 'for_students',
             :format => 'json', :course_id => @course.to_param },
           { :student_ids => [@student1.id, @student2.id] })
        expect(json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }).to eq [
            { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 }
        ]
      end

      it "allows an observer to view all observed students' submissions via student_ids[]=all" do
        @user = @observer
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => ['all'] })
        expect(json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }).to eq [
            { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 }
        ]
      end

      context "observer that is a student" do
        before :once do
          @course.enroll_student(@observer, :allow_multiple_enrollments => true).accept!
          submit_homework(@assignment1, @observer)
          @assignment1.grade_student(@observer, grade: 5, grader: @teacher)
        end

        it "allows an observer that is a student to view his own and his observees submissions" do
          @user = @observer
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/students/submissions",
                          { :controller => 'submissions_api', :action => 'for_students',
                            :format => 'json', :course_id => @course.to_param },
                          { :student_ids => [@student1.id, @observer.id] })
          expect(json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }).to eq [
              { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
              { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
              { 'user_id' => @observer.id, 'assignment_id' => @assignment1.id, 'score' => 5 }
          ]
        end

        it "allows an observer that is a student to view his own and his observees submissions via student_ids[]=all" do
          @user = @observer
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/students/submissions",
                          { :controller => 'submissions_api', :action => 'for_students',
                            :format => 'json', :course_id => @course.to_param },
                          { :student_ids => ['all'] })
          expect(json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }).to eq [
              { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
              { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
              { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
              { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 },
              { 'user_id' => @observer.id, 'assignment_id' => @assignment1.id, 'score' => 5 }
          ]
        end
      end

      it "allows an observer to view observed students' submissions (grouped)" do
        @user = @observer
        json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json?student_ids[]=#{@student1.id}&student_ids[]=#{@student2.id}&grouped=1",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param,
              :student_ids => [@student1.to_param, @student2.to_param],
              :grouped => '1' })
        expect(json.size).to eq 2
        expect(json.map { |entry| entry['user_id'] }.sort).to eq [@student1.id, @student2.id]
      end

      it "does not allow an observer to view non-observed students' submissions" do
        student3 = student_in_course(:active_all => true).user
        @user = @observer
        api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.id, @student2.id, student3.id] },
            {}, { :expected_status => 401 })
      end

      it "does not work with a non-active ObserverEnrollment" do
        @observer.enrollments.first.conclude
        @user = @observer
        api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.id, @student2.id] },
            {}, { :expected_status => 401 })
      end
    end

    context "logged out user" do
      it "renders api unauthenticated" do
        @user = nil
        api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [@student1.id, @student2.id] },
          {}, { :expected_status => 401 })
      end
    end
  end

  describe '#update' do
    before :once do
      student_in_course(:active_all => true)
      teacher_in_course(:active_all => true)
      @assignment = @course.assignments.create!(
        title: 'assignment1',
        grading_type: 'letter_grade',
        points_possible: 15
      )
    end

    it "allows grading an uncreated submission" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: 'submissions_api',
          action: 'update',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        }, {
          submission: {
            posted_grade: 'B'
          },
        }
      )

      expect(Submission.count).to eq 1
      expect(json['grade']).to eq 'B'
      expect(json['score']).to eq 12.9
    end

    it "can excuse assignments" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: 'submissions_api',
          action: 'update',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        }, {
          submission: {
            excuse: "1"
          }
        }
      )

      submission = @assignment.submission_for_student(@student)
      expect(submission).to be_excused
      expect(json['excused']).to eq true
    end

    it "can unexcuse assignments" do
      @assignment.grade_student(@student, excuse: true, grader: @teacher)
      submission = @assignment.submission_for_student(@student)
      expect(submission).to be_excused

      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: 'submissions_api',
          action: 'update',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        }, {
          submission: { excuse: "0" }
        }
      )

      expect(submission.reload).not_to be_excused
      expect(json['excused']).to eq false
    end

    it "creates a provisional grade and comment" do
      @assignment.update_attribute(:moderated_grading, true)
      submission = @assignment.submit_homework(@student, :body => 'what')

      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: 'submissions_api',
          action: 'update',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        }, {
          submission: {
            posted_grade: '100',
            provisional: true
          },
          comment: {
            text_comment: 'strong work'
          }
        }
      )

      submission.reload
      expect(submission.workflow_state).to eq 'submitted'
      expect(submission.score).to be_nil
      expect(submission.grade).to be_nil
      expect(submission.submission_comments.count).to eq 0

      pg = submission.provisional_grades.last
      expect(pg.score).to eq 100
      expect(pg.submission_comments.first.comment).to eq 'strong work'

      expect(json['provisional_grades'].first['score']).to eq 100

    end

    it "creates a provisional grade and comment when no submission exists" do
      @assignment.update_attribute(:moderated_grading, true)

      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: 'submissions_api',
          action: 'update',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        }, {
          submission: {
            posted_grade: '0',
            provisional: true
          },
          comment: {
            text_comment: 'you slacker'
          }
        }
      )

      sub = @assignment.submissions.where(user_id: @student).last
      expect(sub.workflow_state).to eq 'unsubmitted'
      expect(sub.score).to be_nil
      expect(sub.grade).to be_nil
      expect(sub.submission_comments.count).to eq 0

      pg = sub.provisional_grades.last
      expect(pg.score).to eq 0
      expect(pg.submission_comments.first.comment).to eq 'you slacker'

      expect(json['provisional_grades'].first['score']).to eq 0
    end

    it "returns an error trying to grade a student not enrolled in the course" do
      @student.enrollments.first.conclude
      a1 = @course.assignments.create!(
        title: 'assignment1',
        grading_type: 'points',
        points_possible: 15
      )
      json = api_call(:put,
            "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{@student.id}.json",
            { :controller => 'submissions_api', :action => 'update',
              :format => 'json', :course_id => @course.id.to_s,
              :assignment_id => a1.id.to_s, :user_id => @student.id.to_s },
            { :submission => { :posted_grade => 10 } },
            {},
            { expected_status: 400 })
      expect(json["error"]).not_to be_nil
    end

    it "allows a LTI launch URL to be assigned" do
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: 'submissions_api',
          action: 'update',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        }, {
          submission: {
            posted_grade: 'B',
            submission_type: 'basic_lti_launch',
            url: 'http://example.test'
          },
        }
      )

      expect(Submission.count).to eq 1
      expect(json['submission_type']).to eql 'basic_lti_launch'
      expect(json['url']).to eql 'http://example.test'
    end

    it 'does not allow a submission to be overwritten if type is a non-lti type' do
      @assignment.submit_homework(@student, body: 'what')
      json = api_call(
        :put,
        "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
        {
          controller: 'submissions_api',
          action: 'update',
          format: 'json',
          course_id: @course.id.to_s,
          assignment_id: @assignment.id.to_s,
          user_id: @student.id.to_s
        }, {
          submission: {
            posted_grade: 'B',
            submission_type: 'basic_lti_launch',
            url: 'http://example.test'
          },
        }
      )

      expect(Submission.count).to eq 1
      expect(json['submission_type']).to eql 'online_text_entry'
      expect(json['url']).to be_nil
    end
  end

  it "allows posting grade by sis id" do
    student = user_with_pseudonym(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @course.update_attribute(:sis_source_id, "my-course-id")
    student.pseudonym.update_attribute(:sis_user_id, "my-user-id")
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    json = api_call(:put,
          "/api/v1/courses/sis_course_id:my-course-id/assignments/#{a1.id}/submissions/sis_user_id:my-user-id.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => 'sis_course_id:my-course-id',
            :assignment_id => a1.id.to_s, :user_id => 'sis_user_id:my-user-id' },
          { :submission => { :posted_grade => 'B' } })

    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json['grade']).to eq 'B'
    expect(json['score']).to eq 12.9
  end

  it "allows commenting by a student without trying to grade" do
    course_with_teacher(:active_all => true)
    student = user_factory(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    # since student is the most recently created user, @user = student, so this
    # call will happen as student
    api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => 'witty remark' } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(@submission.submission_comments.size).to eq 1
    comment = @submission.submission_comments.first
    expect(comment.comment).to eq 'witty remark'
    expect(comment.author).to eq student
  end

  it "does not allow grading by a student" do
    course_with_teacher(:active_all => true)
    student = user_factory(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    # since student is the most recently created user, @user = student, so this
    # call will happen as student
    raw_api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => 'witty remark' },
            :submission => { :posted_grade => 'B' } })
    assert_status(401)
  end

  it "does not allow rubricking by a student" do
    course_with_teacher(:active_all => true)
    student = user_factory(active_all: true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    # since student is the most recently created user, @user = student, so this
    # call will happen as student
    raw_api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => 'witty remark' },
            :rubric_assessment => { :criteria => { :points => 5 } } })
    assert_status(401)
  end

  it "does not return submissions for no-longer-enrolled students" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    enrollment = @course.enroll_student(student)
    enrollment.accept!
    assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    submit_homework(assignment, student)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => assignment.id.to_s })
    expect(json.length).to eq 1

    enrollment.destroy

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => assignment.id.to_s })
    expect(json.length).to eq 0
  end

  it "allows updating the grade for an existing submission" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    submission = a1.find_or_create_submission(student)
    expect(submission).not_to be_new_record
    submission.grade = 'A'
    submission.grader = @teacher
    submission.save!

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => 'B' } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(submission.id).to eq @submission.id

    expect(json['grade']).to eq 'B'
    expect(json['score']).to eq 12.9
  end

  it "adds hidden comments if the assignment is muted" do
    course_with_teacher(:active_all => true)
    student    = user_factory(active_all: true)
    assignment = @course.assignments.create!(:title => 'assignment')
    assignment.update_attribute(:muted, true)
    @user = @teacher
    @course.enroll_student(student).accept!
    submission = assignment.find_or_create_submission(student)
    api_call(:put, "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{student.id}",
      { :controller => 'submissions_api', :action => 'update', :format => 'json',
        :course_id => @course.to_param, :assignment_id => assignment.to_param,
        :user_id => student.to_param },
      { :comment => { :text_comment => 'hidden comment' } })
    expect(submission.submission_comments.order("id DESC").first).to be_hidden
  end

  it "does not hide student comments on muted assignments" do
    course_with_teacher(:active_all => true)
    student    = user_factory(active_all: true)
    assignment = @course.assignments.create!(:title => 'assignment')
    assignment.update_attribute(:muted, true)
    @user = student
    @course.enroll_student(student).accept!
    submission = assignment.find_or_create_submission(student)
    api_call(:put, "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{student.id}",
      { :controller => 'submissions_api', :action => 'update', :format => 'json',
        :course_id => @course.to_param, :assignment_id => assignment.to_param,
        :user_id => student.to_param },
      { :comment => { :text_comment => 'hidden comment' } })
    expect(submission.submission_comments.order("id DESC").first).not_to be_hidden
  end

  it "allows submitting points" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, '13.2', 13.2, '13.2')
  end

  it "allows submitting points above points_possible (for extra credit)" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, '16', 16, '16')
  end

  it "allows submitting percent to a points assignment" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, '50%', 7.5, '7.5')
  end

  it "allows submitting percent" do
    submit_with_grade({ :grading_type => 'percent', :points_possible => 10 }, '75%', 7.5, "75%")
  end

  it "allows submitting points to a percent assignment" do
    submit_with_grade({ :grading_type => 'percent', :points_possible => 10 }, '5', 5, "50%")
  end

  it "allows submitting percent above points_possible (for extra credit)" do
    submit_with_grade({ :grading_type => 'percent', :points_possible => 10 }, '105%', 10.5, "105%")
  end

  it "allows submitting letter_grade as a letter score" do
    submit_with_grade({ :grading_type => 'letter_grade', :points_possible => 15 }, 'B', 12.9, 'B')
  end

  it "allows submitting letter_grade as a numeric score" do
    submit_with_grade({ :grading_type => 'letter_grade', :points_possible => 15 }, '11.9', 11.9, 'C+')
  end

  it "allows submitting letter_grade as a percentage score" do
    submit_with_grade({ :grading_type => 'letter_grade', :points_possible => 15 }, '70%', 10.5, 'C-')
  end

  it "rejects letter grades sent to a points assignment" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, 'B-', nil, nil)
  end

  it "allows submitting pass_fail (pass)" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, 'pass', 12, "complete")
  end

  it "allows submitting pass_fail (fail)" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, 'fail', 0, "incomplete")
  end

  it "allows a points score for pass_fail, at full points" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '12', 12, "complete")
  end

  it "allows a points score for pass_fail, at zero points" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '0', 0, "incomplete")
  end

  it "allows a percentage score for pass_fail, at full points" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '100%', 12, "complete")
  end

  it "rejects any other type of score for a pass_fail assignment" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '50%', nil, nil)
  end

  it "sets complete for zero point assignments" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 0 }, 'pass', 0, 'complete')
  end

  def submit_with_grade(assignment_opts, param, score, grade)
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!({:title => 'assignment1'}.merge(assignment_opts))

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => param } })

    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json['score']).to eq score
    expect(json['grade']).to eq grade
  end

  it "allows posting a rubric assessment" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    rubric = rubric_model(:user => @user, :context => @course,
                          :data => larger_rubric_data)
    a1.create_rubric_association(:rubric => rubric, :purpose => 'grading', :use_for_grading => true, :context => @course)

    api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :rubric_assessment =>
             { :crit1 => { :points => 7 },
               :crit2 => { :points => 2, :comments => 'Rock on' } } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(@submission.user_id).to eq student.id
    expect(@submission.score).to eq 9
    expect(@submission.rubric_assessment).not_to be_nil
    expect(@submission.rubric_assessment.data).to eq(
      [{:description=>"B",
        :criterion_id=>"crit1",
        :comments_enabled=>true,
        :points=>7,
        :learning_outcome_id=>nil,
        :id=>"rat2",
        :comments=>nil},
      {:description=>"Pass",
        :criterion_id=>"crit2",
        :comments_enabled=>true,
        :points=>2,
        :learning_outcome_id=>nil,
        :id=>"rat1",
        :comments=>"Rock on",
        :comments_html=>"Rock on"}]
    )
  end

  it "allows posting a comment on a submission" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    submit_homework(@assignment, student)

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :comment =>
            { :text_comment => "ohai!" } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(json['submission_comments'].size).to eq 1
    expect(json['submission_comments'].first['comment']).to eq 'ohai!'
  end

  it "allows posting a group comment on a submission" do
    student1 = user_factory(active_all: true)
    student2 = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!
    group_category = @course.group_categories.create(:name => "Category")
    @group = @course.groups.create(:name => "Group", :group_category => group_category, :context => @course)
    @group.users = [student1, student2]
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12, :group_category => group_category)
    submit_homework(@assignment, student1)

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student1.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student1.id.to_s },
          { :comment =>
            { :text_comment => "ohai!", :group_comment => "1" } })
    expect(json['submission_comments'].size).to eq 1
    expect(json['submission_comments'].first['comment']).to eq 'ohai!'

    expect(Submission.count).to eq 2
    Submission.all.each do |submission|
      expect(submission.submission_comments.size).to eql 1
      expect(submission.submission_comments.first.comment).to eql 'ohai!'
    end
  end

  it "allows posting a media comment on a submission, given a kaltura id" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    media_object(:media_id => "1234", :media_type => 'audio')

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :comment =>
            { :media_comment_id => '1234', :media_comment_type => 'audio' } })

    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(json['submission_comments'].size).to eq 1
    comment = json['submission_comments'].first
    expect(comment['comment']).to eq 'This is a media comment.'
    expect(comment['media_comment']['url']).to eq "http://www.example.com/users/#{@user.id}/media_download?entryId=1234&redirect=1&type=mp4"
    expect(comment['media_comment']["content-type"]).to eq "audio/mp4"
  end

  it "allows commenting on an uncreated submission" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => "Why U no submit" } })

    expect(Submission.count).to eq 1
    @submission = Submission.first

    comment = @submission.submission_comments.first
    expect(comment).to be_present
    expect(comment.comment).to eq "Why U no submit"
  end

  it "allows clearing out the current grade with a blank grade" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    @assignment.grade_student(student, grade: '10', grader: @teacher)
    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(@submission.grade).to eq '10'
    expect(@submission.score).to eq 10
    expect(@submission.workflow_state).to eq 'graded'

    api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => '' } })
    expect(Submission.count).to eq 1
    @submission = Submission.first
    expect(@submission.grade).to be_nil
    expect(@submission.score).to be_nil
  end

  it "allows repeated changes to a submission to accumulate" do
    student = user_factory(active_all: true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    submit_homework(@assignment, student)

    # post a comment
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => "This works" } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    # grade the submission
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => '10' } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    # post another comment
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => "10/12 ain't bad" } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json['grade']).to eq '10'
    expect(@submission.grade).to eq '10'
    expect(@submission.score).to eq 10
    expect(json['body']).to eq 'test!'
    expect(@submission.body).to eq 'test!'
    expect(json['submission_comments'].size).to eq 2
    expect(json['submission_comments'].first['comment']).to eq "This works"
    expect(json['submission_comments'].last['comment']).to eq "10/12 ain't bad"
    expect(@submission.user_id).to eq student.id

    # post another grade
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => '12' } })
    expect(Submission.count).to eq 1
    @submission = Submission.first

    expect(json['grade']).to eq '12'
    expect(@submission.grade).to eq '12'
    expect(@submission.score).to eq 12
    expect(json['body']).to eq 'test!'
    expect(@submission.body).to eq 'test!'
    expect(json['submission_comments'].size).to eq 2
    expect(json['submission_comments'].first['comment']).to eq "This works"
    expect(json['submission_comments'].last['comment']).to eq "10/12 ain't bad"
    expect(@submission.user_id).to eq student.id
  end

  it "does not allow accessing other sections when limited" do
    course_with_teacher(:active_all => true)
    @enrollment.update_attribute(:limit_privileges_to_course_section, true)
    @teacher = @user
    s1 = submission_model(:course => @course)
    section2 = @course.course_sections.create(:name => "another section")
    s2 = submission_model(:course => @course, :username => 'otherstudent@example.com', :section => section2, :assignment => @assignment)
    @user = @teacher

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s })
    expect(json.map { |u| u['user_id'] }).to eq [s1.user_id]

    # try querying the other section directly
    json = api_call(:get,
          "/api/v1/sections/#{section2.id}/assignments/#{@assignment.id}/submissions",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :section_id => section2.id.to_s,
            :assignment_id => @assignment.id.to_s })
    expect(json.size).to eq 0

    raw_api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => s2.user_id.to_s })
    assert_status(404)

    # try querying the other section directly
    raw_api_call(:get,
          "/api/v1/sections/#{section2.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :section_id => section2.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => s2.user_id.to_s })
    assert_status(404)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.id.to_s },
          { :student_ids => [s1.user_id, s2.user_id], :grouped => 1 },
          {}, expected_status: 401)

    # try querying the other section directly
    json = api_call(:get,
          "/api/v1/sections/#{section2.id}/students/submissions",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :section_id => section2.id.to_s },
          { :student_ids => [s1.user_id, s2.user_id], :grouped => 1 },
          {}, expected_status: 401)

    # grade the s1 submission, succeeds because the section is the same
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{s1.user_id}",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => s1.user_id.to_s },
          { :submission => { :posted_grade => '10' } })
    @submission = @assignment.submission_for_student(s1.user)
    expect(@submission).to be_present
    expect(@submission.grade).to eq '10'

    # grading s2 will fail because the teacher can't manipulate this student's section
    raw_api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => s2.user_id.to_s },
          { :submission => { :posted_grade => '10' } })
    assert_status(404)

    # try querying the other section directly
    raw_api_call(:put,
          "/api/v1/sections/#{section2.id}/assignments/#{@assignment.id}/submissions/#{s2.user_id}",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :section_id => section2.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => s2.user_id.to_s },
          { :submission => { :posted_grade => '10' } })
    assert_status(404)
  end

  context 'map_user_ids' do
    before do
      @controller = SubmissionsApiController.new
      @controller.instance_variable_set :@domain_root_account, Account.default
    end

    it 'maps an empty list' do
      expect(@controller.map_user_ids([])).to eq []
    end

    it 'maps a list of AR ids' do
      expect(@controller.map_user_ids([1, 2, '3', '4']).sort).to eq [1, 2, 3, 4]
    end

    it "bails on ids it can't figure out" do
      expect(@controller.map_user_ids(["nonexistentcolumn:5"])).to eq []
    end

    it "filters out sis ids that don't exist, but not filter out AR ids" do
      expect(@controller.map_user_ids(["sis_user_id:1", "2"])).to eq [2]
    end

    it "finds sis ids that exist" do
      user_with_pseudonym
      @pseudonym.sis_user_id = "sisuser1"
      @pseudonym.save!
      @user1 = @user
      user_with_pseudonym :username => "sisuser2@example.com"
      @user2 = @user
      user_with_pseudonym :username => "sisuser3@example.com"
      @user3 = @user
      expect(@controller.map_user_ids(["sis_user_id:sisuser1", "sis_login_id:sisuser2@example.com",
        "hex:sis_login_id:7369737573657233406578616d706c652e636f6d", "sis_user_id:sisuser4",
        "5123"]).sort).to eq [
        @user1.id, @user2.id, @user3.id, 5123].sort
    end

    it "does not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      @controller.instance_variable_set :@domain_root_account, account1
      user1 = user_with_pseudonym :username => "sisuser1@example.com", :account => account1
      user_with_pseudonym :username => "sisuser2@example.com", :account => account2
      user3 = user_with_pseudonym :username => "sisuser3@example.com", :account => account1
      user_with_pseudonym :username => "sisuser3@example.com", :account => account2
      user5 = user_factory :account => account1
      user6 = user_factory :account => account2
      expect(@controller.map_user_ids(["sis_login_id:sisuser1@example.com", "sis_login_id:sisuser2@example.com", "sis_login_id:sisuser3@example.com", user5.id, user6.id]).sort).to eq [user1.id, user3.id, user5.id, user6.id].sort
    end
  end

  context "create" do
    before :once do
      course_with_student(:active_all => true)
      assignment_model(:course => @course, :submission_types => "online_url", :points_possible => 12)
      @url = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions"
      @args = { :controller => "submissions", :action => "create", :format => "json", :course_id => @course.id.to_s, :assignment_id => @assignment.id.to_s }
    end

    it "rejects a submission by a non-student" do
      @user = course_with_teacher(:course => @course).user
      api_call(:post, @url, @args, { :submission => { :submission_type => "online_url", :url => "www.example.com" } }, {}, :expected_status => 401)
    end

    it "rejects a request with an invalid submission_type" do
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "blergh" } }, {}, :expected_status => 400)
      expect(json['message']).to eq "Invalid submission[submission_type] given"
    end

    it "rejects a submission_type not allowed by the assignment" do
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "media_recording" } }, {}, :expected_status => 400)
      expect(json['message']).to eq "Invalid submission[submission_type] given"
    end

    it "rejects mismatched submission_type and params" do
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "online_url", :body => "some html text" } }, {}, :expected_status => 400)
      expect(json['message']).to eq "Invalid parameters for submission_type online_url. Required: submission[url]"
    end

    it "works with section ids" do
      @section = @course.default_section
      api_call(:post, "/api/v1/sections/#{@section.id}/assignments/#{@assignment.id}/submissions", { :controller => "submissions", :action => "create", :format => "json", :section_id => @section.id.to_s, :assignment_id => @assignment.id.to_s }, { :submission => { :submission_type => "online_url", :url => "www.example.com/a/b?q=1" } })
      @submission = @assignment.submissions.where(user_id: @user).first
      expect(@submission).to be_present
      expect(@submission.url).to eq 'http://www.example.com/a/b?q=1'
    end

    describe "valid submissions" do
      def do_submit(opts)
        json = api_call(:post, @url, @args, { :submission => opts })
        expect(response['Location']).to eq "http://www.example.com/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}"
        @submission = @assignment.submissions.where(user_id: @user).first
        expect(@submission).to be_present
        expect(json.slice('user_id', 'assignment_id', 'score', 'grade')).to eq({
          'user_id' => @user.id,
          'assignment_id' => @assignment.id,
          'score' => nil,
          'grade' => nil,
        })
        json
      end

      it "creates a url submission" do
        json = do_submit(:submission_type => "online_url", :url => "www.example.com/a/b?q=1")
        expect(@submission.url).to eq 'http://www.example.com/a/b?q=1'
        expect(json['url']).to eq @submission.url
      end

      it "creates with an initial comment" do
        json = api_call(:post, @url, @args, { :comment => { :text_comment => "ohai teacher" }, :submission => { :submission_type => "online_url", :url => "http://www.example.com/a/b" } })
        @submission = @assignment.submissions.where(user_id: @user).first
        expect(@submission.submission_comments.size).to eq 1
        expect(@submission.submission_comments.first.attributes.slice('author_id', 'comment')).to eq({
          'author_id' => @user.id,
          'comment' => 'ohai teacher',
        })
        expect(json['url']).to eq "http://www.example.com/a/b"
      end

      it "creates a online text submission" do
        @assignment.update_attributes(:submission_types => 'online_text_entry')
        json = do_submit(:submission_type => 'online_text_entry', :body => %{<p>
          This is <i>some</i> text. The <script src='evil.com'></script> sanitization will take effect.
        </p>})
        expect(json['body']).to eq %{<p>
          This is <i>some</i> text. The  sanitization will take effect.
        </p>}
        expect(json['body']).to eq @submission.body
      end

      it "processs html content in body" do
        @assignment.update_attributes(:submission_types => 'online_text_entry')
        should_process_incoming_user_content(@course) do |content|
          do_submit(:submission_type => 'online_text_entry', :body => content)
          @submission.body
        end
      end

      it "creates a file upload submission" do
        @assignment.update_attributes(:submission_types => 'online_upload')
        a1 = attachment_model(:context => @user)
        a2 = attachment_model(:context => @user)
        json = do_submit(:submission_type => 'online_upload', :file_ids => [a1.id, a2.id])
        expect(json['attachments'].map { |a| a['url'] }).to eq [ file_download_url(a1, :verifier => a1.uuid, :download => '1', :download_frd => '1'), file_download_url(a2, :verifier => a2.uuid, :download => '1', :download_frd => '1') ]
      end

      it "creates a media comment submission" do
        @assignment.update_attributes(:submission_types => "media_recording")
        media_object(:media_id => "3232", :media_type => "audio")
        json = do_submit(:submission_type => "media_recording", :media_comment_id => "3232", :media_comment_type => "audio")
        expect(json['media_comment'].slice('media_id', 'media_type')).to eq({
          'media_id' => '3232',
          'media_type' => 'audio',
        })
      end

      it "copys files to the submissions folder if they're not there already" do
        @course.root_account.enable_feature! :submissions_folder
        @assignment.update_attributes(:submission_types => 'online_upload')
        a1 = attachment_model(:context => @user, :folder => @user.submissions_folder)
        a2 = attachment_model(:context => @user)
        json = do_submit(:submission_type => 'online_upload', :file_ids => [a1.id, a2.id])
        submission_attachment_ids = json['attachments'].map { |a| a['id'] }
        expect(submission_attachment_ids.size).to eq 2
        expect(submission_attachment_ids.delete(a1.id)).not_to be_nil
        copy = Attachment.find(submission_attachment_ids.last)
        expect(copy.folder).to eq @user.submissions_folder(@course)
        expect(copy.root_attachment).to eq a2
      end
    end

    context "submission file uploads" do
      before :once do
        @assignment.update_attributes(:submission_types => 'online_upload')
        @student1 = @student
        course_with_student(:course => @course)
        @context = @course
        @student2 = @student
        @user = @student1
        @always_scribd = true
      end

      include_examples "file uploads api"
      include_examples "file uploads api without quotas"

      def preflight(preflight_params)
        api_call(:post, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student1.id}/files",
          { :controller => "submissions_api", :action => "create_file", :format => "json", :course_id => @course.to_param, :assignment_id => @assignment.to_param, :user_id => @student1.to_param },
          preflight_params)
      end

      def has_query_exemption?
        true
      end

      it "rejects uploading files to other students' submissions" do
        api_call(:post, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student2.id}/files",
                        { :controller => "submissions_api", :action => "create_file", :format => "json", :course_id => @course.to_param, :assignment_id => @assignment.to_param, :user_id => @student2.to_param }, {}, {}, { :expected_status => 401 })
      end

      it "uploads to a student's Submissions folder if the feature is enabled" do
        @course.root_account.enable_feature! :submissions_folder
        preflight(name: 'test.txt', size: 12345, content_type: 'text/plain')
        f = Attachment.last.folder
        expect(f.submission_context_code).to eq @course.asset_string
      end

      it "does not do so otherwise" do
        preflight(name: 'test.txt', size: 12345, content_type: 'text/plain')
        expect(Attachment.last.folder).not_to be_for_submissions
      end
    end

    it "rejects invalid urls" do
      api_call(:post, @url, @args, { :submission => { :submission_type => "online_url", :url => "ftp://ftp.example.com/a/b" } }, {}, :expected_status => 400)
    end

    it "rejects attachment ids not belonging to the user" do
      @assignment.update_attributes(:submission_types => 'online_upload')
      a1 = attachment_model(:context => @course)
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "online_upload", :file_ids => [a1.id] } }, {}, :expected_status => 400)
      expect(json['message']).to eq 'No valid file ids given'
    end
  end

  context "draft assignments" do
    before :once do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @a2 = @course.assignments.create!({:title => 'assignment2'})
      @a2.workflow_state = "unpublished"
      @a2.save!
    end

    it "does not allow comments (teachers)" do
      @user = @teacher
      draft_assignment_update({ :comment => { :text_comment => 'Tacos are tasty' }})
    end

    it "does not allow comments (students)" do
      @user = @student
      draft_assignment_update({ :comment => { :text_comment => 'Tacos are tasty' }})
    end

    it "does not allow group comments (students)" do
      student2 = user_factory(active_all: true)
      @course.enroll_student(student2).accept!
      group_category = @course.group_categories.create(:name => "Category")
      @group = @course.groups.create(:name => "Group", :group_category => group_category, :context => @course)
      @group.users = [@student, student2]
      @a2 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12, :group_category => group_category)
      draft_assignment_update({ :comment => { :text_comment => "HEY GIRL HEY!", :group_comment => "1" } })
    end

    it "does not allow grading with points" do
      @a2.grading_type = "points"
      @a2.points_possible = 15
      @a2.save!
      @user = @teacher
      grade = "13.2"
      draft_assignment_update({ :submission => { :posted_grade => grade }})
    end

    it "does not mark as complete for zero credit assignments" do
      @a2.grading_type = "pass_fail"
      @a2.points_possible = 0
      @a2.save!
      @user = @teacher
      grade = "pass"
      draft_assignment_update({ :submission => { :posted_grade => grade }})
    end

    # Give this a hash of items to update with the API call
    def draft_assignment_update(opts)
      raw_api_call(
              :put,
              "/api/v1/courses/#{@course.id}/assignments/#{@a2.id}/submissions/#{@student.id}",
              {
                :controller => 'submissions_api',
                :action => 'update',
                :format => 'json',
                :course_id => @course.id.to_s,
                :assignment_id => @a2.id.to_s,
                :user_id => @student.id.to_s
              },
              opts)
      assert_status(401)
    end
  end

  it "includes preview urls for attachments" do
    Canvadocs.stubs(:config).returns({a: 1})

    course_with_teacher_logged_in active_all: true
    student_in_course active_all: true
    @user = @teacher
    a = @course.assignments.create!
    a.submit_homework(@student, submission_type: 'online_upload',
                      attachments: [crocodocable_attachment_model(context: @student)])
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a.id}/submissions?include[]=submission_history",
                    { course_id: @course.id.to_s, assignment_id: a.id.to_s,
                      action: 'index', controller: 'submissions_api', format: 'json',
                      include: %w[submission_history] })

    expect(json[0]["submission_history"][0]["attachments"][0]["preview_url"]).to match(
      /canvadoc_session/
    )
  end

  it "includes crocodoc whitelist ids in the preview url for attachments" do
    Canvas::Crocodoc.stubs(:config).returns({a: 1})

    course_with_teacher_logged_in active_all: true
    student_in_course active_all: true
    @user = @teacher
    assignment = @course.assignments.create!(moderated_grading: true)
    submission = assignment.submit_homework(@student, submission_type: 'online_upload',
      attachments: [crocodocable_attachment_model(context: @student)])
    provisional_grade = submission.find_or_create_provisional_grade!(@teacher, score: 1)
    assignment.moderated_grading_selections.create! do |s|
      s.student = @student
      s.provisional_grade = provisional_grade
    end
    assignment.update(grades_published_at: 1.hour.ago)
    submission.reload
    submission.attachments.first.create_crocodoc_document(uuid: '1234',
                                                          process_state: 'PROCESSED')

    url = "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions?include[]=submission_history"
    json = api_call(:get, url, { course_id: @course.id.to_s, assignment_id: assignment.id.to_s,
                      action: 'index', controller: 'submissions_api', format: 'json',
                      include: %w[submission_history] })

    result_url = json.first.fetch("submission_history").first.fetch("attachments").first.
      fetch("preview_url")
    expect(result_url).to match(/crocodoc_ids%22:\[1,2\]/)
  end


  def course_with_student_and_submitted_homework
    course_with_teacher(:active_all => true)
    @teacher = @user
    student_in_course
    @student = @user
    @user = @teacher # @user needs to be the user making the api calls later
    @assignment = @course.assignments.create!(:title => "some assignment", :submission_types => "online_url,online_upload")
    @submission = @assignment.submit_homework(@student)
  end

  it 'marks as read' do
    course_with_student_and_submitted_homework
    @submission.add_comment(:author => @student, :comment => "some comment")
    raw_api_call(:put,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/read",
             {course_id: @course.id.to_s, assignment_id: @assignment.id.to_s, user_id: @student.id.to_s,
               action: 'mark_submission_read', controller: 'submissions_api', format: 'json'})
    expect(@submission.reload.read?(@teacher)).to be_truthy
  end

  it 'marks as unread' do
    course_with_student_and_submitted_homework
    @submission.add_comment(:author => @student, :comment => "some comment")
    @submission.change_read_state('read', @teacher)
    raw_api_call(:delete,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}/read",
             {course_id: @course.id.to_s, assignment_id: @assignment.id.to_s, user_id: @student.id.to_s,
               action: 'mark_submission_unread', controller: 'submissions_api', format: 'json'})
    expect(@submission.reload.read?(@teacher)).to be_falsey
  end

  context 'bulk update' do
    before :each do
      @student1 = user_factory(active_all: true)
      @student2 = user_factory(active_all: true)
      course_with_teacher(:active_all => true)
      @default_section = @course.default_section
      @section = @course.course_sections.create!(:name => "section2")
      @course.enroll_user(@student1, 'StudentEnrollment', :section => @section).accept!
      @course.enroll_user(@student2, 'StudentEnrollment').accept!
      @a1 = @course.assignments.create!({:title => 'assignment1', :grading_type => 'percent', :points_possible => 10})
    end

    it "queues bulk update through courses" do
      grade_data = {
        :grade_data => {
          @student1.id => { :posted_grade => '75%'},
          @student2.id => { :posted_grade => '95%'}
        }
      }

      json = api_call(:post,
        "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
        { :controller => 'submissions_api', :action => 'bulk_update',
          :format => 'json', :course_id => @course.id.to_s,
          :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 2
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
      s2 = @student2.submissions.first
      expect(s2.grade).to eq "95%"
    end

    it "finds users through sis api ids" do
      student3 = user_with_pseudonym(:active_all => true)
      student3.pseudonym.update_attribute(:sis_user_id, 'my-student-id')
      @course.enroll_user(student3, 'StudentEnrollment').accept!

      grade_data = {
          :grade_data => {
              'sis_user_id:my-student-id' => { :posted_grade => '75%'}
          }
      }

      @user = @teacher
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { :controller => 'submissions_api', :action => 'bulk_update',
                        :format => 'json', :course_id => @course.id.to_s,
                        :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 1
      s1 = student3.submissions.first
      expect(s1.grade).to eq "75%"
    end

    it "restricts with differentiated assignments" do
      @a1.only_visible_to_overrides = true
      @a1.save!
      create_section_override_for_assignment(@a1, course_section: @section)

      student3 = user_with_pseudonym(:active_all => true)
      student3.pseudonym.update_attribute(:sis_user_id, 'my-student-id')
      @course.enroll_user(student3, 'StudentEnrollment').accept!

      grade_data = {
          :grade_data => {
              @student1.id => { :posted_grade => '75%'},
              @student2.id => { :posted_grade => '95%'},
              'sis_user_id:my-student-id' => { :posted_grade => '85%'},
          }
      }

      @user = @teacher
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { :controller => 'submissions_api', :action => 'bulk_update',
                        :format => 'json', :course_id => @course.id.to_s,
                        :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.failed?).to be_truthy
      expect(progress.message).to eq "Couldn't find User(s) with API ids '#{@student2.id}', 'sis_user_id:my-student-id'"

      create_section_override_for_assignment(@a1, course_section: @course.default_section)
      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { :controller => 'submissions_api', :action => 'bulk_update',
                        :format => 'json', :course_id => @course.id.to_s,
                        :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 3
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
      s2 = @student2.submissions.first
      expect(s2.grade).to eq "95%"
      s3 = student3.submissions.first
      expect(s3.grade).to eq "85%"
    end

    it "queues bulk update through sections" do
      grade_data = {
        :grade_data => {
          @student1.id => { :posted_grade => '75%'}
        }
      }

      json = api_call(:post,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
        { :controller => 'submissions_api', :action => 'bulk_update',
          :format => 'json', :section_id => @section.id.to_s,
          :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 1
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
    end

    it "allows bulk grading with rubric assessments" do
      rubric = rubric_model(:user => @user, :context => @course, :data => larger_rubric_data)
      @a1.create_rubric_association(:rubric => rubric, :purpose => 'grading', :use_for_grading => true, :context => @course)

      grade_data = {
        :grade_data => {
          @student1.id => { :posted_grade => '75%' },
          @student2.id => {
            :rubric_assessment => {
              :crit1 => { :points => 7 },
              :crit2 => { :points => 2, :comments => 'Rock on' }
            }
          }
        }
      }

      json = api_call(:post,
                      "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
                      { :controller => 'submissions_api', :action => 'bulk_update',
                        :format => 'json', :course_id => @course.id.to_s,
                        :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.completed?).to be_truthy

      expect(Submission.count).to eq 2
      s1 = @student1.submissions.first
      expect(s1.grade).to eq "75%"
      s2 = @student2.submissions.first
      expect(s2.rubric_assessment).not_to be_nil
      expect(s2.rubric_assessment.data).to eq(
          [{:description=>"B",
            :criterion_id=>"crit1",
            :comments_enabled=>true,
            :points=>7,
            :learning_outcome_id=>nil,
            :id=>"rat2",
            :comments=>nil},
           {:description=>"Pass",
            :criterion_id=>"crit2",
            :comments_enabled=>true,
            :points=>2,
            :learning_outcome_id=>nil,
            :id=>"rat1",
            :comments=>"Rock on",
            :comments_html=>"Rock on"}]
      )
    end

    it "requires authorization" do
      @user = @student1
      raw_api_call(:post,
        "/api/v1/courses/#{@course.id}/assignments/#{@a1.id}/submissions/update_grades",
        { :controller => 'submissions_api', :action => 'bulk_update',
          :format => 'json', :course_id => @course.id.to_s,
          :assignment_id => @a1.id.to_s, :grade_data => {foo: "bar"} }, {})
      assert_status(401)
    end

    it "excuses assignments" do
      grade_data = {
        grade_data: { @student1.id => {excuse: "1"} }
      }

      api_call(:post,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
        { :controller => 'submissions_api', :action => 'bulk_update',
          :format => 'json', :section_id => @section.id.to_s,
          :assignment_id => @a1.id.to_s }, grade_data)
      run_jobs

      expect(@a1.submission_for_student(@student1)).to be_excused
    end

    it "checks user ids for sections" do
      grade_data = {
        :grade_data => {
          @student1.id => { :posted_grade => '75%'},
          @student2.id => { :posted_grade => '95%'}
        }
      }

      json = api_call(:post,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
        { :controller => 'submissions_api', :action => 'bulk_update',
          :format => 'json', :section_id => @section.id.to_s,
          :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      progress = Progress.find(json["id"])
      expect(progress.failed?).to be_truthy
      expect(progress.message).to eq "Couldn't find User(s) with API ids '#{@student2.id}'"
    end

    it "maintains grade when updating comments" do
      @a1.grade_student(@student1, grade: '5%', grader: @teacher)

      grade_data = {
        :grade_data => {
          @student1.id => { :text_comment => "Awesome comment" }
        }
      }
      api_call(:post,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
        { :controller => 'submissions_api', :action => 'bulk_update',
          :format => 'json', :section_id => @section.id.to_s,
          :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      s1 = @student1.submissions.first
      expect(s1.grade).to eq '5%'
    end

    it "nils grade when receiving empty posted_grade" do
      @a1.grade_student(@student1, grade: '5%', grader: @teacher)

      grade_data = {
        :grade_data => {
          @student1.id => { :posted_grade => nil }
        }
      }
      api_call(:post,
        "/api/v1/sections/#{@section.id}/assignments/#{@a1.id}/submissions/update_grades",
        { :controller => 'submissions_api', :action => 'bulk_update',
          :format => 'json', :section_id => @section.id.to_s,
          :assignment_id => @a1.id.to_s }, grade_data)

      run_jobs
      s1 = @student1.submissions.first
      expect(s1.grade).to be_nil
    end
  end

  describe "list_gradeable_students" do
    before(:once) do
      course_with_teacher :active_all => true
      ta_in_course :active_all => true
      @student1 = student_in_course(:active_all => true).user
      @student2 = student_in_course(:active_all => true).user
      @assignment = @course.assignments.build
      @assignment.moderated_grading = true
      @assignment.save!
      @assignment.submit_homework @student1, :body => 'EHLO'
      @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/gradeable_students"
      @params = { :controller => 'submissions_api', :action => 'gradeable_students',
                  :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.to_param }
    end

    it "requires grading rights" do
      api_call_as_user(@student1, :get, @path, @params, {}, {}, { :expected_status => 401 })
    end

    it "lists students with and without submissions" do
      json = api_call_as_user(@ta, :get, @path, @params)
      expect(json.map { |el| el['id'] }).to match_array([@student1.id, @student2.id])
    end

    it "paginates" do
      json = api_call_as_user(@teacher, :get, @path + "?per_page=1", @params.merge(:per_page => '1'))
      expect(json.size).to eq 1
      expect(response.headers).to include 'Link'
      expect(response.headers['Link']).to match(/rel="next"/)
    end

    describe "include[]=provisional_grades" do
      before(:once) do
        @path = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/gradeable_students?include[]=provisional_grades"
        @params = { :controller => 'submissions_api', :action => 'gradeable_students',
                    :format => 'json', :course_id => @course.to_param, :assignment_id => @assignment.to_param,
                    :include => [ 'provisional_grades' ] }
      end

      it "requires :moderate_grades permission" do
        api_call_as_user(@ta, :get, @path, @params, {}, {}, { :expected_status => 401 })
      end

      it "includes provisional grades with selections" do
        sub = @assignment.grade_student(@student1, :score => 90, :grader => @ta, :provisional => true).first
        pg = sub.provisional_grades.first
        sel = @assignment.moderated_grading_selections.build
        sel.student_id = @student1.id
        sel.selected_provisional_grade_id = pg.id
        sel.save!
        json = api_call_as_user(@teacher, :get, @path, @params)
        expect(json).to match_array(
          [{"id"=>@student1.id,
            "display_name"=>"User",
            "avatar_image_url"=>"http://www.example.com/images/messages/avatar-50.png",
            "html_url"=>"http://www.example.com/courses/#{@course.id}/users/#{@student1.id}",
            "in_moderation_set"=>true,
            "selected_provisional_grade_id"=>pg.id,
            "provisional_grades"=>
              [{"grade"=>"90",
                "score"=>90,
                "graded_at"=>pg.graded_at.iso8601,
                "scorer_id"=>@ta.id,
                "provisional_grade_id"=>pg.id,
                "grade_matches_current_submission"=>true,
                "graded_anonymously"=>nil,
                "final"=>false,
                "speedgrader_url"=>"http://www.example.com/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}#%7B%22student_id%22:#{@student1.id},%22provisional_grade_id%22:#{pg.id}%7D"}]},
           {"id"=>@student2.id,
            "display_name"=>"User",
            "avatar_image_url"=>"http://www.example.com/images/messages/avatar-50.png",
            "html_url"=>"http://www.example.com/courses/#{@course.id}/users/#{@student2.id}",
            "in_moderation_set"=>false,
            "selected_provisional_grade_id"=>nil,
            "provisional_grades"=>[]}]
        )
      end
    end
  end

  describe "list_gradeable_students_for_multiple_assignments" do
    before(:once) do
      course_with_teacher :active_all => true
      ta_in_course :active_all => true
      @student1 = student_in_course(:active_all => true).user
      @student2 = student_in_course(:active_all => true).user
      @assignment1 = @course.assignments.build
      @assignment1.moderated_grading = true
      @assignment1.save!
      @assignment2 = @course.assignments.build
      @assignment2.save!
      @assignment_ids = [@assignment1.id, @assignment2.id]
      @path = "/api/v1/courses/#{@course.id}/assignments/gradeable_students"
      @params = { :controller => 'submissions_api', :action => 'multiple_gradeable_students',
                  :format => 'json', :course_id => @course.to_param,
                  :assignment_ids => [@assignment1.to_param, @assignment2.to_param] }
    end

    it "requires grading rights" do
      api_call_as_user(@student1, :get, @path, @params, {}, {}, { :expected_status => 401 })
    end

    it "lists students" do
      json = api_call_as_user(@ta, :get, @path, @params)

      expect(json.map {|el| el['id'] }).to match_array([@student1.id, @student2.id])
      expect(json[0]['assignment_ids']).to match_array(@assignment_ids)
      expect(json[1]['assignment_ids']).to match_array(@assignment_ids)
    end

    it "paginates" do
      json = api_call_as_user(@teacher, :get, @path + "?per_page=1", @params.merge(:per_page => '1'))
      expect(json.size).to eq 1
      expect(response.headers).to include 'Link'
      expect(response.headers['Link']).to match(/rel="next"/)
    end

    it "limits access to sections user is a part of" do
      section = add_section('Test Section')
      section_teacher = teacher_in_section(section, :active_all => true, :limit_privileges_to_course_section => true)
      section_student = student_in_section(section, :active_all => true)

      json = api_call_as_user(section_teacher, :get, @path, @params)

      expect(json.size).to eq 1
      expect(json[0]['id']).to eq section_student.id
    end

    it "respects differentiated assignments" do
      assignment = @course.assignments.build
      section = add_section('Test Section')
      section_teacher = teacher_in_section(section, :active_all => true)
      section_student = student_in_section(section, :active_all => true)
      differentiated_assignment(:assignment => assignment, :course_section => section)

      differentiated_params = { :controller => 'submissions_api', :action => 'multiple_gradeable_students',
                  :format => 'json', :course_id => @course.to_param,
                  :assignment_ids => [@assignment.id] }

      json = api_call_as_user(section_teacher, :get, @path, differentiated_params)

      expect(json.size).to eq 1
      expect(json[0]['id']).to eq section_student.id
    end
  end

  describe '#index' do
    context 'grouped_submissions' do
      let(:test_course) { course_factory() }
      let(:teacher)   { user_factory(active_all: true) }
      let(:student1)  { user_factory(active_all: true) }
      let(:student2)  { user_factory(active_all: true) }
      let(:group) do
        group_category = test_course.group_categories.create(name: 'Engineering')
        test_course.groups.create(name: 'Group1', group_category: group_category)
      end
      let(:assignment) do
        test_course.assignments.create!(
          title: 'group assignment',
          grading_type: 'points',
          points_possible: 10,
          submission_types: 'online_text_entry',
          group_category: group.group_category
        )
      end

      let!(:enroll_teacher_and_students) do
        test_course.enroll_teacher(teacher).accept!
        test_course.enroll_student(student1, enrollment_state: 'active')
        test_course.enroll_student(student2, enrollment_state: 'active')
      end
      let!(:add_students_to_group) do
        group.add_user(student1)
        group.add_user(student2)
      end
      let!(:submit_homework) { assignment.submit_homework(student1) }

      let(:path) { "/api/v1/courses/#{test_course.id}/assignments/#{assignment.id}/submissions" }
      let(:params) do
        {
          controller: 'submissions_api', action: 'index',
          format: 'json', course_id: test_course.id.to_s,
          assignment_id: assignment.id.to_s
        }
      end

      it 'returns two assignment and submission objects for a user group' do
        params[:grouped] = false
        json = api_call_as_user(teacher, :get, path, params)
        expect(json.size).to eq 2
      end

      it 'returns a single assignment and submission object per user group' do
        params[:grouped] = true
        json = api_call_as_user(teacher, :get, path, params)
        expect(json.size).to eq 1
      end

      it 'includes the group_id and group_name if include[]=group is passed' do
        params[:include] = %w/group/
        json = api_call_as_user(teacher, :get, path, params)
        expect(json.first.fetch('group').fetch('id')).to eq group.id
        expect(json.first.fetch('group').fetch('name')).to eq group.name
      end
    end
  end
end
