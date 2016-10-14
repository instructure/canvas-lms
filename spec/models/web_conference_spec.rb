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

describe WebConference do
  before(:record) { stub_plugins }
  before(:each)   { stub_plugins }

  def stub_plugins
    WebConference.stubs(:plugins).returns(
        [web_conference_plugin_mock("big_blue_button", {:domain => "bbb.instructure.com", :secret_dec => "secret"}),
         web_conference_plugin_mock("wimba", {:domain => "wimba.test"}),
         web_conference_plugin_mock("broken_plugin", {:foor => :bar})]
    )
  end

  context "broken_plugin" do
    it "should return false on valid_config? if no matching config" do
      expect(WebConference.new).not_to be_valid_config
      conf = WebConference.new
      conf.conference_type = 'bad_type'
      expect(conf).not_to be_valid_config
    end

    it "should return false on valid_config? if plugin subclass is broken/missing" do
      conf = WebConference.new
      conf.conference_type = "broken_plugin"
      expect(conf).not_to be_valid_config
    end
  end

  context "user settings" do
    before :once do
      user_model
    end

    it "should ignore invalid user settings" do
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = WimbaConference.create!(:title => "my conference", :user => @user, :user_settings => {:foo => :bar}, :context => course)
      expect(conference.user_settings).to be_empty
    end

    it "should not expose internal settings to users" do
      email = "email@email.com"
      @user.stubs(:email).returns(email)
      conference = BigBlueButtonConference.new(:title => "my conference", :user => @user, :context => course)
      conference.settings = {:record => true, :not => :for_user}
      conference.save
      conference.reload
      expect(conference.user_settings).to eql({:record => true})
    end

  end

  context "starting and ending" do
    before :once do
      user_model
    end

    let_once(:conference) do
      WimbaConference.create!(:title => "my conference", :user => @user, :duration => 60, :context => course)
    end

    before :each do
      email = "email@email.com"
      @user.stubs(:email).returns(email)
    end

    it "should not set start and end times by default" do
      expect(conference.start_at).to be_nil
      expect(conference.end_at).to be_nil
      expect(conference.started_at).to be_nil
      expect(conference.ended_at).to be_nil
    end

    it "should set start and end times when a paricipant is added" do
      conference.add_attendee(@user)
      expect(conference.start_at).not_to be_nil
      expect(conference.end_at).to eql(conference.start_at + conference.duration_in_seconds)
      expect(conference.started_at).to eql(conference.start_at)
      expect(conference.ended_at).to be_nil
    end

    it "should not set ended_at if the conference is still active" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:active)
      expect(conference.ended_at).to be_nil
      expect(conference).to be_active
      expect(conference.ended_at).to be_nil
    end

    it "should not set ended_at if the conference is no longer active but end_at has not passed" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:closed)
      expect(conference.ended_at).to be_nil
      expect(conference.active?(true)).to eql(false)
      expect(conference.ended_at).to be_nil
    end

    it "should set ended_at if the conference is no longer active and end_at has passed" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:closed)
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      expect(conference.ended_at).to be_nil
      expect(conference.active?(true)).to eql(false)
      expect(conference.ended_at).not_to be_nil
      expect(conference.ended_at).to be < Time.zone.now
    end

    it "should set ended_at if it's more than 15 minutes past end_at" do
      conference.add_attendee(@user)
      conference.stubs(:conference_status).returns(:active)
      expect(conference.ended_at).to be_nil
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      expect(conference.active?(true)).to eql(false)
      expect(conference.conference_status).to eql(:active)
      expect(conference.ended_at).not_to be_nil
      expect(conference.ended_at).to be < Time.zone.now
    end

    it "should not be active if it was manually ended" do
      conference.start_at = 1.hour.ago
      conference.end_at = nil
      conference.ended_at = 1.minute.ago
      expect(conference).not_to be_active
    end

    it "rejects ridiculously long conferences" do
      conference.duration = 100000000000000
      expect(conference).not_to be_valid
    end

    describe "restart" do
      it "sets end_at to the new end date if a duration is known" do
        conference.close
        teh_future = 100.seconds.from_now
        Timecop.freeze(teh_future) do
          conference.restart
          expect(conference.end_at).to eq teh_future + conference.duration.minutes
        end
      end

      it "sets end_at to nil for a long-running manually-restarted conference" do
        conference.duration = nil
        conference.close
        expect(conference.end_at).not_to be_nil
        conference.restart
        expect(conference.end_at).to be_nil
      end
    end
  end

  context "notifications" do
    before :once do
      Notification.create!(:name => 'Web Conference Invitation',
                           :category => "TestImmediately")
      Notification.create!(:name => 'Web Conference Recording Ready',
                           :category => "TestImmediately")
      course_with_teacher(active_all: true)
      @student = user_with_communication_channel(active_all: true)
      student_in_course(user: @student, active_all: true)
    end

    it "should send invitation notifications", priority: "1", test_id: 193154 do
      conference = WimbaConference.create!(
        :title => "my conference",
        :user => @teacher,
        :context => @course
      )
      conference.add_attendee(@student)
      conference.save!
      expect(conference.messages_sent['Web Conference Invitation']).not_to be_empty
    end

    it "should not send invitation notifications if course is not published" do
      @course.workflow_state = 'claimed'
      @course.save!

      conference = WimbaConference.create!(
        :title => "my conference",
        :user => @teacher,
        :context => @course
      )
      conference.add_attendee(@student)
      conference.save!
      expect(conference.messages_sent['Web Conference Invitation']).to be_blank
    end

    it "should not send invitation notifications to inactive users" do
      @course.restrict_enrollments_to_course_dates = true
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!

      conference = WimbaConference.create!(
        :title => "my conference",
        :user => @teacher,
        :context => @course
      )
      conference.add_attendee(@student)
      conference.save!
      expect(conference.messages_sent['Web Conference Invitation']).to be_blank
    end

    it "should send recording ready notifications, but only once" do
      conference = WimbaConference.create!(
        :title => "my conference",
        :user => @student,
        :context => @course
      )
      conference.recording_ready!
      expect(conference.messages_sent['Web Conference Recording Ready'].length).to eq(2)

      # check that it won't send the notification again when saved again.
      conference.save!
      expect(conference.messages_sent['Web Conference Recording Ready'].length).to eq(2)
    end

    it "should not send notifications to users that don't belong to the context" do
      non_course_user = user_with_communication_channel(active_all: true)
      conference = WimbaConference.create!(
        :title => "my conference",
        :user => @teacher,
        :context => @course
      )
      conference.add_attendee(non_course_user)
      conference.save!
      expect(conference.messages_sent['Web Conference Invitation']).to be_blank
    end
  end

  context "scheduled conferences" do
    before :once do
      course_with_student(:active_all => 1)
      @conference = WimbaConference.create!(:title => "my conference", :user => @user, :duration => 60, :context => course)
    end

    it "has a start date" do
      @conference.start_at = Time.now
      expect(@conference.scheduled?).to be_falsey
    end

    it "has a schduled date in the past" do
      @conference.stubs(:scheduled_date).returns(Time.now - 10.days)
      expect(@conference.scheduled?).to be_falsey
    end

    it "has a schduled date in the future" do
      @conference.stubs(:scheduled_date).returns(Time.now + 10.days)
      expect(@conference.scheduled?).to be_truthy
    end

  end

  context "creation rights" do
    it "should let teachers create conferences" do
      course_with_teacher(:active_all => true)
      expect(@course.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_truthy

      group(:context => @course)
      expect(@group.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_truthy
    end

    it "should not let teachers create conferences if the permission is disabled" do
      course_with_teacher(:active_all => true)
      @course.account.role_overrides.create!(:role => teacher_role, :permission => "create_conferences", :enabled => false)
      expect(@course.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_falsey

      group(:context => @course)
      expect(@group.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_falsey
    end

    it "should let students create conferences" do
      course_with_student(:active_all => true)
      expect(@course.web_conferences.temp_record.grants_right?(@student, :create)).to be_truthy

      group_with_user(:user => @student, :context => @course)
      expect(@group.web_conferences.temp_record.grants_right?(@student, :create)).to be_truthy
    end

    it "should not let students create conferences if the permission is disabled" do
      course_with_student(:active_all => true)
      @course.account.role_overrides.create!(:role => student_role, :permission => "create_conferences", :enabled => false)
      expect(@course.web_conferences.temp_record.grants_right?(@student, :create)).to be_falsey

      group_with_user(:user => @student, :context => @course)
      expect(@group.web_conferences.temp_record.grants_right?(@student, :create)).to be_falsey
    end
  end

end
