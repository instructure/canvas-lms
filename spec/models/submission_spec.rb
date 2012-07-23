#
# Copyright (C) 2012 Instructure, Inc.
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
    @context = factory_with_protected_attributes(Course, :name => "some course", :workflow_state => "available")
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
  
  it_should_behave_like "url validation tests"
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

  it "should not return duplicate conversation groups" do
    assignment_model
    @assignment.workflow_state = 'published'
    @assignment.save!
    @course.teacher_enrollments.create(:user => @teacher, :workflow_state => 'accepted')
    @course.teacher_enrollments.create(:user => @teacher, :workflow_state => 'accepted')
    @course.teacher_enrollments.create(:user => @teacher, :workflow_state => 'accepted')
    @course.teacher_enrollments.create(:user => @teacher, :workflow_state => 'invited')
    @course.teacher_enrollments.create(:user => @teacher, :workflow_state => 'completed')
    @course.offer!
    @course.enroll_student(@student = user)
    @assignment.context.reload

    @submission = @assignment.submit_homework(@student, :body => 'some message')
    @submission.conversation_groups.should eql @submission.conversation_groups.uniq
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
      @submission = @assignment.submissions.scoped(:conditions => {:user_id => @entry1.user_id}).first
      new_time = Time.now + 30.minutes
      Time.stubs(:now).returns(new_time)
      @entry2 = @topic.discussion_entries.create(:message => "second entry", :user => @user)
      @submission.reload
      (@submission.submitted_at.to_i - @submission.created_at.to_i).abs.should < 1.minute
    end
  end

  context "broadcast policy" do
    context "Assignment Submitted Late" do
      it "should create a message when the assignment is turned in late" do
        Notification.create(:name => 'Assignment Submitted Late')
        t = User.create(:name => "some teacher")
        s = User.create(:name => "late student")
        @context.enroll_teacher(t)
        @context.enroll_student(s)
#        @context.stubs(:teachers).returns([@user])
        @assignment.workflow_state = "published"
        @assignment.update_attributes(:due_at => Time.now - 1000)
#        @assignment.stubs(:due_at).returns(Time.now - 100)
        submission_spec_model(:user => s)
        
#        @submission.stubs(:validate_enrollment).returns(true)
#        @submission.save
        @submission.messages_sent.should be_include('Assignment Submitted Late')
      end
    end
    
    context "Submission Graded" do
      it "should create a message when the assignment has been graded and published" do
        Notification.create(:name => 'Submission Graded')
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @submission.reload
        @submission.assignment.should eql(@assignment)
        @submission.assignment.state.should eql(:published)
        @submission.grade_it!
        @submission.messages_sent.should be_include('Submission Graded')
      end

      it "should not create a message when a muted assignment has been graded and published" do
        Notification.create(:name => 'Submission Graded')
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @assignment.mute!
        @submission.reload
        @submission.assignment.should eql(@assignment)
        @submission.assignment.state.should eql(:published)
        @submission.grade_it!
        @submission.messages_sent.should_not be_include "Submission Graded"
      end

      it "should create a hidden stream_item_instance when muted, graded, and published" do
        Notification.create :name => "Submission Graded"
        submission_spec_model
        @cc = @user.communication_channels.create :path => "somewhere"
        @assignment.mute!
        lambda {
          @submission = @assignment.grade_student(@user, :grade => 10)[0]
        }.should change StreamItemInstance, :count
        @user.stream_item_instances.last.should be_hidden
      end

      it "should hide any existing stream_item_instances when muted" do
        Notification.create :name => "Submission Graded"
        submission_spec_model
        @cc = @user.communication_channels.create :path => "somewhere"
        lambda {
          @submission = @assignment.grade_student(@user, :grade => 10)[0]
        }.should change StreamItemInstance, :count
        @user.stream_item_instances.last.should_not be_hidden
        @assignment.mute!
        @user.stream_item_instances.last.should be_hidden
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
      item_asset_strings    = @assignment.submissions.map { |s| "submission_#{s.id}" }
      stream_item_ids       = StreamItem.all(:select => :id, :conditions => { :item_asset_string => item_asset_strings })
      stream_item_instances = StreamItemInstance.all(:conditions => { :stream_item_id => stream_item_ids })
      stream_item_instances.each { |sii| sii.should_not be_hidden }
    end

        
    context "Submission Grade Changed" do
      it "should create a message when the score is changed and the grades were already published" do
        Notification.create(:name => 'Submission Grade Changed')
        @assignment.stubs(:score_to_grade).returns(10.0)
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
      
      it "should create a message when the score is changed and the grades were already published" do
        Notification.create(:name => 'Submission Grade Changed')
        Notification.create(:name => 'Submission Graded')
        @assignment.stubs(:score_to_grade).returns(10.0)
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
        @assignment.stubs(:score_to_grade).returns(10.0)
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
        @assignment.stubs(:score_to_grade).returns(10.0)
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
        Delayed::Job.destroy_all(:tag => 'Submission#submit_to_turnitin')
        @assignment.submission_types = "online_upload,online_text_entry"
        @assignment.turnitin_enabled = true
        @assignment.turnitin_settings = @assignment.turnitin_settings
        @assignment.save!
        @submission = @assignment.submit_homework(@user, { :body => "hello there", :submission_type => 'online_text_entry' })
      end

      it "should submit to turnitin after a delay" do
        job = Delayed::Job.find_by_tag('Submission#submit_to_turnitin')
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
        Delayed::Job.find_all_by_tag('Submission#submit_to_turnitin').count.should == 2
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

        @submission.check_turnitin_status(Submission::TURNITIN_RETRY-1)
        @submission.reload.turnitin_data[@submission.asset_string][:status].should == 'pending'
        Delayed::Job.find_by_tag('Submission#check_turnitin_status').should_not be_nil

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
    submission.quiz_submission_version.should == 2
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
  
end

def submission_spec_model(opts={})
  @submission = Submission.new(@valid_attributes.merge(opts))
  @submission.assignment.should eql(@assignment)
  @assignment.context.should eql(@context)
  @submission.assignment.context.should eql(@context)
  @submission.save
end
