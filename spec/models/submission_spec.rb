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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

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
  
  it "should offer the context, if one is available" do
    @course = mock_model(Course)
    @assignment = mock_model(Assignment)
    @assignment.should_receive(:context).and_return(@course)
    
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

  context "broadcast policy" do
    it "should have a broadcast policy" do
      submission_spec_model
      @submission.should be_respond_to(:dispatch)
      @submission.should be_respond_to(:to)
    end
    
    it "should have 6 policies defined" do
      submission_spec_model
      @submission.broadcast_policy_list.size.should eql(6)
    end
        
    context "Assignment Submitted Late" do
      it "should have a 'Assignment Submitted Late' policy" do
        submission_spec_model
        @submission.broadcast_policy_list.map {|bp| bp.dispatch}.should be_include('Assignment Submitted Late')
      end
      
      it "should create a message when the assignment is turned in late" do
        Notification.create(:name => 'Assignment Submitted Late')
        t = User.create(:name => "some teacher")
        s = User.create(:name => "late student")
        @context.enroll_teacher(t)
        @context.enroll_student(s)
#        @context.stub!(:teachers).and_return([@user])
        @assignment.workflow_state = "published"
        @assignment.update_attributes(:due_at => Time.now - 1000)
#        @assignment.stub!(:due_at).and_return(Time.now - 100)
        submission_spec_model(:user => s)
        
#        @submission.stub!(:validate_enrollment).and_return(true)
#        @submission.save
        @submission.messages_sent.should be_include('Assignment Submitted Late')
      end
    end
    
    context "Submission Graded" do
      it "should have a 'Submission Graded' policy" do
        submission_spec_model
        @submission.broadcast_policy_list.map {|bp| bp.dispatch}.should be_include('Submission Graded')
      end
      
      it "should create a message when the assignment has been graded and published" do
        Notification.create(:name => 'Submission Graded')
        submission_spec_model
        @cc = @user.communication_channels.create(:path => "somewhere")
        @submission.reload
        @submission.assignment.should eql(@assignment)
        @submission.assignment.state.should eql(:published)
#        @assignment.stub!(:state).and_return(:published)
#        @cc = mock_model(CommunicationChannel)
#        @cc.stub!(:path).and_return('somewhere@example.com')
#        @cc.stub!(:user).and_return(@user)
#        @user.stub!(:communication_channel).and_return(@cc)
#        @submission.stub!(:student).and_return(@user)
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
      it "should have a 'Submission Grade Changed' policy" do
        submission_spec_model
        @submission.broadcast_policy_list.map {|bp| bp.dispatch}.should be_include('Submission Grade Changed')
      end
      
      it "should create a message when the score is changed and the grades were already published" do
        Notification.create(:name => 'Submission Grade Changed')
        @assignment.stub!(:score_to_grade).and_return(10.0)
        @assignment.stub!(:due_at).and_return(Time.now  - 100)
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
        @assignment.stub!(:score_to_grade).and_return(10.0)
        @assignment.stub!(:due_at).and_return(Time.now  - 100)
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
        @assignment.stub!(:score_to_grade).and_return(10.0)
        @assignment.stub!(:due_at).and_return(Time.now  - 100)
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
        @assignment.stub!(:score_to_grade).and_return(10.0)
        @assignment.stub!(:due_at).and_return(Time.now  - 100)
        submission_spec_model

        @cc = @user.communication_channels.create(:path => "somewhere")
        s = @assignment.grade_student(@user, :grade => 10)[0] #@submission
        @submission = @assignment.grade_student(@user, :grade => 9)[0]
        @submission.should eql(s)
        @submission.messages_sent.should_not be_include('Submission Grade Changed')
      end
    end
  end

  context "URL submissions" do
    it "should automatically add the 'http://' scheme if none given" do
      s = Submission.create!(@valid_attributes)
      s.url.should == 'http://www.instructure.com'

      long_url = ("a"*300 + ".com")
      s.url = long_url
      s.save!
      s.url.should == "http://#{long_url}"
      # make sure it adds the "http://" to the body for long urls, too
      s.body.should == "http://#{long_url}"
    end

    it "should reject invalid urls" do
      s = Submission.create(@valid_attributes.merge :url => 'bad url')
      s.new_record?.should be_true
      s.errors.length.should == 1
      s.errors.first.to_s.should match(/not a valid URL/)
    end
  end

  context "turnitin" do
    before do
      @assignment.turnitin_enabled = true
      @assignment.turnitin_settings = @assignment.turnitin_settings
      @assignment.save!
      submission_spec_model
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
      Turnitin::Client.should_receive(:new).at_least(:once).and_return(api)
      api.should_receive(:sendRequest).with(:generate_report, 1, hash_including(:oid => "123456789")).at_least(:once).and_return('http://foo.bar')
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

def submission_spec_model(opts={})
  @submission = Submission.new(@valid_attributes.merge(opts))
  @submission.assignment.should eql(@assignment)
  @assignment.context.should eql(@context)
  @submission.assignment.context.should eql(@context)
  @submission.save
end
