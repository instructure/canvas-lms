# frozen_string_literal: true

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

describe WebConference do
  include ExternalToolsSpecHelper

  before { stub_plugins }

  def stub_plugins
    allow(WebConference).to receive(:plugins).and_return(
      [
        web_conference_plugin_mock("big_blue_button", { domain: "bbb.instructure.com", secret_dec: "secret" }),
        web_conference_plugin_mock("wimba", { domain: "wimba.test" }),
        web_conference_plugin_mock("broken_plugin", { foor: :bar })
      ]
    )
  end

  describe ".enabled_plugin_conference_names" do
    it "returns the enabled plugins" do
      expect(WebConference.enabled_plugin_conference_names).to match_array(["Big blue button", "Wimba"])
    end
  end

  describe ".conference_tab_name" do
    context "when there are plugins enabled" do
      it "returns the plugin names" do
        expect(WebConference.conference_tab_name).to eq("Big blue button Wimba")
      end
    end

    context "when there are no enabled" do
      before do
        allow(WebConference).to receive(:plugins).and_return([])
      end

      it "returns Conferences" do
        expect(WebConference.conference_tab_name).to eq("Conferences")
      end
    end
  end

  context "broken_plugin" do
    it "returns false on valid_config? if no matching config" do
      expect(WebConference.new).not_to be_valid_config
      conf = WebConference.new
      conf.conference_type = "bad_type"
      expect(conf).not_to be_valid_config
    end

    it "returns false on valid_config? if plugin subclass is broken/missing" do
      conf = WebConference.new
      conf.conference_type = "broken_plugin"
      expect(conf).not_to be_valid_config
    end
  end

  context "user settings" do
    before do
      user_model
    end

    it "ignores invalid user settings" do
      email = "email@email.com"
      allow(@user).to receive(:email).and_return(email)
      conference = WimbaConference.create!(title: "my conference", user: @user, user_settings: { foo: :bar }, context: course_factory)
      expect(conference.user_settings).to be_empty
    end

    it "does not expose internal settings to users" do
      email = "email@email.com"
      allow(@user).to receive(:email).and_return(email)
      conference = BigBlueButtonConference.new(title: "my conference", user: @user, context: course_factory)
      conference.settings = { record: true, not: :for_user }
      conference.save
      conference.reload
      expect(conference.user_settings).not_to have_key(:not)
    end

    it "does not mark object dirty if settings are unchanged" do
      email = "email@email.com"
      allow(@user).to receive(:email).and_return(email)
      conference = BigBlueButtonConference.create!(title: "my conference", user: @user, context: course_factory, user_settings: { record: true })
      user_settings = conference.user_settings.dup
      conference.user_settings = user_settings
      expect(conference).not_to be_changed
    end

    it "marks object dirty if settings are changed" do
      email = "email@email.com"
      allow(@user).to receive(:email).and_return(email)
      conference = BigBlueButtonConference.create!(title: "my conference", user: @user, context: course_factory, user_settings: { record: true })
      conference.user_settings = { record: false }
      expect(conference).to be_changed
    end
  end

  context "starting and ending" do
    before do
      user_model
    end

    let!(:conference) do
      WimbaConference.create!(title: "my conference", user: @user, duration: 60, context: course_factory)
    end

    before do
      email = "email@email.com"
      allow(@user).to receive(:email).and_return(email)
    end

    it "does not set start and end times by default" do
      expect(conference.start_at).to be_nil
      expect(conference.end_at).to be_nil
      expect(conference.started_at).to be_nil
      expect(conference.ended_at).to be_nil
    end

    it "sets start and end times when a paricipant is added" do
      conference.add_attendee(@user)
      expect(conference.start_at).not_to be_nil
      expect(conference.end_at).to eql(conference.start_at + conference.duration_in_seconds)
      expect(conference.started_at).to eql(conference.start_at)
      expect(conference.ended_at).to be_nil
    end

    it "does not set ended_at if the conference is still active" do
      conference.add_attendee(@user)
      allow(conference).to receive(:conference_status).and_return(:active)
      expect(conference.ended_at).to be_nil
      expect(conference).to be_active
      expect(conference.ended_at).to be_nil
    end

    it "does not set ended_at if the conference is no longer active but end_at has not passed" do
      conference.add_attendee(@user)
      allow(conference).to receive(:conference_status).and_return(:closed)
      expect(conference.ended_at).to be_nil
      expect(conference.active?(true)).to be(false)
      expect(conference.ended_at).to be_nil
    end

    it "sets ended_at if the conference is no longer active and end_at has passed" do
      conference.add_attendee(@user)
      allow(conference).to receive(:conference_status).and_return(:closed)
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      expect(conference.ended_at).to be_nil
      expect(conference.active?(true)).to be(false)
      expect(conference.ended_at).not_to be_nil
      expect(conference.ended_at).to be < Time.zone.now
    end

    it "sets ended_at if it's more than 15 minutes past end_at" do
      conference.add_attendee(@user)
      allow(conference).to receive(:conference_status).and_return(:active)
      expect(conference.ended_at).to be_nil
      conference.start_at = 30.minutes.ago
      conference.end_at = 20.minutes.ago
      conference.save!
      expect(conference.active?(true)).to be(false)
      expect(conference.conference_status).to be(:active)
      expect(conference.ended_at).not_to be_nil
      expect(conference.ended_at).to be < Time.zone.now
    end

    it "is not active if it was manually ended" do
      conference.start_at = 1.hour.ago
      conference.end_at = nil
      conference.ended_at = 1.minute.ago
      expect(conference).not_to be_active
    end

    it "rejects ridiculously long conferences" do
      conference.duration = 100_000_000_000_000
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

  context "invite users" do
    it "invites users from a specified set of user ids" do
      user1 = user_factory(active_all: true)
      user2 = user_factory(active_all: true)
      course = course_factory(active_all: true)
      course.enroll_student(user1).accept!
      course.enroll_student(user2).accept!
      conference = BigBlueButtonConference.new(title: "my conference", user: user1, context: course)
      conference.save
      conference.invite_users_from_context([user2.id])
      expect(conference.invitees.pluck(:user_id)).to match_array([user2.id])
    end

    it "invites all users from context" do
      user1 = user_factory(active_all: true)
      user2 = user_factory(active_all: true)
      course = course_factory(active_all: true)
      course.enroll_student(user1).accept!
      course.enroll_student(user2).accept!
      conference = BigBlueButtonConference.new(title: "my conference", user: user1, context: course)
      conference.save
      conference.invite_users_from_context
      expect(conference.invitees.pluck(:user_id)).to match_array(course.user_ids)
    end
  end

  context "notifications" do
    before do
      Notification.create!(name: "Web Conference Invitation",
                           category: "TestImmediately")
      Notification.create!(name: "Web Conference Recording Ready",
                           category: "TestImmediately")
      course_with_teacher(active_all: true)
      @student = user_with_communication_channel(active_all: true)
      student_in_course(user: @student, active_all: true)
    end

    it "sends invitation notifications", priority: "1" do
      conference = WimbaConference.create!(
        title: "my conference",
        user: @teacher,
        context: @course
      )
      conference.add_attendee(@student)
      conference.save!
      expect(conference.messages_sent["Web Conference Invitation"]).not_to be_empty
    end

    it "does not send invitation notifications if course is not published" do
      @course.workflow_state = "claimed"
      @course.save!

      conference = WimbaConference.create!(
        title: "my conference",
        user: @teacher,
        context: @course
      )
      conference.add_attendee(@student)
      conference.save!
      expect(conference.messages_sent["Web Conference Invitation"]).to be_blank
    end

    it "does not send invitation notifications to inactive users" do
      @course.restrict_enrollments_to_course_dates = true
      @course.start_at = 2.days.from_now
      @course.conclude_at = 4.days.from_now
      @course.save!

      conference = WimbaConference.create!(
        title: "my conference",
        user: @teacher,
        context: @course
      )
      conference.add_attendee(@student)
      conference.save!
      expect(conference.messages_sent["Web Conference Invitation"]).to be_blank
    end

    it "sends recording ready notifications, but only once" do
      conference = WimbaConference.create!(
        title: "my conference",
        user: @student,
        context: @course
      )
      conference.recording_ready!
      expect(conference.messages_sent["Web Conference Recording Ready"].length).to eq(2)

      # check that it won't send the notification again when saved again.
      conference.save!
      expect(conference.messages_sent["Web Conference Recording Ready"].length).to eq(2)
    end

    it "does not send notifications to users that don't belong to the context" do
      non_course_user = user_with_communication_channel(active_all: true)
      conference = WimbaConference.create!(
        title: "my conference",
        user: @teacher,
        context: @course
      )
      conference.add_attendee(non_course_user)
      conference.save!
      expect(conference.messages_sent["Web Conference Invitation"]).to be_blank
    end
  end

  context "scheduled conferences" do
    before do
      course_with_student(active_all: 1)
      @conference = WimbaConference.create!(title: "my conference", user: @user, duration: 60, context: @course)
    end

    it "has a start date" do
      @conference.start_at = Time.now
      expect(@conference.scheduled?).to be_falsey
    end

    it "has a schduled date in the past" do
      allow(@conference).to receive(:scheduled_date).and_return(Time.now - 10.days)
      expect(@conference.scheduled?).to be_falsey
    end

    it "has a schduled date in the future" do
      allow(@conference).to receive(:scheduled_date).and_return(Time.now + 10.days)
      expect(@conference.scheduled?).to be_truthy
    end
  end

  context "creation rights" do
    it "lets teachers create conferences" do
      course_with_teacher(active_all: true)
      expect(@course.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_truthy

      group(context: @course)
      expect(@group.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_truthy
    end

    it "does not let teachers create conferences if the permission is disabled" do
      course_with_teacher(active_all: true)
      @course.account.role_overrides.create!(role: teacher_role, permission: "create_conferences", enabled: false)
      expect(@course.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_falsey

      group(context: @course)
      expect(@group.web_conferences.temp_record.grants_right?(@teacher, :create)).to be_falsey
    end

    it "lets students create conferences" do
      course_with_student(active_all: true)
      expect(@course.web_conferences.temp_record.grants_right?(@student, :create)).to be_truthy

      group_with_user(user: @student, context: @course)
      expect(@group.web_conferences.temp_record.grants_right?(@student, :create)).to be_truthy
    end

    it "does not let students create conferences if the permission is disabled" do
      course_with_student(active_all: true)
      @course.account.role_overrides.create!(role: student_role, permission: "create_conferences", enabled: false)
      expect(@course.web_conferences.temp_record.grants_right?(@student, :create)).to be_falsey

      group_with_user(user: @student, context: @course)
      expect(@group.web_conferences.temp_record.grants_right?(@student, :create)).to be_falsey
    end
  end

  context "calendar events" do
    it "nullifies event conference when a conference is destroyed" do
      course_with_teacher(active_all: true)
      conference = WimbaConference.create!(title: "my conference", user: @user, context: @course)
      event = calendar_event_model web_conference: conference
      conference.web_conference_participants.scope.delete_all
      conference.destroy!
      expect(event.reload.web_conference).to be_nil
    end
  end

  context "LTI conferences" do
    let_once(:course) { course_model }
    let_once(:tool) do
      new_valid_tool(course).tap do |t|
        t.name = "course tool"
        t.conference_selection = { message_type: "LtiResourceLinkRequest" }
        t.save!
      end
    end
    let_once(:user) { user_model }

    it "does not include LTI conference types without the feature flag enabled" do
      expect(WebConference.conference_types(course).pluck(:conference_type)).not_to include "LtiConference"
    end

    context "with conference_selection_lti_placement FF" do
      before do
        Account.site_admin.enable_feature! :conference_selection_lti_placement
      end

      context "self.conference_types" do
        it "includes an LTI conference type" do
          expect(WebConference.conference_types(course).pluck(:conference_type)).to include "LtiConference"
          expect(WebConference.conference_types(course).pluck(:name)).to include tool.name
        end

        it "includes LTI tools from reachable contexts" do
          tool.update! context: Account.default
          expect(WebConference.conference_types(course).pluck(:name)).to include tool.name
        end

        it "can include multiple LTI conference type" do
          another_tool = new_valid_tool(course)
          another_tool.name = "same course tool"
          another_tool.conference_selection = { message_type: "LtiResourceLinkRequest" }
          another_tool.save!
          expect(WebConference.conference_types(course).pluck(:name)).to include tool.name
          expect(WebConference.conference_types(course).pluck(:name)).to include another_tool.name
        end

        it "only includes tools with conference_selection placements" do
          editor_button = new_valid_tool(course)
          editor_button.name = "different type of tool"
          editor_button.editor_button = { message_type: "LtiResourceLinkRequest" }
          editor_button.save!

          expect(WebConference.conference_types(course).pluck(:name)).not_to include editor_button.name
        end

        it "only includes types from the given context" do
          another_course = course_model
          another_tool = new_valid_tool(another_course)
          another_tool.name = "another course tool"
          another_tool.conference_selection = { message_type: "LtiResourceLinkRequest" }
          another_tool.save!

          expect(WebConference.conference_types(course).pluck(:name)).not_to include another_tool.name
          expect(WebConference.conference_types(another_course).pluck(:name)).to include another_tool.name
        end
      end

      context ".active scope" do
        it "does not include LTI conferences" do
          conference = course.web_conferences.create! do |c|
            c.user = user
            c.conference_type = "LtiConference"
            c.lti_settings = { tool_id: tool.id }
          end
          expect(WebConference.active.pluck(:id)).not_to include conference.id
        end
      end

      context "instance methods" do
        it "allows creating an LTI conference" do
          conference = course.web_conferences.create! do |c|
            c.user = user
            c.conference_type = "LtiConference"
            c.lti_settings = { tool_id: tool.id }
          end
          expect(conference).not_to be_nil
        end

        it "requires an external tool be specified" do
          conference = course.web_conferences.build
          conference.user = user
          conference.conference_type = "LtiConference"
          conference.lti_settings = { foo: "bar" }
          expect(conference).not_to be_valid
          expect(conference.errors[:settings].to_s).to include("must exist")
        end

        it "requires the external tool be visible from the conference context" do
          another_tool = new_valid_tool(course_model)
          another_tool.conference_selection = { message_type: "LtiResourceLinkRequest" }
          another_tool.save!

          conference = course.web_conferences.build
          conference.user = user
          conference.conference_type = "LtiConference"
          conference.lti_settings = { tool_id: another_tool.id }
          expect(conference).not_to be_valid
          expect(conference.errors[:settings].to_s).to include("visible in context")
        end

        it "requires the external tool have a conference_selection placement" do
          another_tool = new_valid_tool(course)
          another_tool.editor_button = { message_type: "LtiResourceLinkRequest" }
          another_tool.save!

          conference = course.web_conferences.build
          conference.user = user
          conference.conference_type = "LtiConference"
          conference.lti_settings = { tool_id: another_tool.id }
          expect(conference).not_to be_valid
          expect(conference.errors[:settings].to_s).to include("conference_selection placement")
        end
      end
    end
  end

  context "record creation" do
    it "sets the root_account_id using course context" do
      course_factory
      user_factory
      tool = new_valid_tool(@course)
      tool.conference_selection = { message_type: "LtiResourceLinkRequest" }
      tool.save!

      conference = @course.web_conferences.build
      conference.user = @user
      conference.conference_type = "LtiConference"
      conference.lti_settings = { tool_id: tool.id }
      conference.save!

      expect(conference.root_account_id).to eq @course.root_account_id
    end
  end
end
