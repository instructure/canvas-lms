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

require "feedjira"

describe CalendarsController do
  def course_event(date = nil)
    date = Date.parse(date) if date
    @event = @course.calendar_events.create(title: "some assignment", start_at: date, end_at: date)
  end

  before(:once) do
    course_with_student(active_all: true)
  end

  before { user_session(@student) }

  describe "GET 'show'" do
    it "does not redirect to the old calendar even with default settings" do
      get "show", params: { user_id: @user.id }
      expect(response).not_to redirect_to(calendar_url(anchor: " "))
    end

    it "assigns variables" do
      course_event
      get "show", params: { user_id: @user.id }
      expect(response).to be_successful
      expect(assigns[:contexts]).not_to be_nil
      expect(assigns[:contexts]).not_to be_empty
      expect(assigns[:contexts][0]).to eql(@user)
      expect(assigns[:contexts][1]).to eql(@course)
    end

    it "sets user_is_student based off enrollments" do
      course_event
      get "show", params: { user_id: @user.id }
      expect(response).to be_successful
      expect(assigns[:contexts_json][0][:user_is_student]).to be(false)
      expect(assigns[:contexts_json][1][:user_is_student]).to be(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.due_date_required_for_account? == true" do
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      get "show", params: { user_id: @user.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env DUE_DATE_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.due_date_required_for_account? == false" do
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(false)
      get "show", params: { user_id: @user.id }
      expect(assigns[:js_env][:DUE_DATE_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env SIS_NAME is SIS when @context does not respond_to assignments" do
      allow(@course).to receive(:respond_to?).and_return(false)
      allow(controller).to receive(:set_js_assignment_data).and_return({ js_env: {} })
      get "show", params: { user_id: @user.id }
      expect(assigns[:js_env][:SIS_NAME]).to eq("SIS")
    end

    it "js_env SIS_NAME is Foo Bar when AssignmentUtil.post_to_sis_friendly_name is Foo Bar" do
      allow(AssignmentUtil).to receive(:post_to_sis_friendly_name).and_return("Foo Bar")
      get "show", params: { user_id: @user.id }
      expect(assigns[:js_env][:SIS_NAME]).to eq("Foo Bar")
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is true when AssignmentUtil.name_length_required_for_account? == true" do
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(true)
      get "show", params: { user_id: @user.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to be(true)
    end

    it "js_env MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT is false when AssignmentUtil.name_length_required_for_account? == false" do
      allow(AssignmentUtil).to receive(:name_length_required_for_account?).and_return(false)
      get "show", params: { user_id: @user.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT]).to be(false)
    end

    it "js_env MAX_NAME_LENGTH is a 15 when AssignmentUtil.assignment_max_name_length returns 15" do
      allow(AssignmentUtil).to receive(:assignment_max_name_length).and_return(15)
      get "show", params: { user_id: @user.id }
      expect(assigns[:js_env][:MAX_NAME_LENGTH]).to eq(15)
    end

    it "sets account's auto_subscribe" do
      account = @user.account
      account.account_calendar_visible = true
      account.account_calendar_subscription_type = "auto"
      account.save!
      @admin = account_admin_user(account:, active_all: true)
      @admin.set_preference(:enabled_account_calendars, account.id)
      get "show"
      expect(assigns[:contexts_json].find { |c| c[:type] == "account" }[:auto_subscribe]).to be(true)
    end

    it "sets viewed_auto_subscribed_account_calendars for viewed auto-subscribed account calendars" do
      account = @student.account
      account.account_calendar_visible = true
      account.account_calendar_subscription_type = "auto"
      account.save!
      @admin = account_admin_user(account:, active_all: true)
      @admin.set_preference(:enabled_account_calendars, account.id)
      get "show"
      expect(@student.get_preference(:viewed_auto_subscribed_account_calendars)).to eql([account.global_id])
    end

    it "does not set viewed_auto_subscribed_account_calendars for viewed manual-subscribed account calendars" do
      account = @user.account
      account.account_calendar_visible = true
      account.account_calendar_subscription_type = "manual"
      account.save!
      @admin = account_admin_user(account:, active_all: true)
      @admin.set_preference(:enabled_account_calendars, account.id)
      get "show"
      expect(@student.get_preference(:viewed_auto_subscribed_account_calendars)).to eql([])
    end

    it "includes unviewed, auto subscribed calendars to be selected" do
      account = @user.account
      account.account_calendar_visible = true
      account.account_calendar_subscription_type = "auto"
      account.save!
      @admin = account_admin_user(account:, active_all: true)
      @admin.set_preference(:enabled_account_calendars, account.id)
      @student.set_preference(:selected_calendar_contexts, [])
      get "show"
      expect(assigns[:selected_contexts]).to eql([account.asset_string])
    end

    it "has account calendars cope with a non-array user preference" do
      # this was caught in Sentry when the :selected_calendar_contexts preference
      # was a string instead of an array.
      account = @user.account
      account.account_calendar_visible = true
      account.account_calendar_subscription_type = "auto"
      account.save!
      @admin = account_admin_user(account:, active_all: true)
      @admin.set_preference(:enabled_account_calendars, account.id)
      # this pref should be an array, but sometimes is not
      @student.set_preference(:selected_calendar_contexts, account.asset_string)
      get "show"
      expect(assigns[:selected_contexts]).to eql([account.asset_string])
    end

    it "sets selected_contexts to nil if the user_preference is nil" do
      # this was caught in Sentry when the :selected_calendar_contexts preference
      # was a string instead of an array.
      account = @user.account
      account.account_calendar_visible = true
      account.account_calendar_subscription_type = "auto"
      account.save!
      @admin = account_admin_user(account:, active_all: true)
      @admin.set_preference(:enabled_account_calendars, account.id)
      # this pref should be an array, but sometimes is not
      @student.set_preference(:selected_calendar_contexts, nil)
      get "show"
      expect(assigns[:selected_contexts]).to be_nil
    end

    it "sets context.course_sections.can_create_ag based off :manage_calendar permission" do
      @section1 = @course.default_section
      @section2 = @course.course_sections.create!(name: "Section 2")
      @user.enrollments.destroy_all
      @course.enroll_teacher(@user, enrollment_state: :active, section: @section2)
      @user.enrollments.update_all(limit_privileges_to_course_section: true)

      get "show", params: { user_id: @user.id }
      contexts = assigns(:contexts_json)
      sections = contexts[1][:course_sections]
      sections.each do |section|
        if section[:name] == "Section 2"
          expect(section[:can_create_ag]).to be_truthy
        else
          expect(section[:can_create_ag]).to be_falsey
        end
      end
    end

    it "does not set context.course_sections on account contexts" do
      account = @course.account
      account.account_calendar_visible = true
      account.save!
      @admin = account_admin_user(account:, active_all: true)
      @course.enroll_teacher(@admin, enrollment_state: :active)
      @admin.set_preference(:enabled_account_calendars, account.id)
      user_session(@admin)

      get "show"
      contexts = assigns(:contexts_json)
      expect(contexts.find { |c| c[:type] == "account" }[:course_sections]).to be_nil
      expect(contexts.find { |c| c[:type] == "course" }[:course_sections].length).to be 1
    end

    it "emits calendar.visit metric to statsd with appropriate enrollment tags" do
      allow(InstStatsd::Statsd).to receive(:increment)
      course_with_teacher(user: @user, active_all: true)

      get "show", params: { user_id: @user.id }
      expect(InstStatsd::Statsd).to have_received(:increment).once.with("calendar.visit", tags: %w[enrollment_type:StudentEnrollment enrollment_type:TeacherEnrollment])
    end

    context "with sharding" do
      specs_require_sharding

      it "sets permissions using contexts from the correct shard" do
        # non-shard-aware code could use a shard2 id on shard1. this could grab the wrong course,
        # or no course at all. this sort of aliasing used to break a permission check in show
        invalid_shard1_course_id = (Course.maximum(:id) || 0) + 1
        @shard2.activate do
          account = Account.create!
          @course = account.courses.build
          @course.id = invalid_shard1_course_id
          @course.save!
          @course.offer!
          student_in_course(active_all: true, user: @user)
        end
        get "show", params: { user_id: @user.id }
        expect(response).to be_successful
      end

      it "sets context.course_sections.can_create_ag for users in sections on multiple shards" do
        # ensure we're shard aware by picking a section id that is guaranteed to not exist on shard1
        invalid_shard1_section_id = (CourseSection.maximum(:id) || 0) + 1
        @user.enrollments.destroy_all
        @shard2.activate do
          account2 = Account.create!
          course_with_student(account: account2, user: @user)
          @section = @course.course_sections.build
          @section.id = invalid_shard1_section_id
          @section.name = "Teacher Section"
          @section.save!
          @course.enroll_teacher(@user, enrollment_state: :active, section: @section)
          @user.enrollments.shard(Shard.current).update_all(limit_privileges_to_course_section: true)
        end

        get "show", params: { user_id: @user.id }
        expect(response).to be_successful

        contexts = assigns(:contexts_json)
        sections = contexts[1][:course_sections]
        sections.each do |section|
          if section[:name] == "Teacher Section"
            expect(section[:can_create_ag]).to be_truthy
          else
            expect(section[:can_create_ag]).to be_falsey
          end
        end
      end
    end
  end
end

describe CalendarEventsApiController do
  def course_event(date = Time.now)
    @event = @course.calendar_events.create(title: "some assignment", start_at: date, end_at: date)
  end

  describe "GET 'public_feed'" do
    before(:once) do
      course_with_student(active_all: true)
      course_event
      @course.is_public = true
      @course.save!
      @course.assignments.create!(title: "some assignment")
    end

    it "assigns variables" do
      get "public_feed", params: { feed_code: "course_#{@course.uuid}" }, format: "ics"
      expect(response).to be_successful
      expect(assigns[:events]).to be_present
      expect(assigns[:events][0]).to eql(@event)
    end

    it "uses the relevant event for that section, in the course feed" do
      skip "requires changing the format of the course feed url to include user information"
      s2 = @course.course_sections.create!(name: "s2")
      c1 = factory_with_protected_attributes(@event.child_events, description: @event.description, title: @event.title, context: @course.default_section, start_at: 2.hours.ago, end_at: 1.hour.ago)
      factory_with_protected_attributes(@event.child_events, description: @event.description, title: @event.title, context: s2, start_at: 3.hours.ago, end_at: 2.hours.ago)
      get "public_feed", params: { feed_code: "course_#{@course.uuid}", format: "ics" }
      expect(response).to be_successful
      expect(assigns[:events]).to be_present
      expect(assigns[:events]).to eq [c1]
    end

    context "for a user context" do
      it "uses the relevant event for that section" do
        s2 = @course.course_sections.create!(name: "s2")
        c1 = factory_with_protected_attributes(@event.child_events, description: @event.description, title: @event.title, context: @course.default_section, start_at: 2.hours.ago, end_at: 1.hour.ago)
        factory_with_protected_attributes(@event.child_events, description: @event.description, title: @event.title, context: s2, start_at: 3.hours.ago, end_at: 2.hours.ago)
        get "public_feed", params: { feed_code: "user_#{@user.uuid}" }, format: "ics"
        expect(response).to be_successful
        expect(assigns[:events]).to be_present
        expect(assigns[:events]).to eq [c1]
      end

      it "requires authorization" do
        get "public_feed", params: { feed_code: @user.feed_code + "x" }, format: "atom"
        expect(response).to render_template("shared/unauthorized_feed")
      end

      it "includes absolute path for rel='self' link" do
        get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
        feed = Feedjira.parse(response.body)
        expect(feed).not_to be_nil
        expect(feed.feed_url).to match(%r{http://})
      end

      it "includes an author for each entry" do
        get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
        feed = Feedjira.parse(response.body)
        expect(feed).not_to be_nil
        expect(feed.entries).not_to be_empty
        expect(feed.entries.all? { |e| e.author.present? }).to be_truthy
      end

      it "includes description in event for unlocked assignment" do
        assignment = @course.assignments.create!({
                                                   title: "assignment event test",
                                                   description: "foo",
                                                   due_at: Time.zone.now + (60 * 5)
                                                 })
        get "public_feed", params: { feed_code: @user.feed_code }, format: "ics"
        expect(response.body).to include("DESCRIPTION:#{assignment.description}")
      end

      it "does not include description in event for locked assignment" do
        assignment = @course.assignments.create!({
                                                   title: "assignment event test",
                                                   description: "foo",
                                                   due_at: Time.zone.now + (60 * 10),
                                                   unlock_at: Time.zone.now + (60 * 5)
                                                 })
        get "public_feed", params: { feed_code: @user.feed_code }, format: "ics"
        expect(response.body).not_to include("DESCRIPTION:#{assignment.description}")
      end
    end
  end
end
