#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../lib/validates_as_url.rb')

describe Submission do
  before(:once) do
    course_with_student(active_all: true)
    @context = @course
    @assignment = @context.assignments.new(:title => "some assignment")
    @assignment.workflow_state = "published"
    @assignment.save
    @valid_attributes = {
      :assignment_id => @assignment.id,
      :user_id => @user.id,
      :grade => "1.5",
      :url => "www.instructure.com"
    }
  end

  it "should create a new instance given valid attributes" do
    Submission.create!(@valid_attributes)
  end

  include_examples "url validation tests"
  it "should check url validity" do
    test_url_validation(Submission.create!(@valid_attributes))
  end

  it "should add http:// to the body for long urls, too" do
    s = Submission.create!(@valid_attributes)
    expect(s.url).to eq 'http://www.instructure.com'

    long_url = ("a"*300 + ".com")
    s.url = long_url
    s.save!
    expect(s.url).to eq "http://#{long_url}"
    # make sure it adds the "http://" to the body for long urls, too
    expect(s.body).to eq "http://#{long_url}"
  end

  it "should offer the context, if one is available" do
    @course = Course.new
    @assignment = Assignment.new(:context => @course)
    @assignment.expects(:context).returns(@course)

    @submission = Submission.new
    expect{@submission.context}.not_to raise_error
    expect(@submission.context).to be_nil
    @submission.assignment = @assignment
    expect(@submission.context).to eql(@course)
  end

  it "should have an interesting state machine" do
    submission_spec_model
    expect(@submission.state).to eql(:submitted)
    @submission.grade_it
    expect(@submission.state).to eql(:graded)
  end

  it "should be versioned" do
    submission_spec_model
    expect(@submission).to be_respond_to(:versions)
  end

  it "should not save new versions by default" do
    submission_spec_model
    expect {
      @submission.save!
    }.not_to change(@submission.versions, :count)
  end

  describe "version indexing" do
    it "should create a SubmissionVersion when a new submission is created" do
      expect {
        submission_spec_model
      }.to change(SubmissionVersion, :count)
    end

    it "should create a SubmissionVersion when a new version is saved" do
      submission_spec_model
      expect {
        @submission.with_versioning(:explicit => true) { @submission.save }
      }.to change(SubmissionVersion, :count)
    end
  end

  it "should ensure the media object exists" do
    assignment_model
    se = @course.enroll_student(user)
    MediaObject.expects(:ensure_media_object).with("fake", { :context => se.user, :user => se.user })
    @submission = @assignment.submit_homework(se.user, :media_comment_id => "fake", :media_comment_type => "audio")
  end

  it "should log submissions with grade changes" do
    submission_spec_model

    Auditors::GradeChange.expects(:record).once

    @submission.score = 5
    @submission.save!

    @submission.grader_id = @user.id
    @submission.save!
  end

  it "should log excused submissions" do
    submission_spec_model

    Auditors::GradeChange.expects(:record).once

    @submission.excused = true
    @submission.save!

    @submission.grader_id = @user.id
    @submission.save!
  end

  context "#graded_anonymously" do
    it "saves when grade changed and set explicitly" do
      submission_spec_model
      expect(@submission.graded_anonymously).to be_falsey
      @submission.score = 42
      @submission.graded_anonymously = true
      @submission.save!
      expect(@submission.graded_anonymously).to be_truthy
      @submission.reload
      expect(@submission.graded_anonymously).to be_truthy
    end

    it "retains its value when grade does not change" do
      submission_spec_model(graded_anonymously: true, score: 3, grade: "3")
      @submission = Submission.find(@submission.id) # need new model object
      expect(@submission.graded_anonymously).to be_truthy
      @submission.body = 'test body'
      @submission.save!
      @submission.reload
      expect(@submission.graded_anonymously).to be_truthy
    end

    it "resets when grade changed and not set explicitly" do
      submission_spec_model(graded_anonymously: true, score: 3, grade: "3")
      @submission = Submission.find(@submission.id) # need new model object
      expect(@submission.graded_anonymously).to be_truthy
      @submission.score = 42
      @submission.save!
      @submission.reload
      expect(@submission.graded_anonymously).to be_falsey
    end
  end

  context "Discussion Topic" do
    it "should use correct date for its submitted_at value" do
      course_with_student_logged_in(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "some topic")
      @assignment = @course.assignments.create(:title => "some discussion assignment")
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!
      @entry1 = @topic.discussion_entries.create(:message => "first entry", :user => @user)
      @topic.assignment_id = @assignment.id
      @topic.save!
      @submission = @assignment.submissions.where(:user_id => @entry1.user_id).first
      new_time = Time.now + 30.minutes
      Time.stubs(:now).returns(new_time)
      @entry2 = @topic.discussion_entries.create(:message => "second entry", :user => @user)
      @submission.reload
      expect((@submission.submitted_at.to_i - @submission.created_at.to_i).abs).to be < 1.minute
    end

    it "should not create multiple versions on submission for discussion topics" do
      course_with_student_logged_in(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "some topic")
      @assignment = @course.assignments.create(:title => "some discussion assignment")
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!
      @topic.assignment_id = @assignment.id
      @topic.save!

      Timecop.freeze(1.second.ago) do
        @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
      end
      @assignment.submit_homework(@student, :submission_type => 'discussion_topic')
      expect(@student.submissions.first.submission_history.count).to eq 1
    end
  end

  context "broadcast policy" do
    context "Submission Notifications" do
      before :once do
        Notification.create(:name => 'Assignment Submitted')
        Notification.create(:name => 'Assignment Resubmitted')
        Notification.create(:name => 'Assignment Submitted Late')
        Notification.create(:name => 'Group Assignment Submitted Late')

        course_with_teacher(course: @course, active_all: true)
      end

      it "should send the correct message when an assignment is turned in on-time" do
        @assignment.workflow_state = "published"
        @assignment.update_attributes(:due_at => Time.now + 1000)

        submission_spec_model(:user => @student)
        expect(@submission.messages_sent.keys).to eq ['Assignment Submitted']
      end

      it "should send the correct message when an assignment is turned in late" do
        @assignment.workflow_state = "published"
        @assignment.update_attributes(:due_at => Time.now - 1000)

        submission_spec_model(:user => @student)
        expect(@submission.messages_sent.keys).to eq ['Assignment Submitted Late']
      end

      it "should send the correct message when an assignment is resubmitted on-time" do
        @assignment.submission_types = ['online_text_entry']
        @assignment.due_at = Time.now + 1000
        @assignment.save!

        @assignment.submit_homework(@student, :body => "lol")
        resubmission = @assignment.submit_homework(@student, :body => "frd")
        expect(resubmission.messages_sent.keys).to eq ['Assignment Resubmitted']
      end

      it "should send the correct message when an assignment is resubmitted late" do
        @assignment.submission_types = ['online_text_entry']
        @assignment.due_at = Time.now - 1000
        @assignment.save!

        @assignment.submit_homework(@student, :body => "lol")
        resubmission = @assignment.submit_homework(@student, :body => "frd")
        expect(resubmission.messages_sent.keys).to eq ['Assignment Submitted Late']
      end

      it "should send the correct message when a group assignment is submitted late" do
        @a = assignment_model(:course => @context, :group_category => "Study Groups", :due_at => Time.now - 1000, :submission_types => ["online_text_entry"])
        @group1 = @a.context.groups.create!(:name => "Study Group 1", :group_category => @a.group_category)
        @group1.add_user(@student)
        submission = @a.submit_homework @student, :submission_type => "online_text_entry", :body => "blah"

        expect(submission.messages_sent.keys).to eq ['Group Assignment Submitted Late']
      end
    end

    context "Submission Graded" do
      before :once do
        Notification.create(:name => 'Submission Graded', :category => 'TestImmediately')
      end

      it "should create a message when the assignment has been graded and published" do
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to eql(:published)
        @submission.grade_it!
        expect(@submission.messages_sent).to be_include('Submission Graded')
      end

      it "should not create a message for a soft-concluded student" do
        submission_spec_model
        @course.start_at = 2.weeks.ago
        @course.conclude_at = 1.weeks.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        @cc = @user.communication_channels.create(:path => "somewhere")
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to eql(:published)
        @submission.grade_it!
        expect(@submission.messages_sent).to_not be_include('Submission Graded')
      end

      it "notifies observers" do
        submission_spec_model
        course_with_observer(course: @course, associated_user_id: @user.id, active_all: true, active_cc: true)
        @submission.grade_it!
        expect(@observer.email_channel.messages.length).to eq 1
      end

      it "should not create a message when a muted assignment has been graded and published" do
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @assignment.mute!
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to eql(:published)
        @submission.grade_it!
        expect(@submission.messages_sent).not_to be_include "Submission Graded"
      end

      it "should not create a message when this is a quiz submission" do
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @quiz = Quizzes::Quiz.create!(:context => @course)
        @submission.quiz_submission = @quiz.generate_submission(@user)
        @submission.save!
        @submission.reload
        expect(@submission.assignment).to eql(@assignment)
        expect(@submission.assignment.state).to eql(:published)
        @submission.grade_it!
        expect(@submission.messages_sent).not_to include('Submission Graded')
      end

      it "should create a hidden stream_item_instance when muted, graded, and published" do
        submission_spec_model
        @cc = @user.communication_channels.create :path => "somewhere"
        @assignment.mute!
        expect {
          @submission = @assignment.grade_student(@user, :grade => 10)[0]
        }.to change StreamItemInstance, :count
        expect(@user.stream_item_instances.last).to be_hidden
      end

      it "should hide any existing stream_item_instances when muted" do
        submission_spec_model
        @cc = @user.communication_channels.create :path => "somewhere"
        expect {
          @submission = @assignment.grade_student(@user, :grade => 10)[0]
        }.to change StreamItemInstance, :count
        expect(@user.stream_item_instances.last).not_to be_hidden
        @assignment.mute!
        expect(@user.stream_item_instances.last).to be_hidden
      end

      it "should not create a message for admins and teachers with quiz submissions" do
        course_with_teacher(:active_all => true)
        assignment = @course.assignments.create!(
          :title => 'assignment',
          :points_possible => 10)
        quiz       = @course.quizzes.build(
          :assignment_id   => assignment.id,
          :title           => 'test quiz',
          :points_possible => 10)
        quiz.workflow_state = 'available'
        quiz.save!

        user       = account_admin_user
        channel    = user.communication_channels.create!(:path => 'admin@example.com')
        submission = quiz.generate_submission(user, false)
        Quizzes::SubmissionGrader.new(submission).grade_submission

        channel2   = @teacher.communication_channels.create!(:path => 'chang@example.com')
        submission2 = quiz.generate_submission(@teacher, false)
        Quizzes::SubmissionGrader.new(submission2).grade_submission

        expect(submission.submission.messages_sent).not_to be_include('Submission Graded')
        expect(submission2.submission.messages_sent).not_to be_include('Submission Graded')
      end
    end

    it "should create a stream_item_instance when graded and published" do
      Notification.create :name => "Submission Graded"
      submission_spec_model
      @cc = @user.communication_channels.create :path => "somewhere"
      expect {
        @assignment.grade_student(@user, :grade => 10)
      }.to change StreamItemInstance, :count
    end

    it "should create a stream_item_instance when graded, and then made it visible when unmuted" do
      Notification.create :name => "Submission Graded"
      submission_spec_model
      @cc = @user.communication_channels.create :path => "somewhere"
      @assignment.mute!
      expect {
        @assignment.grade_student(@user, :grade => 10)
      }.to change StreamItemInstance, :count

      @assignment.unmute!
      stream_item_ids       = StreamItem.where(:asset_type => 'Submission', :asset_id => @assignment.submissions.all).pluck(:id)
      stream_item_instances = StreamItemInstance.where(:stream_item_id => stream_item_ids)
      stream_item_instances.each { |sii| expect(sii).not_to be_hidden }
    end


    context "Submission Grade Changed" do
      it "should create a message when the score is changed and the grades were already published" do
        Notification.create(:name => 'Submission Grade Changed')
        @assignment.stubs(:score_to_grade).returns("10.0")
        @assignment.stubs(:due_at).returns(Time.now  - 100)
        submission_spec_model

        @cc = @user.communication_channels.create(:path => "somewhere")
        s = @assignment.grade_student(@user, :grade => 10)[0] #@submission
        s.graded_at = Time.parse("Jan 1 2000")
        s.save
        @submission = @assignment.grade_student(@user, :grade => 9)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).to be_include('Submission Grade Changed')
      end

      it 'doesnt create a grade changed message when theres a quiz attached' do
        Notification.create(:name => 'Submission Grade Changed')
        @assignment.stubs(:score_to_grade).returns("10.0")
        @assignment.stubs(:due_at).returns(Time.now  - 100)
        submission_spec_model
        @quiz = Quizzes::Quiz.create!(:context => @course)
        @submission.quiz_submission = @quiz.generate_submission(@user)
        @submission.save!
        @cc = @user.communication_channels.create(:path => "somewhere")
        s = @assignment.grade_student(@user, :grade => 10)[0] #@submission
        s.graded_at = Time.parse("Jan 1 2000")
        s.save
        @submission = @assignment.grade_student(@user, :grade => 9)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).not_to include('Submission Grade Changed')
      end

      it "should create a message when the score is changed and the grades were already published" do
        Notification.create(:name => 'Submission Grade Changed')
        Notification.create(:name => 'Submission Graded')
        @assignment.stubs(:score_to_grade).returns("10.0")
        @assignment.stubs(:due_at).returns(Time.now  - 100)
        submission_spec_model

        @cc = @user.communication_channels.create(:path => "somewhere")
        s = @assignment.grade_student(@user, :grade => 10)[0] #@submission
        @submission = @assignment.grade_student(@user, :grade => 9)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).not_to be_include('Submission Grade Changed')
        expect(@submission.messages_sent).to be_include('Submission Graded')
      end

      it "should not create a message when the score is changed and the grades were already published for a muted assignment" do
        Notification.create(:name => 'Submission Grade Changed')
        @assignment.mute!
        @assignment.stubs(:score_to_grade).returns("10.0")
        @assignment.stubs(:due_at).returns(Time.now  - 100)
        submission_spec_model

        @cc = @user.communication_channels.create(:path => "somewhere")
        s = @assignment.grade_student(@user, :grade => 10)[0] #@submission
        s.graded_at = Time.parse("Jan 1 2000")
        s.save
        @submission = @assignment.grade_student(@user, :grade => 9)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).not_to be_include('Submission Grade Changed')

      end

      it "should NOT create a message when the score is changed and the submission was recently graded" do
        Notification.create(:name => 'Submission Grade Changed')
        @assignment.stubs(:score_to_grade).returns("10.0")
        @assignment.stubs(:due_at).returns(Time.now  - 100)
        submission_spec_model

        @cc = @user.communication_channels.create(:path => "somewhere")
        s = @assignment.grade_student(@user, :grade => 10)[0] #@submission
        @submission = @assignment.grade_student(@user, :grade => 9)[0]
        expect(@submission).to eql(s)
        expect(@submission.messages_sent).not_to be_include('Submission Grade Changed')
      end
    end
  end

  context "turnitin" do

    context "Turnitin LTI" do
      let(:lti_tii_data) do
        {
            "attachment_42" => {
                :status => "error",
                :outcome_response => {
                    "outcomes_tool_placement_url" => "https://api.turnitin.com/api/lti/1p0/invalid?lang=en_us",
                    "paperid" => "607954245",
                    "lis_result_sourcedid" => "10-5-42-8-invalid"
                },
                :public_error_message => "Turnitin has not returned a score after 11 attempts to retrieve one."
            }
        }
      end

      let(:submission) { Submission.new }

      describe "#turnitinable_by_lti?" do
        it 'returns true if there is an associated lti tool and data stored' do
          submission.turnitin_data = lti_tii_data
          expect(submission.turnitinable_by_lti?).to be true
        end
      end

      describe "#resubmit_lti_tii" do
        let(:tool) do
          @course.context_external_tools.create(
              name: "a",
              consumer_key: '12345',
              shared_secret: 'secret',
              url: 'http://example.com/launch')
        end

        it 'resubmits errored tii attachments' do
          a = @course.assignments.create!(title: "test",
                                          submission_types: 'external_tool',
                                          external_tool_tag_attributes: {url: tool.url})
          submission.assignment = a
          submission.turnitin_data = lti_tii_data
          submission.user = @user
          outcome_response_processor_mock = mock('outcome_response_processor')
          outcome_response_processor_mock.expects(:resubmit).with(submission, "attachment_42")
          Turnitin::OutcomeResponseProcessor.stubs(:new).returns(outcome_response_processor_mock)
          submission.retrieve_lti_tii_score
        end
      end
    end

    context "submission" do
      def init_turnitin_api
        @turnitin_api = Turnitin::Client.new('test_account', 'sekret')
        @submission.context.expects(:turnitin_settings).at_least(1).returns([:placeholder])
        Turnitin::Client.expects(:new).at_least(1).with(:placeholder).returns(@turnitin_api)
      end

      before(:once) do
        @assignment.submission_types = "online_upload,online_text_entry"
        @assignment.turnitin_enabled = true
        @assignment.turnitin_settings = @assignment.turnitin_settings
        @assignment.save!
        @submission = @assignment.submit_homework(@user, { :body => "hello there", :submission_type => 'online_text_entry' })
      end

      it "should submit to turnitin after a delay" do
        job = Delayed::Job.list_jobs(:future, 100).find { |j| j.tag == 'Submission#submit_to_turnitin' }
        expect(job).not_to be_nil
        expect(job.run_at).to be > Time.now.utc
      end

      it "should initially set turnitin submission to pending" do
        init_turnitin_api
        @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).returns({ :assignment_id => "1234" })
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(stub(:success? => true))
        @turnitin_api.expects(:submitPaper).returns({
          @submission.asset_string => {
            :object_id => '12345'
          }
        })
        @submission.submit_to_turnitin
        expect(@submission.reload.turnitin_data[@submission.asset_string][:status]).to eq 'pending'
      end

      it "should schedule a retry if something fails initially" do
        init_turnitin_api
        @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).returns({ :assignment_id => "1234" })
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(stub(:success? => false))
        @submission.submit_to_turnitin
        expect(Delayed::Job.list_jobs(:future, 100).find_all { |j| j.tag == 'Submission#submit_to_turnitin' }.size).to eq 2
      end

      it "should set status as failed if something fails after several attempts" do
        init_turnitin_api
        @assignment.expects(:create_in_turnitin).returns(false)
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(stub(:success? => false, :error? => true, :error_hash => {}))
        @turnitin_api.expects(:submitPaper).never
        @submission.submit_to_turnitin(Submission::TURNITIN_RETRY)
        expect(@submission.reload.turnitin_data[:status]).to eq 'error'
      end

      it "should set status back to pending on retry" do
        init_turnitin_api
        # first a submission, to get us into failed state
        @assignment.expects(:create_in_turnitin).returns(false)
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(stub(:success? => false, :error? => true, :error_hash => {}))
        @turnitin_api.expects(:submitPaper).never
        @submission.submit_to_turnitin(Submission::TURNITIN_RETRY)
        expect(@submission.reload.turnitin_data[:status]).to eq 'error'

        # resubmit
        @submission.resubmit_to_turnitin
        expect(@submission.reload.turnitin_data[:status]).to be_nil
        expect(@submission.turnitin_data[@submission.asset_string][:status]).to eq 'pending'
      end

      it "should set status to scored on success" do
        init_turnitin_api
        @submission.turnitin_data ||= {}
        @submission.turnitin_data[@submission.asset_string] = { :object_id => '1234', :status => 'pending' }
        @turnitin_api.expects(:generateReport).with(@submission, @submission.asset_string).returns({
          :similarity_score => 56,
          :web_overlap => 22,
          :publication_overlap => 0,
          :student_overlap => 33
        })

        @submission.check_turnitin_status
        expect(@submission.reload.turnitin_data[@submission.asset_string][:status]).to eq 'scored'
      end

      it "should set status as failed if something fails after several attempts" do
        init_turnitin_api
        @submission.turnitin_data ||= {}
        @submission.turnitin_data[@submission.asset_string] = { :object_id => '1234', :status => 'pending' }
        @turnitin_api.expects(:generateReport).with(@submission, @submission.asset_string).returns({})

        expects_job_with_tag('Submission#check_turnitin_status') do
          @submission.check_turnitin_status(Submission::TURNITIN_STATUS_RETRY-1)
          expect(@submission.reload.turnitin_data[@submission.asset_string][:status]).to eq 'pending'
        end

        @submission.check_turnitin_status(Submission::TURNITIN_STATUS_RETRY)
        @submission.reload
        updated_data = @submission.turnitin_data[@submission.asset_string]
        expect(updated_data[:status]).to eq 'error'
      end

      it "should check status for all assets" do
        init_turnitin_api
        @submission.turnitin_data ||= {}
        @submission.turnitin_data[@submission.asset_string] = { :object_id => '1234', :status => 'pending' }
        @submission.turnitin_data["other_asset"] = { :object_id => 'xxyy', :status => 'pending' }
        @turnitin_api.expects(:generateReport).with(@submission, @submission.asset_string).returns({
          :similarity_score => 56, :web_overlap => 22, :publication_overlap => 0, :student_overlap => 33
        })
        @turnitin_api.expects(:generateReport).with(@submission, "other_asset").returns({ :similarity_score => 20 })

        @submission.check_turnitin_status
        @submission.reload
        expect(@submission.turnitin_data[@submission.asset_string][:status]).to eq 'scored'
        expect(@submission.turnitin_data["other_asset"][:status]).to eq 'scored'
      end

      it "should not blow up if submission_type has changed when job runs" do
        @submission.submission_type = 'online_url'
        @submission.context.expects(:turnitin_settings).never
        expect { @submission.submit_to_turnitin }.not_to raise_error
      end
    end

    describe "group" do
      before(:once) do
        @teacher = User.create(:name => "some teacher")
        @student = User.create(:name => "a student")
        @student1 = User.create(:name => "student 1")
        @context.enroll_teacher(@teacher)
        @context.enroll_student(@student)
        @context.enroll_student(@student1)

        @a = assignment_model(:course => @context, :group_category => "Study Groups")
        @a.submission_types = "online_upload,online_text_entry"
        @a.turnitin_enabled = true
        @a.save!

        @group1 = @a.context.groups.create!(:name => "Study Group 1", :group_category => @a.group_category)
        @group1.add_user(@student)
        @group1.add_user(@student1)
      end

      it "should submit to turnitin for the original submitter" do
        submission = @a.submit_homework @student, :submission_type => "online_text_entry", :body => "blah"
        Submission.where(assignment_id: @a).each do |s|
          if s.id == submission.id
            expect(s.turnitin_data[:last_processed_attempt]).to be > 0
          else
            expect(s.turnitin_data).to eq({})
          end
        end
      end

    end

    context "report" do
      before :once do
        @assignment.submission_types = "online_upload,online_text_entry"
        @assignment.turnitin_enabled = true
        @assignment.turnitin_settings = @assignment.turnitin_settings
        @assignment.save!
        @submission = @assignment.submit_homework(@user, { :body => "hello there", :submission_type => 'online_text_entry' })
        @submission.turnitin_data = {
          "submission_#{@submission.id}" => {
            :web_overlap => 92,
            :error => true,
            :publication_overlap => 0,
            :state => "failure",
            :object_id => "123456789",
            :student_overlap => 90,
            :similarity_score => 92
          }
        }
        @submission.save!
      end

      before :each do
        api = Turnitin::Client.new('test_account', 'sekret')
        Turnitin::Client.expects(:new).at_least(1).returns(api)
        api.expects(:sendRequest).with(:generate_report, 1, has_entries(:oid => "123456789")).at_least(1).returns('http://foo.bar')
      end

      it "should let teachers view the turnitin report" do
        @teacher = User.create
        @context.enroll_teacher(@teacher)
        expect(@submission).to be_grants_right(@teacher, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @teacher)).not_to be_nil
      end

      it "should let students view the turnitin report after grading" do
        @assignment.turnitin_settings[:originality_report_visibility] = 'after_grading'
        @assignment.save!
        @submission.reload

        expect(@submission).not_to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).to be_nil

        @submission.score = 1
        @submission.grade_it!
        AdheresToPolicy::Cache.clear

        expect(@submission).to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).not_to be_nil
      end

      it "should let students view the turnitin report immediately if the visibility setting allows it" do
        @assignment.turnitin_settings[:originality_report_visibility] = 'after_grading'
        @assignment.save
        @submission.reload

        expect(@submission).not_to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).to be_nil

        @assignment.turnitin_settings[:originality_report_visibility] = 'immediate'
        @assignment.save
        @submission.reload
        AdheresToPolicy::Cache.clear

        expect(@submission).to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).not_to be_nil
      end

      it "should let students view the turnitin report after the due date if the visibility setting allows it" do
        @assignment.turnitin_settings[:originality_report_visibility] = 'after_due_date'
        @assignment.due_at = Time.now + 1.day
        @assignment.save
        @submission.reload

        expect(@submission).not_to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).to be_nil

        @assignment.due_at = Time.now - 1.day
        @assignment.save
        @submission.reload
        AdheresToPolicy::Cache.clear

        expect(@submission).to be_grants_right(@user, nil, :view_turnitin_report)
        expect(@submission.turnitin_report_url("submission_#{@submission.id}", @user)).not_to be_nil
      end
    end
  end

  context '#external_tool_url' do
    let(:submission) { Submission.new }
    let(:lti_submission) { @assignment.submit_homework @user, submission_type: 'basic_lti_launch', url: 'http://www.example.com' }
    context 'submission_type of "basic_lti_launch"' do
      it 'returns a url containing the submitted url' do
        expect(lti_submission.external_tool_url).to eq(lti_submission.url)
      end
    end

    context 'submission_type of anything other than "basic_lti_launch"' do
      it 'returns nothing' do
        expect(submission.external_tool_url).to be_nil
      end
    end
  end

  it "should return the correct quiz_submission_version" do
    # see redmine #6048

    # set up the data to have a submission with a quiz submission with multiple versions
    course
    quiz = @course.quizzes.create!
    quiz_submission = quiz.generate_submission @user, false
    quiz_submission.save

    submission = Submission.create!({
      :assignment_id => @assignment.id,
      :user_id => @user.id,
      :quiz_submission_id => quiz_submission.id
    })

    submission = @assignment.submit_homework @user, :submission_type => 'online_quiz'
    submission.quiz_submission_id = quiz_submission.id

    # set the microseconds of the submission.submitted_at to be less than the
    # quiz_submission.finished_at.

    # first set them to be exactly the same (with microseconds)
    time_to_i = submission.submitted_at.to_i
    usec = submission.submitted_at.usec
    timestamp = "#{time_to_i}.#{usec}".to_f

    quiz_submission.finished_at = Time.at(timestamp)
    quiz_submission.save

    # get the data in a strange state where the quiz_submission.finished_at is
    # microseconds older than the submission (caused the bug in #6048)
    quiz_submission.finished_at = Time.at(timestamp + 0.00001)
    quiz_submission.save

    # verify the data is weird, to_i says they are equal, but the usecs are off
    expect(quiz_submission.finished_at.to_i).to eq submission.submitted_at.to_i
    expect(quiz_submission.finished_at.usec).to be > submission.submitted_at.usec

    # create the versions that Submission#quiz_submission_version uses
    quiz_submission.with_versioning do
      quiz_submission.save
      quiz_submission.save
    end

    # the real test, quiz_submission_version shouldn't care about usecs
    expect(submission.reload.quiz_submission_version).to eq 2
  end

  it "should return only comments readable by the user" do
    course_with_teacher(:active_all => true)
    @student1 = student_in_course(:active_user => true).user
    @student2 = student_in_course(:active_user => true).user

    @assignment = @course.assignments.new(:title => "some assignment")
    @assignment.submission_types = "online_text_entry"
    @assignment.workflow_state = "published"
    @assignment.save

    @submission = @assignment.submit_homework(@student1, :body => 'some message')
    sc1 = SubmissionComment.create!(:submission => @submission, :author => @teacher, :comment => "a")
    sc2 = SubmissionComment.create!(:submission => @submission, :author => @teacher, :comment => "b", :hidden => true)
    sc3 = SubmissionComment.create!(:submission => @submission, :author => @student1, :comment => "c")
    sc4 = SubmissionComment.create!(:submission => @submission, :author => @student2, :comment => "d")
    @submission.reload

    @submission.limit_comments(@teacher)
    expect(@submission.submission_comments.count).to eql 4
    expect(@submission.visible_submission_comments.count).to eql 3

    @submission.limit_comments(@student1)
    expect(@submission.submission_comments.count).to eql 3
    expect(@submission.visible_submission_comments.count).to eql 3

    @submission.limit_comments(@student2)
    expect(@submission.submission_comments.count).to eql 1
    expect(@submission.visible_submission_comments.count).to eql 1
  end

  describe "read/unread state" do
    it "should be read if a submission exists with no grade" do
      @submission = @assignment.submit_homework(@user)
      expect(@submission.read?(@user)).to be_truthy
    end

    it "should be unread after assignment is graded" do
      @submission = @assignment.grade_student(@user, { :grade => 3 }).first
      expect(@submission.unread?(@user)).to be_truthy
    end

    it "should be unread after submission is graded" do
      @assignment.submit_homework(@user)
      @submission = @assignment.grade_student(@user, { :grade => 3 }).first
      expect(@submission.unread?(@user)).to be_truthy
    end

    it "should be unread after submission is commented on by teacher" do
      @student = @user
      course_with_teacher(:course => @context, :active_all => true)
      @submission = @assignment.update_submission(@student, { :commenter => @teacher, :comment => "good!" }).first
      expect(@submission.unread?(@user)).to be_truthy
    end

    it "should be read if other submission fields change" do
      @submission = @assignment.submit_homework(@user)
      @submission.workflow_state = 'graded'
      @submission.graded_at = Time.now
      @submission.save!
      expect(@submission.read?(@user)).to be_truthy
    end
  end

  describe "mute" do
    let(:submission) { Submission.new }

    before :each do
      submission.published_score = 100
      submission.published_grade = 'A'
      submission.graded_at = Time.now
      submission.grade = 'B'
      submission.score = 90
      submission.mute
    end

    specify { expect(submission.published_score).to be_nil }
    specify { expect(submission.published_grade).to be_nil }
    specify { expect(submission.graded_at).to be_nil }
    specify { expect(submission.grade).to be_nil }
    specify { expect(submission.score).to be_nil }
  end

  describe "muted_assignment?" do
    it "returns true if assignment is muted" do
      assignment = stub(:muted? => true)
      @submission = Submission.new
      @submission.expects(:assignment).returns(assignment)
      expect(@submission.muted_assignment?).to eq true
    end

    it "returns false if assignment is not muted" do
      assignment = stub(:muted? => false)
      @submission = Submission.new
      @submission.expects(:assignment).returns(assignment)
      expect(@submission.muted_assignment?).to eq false
    end
  end

  describe "without_graded_submission?" do
    let(:submission) { Submission.new }

    it "returns false if submission does not has_submission?" do
      submission.stubs(:has_submission?).returns false
      submission.stubs(:graded?).returns true
      expect(submission.without_graded_submission?).to eq false
    end

    it "returns false if submission does is not graded" do
      submission.stubs(:has_submission?).returns true
      submission.stubs(:graded?).returns false
      expect(submission.without_graded_submission?).to eq false
    end

    it "returns true if submission is not graded and has no submission" do
      submission.stubs(:has_submission?).returns false
      submission.stubs(:graded?).returns false
      expect(submission.without_graded_submission?).to eq true
    end
  end

  describe "graded?" do
    it "is false before graded" do
      submission, _ = @assignment.find_or_create_submission(@user)
      expect(submission).to_not be_graded
    end

    it "is true for graded assignments" do
      submission, _ = @assignment.grade_student(@user, grade: 1)
      expect(submission).to be_graded
    end

    it "is also true for excused assignments" do
      submission, _ = @assignment.find_or_create_submission(@user)
      submission.excused = true
      expect(submission).to be_graded
    end
  end

  describe "autograded" do
    let(:submission) { Submission.new }

    it "returns false when its not autograded" do
      submission = Submission.new
      expect(submission).to_not be_autograded

      submission.grader_id = Shard.global_id_for(@user.id)
      expect(submission).to_not be_autograded
    end

    it "returns true when its autograded" do
      submission = Submission.new
      submission.grader_id = -1
      expect(submission).to be_autograded
    end
  end

  describe "past_due" do
    before :once do
      submission_spec_model
      @submission1 = @submission

      add_section('overridden section')
      u2 = student_in_section(@course_section, :active_all => true)
      submission_spec_model(:user => u2)
      @submission2 = @submission

      @assignment.update_attribute(:due_at, Time.zone.now - 1.day)
      @submission1.reload
      @submission2.reload
    end

    it "should update when an assignment's due date is changed" do
      expect(@submission1).to be_past_due
      @assignment.reload.update_attribute(:due_at, Time.zone.now + 1.day)
      expect(@submission1.reload).not_to be_past_due
    end

    it "should update when an applicable override is changed" do
      expect(@submission1).to be_past_due
      expect(@submission2).to be_past_due

      assignment_override_model :assignment => @assignment,
                                :due_at => Time.zone.now + 1.day,
                                :set => @course_section
      expect(@submission1.reload).to be_past_due
      expect(@submission2.reload).not_to be_past_due
    end

    it "should give a quiz submission 30 extra seconds before making it past due" do
      quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}}]) do
        {
          "text_after_answers"            => "",
          "question_#{@questions[0].id}"  => "<p>Lorem ipsum answer.</p>",
          "context_id"                    => "#{@course.id}",
          "context_type"                  => "Course",
          "user_id"                       => "#{@user.id}",
          "quiz_id"                       => "#{@quiz.id}",
          "course_id"                     => "#{@course.id}",
          "question_text"                 => "Lorem ipsum question",
        }
      end
      @assignment.due_at = "20130101T23:59Z"
      @assignment.save!

      submission = @quiz_submission.submission.reload
      submission.write_attribute(:submitted_at, @assignment.due_at + 3.days)
      expect(submission).to be_past_due

      submission.write_attribute(:submitted_at, @assignment.due_at + 30.seconds)
      expect(submission).not_to be_past_due
    end
  end

  describe "late" do
    before :once do
      submission_spec_model
    end

    it "should be false if not past due" do
      @submission.submitted_at = 2.days.ago
      @submission.cached_due_date = 1.day.ago
      expect(@submission).not_to be_late
    end

    it "should be false if not submitted, even if past due" do
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago
      expect(@submission).not_to be_late
    end

    it "should be true if submitted and past due" do
      @submission.submitted_at = 1.day.ago
      @submission.cached_due_date = 2.days.ago
      expect(@submission).to be_late
    end
  end

  describe "missing" do
    before :once do
      submission_spec_model
    end

    it "should be false if not past due" do
      @submission.submitted_at = 2.days.ago
      @submission.cached_due_date = 1.day.ago
      expect(@submission).not_to be_missing
    end

    it "should be false if submitted, even if past due" do
      @submission.submitted_at = 1.day.ago
      @submission.cached_due_date = 2.days.ago
      expect(@submission).not_to be_missing
    end

    it "should be true if not submitted, past due, and expects a submission" do
      @submission.assignment.submission_types = "online_quiz"
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago

      # Regardless of score
      @submission.score = 0.00000001
      @submission.graded_at = Time.zone.now + 1.day

      expect(@submission).to be_missing
    end

    it "should be true if not submitted, score of zero, and does not expect a submission" do
      @submission.assignment.submission_types = "on_paper"
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago
      @submission.score = 0
      @submission.graded_at = Time.zone.now + 1.day
      expect(@submission).to be_missing
    end

    it "should be false if not submitted, score greater than zero, and does not expect a submission" do
      @submission.assignment.submission_types = "on_paper"
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago
      @submission.score = 0.00000001
      @submission.graded_at = Time.zone.now + 1.day
      expect(@submission).to be_missing
    end
  end

  describe "cached_due_date" do
    it "should get initialized during submission creation" do
      # create an invited user, so that the submission is not automatically
      # created by the DueDateCacher
      student_in_course
      @assignment.update_attribute(:due_at, Time.zone.now - 1.day)

      override = @assignment.assignment_overrides.build
      override.title = "Some Title"
      override.set = @course.default_section
      override.override_due_at(Time.zone.now + 1.day)
      override.save!
      # mysql just truncated the timestamp
      override.reload

      submission = @assignment.submissions.create(:user => @user)
      expect(submission.cached_due_date).to eq override.due_at
    end
  end

  describe "update_attachment_associations" do
    before do
      course_with_student active_all: true
      @assignment = @course.assignments.create!
    end

    it "doesn't include random attachment ids" do
      f = Attachment.create! uploaded_data: StringIO.new('blah'),
        context: @course,
        filename: 'blah.txt'
      sub = @assignment.submit_homework(@user, attachments: [f])
      expect(sub.attachments).to eq []
    end
  end

  describe "versioned_attachments" do
    it "should include user attachments" do
      student_in_course(active_all: true)
      att = attachment_model(filename: "submission.doc", :context => @student)
      sub = @assignment.submit_homework(@student, attachments: [att])
      expect(sub.versioned_attachments).to eq [att]
    end

    it "should not include attachments with a context of Submission" do
      student_in_course(active_all: true)
      att = attachment_model(filename: "submission.doc", :context => @student)
      sub = @assignment.submit_homework(@student, attachments: [att])
      sub.attachments.update_all(:context_type => "Submission", :context_id => sub.id)
      expect(sub.reload.versioned_attachments).to be_empty
    end
  end

  describe "includes_attachment?" do
    it "includes current attachments" do
      spoiler = attachment_model(context: @student)
      attachment_model context: @student
      sub = @assignment.submit_homework @student, attachments: [@attachment]
      expect(sub.attachments).to eq([@attachment])
      expect(sub.includes_attachment?(spoiler)).to eq false
      expect(sub.includes_attachment?(@attachment)).to eq true
    end

    it "includes attachments to previous versions" do
      old_attachment_1 = attachment_model(context: @student)
      old_attachment_2 = attachment_model(context: @student)
      sub = @assignment.submit_homework @student, attachments: [old_attachment_1, old_attachment_2]
      attachment_model context: @student
      sub = @assignment.submit_homework @student, attachments: [@attachment]
      expect(sub.attachments).to eq([@attachment])
      expect(sub.includes_attachment?(old_attachment_1)).to eq true
      expect(sub.includes_attachment?(old_attachment_2)).to eq true
    end
  end

  context "bulk loading" do
    def ensure_attachments_arent_queried
      Attachment.expects(:where).never
    end

    def submission_for_some_user
      student_in_course active_all: true
      @assignment.submit_homework(@student,
                                  submission_type: "online_url",
                                  url: "http://example.com")
    end

    describe "#bulk_load_versioned_attachments" do
      it "loads attachments for many submissions at once" do
        attachments = []

        submissions = 3.times.map do |i|
          student_in_course(active_all: true)
          attachments << [
                          attachment_model(filename: "submission#{i}-a.doc", :context => @student),
                          attachment_model(filename: "submission#{i}-b.doc", :context => @student)
                         ]

          @assignment.submit_homework @student, attachments: attachments[i]
        end

        Submission.bulk_load_versioned_attachments(submissions)
        ensure_attachments_arent_queried
        submissions.each_with_index do |s, i|
          expect(s.versioned_attachments).to eq attachments[i]
        end
      end

      it "includes url submission attachments" do
        s = submission_for_some_user
        s.attachment = attachment_model(filename: "screenshot.jpg",
                                        context: @student)

        Submission.bulk_load_versioned_attachments([s])
        ensure_attachments_arent_queried
        expect(s.versioned_attachments).to eq [s.attachment]
      end

      it "handles bad data" do
        s = submission_for_some_user
        s.update_attribute(:attachment_ids, '99999999')
        Submission.bulk_load_versioned_attachments([s])
        expect(s.versioned_attachments).to eq []
      end

      it "handles submission histories with different attachments" do
        student_in_course(active_all: true)
        attachments = [attachment_model(filename: "submission-a.doc", :context => @student)]
        Timecop.freeze(10.second.ago) do
          @assignment.submit_homework(@student, submission_type: 'online_upload',
                                      attachments: [attachments[0]])
        end

        attachments << attachment_model(filename: "submission-b.doc", :context => @student)
        Timecop.freeze(5.second.ago) do
          @assignment.submit_homework @student, attachments: [attachments[1]]
        end

        attachments << attachment_model(filename: "submission-c.doc", :context => @student)
        Timecop.freeze(1.second.ago) do
          @assignment.submit_homework @student, attachments: [attachments[2]]
        end

        submission = @assignment.submission_for_student(@student)
        Submission.bulk_load_versioned_attachments(submission.submission_history)

        submission.submission_history.each_with_index do |s, index|
          expect(s.attachment_ids.to_i).to eq attachments[index].id
        end
      end
    end

    describe "#bulk_load_attachments_for_submissions" do
      it "loads attachments for many submissions at once and returns a hash" do
        expected_attachments_for_submissions = {}

        submissions = 3.times.map do |i|
          student_in_course(active_all: true)
          attachment = [attachment_model(filename: "submission#{i}.doc", :context => @student)]
          sub = @assignment.submit_homework @student, attachments: attachment
          expected_attachments_for_submissions[sub] = attachment
          sub
        end

        result = Submission.bulk_load_attachments_for_submissions(submissions)
        ensure_attachments_arent_queried
        expect(result).to eq(expected_attachments_for_submissions)
      end

      it "handles bad data" do
        s = submission_for_some_user
        s.update_attribute(:attachment_ids, '99999999')
        expected_attachments_for_submissions = { s => [] }
        result = Submission.bulk_load_attachments_for_submissions(s)
        expect(result).to eq(expected_attachments_for_submissions)
      end
    end
  end

  describe "#assign_assessor" do
    def peer_review_assignment
      assignment = @course.assignments.build(title: 'Peer review',
        due_at: Time.now - 1.day,
        points_possible: 5,
        submission_types: 'online_text_entry')
      assignment.peer_reviews_assigned = true
      assignment.peer_reviews = true
      assignment.automatic_peer_reviews = true
      assignment.save!

      assignment
    end

    before(:each) do
      student_in_course(active_all: true)
      @student2 = user
      @course.enroll_student(@student2).accept!
      @assignment = peer_review_assignment
      @assignment.submit_homework(@student,  body: 'Lorem ipsum dolor')
      @assignment.submit_homework(@student2, body: 'Sit amet consectetuer')
    end

    it "should send a reminder notification" do
      AssessmentRequest.any_instance.expects(:send_reminder!).once
      submission1, submission2 = @assignment.submissions
      submission1.assign_assessor(submission2)
    end
  end

  describe "#get_web_snapshot" do
    it "should not blow up if web snapshotting fails" do
      sub = Submission.new(@valid_attributes)
      CutyCapt.expects(:enabled?).returns(true)
      CutyCapt.expects(:snapshot_attachment_for_url).with(sub.url).returns(nil)
      sub.get_web_snapshot
    end
  end

  describe '#submit_attachments_to_canvadocs' do
    it 'creates crocodoc documents' do
      Canvas::Crocodoc.stubs(:enabled?).returns true
      s = @assignment.submit_homework(@user,
                                      submission_type: "online_text_entry",
                                      body: "hi")

      # creates crocodoc documents
      a1 = crocodocable_attachment_model context: @user
      s.attachments = [a1]
      s.save
      cd = a1.crocodoc_document
      expect(cd).not_to be_nil

      # shouldn't mess with existing crocodoc documents
      a2 = crocodocable_attachment_model context: @user
      s.attachments = [a1, a2]
      s.save
      expect(a1.crocodoc_document(true)).to eq cd
      expect(a2.crocodoc_document).to eq a2.crocodoc_document
    end

    context "canvadocs_submissions records" do
      before(:once) do
        @student1, @student2 = n_students_in_course(2)
        @attachment = crocodocable_attachment_model(context: @student1)
        @assignment = @course.assignments.create! name: "A1",
          submission_types: "online_upload"
      end

      before do
        Canvadocs.stubs(:enabled?).returns true
        Canvadocs.stubs(:annotations_supported?).returns true
        Canvadocs.stubs(:config).returns {}
      end

      it "ties submissions to canvadocs" do
        s = @assignment.submit_homework(@student1,
                                        submission_type: "online_upload",
                                        attachments: [@attachment])
        expect(s.canvadocs).to eq [@attachment.canvadoc]
      end

      it "create records for each group submission" do
        gc = @course.group_categories.create! name: "Project Groups"
        group = gc.groups.create! name: "A Team", context: @course
        group.add_user(@student1)
        group.add_user(@student2)

        @assignment.update_attribute :group_category, gc
        @assignment.submit_homework(@student1,
                                    submission_type: "online_upload",
                                    attachments: [@attachment])

        [@student1, @student2].each do |student|
          submission = @assignment.submission_for_student(student)
          expect(submission.canvadocs).to eq [@attachment.canvadoc]
        end
      end
    end

    it "doesn't create jobs for non-previewable documents" do
      job_scope = Delayed::Job.where(strand: "canvadocs")
      orig_job_count = job_scope.count

      attachment = attachment_model(context: @user)
      s = @assignment.submit_homework(@user,
                                      submission_type: "online_upload",
                                      attachments: [attachment])
      expect(job_scope.count).to eq orig_job_count
    end

    it "doesn't use canvadocs for moderated grading assignments" do
      @assignment.update_attribute :moderated_grading, true
      Canvas::Crocodoc.stubs(:enabled?).returns true
      Canvadocs.stubs(:enabled?).returns true
      Canvadocs.stubs(:annotations_supported?).returns true

      attachment = crocodocable_attachment_model(context: @user)
      s = @assignment.submit_homework(@user,
                                      submission_type: "online_upload",
                                      attachments: [attachment])
      run_jobs
      expect(@attachment.canvadoc).to be_nil
      expect(@attachment.crocodoc_document).not_to be_nil
    end
  end

  describe "cross-shard attachments" do
    specs_require_sharding
    it "should work" do
      @shard1.activate do
        @student = user(:active_user => true)
        @attachment = Attachment.create! uploaded_data: StringIO.new('blah'), context: @student, filename: 'blah.txt'
      end
      course(:active_all => true)
      @course.enroll_user(@student, "StudentEnrollment").accept!
      @assignment = @course.assignments.create!

      sub = @assignment.submit_homework(@user, attachments: [@attachment])
      expect(sub.attachments).to eq [@attachment]
    end
  end

  describe '.process_bulk_update' do
    before(:once) do
      course_with_teacher active_all: true
      @u1, @u2 = n_students_in_course(2)
      @a1, @a2 = 2.times.map {
        @course.assignments.create! points_possible: 10
      }
      @progress = Progress.create!(context: @course, tag: "submissions_update")
    end

    it 'updates submissions on an assignment' do
      Submission.process_bulk_update(@progress, @course, nil, @teacher, {
        @a1.id.to_s => {
          @u1.id => {posted_grade: 5},
          @u2.id => {posted_grade: 10}
        }
      })

      expect(@a1.submission_for_student(@u1).grade).to eql "5"
      expect(@a1.submission_for_student(@u2).grade).to eql "10"
    end

    it 'updates submissions on multiple assignments' do
      Submission.process_bulk_update(@progress, @course, nil, @teacher, {
        @a1.id => {
          @u1.id => {posted_grade: 5},
          @u2.id => {posted_grade: 10}
        },
        @a2.id.to_s => {
          @u1.id => {posted_grade: 10},
          @u2.id => {posted_grade: 5}
        }
      })

      expect(@a1.submission_for_student(@u1).grade).to eql "5"
      expect(@a1.submission_for_student(@u2).grade).to eql "10"
      expect(@a2.submission_for_student(@u1).grade).to eql "10"
      expect(@a2.submission_for_student(@u2).grade).to eql "5"
    end

    it "should maintain grade when only updating comments" do
      @a1.grade_student(@u1, :grade => 3)
      Submission.process_bulk_update(@progress, @course, nil, @teacher,
                                     {
                                       @a1.id => {
                                         @u1.id => {text_comment: "comment"}
                                       }
                                     })

      expect(@a1.submission_for_student(@u1).grade).to eql "3"
    end

    it "should nil grade when receiving empty posted_grade" do
      @a1.grade_student(@u1, :grade => 3)
      Submission.process_bulk_update(@progress, @course, nil, @teacher,
                                     {
                                       @a1.id => {
                                         @u1.id => {posted_grade: nil}
                                       }
                                     })

      expect(@a1.submission_for_student(@u1).grade).to be_nil
    end
  end

  describe 'crocodoc_whitelist' do
    before(:once) do
      submission_spec_model
    end

    context "not moderated" do
      it "returns nil" do
        expect(@submission.crocodoc_whitelist).to be_nil
      end
    end

    context "moderated" do
      before(:once) do
        @assignment.moderated_grading = true
        @assignment.save!
        @submission.reload
        @pg = @submission.find_or_create_provisional_grade!(scorer: @teacher, score: 1)
      end

      context "grades not published" do
        context "student not in moderation set" do
          it "returns the student alone" do
            expect(@submission.crocodoc_whitelist).to eq([@student.reload.crocodoc_id!])
          end
        end

        context "student in moderation set" do
          it "returns the student alone" do
            @assignment.moderated_grading_selections.create!(student: @student)
            expect(@submission.crocodoc_whitelist).to eq([@student.reload.crocodoc_id!])
          end
        end
      end

      context "grades published" do
        before(:once) do
          @assignment.grades_published_at = 1.hour.ago
          @assignment.save!
          @submission.reload
        end

        context "student not in moderation set" do
          it "returns nil" do
            expect(@submission.crocodoc_whitelist).to be_nil
          end
        end

        context "student in moderation set" do
          before(:once) do
            @sel = @assignment.moderated_grading_selections.create!(student: @student)
          end

          it "returns nil if no provisional grade was published" do
            expect(@submission.crocodoc_whitelist).to be_nil
          end

          it "returns the student's and selected provisional grader's ids" do
            @sel.provisional_grade = @pg
            @sel.save!
            expect(@submission.crocodoc_whitelist).to match_array([@student.reload.crocodoc_id!,
                                                                   @teacher.reload.crocodoc_id!])
          end

          it "returns the student's, provisional grader's, and moderator's ids for a copied mark" do
            moderator = @course.enroll_teacher(user_model, :enrollment_state => 'active').user
            final = @pg.copy_to_final_mark!(moderator)
            @sel.provisional_grade = final
            @sel.save!
            expect(@submission.crocodoc_whitelist).to match_array([@student.reload.crocodoc_id!,
                                                                   @teacher.reload.crocodoc_id!,
                                                                   moderator.reload.crocodoc_id!])
          end
        end
      end
    end
  end

  describe '#rubric_association_with_assessing_user_id' do
    before :once do
      submission_model assignment: @assignment, user: @student
      rubric_association_model association_object: @assignment, purpose: 'grading'
    end
    subject { @submission.rubric_association_with_assessing_user_id }

    it 'sets assessing_user_id to submission.user_id' do
      expect(subject.assessing_user_id).to eq @submission.user_id
    end
  end

  describe '#visible_rubric_assessments_for' do
    before :once do
      submission_model assignment: @assignment, user: @student
      @viewing_user = @teacher
    end
    subject { @submission.visible_rubric_assessments_for(@viewing_user) }

    it 'returns empty if assignment is muted?' do
      @assignment.update_attribute(:muted, true)
      expect(@assignment.muted?).to be_truthy, 'precondition'
      expect(subject).to be_empty
    end

    it 'returns empty if viewing user cannot :read_grade' do
      student_in_course(active_all: true)
      @viewing_user = @student
      expect(@submission.grants_right?(@viewing_user, :read_grade)).to be_falsey, 'precondition'
      expect(subject).to be_empty
    end

    context 'with rubric_assessments' do
      before :once do
        @assessed_user = @student
        rubric_association_model association_object: @assignment, purpose: 'grading'
        student_in_course(active_all: true)
        [ @teacher, @student ].each do |user|
          @rubric_association.rubric_assessments.create!({
            artifact: @submission,
            assessment_type: 'grading',
            assessor: user,
            rubric: @rubric,
            user: @assessed_user
          })
        end
        @teacher_assessment = @submission.rubric_assessments.where(assessor_id: @teacher).first
        @student_assessment = @submission.rubric_assessments.where(assessor_id: @student).first
      end
      subject { @submission.visible_rubric_assessments_for(@viewing_user) }

      it 'returns rubric_assessments for teacher' do
        expect(subject).to include(@teacher_assessment)
      end

      it 'returns only student rubric assessment' do
        @viewing_user = @student
        expect(subject).not_to include(@teacher_assessment)
        expect(subject).to include(@student_assessment)
      end
    end
  end
end

def submission_spec_model(opts={})
  @submission = Submission.new(@valid_attributes.merge(opts))
  expect(@submission.assignment).to eql(@assignment)
  expect(@assignment.context).to eql(@context)
  expect(@submission.assignment.context).to eql(@context)
  @submission.save!
end
