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
require File.expand_path(File.dirname(__FILE__) + '/../lib/validates_as_url.rb')

describe Submission do
  before(:each) do
    @user = factory_with_protected_attributes(User, :name => "some student", :workflow_state => "registered")
    @course = @context = factory_with_protected_attributes(Course, :name => "some course", :workflow_state => "available")
    @context.enroll_student(@user)
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
    s.url.should == 'http://www.instructure.com'

    long_url = ("a"*300 + ".com")
    s.url = long_url
    s.save!
    s.url.should == "http://#{long_url}"
    # make sure it adds the "http://" to the body for long urls, too
    s.body.should == "http://#{long_url}"
  end

  it "should offer the context, if one is available" do
    @course = Course.new
    @assignment = Assignment.new(:context => @course)
    @assignment.expects(:context).returns(@course)

    @submission = Submission.new
    lambda{@submission.context}.should_not raise_error
    @submission.context.should be_nil
    @submission.assignment = @assignment
    @submission.context.should eql(@course)
  end

  it "should have an interesting state machine" do
    submission_spec_model
    @submission.state.should eql(:submitted)
    @submission.grade_it
    @submission.state.should eql(:graded)
  end

  it "should be versioned" do
    submission_spec_model
    @submission.should be_respond_to(:versions)
  end

  it "should not save new versions by default" do
    submission_spec_model
    lambda {
      @submission.save!
    }.should_not change(@submission.versions, :count)
  end

  describe "version indexing" do
    it "should create a SubmissionVersion when a new submission is created" do
      lambda {
        submission_spec_model
      }.should change(SubmissionVersion, :count)
    end

    it "should create a SubmissionVersion when a new version is saved" do
      submission_spec_model
      lambda {
        @submission.with_versioning(:explicit => true) { @submission.save }
      }.should change(SubmissionVersion, :count)
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
      (@submission.submitted_at.to_i - @submission.created_at.to_i).abs.should < 1.minute
    end
  end

  context "broadcast policy" do
    context "Submission Notifications" do
      before do
        Notification.create(:name => 'Assignment Submitted')
        Notification.create(:name => 'Assignment Resubmitted')
        Notification.create(:name => 'Assignment Submitted Late')
        Notification.create(:name => 'Group Assignment Submitted Late')

        @teacher = User.create(:name => "some teacher")
        @student = User.create(:name => "a student")
        @context.enroll_teacher(@teacher)
        @context.enroll_student(@student)
      end

      it "should send the correct message when an assignment is turned in on-time" do
        @assignment.workflow_state = "published"
        @assignment.update_attributes(:due_at => Time.now + 1000)

        submission_spec_model(:user => @student)
        @submission.messages_sent.keys.should == ['Assignment Submitted']
      end

      it "should send the correct message when an assignment is turned in late" do
        @assignment.workflow_state = "published"
        @assignment.update_attributes(:due_at => Time.now - 1000)

        submission_spec_model(:user => @student)
        @submission.messages_sent.keys.should == ['Assignment Submitted Late']
      end

      it "should send the correct message when an assignment is resubmitted on-time" do
        @assignment.submission_types = ['online_text_entry']
        @assignment.due_at = Time.now + 1000
        @assignment.save!

        @assignment.submit_homework(@student, :body => "lol")
        resubmission = @assignment.submit_homework(@student, :body => "frd")
        resubmission.messages_sent.keys.should == ['Assignment Resubmitted']
      end

      it "should send the correct message when an assignment is resubmitted late" do
        @assignment.submission_types = ['online_text_entry']
        @assignment.due_at = Time.now - 1000
        @assignment.save!

        @assignment.submit_homework(@student, :body => "lol")
        resubmission = @assignment.submit_homework(@student, :body => "frd")
        resubmission.messages_sent.keys.should == ['Assignment Submitted Late']
      end

      it "should send the correct message when a group assignment is submitted late" do
        @a = assignment_model(:course => @context, :group_category => "Study Groups", :due_at => Time.now - 1000, :submission_types => ["online_text_entry"])
        @group1 = @a.context.groups.create!(:name => "Study Group 1", :group_category => @a.group_category)
        @group1.add_user(@student)
        submission = @a.submit_homework @student, :submission_type => "online_text_entry", :body => "blah"

        submission.messages_sent.keys.should == ['Group Assignment Submitted Late']
      end
    end

    context "Submission Graded" do
      before do
        Notification.create(:name => 'Submission Graded')
      end

      it "should create a message when the assignment has been graded and published" do
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @submission.reload
        @submission.assignment.should eql(@assignment)
        @submission.assignment.state.should eql(:published)
        @submission.grade_it!
        @submission.messages_sent.should be_include('Submission Graded')
      end

      it "should not create a message when a muted assignment has been graded and published" do
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @assignment.mute!
        @submission.reload
        @submission.assignment.should eql(@assignment)
        @submission.assignment.state.should eql(:published)
        @submission.grade_it!
        @submission.messages_sent.should_not be_include "Submission Graded"
      end

      it "should not create a message when this is a quiz submission" do
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @quiz = Quizzes::Quiz.create!(:context => @course)
        @submission.quiz_submission = @quiz.generate_submission(@user)
        @submission.save!
        @submission.reload
        @submission.assignment.should eql(@assignment)
        @submission.assignment.state.should eql(:published)
        @submission.grade_it!
        @submission.messages_sent.should_not include('Submission Graded')
      end

      it "should create a hidden stream_item_instance when muted, graded, and published" do
        submission_spec_model
        @cc = @user.communication_channels.create :path => "somewhere"
        @assignment.mute!
        lambda {
          @submission = @assignment.grade_student(@user, :grade => 10)[0]
        }.should change StreamItemInstance, :count
        @user.stream_item_instances.last.should be_hidden
      end

      it "should hide any existing stream_item_instances when muted" do
        submission_spec_model
        @cc = @user.communication_channels.create :path => "somewhere"
        lambda {
          @submission = @assignment.grade_student(@user, :grade => 10)[0]
        }.should change StreamItemInstance, :count
        @user.stream_item_instances.last.should_not be_hidden
        @assignment.mute!
        @user.stream_item_instances.last.should be_hidden
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

        submission.submission.messages_sent.should_not be_include('Submission Graded')
        submission2.submission.messages_sent.should_not be_include('Submission Graded')
      end
    end

    it "should create a stream_item_instance when graded and published" do
      Notification.create :name => "Submission Graded"
      submission_spec_model
      @cc = @user.communication_channels.create :path => "somewhere"
      lambda {
        @assignment.grade_student(@user, :grade => 10)
      }.should change StreamItemInstance, :count
    end

    it "should create a stream_item_instance when graded, and then made it visible when unmuted" do
      Notification.create :name => "Submission Graded"
      submission_spec_model
      @cc = @user.communication_channels.create :path => "somewhere"
      @assignment.mute!
      lambda {
        @assignment.grade_student(@user, :grade => 10)
      }.should change StreamItemInstance, :count

      @assignment.unmute!
      stream_item_ids       = StreamItem.where(:asset_type => 'Submission', :asset_id => @assignment.submissions.all).pluck(:id)
      stream_item_instances = StreamItemInstance.where(:stream_item_id => stream_item_ids)
      stream_item_instances.each { |sii| sii.should_not be_hidden }
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
        @submission.should eql(s)
        @submission.messages_sent.should be_include('Submission Grade Changed')
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
        @submission.should eql(s)
        @submission.messages_sent.should_not include('Submission Grade Changed')
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
        @submission.should eql(s)
        @submission.messages_sent.should_not be_include('Submission Grade Changed')
        @submission.messages_sent.should be_include('Submission Graded')
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
        @submission.should eql(s)
        @submission.messages_sent.should_not be_include('Submission Grade Changed')

      end

      it "should NOT create a message when the score is changed and the submission was recently graded" do
        Notification.create(:name => 'Submission Grade Changed')
        @assignment.stubs(:score_to_grade).returns("10.0")
        @assignment.stubs(:due_at).returns(Time.now  - 100)
        submission_spec_model

        @cc = @user.communication_channels.create(:path => "somewhere")
        s = @assignment.grade_student(@user, :grade => 10)[0] #@submission
        @submission = @assignment.grade_student(@user, :grade => 9)[0]
        @submission.should eql(s)
        @submission.messages_sent.should_not be_include('Submission Grade Changed')
      end
    end
  end

  context "turnitin" do
    context "submission" do
      def init_turnitin_api
        @turnitin_api = Turnitin::Client.new('test_account', 'sekret')
        @submission.context.expects(:turnitin_settings).at_least(1).returns([:placeholder])
        Turnitin::Client.expects(:new).at_least(1).with(:placeholder).returns(@turnitin_api)
      end

      before(:each) do
        @assignment.submission_types = "online_upload,online_text_entry"
        @assignment.turnitin_enabled = true
        @assignment.turnitin_settings = @assignment.turnitin_settings
        @assignment.save!
        @submission = @assignment.submit_homework(@user, { :body => "hello there", :submission_type => 'online_text_entry' })
      end

      it "should submit to turnitin after a delay" do
        job = Delayed::Job.list_jobs(:future, 100).find { |j| j.tag == 'Submission#submit_to_turnitin' }
        job.should_not be_nil
        job.run_at.should > Time.now.utc
      end

      it "should initially set turnitin submission to pending" do
        init_turnitin_api
        @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).returns({ :assignment_id => "1234" })
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(true)
        @turnitin_api.expects(:sendRequest).with(:submit_paper, '2', has_entries(:pdata => @submission.plaintext_body)).returns(Nokogiri('<objectID>12345</objectID>'))
        @submission.submit_to_turnitin
        @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'pending'
      end

      it "should schedule a retry if something fails initially" do
        init_turnitin_api
        @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).returns({ :assignment_id => "1234" })
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(false)
        @submission.submit_to_turnitin
        Delayed::Job.list_jobs(:future, 100).find_all { |j| j.tag == 'Submission#submit_to_turnitin' }.size.should == 2
      end

      it "should set status as failed if something fails after several attempts" do
        init_turnitin_api
        @turnitin_api.expects(:createOrUpdateAssignment).with(@assignment, @assignment.turnitin_settings).returns({ :assignment_id => "1234" })
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(true)
        example_error = '<rerror><rcode>1001</rcode><rmessage>You may not submit a paper to this assignment until the assignment start date</rmessage></rerror>'
        @turnitin_api.expects(:sendRequest).with(:submit_paper, '2', has_entries(:pdata => @submission.plaintext_body)).returns(Nokogiri(example_error))
        @submission.submit_to_turnitin(Submission::TURNITIN_RETRY)
        @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'error'
      end

      it "should set status back to pending on retry" do
        init_turnitin_api
        # first a submission, to get us into failed state
        example_error = '<rerror><rcode>123</rcode><rmessage>You cannot create this assignment right now</rmessage></rerror>'
        @turnitin_api.expects(:sendRequest).with(:create_assignment, '2', has_entries(@assignment.turnitin_settings)).returns(Nokogiri(example_error))
        @turnitin_api.expects(:enrollStudent).with(@context, @user).returns(false)
        @submission.submit_to_turnitin(Submission::TURNITIN_RETRY)
        @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'error'

        # resubmit
        @submission.resubmit_to_turnitin
        @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'pending'
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
        @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'scored'
      end

      it "should set status as failed if something fails after several attempts" do
        init_turnitin_api
        @submission.turnitin_data ||= {}
        @submission.turnitin_data[@submission.asset_string] = { :object_id => '1234', :status => 'pending' }
        @turnitin_api.expects(:generateReport).with(@submission, @submission.asset_string).returns({})

        expects_job_with_tag('Submission#check_turnitin_status') do
          @submission.check_turnitin_status(Submission::TURNITIN_RETRY-1)
          @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'pending'
        end

        @submission.check_turnitin_status(Submission::TURNITIN_RETRY)
        @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'error'
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
        @submission.turnitin_data[@submission.asset_string][:status].should == 'scored'
        @submission.turnitin_data["other_asset"][:status].should == 'scored'
      end
    end

    describe "group" do
      before(:each) do
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
        submissions = Submission.find_all_by_assignment_id @a.id
        submissions.each do |s|
          if s.id == submission.id
            s.turnitin_data[:last_processed_attempt].should > 0
          else
            s.turnitin_data.should == nil
          end
        end
      end

    end

    context "report" do
      before do
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

        api = Turnitin::Client.new('test_account', 'sekret')
        Turnitin::Client.expects(:new).at_least(1).returns(api)
        api.expects(:sendRequest).with(:generate_report, 1, has_entries(:oid => "123456789")).at_least(1).returns('http://foo.bar')
      end

      it "should let teachers view the turnitin report" do
        @teacher = User.create
        @context.enroll_teacher(@teacher)
        @submission.should be_grants_right(@teacher, nil, :view_turnitin_report)
        @submission.turnitin_report_url("submission_#{@submission.id}", @teacher).should_not be_nil
      end

      it "should let students view the turnitin report after grading" do
        @assignment.turnitin_settings[:originality_report_visibility] = 'after_grading'
        @assignment.save!
        @submission.reload

        @submission.should_not be_grants_right(@user, nil, :view_turnitin_report)
        @submission.turnitin_report_url("submission_#{@submission.id}", @user).should be_nil

        @submission.score = 1
        @submission.grade_it!

        @submission.should be_grants_right(@user, nil, :view_turnitin_report)
        @submission.turnitin_report_url("submission_#{@submission.id}", @user).should_not be_nil
      end

      it "should let students view the turnitin report immediately if the visibility setting allows it" do
        @assignment.turnitin_settings[:originality_report_visibility] = 'after_grading'
        @assignment.save
        @submission.reload

        @submission.should_not be_grants_right(@user, nil, :view_turnitin_report)
        @submission.turnitin_report_url("submission_#{@submission.id}", @user).should be_nil

        @assignment.turnitin_settings[:originality_report_visibility] = 'immediate'
        @assignment.save
        @submission.reload

        @submission.should be_grants_right(@user, nil, :view_turnitin_report)
        @submission.turnitin_report_url("submission_#{@submission.id}", @user).should_not be_nil
      end

      it "should let students view the turnitin report after the due date if the visibility setting allows it" do
        @assignment.turnitin_settings[:originality_report_visibility] = 'after_due_date'
        @assignment.due_at = Time.now + 1.day
        @assignment.save
        @submission.reload

        @submission.should_not be_grants_right(@user, nil, :view_turnitin_report)
        @submission.turnitin_report_url("submission_#{@submission.id}", @user).should be_nil

        @assignment.due_at = Time.now - 1.day
        @assignment.save
        @submission.reload

        @submission.should be_grants_right(@user, nil, :view_turnitin_report)
        @submission.turnitin_report_url("submission_#{@submission.id}", @user).should_not be_nil
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
    quiz_submission.finished_at.to_i.should == submission.submitted_at.to_i
    quiz_submission.finished_at.usec.should > submission.submitted_at.usec

    # create the versions that Submission#quiz_submission_version uses
    quiz_submission.with_versioning do
      quiz_submission.save
      quiz_submission.save
    end

    # the real test, quiz_submission_version shouldn't care about usecs
    submission.reload.quiz_submission_version.should == 2
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
    @submission.submission_comments.count.should eql 4
    @submission.visible_submission_comments.count.should eql 3

    @submission.limit_comments(@student1)
    @submission.submission_comments.count.should eql 3
    @submission.visible_submission_comments.count.should eql 3

    @submission.limit_comments(@student2)
    @submission.submission_comments.count.should eql 1
    @submission.visible_submission_comments.count.should eql 1
  end

  describe "read/unread state" do
    it "should be read if a submission exists with no grade" do
      @submission = @assignment.submit_homework(@user)
      @submission.read?(@user).should be_true
    end

    it "should be unread after assignment is graded" do
      @submission = @assignment.grade_student(@user, { :grade => 3 }).first
      @submission.unread?(@user).should be_true
    end

    it "should be unread after submission is graded" do
      @assignment.submit_homework(@user)
      @submission = @assignment.grade_student(@user, { :grade => 3 }).first
      @submission.unread?(@user).should be_true
    end

    it "should be unread after submission is commented on by teacher" do
      @student = @user
      course_with_teacher(:course => @context, :active_all => true)
      @submission = @assignment.grade_student(@student, { :grader => @teacher, :comment => "good!" }).first
      @submission.unread?(@user).should be_true
    end

    it "should be read if other submission fields change" do
      @submission = @assignment.submit_homework(@user)
      @submission.workflow_state = 'graded'
      @submission.graded_at = Time.now
      @submission.save!
      @submission.read?(@user).should be_true
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

    specify { submission.published_score.should be_nil }
    specify { submission.published_grade.should be_nil }
    specify { submission.graded_at.should be_nil }
    specify { submission.grade.should be_nil }
    specify { submission.score.should be_nil }
  end

  describe "muted_assignment?" do
    it "returns true if assignment is muted" do
      assignment = stub(:muted? => true)
      @submission = Submission.new
      @submission.expects(:assignment).returns(assignment)
      @submission.muted_assignment?.should == true
    end

    it "returns false if assignment is not muted" do
      assignment = stub(:muted? => false)
      @submission = Submission.new
      @submission.expects(:assignment).returns(assignment)
      @submission.muted_assignment?.should == false
    end
  end

  describe "without_graded_submission?" do
    let(:submission) { Submission.new }

    it "returns false if submission does not has_submission?" do
      submission.stubs(:has_submission?).returns false
      submission.stubs(:graded?).returns true
      submission.without_graded_submission?.should == false
    end

    it "returns false if submission does is not graded" do
      submission.stubs(:has_submission?).returns true
      submission.stubs(:graded?).returns false
      submission.without_graded_submission?.should == false
    end

    it "returns true if submission is not graded and has no submission" do
      submission.stubs(:has_submission?).returns false
      submission.stubs(:graded?).returns false
      submission.without_graded_submission?.should == true
    end
  end

  describe "autograded" do
    let(:submission) { Submission.new }

    it "returns false when its not autograded" do
      assignment = stub(:muted? => false)
      @submission = Submission.new
      @submission.autograded?.should == false

      @submission.grader_id = Shard.global_id_for(@user.id)
      @submission.autograded?.should == false
    end

    it "returns true when its autograded" do
      assignment = stub(:muted? => false)
      @submission = Submission.new
      @submission.grader_id = -1
      @submission.autograded?.should == true
    end
  end

  describe "past_due" do
    before do
      u1 = @user
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
      @submission1.should be_past_due
      @assignment.reload.update_attribute(:due_at, Time.zone.now + 1.day)
      @submission1.reload.should_not be_past_due
    end

    it "should update when an applicable override is changed" do
      @submission1.should be_past_due
      @submission2.should be_past_due

      assignment_override_model :assignment => @assignment,
                                :due_at => Time.zone.now + 1.day,
                                :set => @course_section
      @submission1.reload.should be_past_due
      @submission2.reload.should_not be_past_due
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
      submission.should be_past_due

      submission.write_attribute(:submitted_at, @assignment.due_at + 30.seconds)
      submission.should_not be_past_due
    end
  end

  describe "late" do
    before do
      submission_spec_model
    end

    it "should be false if not past due" do
      @submission.submitted_at = 2.days.ago
      @submission.cached_due_date = 1.day.ago
      @submission.should_not be_late
    end

    it "should be false if not submitted, even if past due" do
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago
      @submission.should_not be_late
    end

    it "should be true if submitted and past due" do
      @submission.submitted_at = 1.day.ago
      @submission.cached_due_date = 2.days.ago
      @submission.should be_late
    end
  end

  describe "missing" do
    before do
      submission_spec_model
    end

    it "should be false if not past due" do
      @submission.submitted_at = 2.days.ago
      @submission.cached_due_date = 1.day.ago
      @submission.should_not be_missing
    end

    it "should be false if submitted, even if past due" do
      @submission.submitted_at = 1.day.ago
      @submission.cached_due_date = 2.days.ago
      @submission.should_not be_missing
    end

    it "should be true if not submitted, past due, and expects a submission" do
      @submission.assignment.submission_types = "online_quiz"
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago

      # Regardless of score
      @submission.score = 0.00000001
      @submission.graded_at = Time.zone.now + 1.day

      @submission.should be_missing
    end

    it "should be true if not submitted, score of zero, and does not expect a submission" do
      @submission.assignment.submission_types = "on_paper"
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago
      @submission.score = 0
      @submission.graded_at = Time.zone.now + 1.day
      @submission.should be_missing
    end

    it "should be false if not submitted, score greater than zero, and does not expect a submission" do
      @submission.assignment.submission_types = "on_paper"
      @submission.submission_type = nil # forces submitted_at to be nil
      @submission.cached_due_date = 1.day.ago
      @submission.score = 0.00000001
      @submission.graded_at = Time.zone.now + 1.day
      @submission.should be_missing
    end
  end

  describe "cached_due_date" do
    it "should get initialized during submission creation" do
      @assignment.update_attribute(:due_at, Time.zone.now - 1.day)

      override = @assignment.assignment_overrides.build
      override.title = "Some Title"
      override.set = @course.default_section
      override.override_due_at(Time.zone.now + 1.day)
      override.save!
      # mysql just truncated the timestamp
      override.reload

      submission = @assignment.submissions.create(:user => @user)
      submission.cached_due_date.should == override.due_at
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
      sub.attachments.should == []
    end
  end

  describe "versioned_attachments" do
    it "should include user attachments" do
      student_in_course(active_all: true)
      att = attachment_model(filename: "submission.doc", :context => @student)
      sub = @assignment.submit_homework(@student, attachments: [att])
      sub.versioned_attachments.should == [att]
    end

    it "should not include attachments with a context of Submission" do
      student_in_course(active_all: true)
      att = attachment_model(filename: "submission.doc", :context => @student)
      sub = @assignment.submit_homework(@student, attachments: [att])
      sub.attachments.update_all(:context_type => "Submission", :context_id => sub.id)
      sub.reload.versioned_attachments.should be_empty
    end
  end

  describe "#bulk_load_versioned_attachments" do
    it "loads attachments for many submissions at once" do
      attachments = []

      submissions = 3.times.map { |i|
        student_in_course(active_all: true)
        attachments << [
          attachment_model(filename: "submission#{i}-a.doc", :context => @student),
          attachment_model(filename: "submission#{i}-b.doc", :context => @student)
        ]

        @assignment.submit_homework @student, attachments: attachments[i]
      }

      Submission.bulk_load_versioned_attachments(submissions)
      submissions.each_with_index { |s, i|
        s.versioned_attachments.should == attachments[i]
      }
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

  describe "assignment_visible_to_student?" do
    before(:each) do
      student_in_course(active_all: true)
      @assignment.only_visible_to_overrides = true
      @assignment.save!
      @submission = @assignment.submit_homework(@student,  body: 'Lorem ipsum dolor')
    end

    it "submission should be visible with normal course" do
      @submission.assignment_visible_to_student?(@student.id).should be_true
    end

    it "submission should not be visible with DA and no override or grade" do
      @course.enable_feature!(:differentiated_assignments)
      @submission.assignment_visible_to_student?(@student.id).should be_false
    end

    it "submission should be visible with DA and an override" do
      @course.enable_feature!(:differentiated_assignments)
      @student.enrollments.each(&:destroy!)
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student)
      create_section_override_for_assignment(@submission.assignment, course_section: @section)
      @submission.reload
      @submission.assignment_visible_to_student?(@student.id).should be_true
    end

    it "submission should be visible with DA and a grade" do
      @course.enable_feature!(:differentiated_assignments)
      @student.enrollments.each(&:destroy!)
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student)
      @assignment.grade_student(@user, {grade: 10})
      @submission.reload
      @submission.assignment_visible_to_student?(@student.id).should be_true
    end
  end


end

def submission_spec_model(opts={})
  @submission = Submission.new(@valid_attributes.merge(opts))
  @submission.assignment.should eql(@assignment)
  @assignment.context.should eql(@context)
  @submission.assignment.context.should eql(@context)
  @submission.save!
end
