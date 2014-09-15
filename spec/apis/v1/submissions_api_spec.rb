#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../file_uploads_spec_helper')

describe 'Submissions API', type: :request do

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

  it "should not 404 if there is no submission" do
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })
    json.delete('id').should == nil
    json.should == {
      "assignment_id" => @assignment.id,
      "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}?preview=1",
      "user_id"=>student.id,
      "grade"=>nil,
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
    }
  end

  describe "using section ids" do
    before :once do
      @student1 = user(:active_all => true)
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

    it "should list submissions" do
      json = api_call(:get,
            "/api/v1/sections/#{@default_section.id}/assignments/#{@a1.id}/submissions.json",
            { :controller => 'submissions_api', :action => 'index',
              :format => 'json', :section_id => @default_section.id.to_s,
              :assignment_id => @a1.id.to_s },
            { :include => %w(submission_history submission_comments rubric_assessment) })
      json.size.should == 0

      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions.json",
            { :controller => 'submissions_api', :action => 'index',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s },
            { :include => %w(submission_history submission_comments rubric_assessment) })
      json.size.should == 1
      json.first['user_id'].should == @student1.id

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
      json.size.should == 1
    end

    it "should post to submissions" do
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

      Submission.count.should == 2
      @submission = Submission.order(:id).last
      @submission.grader.should == @teacher

      json['score'].should == 7.5
      json['grade'].should == '75%'
    end

    it "should return submissions for a section" do
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_history submission_comments rubric_assessment) })
      json['user_id'].should == @student1.id
    end

    it "should not show grades or hidden comments to students on muted assignments" do
      @a1.mute!
      @a1.grade_student(@student1, :grade => 5)

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
        json[a].should be_nil
      end

      json["submission_comments"].size.should == 1
      json["submission_comments"][0]["comment"].should == "visible comment"

      # should still show this stuff to the teacher
      @user = @teacher
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_comments rubric_assessment) })
      json["submission_comments"].size.should == 2
      json["grade"].should == "5"

      # should show for an admin with no enrollments in the course
      account_admin_user
      @user.enrollments.should be_empty
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions/#{@student1.id}",
            { :controller => 'submissions_api', :action => 'show',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s, :user_id => @student1.id.to_s },
            { :include => %w(submission_comments rubric_assessment) })
      json["submission_comments"].size.should == 2
      json["grade"].should == "5"
    end

    it "should not show rubric assessments to students on muted assignments" do
      @a1.mute!
      sub = @a1.grade_student(@student1, :grade => 5).first

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
      ra = @a1.rubric_association.assess(
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

      json['rubric_assessment'].should be_nil
    end

    it "should not find sections in other root accounts" do
      acct = account_model(:name => 'other root')
      @first_course = @course
      course(:active_all => true, :account => acct)
      @course.default_section.update_attribute('sis_source_id', 'my-section-sis-id')
      json = api_call(:get,
            "/api/v1/sections/sis_section_id:my-section-sis-id/assignments/#{@a1.id}/submissions",
            { :controller => 'submissions_api', :action => 'index',
              :format => 'json', :section_id => 'sis_section_id:my-section-sis-id',
              :assignment_id => @a1.id.to_s })
      json.size.should == 1 # should find the submission for @first_course
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
        response.should be_success
        @assignment.submission_for_student(@student)
        .submission_comments.first
        .attachment_ids.should == @attachment.id.to_s
      end
    end
  end

  it "should return student discussion entries for discussion_topic assignments" do
    @student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(@student).accept!
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, {:title => 'assignment1', :submission_types => 'discussion_topic', :discussion_topic => discussion_topic_model})

    e1 = @topic.discussion_entries.create!(:message => 'main entry', :user => @user)
    se1 = @topic.discussion_entries.create!(:message => 'sub 1', :user => @student, :parent_entry => e1)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    se2 = @topic.discussion_entries.create!(:message => 'student 1', :user => @student)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    e2 = @topic.discussion_entries.create!(:message => 'another entry', :user => @user)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s })

    json['discussion_entries'].sort_by { |h| h['user_id'] }.should ==
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
      }].sort_by { |h| h['user_id'] }

    # don't include discussion entries if response_fields limits the response
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s },
          { :response_fields => SubmissionsApiController::SUBMISSION_JSON_FIELDS })
    json['discussion_entries'].should be_nil

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s },
          { :exclude_response_fields => %w(discussion_entries) })
    json['discussion_entries'].should be_nil
  end

  it "should return student discussion entries from child topics for group discussion_topic assignments" do
    @student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(@student).accept!
    group_category = @course.group_categories.create(:name => "Category")
    @group = @course.groups.create(:name => "Group", :group_category => group_category)
    @group.add_user(@student)
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, {:title => 'assignment1', :submission_types => 'discussion_topic', :discussion_topic => discussion_topic_model(:group_category => @group.group_category)})
    @topic.refresh_subtopics # since the DJ won't happen in time
    @child_topic = @group.discussion_topics.find_by_root_topic_id(@topic.id)

    e1 = @child_topic.discussion_entries.create!(:message => 'main entry', :user => @user)
    se1 = @child_topic.discussion_entries.create!(:message => 'sub 1', :user => @student, :parent_entry => e1)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    se2 = @child_topic.discussion_entries.create!(:message => 'student 1', :user => @student)
    @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
    e2 = @child_topic.discussion_entries.create!(:message => 'another entry', :user => @user)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => @student.id.to_s })

    json['discussion_entries'].sort_by { |h| h['user_id'] }.should ==
      [{
        'id' => se1.id,
        'message' => 'sub 1',
        'user_id' => @student.id,
        'user_name' => 'User',
        'read_state' => 'unread',
        'forced_read_state' => false,
        'parent_id' => e1.id,
        'created_at' => se1.created_at.as_json,
        'updated_at' => se1.updated_at.as_json,
      },
      {
        'id' => se2.id,
        'message' => 'student 1',
        'user_id' => @student.id,
        'user_name' => 'User',
        'read_state' => 'unread',
        'forced_read_state' => false,
        'parent_id' => nil,
        'created_at' => se2.created_at.as_json,
        'updated_at' => se2.updated_at.as_json,
      }].sort_by { |h| h['user_id'] }
  end

  def submission_with_comment
    @student = user(:active_all => true)
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

  it "should return user display info along with submission comments" do

    submission_with_comment

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s },
          { :include => %w(submission_comments) })

    json.first["submission_comments"].size.should == 1
    comment = json.first["submission_comments"].first
    comment.should have_key("author")
    comment["author"].should == {
      "id" => @student.id,
      "display_name" => "User",
      "html_url" => "http://www.example.com/courses/#{@course.id}/users/#{@student.id}",
      "avatar_image_url" => User.avatar_fallback_url
    }
  end

  it "should return comment id along with submission comments" do

    submission_with_comment

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s },
          { :include => %w(submission_comments) })

    json.first["submission_comments"].size.should == 1
    comment = json.first["submission_comments"].first
    comment.should have_key("id")
    comment["id"].should == @submission.submission_comments.first.id
  end

  it "should return a valid preview url for quiz submissions" do
    student1 = user(:active_all => true)
    course_with_teacher_logged_in(:active_all => true) # need to be logged in to view the preview url below
    @course.enroll_student(student1).accept!
    quiz = Quizzes::Quiz.create!(:title => 'quiz1', :context => @course)
    quiz.did_edit!
    quiz.offer!
    a1 = quiz.assignment
    sub = a1.find_or_create_submission(student1)
    sub.submission_type = 'online_quiz'
    sub.workflow_state = 'submitted'
    sub.save!

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })

    get_via_redirect json.first['preview_url']
    response.should be_success
    response.body.should match(/Redirecting to quiz page/)
  end

  it "should allow students to retrieve their own submission" do
    student1 = user(:active_all => true)
    student2 = user(:active_all => true)

    course_with_teacher(:active_all => true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!

    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    sub1 = submit_homework(a1, student1)
    media_object(:media_id => "3232", :media_type => "audio")
    sub1 = a1.grade_student(student1, {:grade => '90%', :comment => "Well here's the thing...", :media_comment_id => "3232", :media_comment_type => "audio", :grader => @teacher}).first
    comment = sub1.submission_comments.first

    @user = student1
    json = api_call(:get,
                    "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                    { :controller => "submissions_api", :action => "show",
                      :format => "json", :course_id => @course.id.to_s,
                      :assignment_id => a1.id.to_s, :user_id => student1.id.to_s },
                    { :include => %w(submission_comments) })

    json.should == {
        "id"=>sub1.id,
        "grade"=>"A-",
        "grader_id"=>@teacher.id,
        "graded_at"=>sub1.graded_at.as_json,
        "body"=>"test!",
        "assignment_id" => a1.id,
        "submitted_at"=>"1970-01-01T01:00:00Z",
        "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1",
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
              "avatar_image_url" => User.avatar_fallback_url
           },
           "author_name"=>"User",
           "id" => comment.id,
           "author_id"=>@teacher.id}],
        "score"=>13.5,
        "workflow_state"=>"graded",
        "late"=>false}

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

  it "should return grading information for observers" do
    @student = user(:active_all => true)
    e = course_with_observer(:active_all => true)
    e.associated_user_id = @student.id
    e.save!
    @course.enroll_student(@student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :points_possible => 15)
    submit_homework(a1, @student)
    a1.grade_student(@student, {:grade => 15})
    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{@student.id}.json",
                  { :controller => "submissions_api", :action => "show",
                    :format => "json", :course_id => @course.id.to_s,
                    :assignment_id => a1.id.to_s, :user_id => @student.id.to_s })
    json["score"].should == 15
  end

  it "should api translate online_text_entry submissions" do
    student1 = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    should_translate_user_content(@course) do |content|
      sub1 = submit_homework(a1, student1, :body => content)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}.json",
                    { :controller => "submissions_api", :action => "show",
                      :format => "json", :course_id => @course.id.to_s,
                      :assignment_id => a1.id.to_s, :user_id => student1.id.to_s })
      json["body"]
    end
  end

  it "should allow retrieving attachments without a session" do
    student1 = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student1).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    sub1 = submit_homework(a1, student1) { |s| s.attachments = [attachment_model(:uploaded_data => stub_png_data, :content_type => 'image/png', :context => student1)] }
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s },
          { :include => %w(submission_history submission_comments rubric_assessment) })
    url = json[0]['attachments'][0]['url']
    get_via_redirect(url)
    response.should be_success
    response['content-type'].should == 'image/png'
  end

  it "should allow retrieving media comments without a session" do
    student1 = user(:active_all => true)
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
    response.should be_redirect
    response['Location'].should match(%r{https://kaltura.example.com/some/url})
  end

  it "should return all submissions for an assignment" do
    student1 = user(:active_all => true)
    student2 = user(:active_all => true)

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
    a1.grade_student(student1, {:grade => '90%', :comment => "Well here's the thing...", :media_comment_id => "3232", :media_comment_type => "audio", :grader => @teacher})
    sub1.reload
    sub1.submission_comments.size.should == 1
    comment = sub1.submission_comments.first
    ra = a1.rubric_association.assess(
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
        "grader_id"=>@teacher.id,
        "graded_at"=>sub1.graded_at.as_json,
        "body"=>"test!",
        "assignment_id" => a1.id,
        "submitted_at"=>"1970-01-01T03:00:00Z",
        "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1",
        "grade_matches_current_submission"=>true,
        "attachments" =>
         [
           { "content-type" => "application/loser",
             "url" => "http://www.example.com/files/#{sub1.attachments.first.id}/download?download_frd=1&verifier=#{sub1.attachments.first.uuid}",
             "filename" => "unknown.loser",
             "display_name" => "unknown.loser",
             "id" => sub1.attachments.first.id,
             "size" => sub1.attachments.first.size,
             'unlock_at' => nil,
             'locked' => false,
             'hidden' => false,
             'lock_at' => nil,
             'locked_for_user' => false,
             'hidden_for_user' => false,
             'created_at' => sub1.attachments.first.reload.created_at.as_json,
             'updated_at' => sub1.attachments.first.updated_at.as_json, 
             'thumbnail_url' => sub1.attachments.first.thumbnail_url },
         ],
        "submission_history"=>
         [{"id"=>sub1.id,
           "grade"=>nil,
           "grader_id"=>nil,
           "graded_at"=>nil,
           "body"=>"test!",
           "assignment_id" => a1.id,
           "submitted_at"=>"1970-01-01T01:00:00Z",
           "attempt"=>1,
           "url"=>nil,
           "submission_type"=>"online_text_entry",
           "user_id"=>student1.id,
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=0",
           "grade_matches_current_submission"=>nil,
           "score"=>nil,
           "workflow_state" => "submitted",
           "late"=>false},
          {"id"=>sub1.id,
           "grade"=>nil,
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
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=1",
           "grade_matches_current_submission"=>nil,
           "score"=>nil,
           "workflow_state" => "submitted",
           "late"=>false},
          {"id"=>sub1.id,
           "grade"=>"A-",
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
                "size" => sub1.attachments.first.size,
                'unlock_at' => nil,
                'locked' => false,
                'hidden' => false,
                'lock_at' => nil,
                'locked_for_user' => false,
                'hidden_for_user' => false,
                'created_at' => sub1.attachments.first.created_at.as_json,
                'updated_at' => sub1.attachments.first.updated_at.as_json, 
                'thumbnail_url' => sub1.attachments.first.thumbnail_url },
            ],
           "body"=>"test!",
           "submitted_at"=>"1970-01-01T03:00:00Z",
           "attempt"=>3,
           "url"=>nil,
           "submission_type"=>"online_text_entry",
           "user_id"=>student1.id,
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student1.id}?preview=1&version=2",
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
             "avatar_image_url" => User.avatar_fallback_url
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
        "grader_id"=>@teacher.id,
        "graded_at"=>sub2.graded_at.as_json,
        "assignment_id" => a1.id,
        "body"=>nil,
        "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student2.id}?preview=1",
        "grade_matches_current_submission"=>true,
        "submitted_at"=>"1970-01-01T04:00:00Z",
        "submission_history"=>
         [{"id"=>sub2.id,
           "grade"=>"F",
           "grader_id"=>@teacher.id,
           "graded_at"=>sub2.graded_at.as_json,
           "assignment_id" => a1.id,
           "body"=>nil,
           "submitted_at"=>"1970-01-01T04:00:00Z",
           "attempt"=>1,
           "url"=>"http://www.instructure.com",
           "submission_type"=>"online_url",
           "user_id"=>student2.id,
           "preview_url" => "http://www.example.com/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student2.id}?preview=1&version=0",
           "grade_matches_current_submission"=>true,
           "attachments" =>
            [
              {"content-type" => "image/png",
               "display_name" => "snapshot.png",
               "filename" => "snapshot.png",
               "url" => "http://www.example.com/files/#{sub2a1.id}/download?download_frd=1&verifier=#{sub2a1.uuid}",
               "id" => sub2a1.id,
               "size" => sub2a1.size,
               'unlock_at' => nil,
               'locked' => false,
               'hidden' => false,
               'lock_at' => nil,
               'locked_for_user' => false,
               'hidden_for_user' => false,
               'created_at' => sub2a1.created_at.as_json,
               'updated_at' => sub2a1.updated_at.as_json,
               'thumbnail_url' => sub2a1.thumbnail_url
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
           "size" => sub2a1.size,
           'unlock_at' => nil,
           'locked' => false,
           'hidden' => false,
           'lock_at' => nil,
           'locked_for_user' => false,
           'hidden_for_user' => false,
           'created_at' => sub2a1.created_at.as_json,
           'updated_at' => sub2a1.updated_at.as_json,
           'thumbnail_url' => sub2a1.thumbnail_url,
          },
         ],
        "submission_comments"=>[],
        "score"=>9,
        "rubric_assessment"=>
         {"crit2"=>{"comments"=>"Hmm", "points"=>2},
          "crit1"=>{"comments"=>nil, "points"=>7}},
        "workflow_state"=>"graded",
        "late"=>false}]
    json.sort_by { |h| h['user_id'] }.should == res.sort_by { |h| h['user_id'] }
  end

  it "should return nothing if no assignments in the course" do
    student1 = user(:active_all => true)
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
    json.sort_by { |h| h['user_id'] }.should == [
      {
        'user_id' => student1.id,
        "section_id" => enrollment1.course_section_id,
        'submissions' => [],
      },
      {
        'user_id' => student2.id,
        "section_id" => enrollment2.course_section_id,
        'integration_id' => nil,
        'submissions' => [],
      },
    ]

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param] })
    json.should == []
  end

  it "should return integration_id for user and assignment" do
    student1 = user(:active_all => true)
    student2 = user_with_pseudonym(:active_all => true)
    student2.pseudonym.update_attribute(:sis_user_id, 'my-student-id')
    student2.pseudonym.update_attribute(:integration_id, 'xyz')

    course_with_teacher(:active_all => true)

    @course.enroll_student(student1).accept!
    @course.enroll_student(student2).accept!
    
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => 'all' })
    json.should == []
  end

  it "should return turnitin data if present" do
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
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
    json.should have_key 'turnitin_data'
    sample_turnitin_data.delete :last_processed_attempt
    json['turnitin_data'].should == sample_turnitin_data.with_indifferent_access

    # as student before graded
    @user = student
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s })
    json.should_not have_key 'turnitin_data'

    # as student after grading
    a1.grade_student(student, {:grade => 11})
    @user = student
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s })
    json.should have_key 'turnitin_data'
    json['turnitin_data'].should == sample_turnitin_data.with_indifferent_access

  end

  it "should return all submissions for a student" do
    student1 = user(:active_all => true)
    student2 = user_with_pseudonym(:active_all => true)
    student2.pseudonym.update_attribute(:sis_user_id, 'my-student-id')

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
          { :student_ids => [student1.to_param] })

    json.size.should == 2
    json.each { |submission| submission['user_id'].should == student1.id }

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param] })

    json.size.should == 3

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param],
            :assignment_ids => [a1.to_param] })

    json.size.should == 2
    json.all? { |submission| submission['assignment_id'].should == a1.id }.should be_true

    # by sis user id!
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, 'sis_user_id:my-student-id'],
            :assignment_ids => [a1.to_param] })

    json.size.should == 2
    json.all? { |submission| submission['assignment_id'].should == a1.id }.should be_true

    # by sis login id!
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, "sis_login_id:#{student2.pseudonym.unique_id}"],
            :assignment_ids => [a1.to_param] })

    json.size.should == 2
    json.all? { |submission| submission['assignment_id'].should == a1.id }.should be_true

    # concluded enrollments!
    student2.enrollments.first.conclude
    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, "sis_login_id:#{student2.pseudonym.unique_id}"],
            :assignment_ids => [a1.to_param] })

    json.size.should == 2
    json.all? { |submission| submission['assignment_id'].should == a1.id }.should be_true
  end

  it "should return student submissions grouped by student" do
    student1 = user(:active_all => true)
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

    json.size.should == 1
    json.first['submissions'].size.should == 2
    json.each { |user| user['user_id'].should == student1.id }

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param], :grouped => '1' })

    json.size.should == 2
    json.map { |u| u['submissions'] }.flatten.size.should == 3

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/students/submissions.json",
          { :controller => 'submissions_api', :action => 'for_students',
            :format => 'json', :course_id => @course.to_param },
          { :student_ids => [student1.to_param, student2.to_param],
            :assignment_ids => [a1.to_param], :grouped => '1' })

    json.size.should == 2
    json.each { |user| user['submissions'].each { |s| s['assignment_id'].should == a1.id } }
  end

  it "should return students with no submissions when grouped" do
    student1 = user(:active_all => true)
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

    json.size.should == 2
    json.detect { |u| u['user_id'] == student1.id }['submissions'].size.should == 2
    json.detect { |u| u['user_id'] == student2.id }['submissions'].size.should == 0
  end

  describe "for_students non-admin" do
    before :once do
      course_with_student :active_all => true
      @student1 = @student
      @student2 = student_in_course(:active_all => true).user
      @student3 = student_in_course(:active_all => true).user
      @assignment1 = @course.assignments.create! :title => 'assignment1', :grading_type => 'points', :points_possible => 15
      @assignment2 = @course.assignments.create! :title => 'assignment2', :grading_type => 'points', :points_possible => 25
      bare_submission_model @assignment1, @student1, grade: 15, score: 15
      bare_submission_model @assignment2, @student1, grade: 25, score: 25
      bare_submission_model @assignment1, @student2, grade: 10, score: 10
      bare_submission_model @assignment2, @student2, grade: 20, score: 20
      bare_submission_model @assignment1, @student3, grade: 20, score: 20
    end

    context "teacher" do
      it "should show all submissions" do
        @user = @teacher
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => ['all'] })
        json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }.should == [
            { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 },
            { 'user_id' => @student3.id, 'assignment_id' => @assignment1.id, 'score' => 20 },
        ]
      end
    end

    context "students" do
      it "should allow a student to view his own submissions" do
        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => [@student1.to_param] })
        json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| entry['assignment_id'] }.should == [
            { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 } ]
      end

      it "should assume the calling user if student_ids is not provided" do
        @user = @student2
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param } )
        json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| entry['assignment_id'] }.should == [
            { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 } ]
      end

      it "should show all possible if student_ids is ['all']" do
        @user = @student2
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => ['all'] })
        json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| entry['assignment_id'] }.should == [
            { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 } ]
      end

      it "should support the 'grouped' argument" do
        @user = @student1
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions.json?grouped=1",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param, :grouped => '1' })
        json.size.should == 1
        json[0]['user_id'].should == @student1.id
        json[0]['submissions'].map { |sub| sub.slice('assignment_id', 'score') }.sort_by { |entry| entry['assignment_id'] }.should == [
            { 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'assignment_id' => @assignment2.id, 'score' => 25 } ]
      end

      it "should not allow a student to view another student's submissions" do
        @user = @student1
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions.json?student_ids[]=#{@student1.id}&student_ids[]=#{@student2.id}",
                 { :controller => 'submissions_api', :action => 'for_students',
                   :format => 'json', :course_id => @course.to_param,
                   :student_ids => [@student1.to_param, @student2.to_param] },
                 {}, {}, :expected_status => 401)
      end

      it "should error if too many students requested" do
        Api.stubs(:max_per_page).returns(0)
        @user = @student1
        api_call(:get,
                 "/api/v1/courses/#{@course.id}/students/submissions.json",
                 { :controller => 'submissions_api', :action => 'for_students',
                   :format => 'json', :course_id => @course.to_param },
                 { :student_ids => [@student1.to_param] }, {}, expected_status: 400)
      end
    end

    context "observers" do
      before :once do
        @observer = user :active_all => true
        @course.enroll_user(@observer, 'ObserverEnrollment', :associated_user_id => @student1.id).accept!
        @course.enroll_user(@observer, 'ObserverEnrollment', :allow_multiple_enrollments => true, :associated_user_id => @student2.id).accept!
      end

      it "should allow an observer to view observed students' submissions" do
        @user = @observer
        json = api_call(:get,
           "/api/v1/courses/#{@course.id}/students/submissions",
           { :controller => 'submissions_api', :action => 'for_students',
             :format => 'json', :course_id => @course.to_param },
           { :student_ids => [@student1.id, @student2.id] })
        json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }.should == [
            { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
            { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
            { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 }
        ]
      end

      it "should allow an observer to view all observed students' submissions via student_ids[]=all" do
        @user = @observer
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/students/submissions",
                        { :controller => 'submissions_api', :action => 'for_students',
                          :format => 'json', :course_id => @course.to_param },
                        { :student_ids => ['all'] })
        json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }.should == [
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
          @assignment1.grade_student(@observer, grade: 5)
        end

        it "should allow an observer that is a student to view his own and his observees submissions" do
          @user = @observer
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/students/submissions",
                          { :controller => 'submissions_api', :action => 'for_students',
                            :format => 'json', :course_id => @course.to_param },
                          { :student_ids => [@student1.id, @observer.id] })
          json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }.should == [
              { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
              { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
              { 'user_id' => @observer.id, 'assignment_id' => @assignment1.id, 'score' => 5 }
          ]
        end

        it "should allow an observer that is a student to view his own and his observees submissions via student_ids[]=all" do
          @user = @observer
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/students/submissions",
                          { :controller => 'submissions_api', :action => 'for_students',
                            :format => 'json', :course_id => @course.to_param },
                          { :student_ids => ['all'] })
          json.map { |entry| entry.slice('user_id', 'assignment_id', 'score') }.sort_by { |entry| [entry['user_id'], entry['assignment_id']] }.should == [
              { 'user_id' => @student1.id, 'assignment_id' => @assignment1.id, 'score' => 15 },
              { 'user_id' => @student1.id, 'assignment_id' => @assignment2.id, 'score' => 25 },
              { 'user_id' => @student2.id, 'assignment_id' => @assignment1.id, 'score' => 10 },
              { 'user_id' => @student2.id, 'assignment_id' => @assignment2.id, 'score' => 20 },
              { 'user_id' => @observer.id, 'assignment_id' => @assignment1.id, 'score' => 5 }
          ]
        end
      end

      it "should allow an observer to view observed students' submissions (grouped)" do
        @user = @observer
        json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions.json?student_ids[]=#{@student1.id}&student_ids[]=#{@student2.id}&grouped=1",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param,
              :student_ids => [@student1.to_param, @student2.to_param],
              :grouped => '1' })
        json.size.should == 2
        json.map { |entry| entry['user_id'] }.sort.should == [@student1.id, @student2.id]
      end

      it "should not allow an observer to view non-observed students' submissions" do
        student3 = student_in_course(:active_all => true).user
        @user = @observer
        json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.id, @student2.id, student3.id] },
            {}, { :expected_status => 401 })
      end

      it "should not work with a non-active ObserverEnrollment" do
        @observer.enrollments.first.conclude
        @user = @observer
        json = api_call(:get,
            "/api/v1/courses/#{@course.id}/students/submissions",
            { :controller => 'submissions_api', :action => 'for_students',
              :format => 'json', :course_id => @course.to_param },
            { :student_ids => [@student1.id, @student2.id] },
            {}, { :expected_status => 401 })
      end
    end
  end

  it "should allow grading an uncreated submission" do
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => 'B' } })

    Submission.count.should == 1
    @submission = Submission.first

    json['grade'].should == 'B'
    json['score'].should == 12.9
  end

  it "should allow posting grade by sis id" do
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

    Submission.count.should == 1
    @submission = Submission.first

    json['grade'].should == 'B'
    json['score'].should == 12.9
  end

  it "should allow commenting by a student without trying to grade" do
    course_with_teacher(:active_all => true)
    student = user(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    # since student is the most recently created user, @user = student, so this
    # call will happen as student
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => 'witty remark' } })

    Submission.count.should == 1
    @submission = Submission.first
    @submission.submission_comments.size.should == 1
    comment = @submission.submission_comments.first
    comment.comment.should == 'witty remark'
    comment.author.should == student
  end

  it "should not allow grading by a student" do
    course_with_teacher(:active_all => true)
    student = user(:active_all => true)
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

  it "should not allow rubricking by a student" do
    course_with_teacher(:active_all => true)
    student = user(:active_all => true)
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

  it "should not return submissions for no-longer-enrolled students" do
    student = user(:active_all => true)
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
    json.length.should == 1

    enrollment.destroy

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}/submissions.json",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => assignment.id.to_s })
    json.length.should == 0
  end

  it "should allow updating the grade for an existing submission" do
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)
    submission = a1.find_or_create_submission(student)
    submission.should_not be_new_record
    submission.grade = 'A'
    submission.save!

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => 'B' } })

    Submission.count.should == 1
    @submission = Submission.first
    submission.id.should == @submission.id

    json['grade'].should == 'B'
    json['score'].should == 12.9
  end

  it "should add hidden comments if the assignment is muted" do
    course_with_teacher(:active_all => true)
    student    = user(:active_all => true)
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
    submission.submission_comments.order("id DESC").first.should be_hidden
  end

  it "should not hide student comments on muted assignments" do
    course_with_teacher(:active_all => true)
    student    = user(:active_all => true)
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
    submission.submission_comments.order("id DESC").first.should_not be_hidden
  end

  it "should allow submitting points" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, '13.2', 13.2, '13.2')
  end

  it "should allow submitting points above points_possible (for extra credit)" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, '16', 16, '16')
  end

  it "should allow submitting percent to a points assignment" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, '50%', 7.5, '7.5')
  end

  it "should allow submitting percent" do
    submit_with_grade({ :grading_type => 'percent', :points_possible => 10 }, '75%', 7.5, "75%")
  end

  it "should allow submitting points to a percent assignment" do
    submit_with_grade({ :grading_type => 'percent', :points_possible => 10 }, '5', 5, "50%")
  end

  it "should allow submitting percent above points_possible (for extra credit)" do
    submit_with_grade({ :grading_type => 'percent', :points_possible => 10 }, '105%', 10.5, "105%")
  end

  it "should allow submitting letter_grade as a letter score" do
    submit_with_grade({ :grading_type => 'letter_grade', :points_possible => 15 }, 'B', 12.9, 'B')
  end

  it "should allow submitting letter_grade as a numeric score" do
    submit_with_grade({ :grading_type => 'letter_grade', :points_possible => 15 }, '11.9', 11.9, 'C+')
  end

  it "should allow submitting letter_grade as a percentage score" do
    submit_with_grade({ :grading_type => 'letter_grade', :points_possible => 15 }, '70%', 10.5, 'C-')
  end

  it "should reject letter grades sent to a points assignment" do
    submit_with_grade({ :grading_type => 'points', :points_possible => 15 }, 'B-', nil, nil)
  end

  it "should allow submitting pass_fail (pass)" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, 'pass', 12, "complete")
  end

  it "should allow submitting pass_fail (fail)" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, 'fail', 0, "incomplete")
  end

  it "should allow a points score for pass_fail, at full points" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '12', 12, "complete")
  end

  it "should allow a points score for pass_fail, at zero points" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '0', 0, "incomplete")
  end

  it "should allow a percentage score for pass_fail, at full points" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '100%', 12, "complete")
  end

  it "should reject any other type of score for a pass_fail assignment" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 12 }, '50%', nil, nil)
  end

  it "should set complete for zero point assignments" do
    submit_with_grade({ :grading_type => 'pass_fail', :points_possible => 0 }, 'pass', 0, 'complete')
  end

  def submit_with_grade(assignment_opts, param, score, grade)
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!({:title => 'assignment1'}.merge(assignment_opts))

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => param } })

    Submission.count.should == 1
    @submission = Submission.first

    json['score'].should == score
    json['grade'].should == grade
  end

  it "should allow posting a rubric assessment" do
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    rubric = rubric_model(:user => @user, :context => @course,
                          :data => larger_rubric_data)
    a1.create_rubric_association(:rubric => rubric, :purpose => 'grading', :use_for_grading => true, :context => @course)

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :rubric_assessment =>
             { :crit1 => { :points => 7 },
               :crit2 => { :points => 2, :comments => 'Rock on' } } })

    Submission.count.should == 1
    @submission = Submission.first
    @submission.user_id.should == student.id
    @submission.score.should == 9
    @submission.rubric_assessment.should_not be_nil
    @submission.rubric_assessment.data.should ==
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
  end

  it "should allow posting a comment on a submission" do
    student = user(:active_all => true)
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

    Submission.count.should == 1
    @submission = Submission.first
    json['submission_comments'].size.should == 1
    json['submission_comments'].first['comment'].should == 'ohai!'
  end

  it "should allow posting a group comment on a submission" do
    student1 = user(:active_all => true)
    student2 = user(:active_all => true)
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
    json['submission_comments'].size.should == 1
    json['submission_comments'].first['comment'].should == 'ohai!'

    Submission.count.should == 2
    Submission.all.each do |submission|
      submission.submission_comments.size.should eql 1
      submission.submission_comments.first.comment.should eql 'ohai!'
    end
  end

  it "should allow posting a media comment on a submission, given a kaltura id" do
    student = user(:active_all => true)
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

    Submission.count.should == 1
    @submission = Submission.first
    json['submission_comments'].size.should == 1
    comment = json['submission_comments'].first
    comment['comment'].should == 'This is a media comment.'
    comment['media_comment']['url'].should == "http://www.example.com/users/#{@user.id}/media_download?entryId=1234&redirect=1&type=mp4"
    comment['media_comment']["content-type"].should == "audio/mp4"
  end

  it "should allow commenting on an uncreated submission" do
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    a1 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'letter_grade', :points_possible => 15)

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{a1.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => a1.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => "Why U no submit" } })

    Submission.count.should == 1
    @submission = Submission.first

    comment = @submission.submission_comments.first
    comment.should be_present
    comment.comment.should == "Why U no submit"
  end

  it "should allow clearing out the current grade with a blank grade" do
    student = user(:active_all => true)
    course_with_teacher(:active_all => true)
    @course.enroll_student(student).accept!
    @assignment = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12)
    @assignment.grade_student(student, { :grade => '10' })
    Submission.count.should == 1
    @submission = Submission.first
    @submission.grade.should == '10'
    @submission.score.should == 10
    @submission.workflow_state.should == 'graded'

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => '' } })
    Submission.count.should == 1
    @submission = Submission.first
    @submission.grade.should be_nil
    @submission.score.should be_nil
  end

  it "should allow repeated changes to a submission to accumulate" do
    student = user(:active_all => true)
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
    Submission.count.should == 1
    @submission = Submission.first

    # grade the submission
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => '10' } })
    Submission.count.should == 1
    @submission = Submission.first

    # post another comment
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :comment => { :text_comment => "10/12 ain't bad" } })
    Submission.count.should == 1
    @submission = Submission.first

    json['grade'].should == '10'
    @submission.grade.should == '10'
    @submission.score.should == 10
    json['body'].should == 'test!'
    @submission.body.should == 'test!'
    json['submission_comments'].size.should == 2
    json['submission_comments'].first['comment'].should == "This works"
    json['submission_comments'].last['comment'].should == "10/12 ain't bad"
    @submission.user_id.should == student.id

    # post another grade
    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{student.id}.json",
          { :controller => 'submissions_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s,
            :assignment_id => @assignment.id.to_s, :user_id => student.id.to_s },
          { :submission => { :posted_grade => '12' } })
    Submission.count.should == 1
    @submission = Submission.first

    json['grade'].should == '12'
    @submission.grade.should == '12'
    @submission.score.should == 12
    json['body'].should == 'test!'
    @submission.body.should == 'test!'
    json['submission_comments'].size.should == 2
    json['submission_comments'].first['comment'].should == "This works"
    json['submission_comments'].last['comment'].should == "10/12 ain't bad"
    @submission.user_id.should == student.id
  end

  it "should not allow accessing other sections when limited" do
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
    json.map { |u| u['user_id'] }.should == [s1.user_id]

    # try querying the other section directly
    json = api_call(:get,
          "/api/v1/sections/#{section2.id}/assignments/#{@assignment.id}/submissions",
          { :controller => 'submissions_api', :action => 'index',
            :format => 'json', :section_id => section2.id.to_s,
            :assignment_id => @assignment.id.to_s })
    json.size.should == 0

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
    @submission.should be_present
    @submission.grade.should == '10'

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

    it 'should map an empty list' do
      @controller.map_user_ids([]).should == []
    end

    it 'should map a list of AR ids' do
      @controller.map_user_ids([1, 2, '3', '4']).sort.should == [1, 2, 3, 4]
    end

    it "should bail on ids it can't figure out" do
      @controller.map_user_ids(["nonexistentcolumn:5"]).should == []
    end

    it "should filter out sis ids that don't exist, but not filter out AR ids" do
      @controller.map_user_ids(["sis_user_id:1", "2"]).should == [2]
    end

    it "should find sis ids that exist" do
      user_with_pseudonym
      @pseudonym.sis_user_id = "sisuser1"
      @pseudonym.save!
      @user1 = @user
      user_with_pseudonym :username => "sisuser2@example.com"
      @user2 = @user
      user_with_pseudonym :username => "sisuser3@example.com"
      @user3 = @user
      @controller.map_user_ids(["sis_user_id:sisuser1", "sis_login_id:sisuser2@example.com",
        "hex:sis_login_id:7369737573657233406578616d706c652e636f6d", "sis_user_id:sisuser4",
        "5123"]).sort.should == [
        @user1.id, @user2.id, @user3.id, 5123].sort
    end

    it "should not find sis ids in other accounts" do
      account1 = account_model
      account2 = account_model
      @controller.instance_variable_set :@domain_root_account, account1
      user1 = user_with_pseudonym :username => "sisuser1@example.com", :account => account1
      user2 = user_with_pseudonym :username => "sisuser2@example.com", :account => account2
      user3 = user_with_pseudonym :username => "sisuser3@example.com", :account => account1
      user4 = user_with_pseudonym :username => "sisuser3@example.com", :account => account2
      user5 = user :account => account1
      user6 = user :account => account2
      @controller.map_user_ids(["sis_login_id:sisuser1@example.com", "sis_login_id:sisuser2@example.com", "sis_login_id:sisuser3@example.com", user5.id, user6.id]).sort.should == [user1.id, user3.id, user5.id, user6.id].sort
    end
  end

  context "create" do
    before :once do
      course_with_student(:active_all => true)
      assignment_model(:course => @course, :submission_types => "online_url", :points_possible => 12)
      @url = "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions"
      @args = { :controller => "submissions", :action => "create", :format => "json", :course_id => @course.id.to_s, :assignment_id => @assignment.id.to_s }
    end

    it "should reject a submission by a non-student" do
      @user = course_with_teacher(:course => @course).user
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "online_url", :url => "www.example.com" } }, {}, :expected_status => 401)
    end

    it "should reject a request with an invalid submission_type" do
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "blergh" } }, {}, :expected_status => 400)
      json['message'].should == "Invalid submission[submission_type] given"
    end

    it "should reject a submission_type not allowed by the assignment" do
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "media_recording" } }, {}, :expected_status => 400)
      json['message'].should == "Invalid submission[submission_type] given"
    end

    it "should reject mismatched submission_type and params" do
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "online_url", :body => "some html text" } }, {}, :expected_status => 400)
      json['message'].should == "Invalid parameters for submission_type online_url. Required: submission[url]"
    end

    it "should work with section ids" do
      @section = @course.default_section
      json = api_call(:post, "/api/v1/sections/#{@section.id}/assignments/#{@assignment.id}/submissions", { :controller => "submissions", :action => "create", :format => "json", :section_id => @section.id.to_s, :assignment_id => @assignment.id.to_s }, { :submission => { :submission_type => "online_url", :url => "www.example.com/a/b?q=1" } })
      @submission = @assignment.submissions.find_by_user_id(@user.id)
      @submission.should be_present
      @submission.url.should == 'http://www.example.com/a/b?q=1'
    end

    describe "valid submissions" do
      def do_submit(opts)
        json = api_call(:post, @url, @args, { :submission => opts })
        response['Location'].should == "http://www.example.com/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@user.id}"
        @submission = @assignment.submissions.find_by_user_id(@user.id)
        @submission.should be_present
        json.slice('user_id', 'assignment_id', 'score', 'grade').should == {
          'user_id' => @user.id,
          'assignment_id' => @assignment.id,
          'score' => nil,
          'grade' => nil,
        }
        json
      end

      it "should create a url submission" do
        json = do_submit(:submission_type => "online_url", :url => "www.example.com/a/b?q=1")
        @submission.url.should == 'http://www.example.com/a/b?q=1'
        json['url'].should == @submission.url
      end

      it "should create with an initial comment" do
        json = api_call(:post, @url, @args, { :comment => { :text_comment => "ohai teacher" }, :submission => { :submission_type => "online_url", :url => "http://www.example.com/a/b" } })
        @submission = @assignment.submissions.find_by_user_id(@user.id)
        @submission.submission_comments.size.should == 1
        @submission.submission_comments.first.attributes.slice('author_id', 'comment').should == {
          'author_id' => @user.id,
          'comment' => 'ohai teacher',
        }
        json['url'].should == "http://www.example.com/a/b"
      end

      it "should create a online text submission" do
        @assignment.update_attributes(:submission_types => 'online_text_entry')
        json = do_submit(:submission_type => 'online_text_entry', :body => %{<p>
          This is <i>some</i> text. The <script src='evil.com'></script> sanitization will take effect.
        </p>})
        json['body'].should == %{<p>
          This is <i>some</i> text. The  sanitization will take effect.
        </p>}
        json['body'].should == @submission.body
      end

      it "should process html content in body" do
        @assignment.update_attributes(:submission_types => 'online_text_entry')
        should_process_incoming_user_content(@course) do |content|
          do_submit(:submission_type => 'online_text_entry', :body => content)
          @submission.body
        end
      end

      it "should create a file upload submission" do
        @assignment.update_attributes(:submission_types => 'online_upload')
        a1 = attachment_model(:context => @user)
        a2 = attachment_model(:context => @user)
        json = do_submit(:submission_type => 'online_upload', :file_ids => [a1.id, a2.id])
        json['attachments'].map { |a| a['url'] }.should == [ file_download_url(a1, :verifier => a1.uuid, :download => '1', :download_frd => '1'), file_download_url(a2, :verifier => a2.uuid, :download => '1', :download_frd => '1') ]
      end

      it "should create a media comment submission" do
        @assignment.update_attributes(:submission_types => "media_recording")
        media_object(:media_id => "3232", :media_type => "audio")
        json = do_submit(:submission_type => "media_recording", :media_comment_id => "3232", :media_comment_type => "audio")
        json['media_comment'].slice('media_id', 'media_type').should == {
          'media_id' => '3232',
          'media_type' => 'audio',
        }
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

      it "should reject uploading files to other students' submissions" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student2.id}/files",
                        { :controller => "submissions_api", :action => "create_file", :format => "json", :course_id => @course.to_param, :assignment_id => @assignment.to_param, :user_id => @student2.to_param }, {}, {}, { :expected_status => 401 })
      end
    end

    it "should reject invalid urls" do
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "online_url", :url => "ftp://ftp.example.com/a/b" } }, {}, :expected_status => 400)
    end

    it "should reject attachment ids not belonging to the user" do
      @assignment.update_attributes(:submission_types => 'online_upload')
      a1 = attachment_model(:context => @course)
      json = api_call(:post, @url, @args, { :submission => { :submission_type => "online_upload", :file_ids => [a1.id] } }, {}, :expected_status => 400)
      json['message'].should == 'No valid file ids given'
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

    it "should not allow comments (teachers)" do
      @user = @teacher
      draft_assignment_update({ :comment => { :text_comment => 'Tacos are tasty' }})
    end

    it "should not allow comments (students)" do
      @user = @student
      draft_assignment_update({ :comment => { :text_comment => 'Tacos are tasty' }})
    end

    it "should not allow group comments (students)" do
      student2 = user(:active_all => true)
      @course.enroll_student(student2).accept!
      group_category = @course.group_categories.create(:name => "Category")
      @group = @course.groups.create(:name => "Group", :group_category => group_category, :context => @course)
      @group.users = [@student, student2]
      @a2 = @course.assignments.create!(:title => 'assignment1', :grading_type => 'points', :points_possible => 12, :group_category => group_category)
      draft_assignment_update({ :comment => { :text_comment => "HEY GIRL HEY!", :group_comment => "1" } })
    end

    it "should not allow grading with points" do
      @a2.grading_type = "points"
      @a2.points_possible = 15
      @a2.save!
      @user = @teacher
      grade = "13.2"
      draft_assignment_update({ :submission => { :posted_grade => grade }})
    end

    it "should not mark as complete for zero credit assignments" do
      @a2.grading_type = "pass_fail"
      @a2.points_possible = 0
      @a2.save!
      @user = @teacher
      grade = "pass"
      draft_assignment_update({ :submission => { :posted_grade => grade }})
    end

    # Give this a hash of items to update with the API call
    def draft_assignment_update(opts)
      json = raw_api_call(
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

end
