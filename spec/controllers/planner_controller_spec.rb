# frozen_string_literal: true

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

describe PlannerController do
  before :once do
    Account.find_or_create_by!(id: 0).update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @group = @course.assignment_groups.create(name: "some group")
    @assignment = course_assignment
    @assignment2 = course_assignment
    @assignment.unmute!
    @assignment2.unmute!
  end

  def course_assignment
    @course.assignments.create(
      title: "some assignment #{@course.assignments.count}",
      assignment_group: @group,
      due_at: 1.week.from_now
    )
  end

  context "unauthenticated" do
    it "returns unauthorized" do
      get :index
      assert_unauthorized
    end
  end

  context "as student" do
    before do
      user_session(@student)
    end

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to be_successful
      end

      it "checks the planner cache" do
        found_planner_meta_request = false
        found_planner_items_request = false
        allow(Rails.cache).to receive(:fetch) do |cache_key, &block|
          if cache_key.include?("planner_items_meta")
            found_planner_meta_request = true
            "meta-cache-key"
          elsif cache_key.include?("meta-cache-key")
            found_planner_items_request = true
            block.call
          else
            block.call
          end
        end
        get :index
        expect(found_planner_meta_request).to be true
        expect(found_planner_items_request).to be true
      end

      it "shows wiki pages with todo dates" do
        wiki_page_model(course: @course)
        @page.todo_date = 1.day.from_now
        @page.save!
        get :index
        response_json = json_parse(response.body)
        expect(response_json.length).to eq 3
        page = response_json.detect { |i| i["plannable_id"] == @page.id }
        expect(page["plannable_type"]).to eq "wiki_page"
      end

      it "shows planner notes for the user" do
        planner_note_model(course: @course)
        get :index
        response_json = json_parse(response.body)
        note = response_json.detect { |i| i["plannable_type"] == "planner_note" }
        expect(response_json.length).to eq 3
        expect(note["plannable"]["title"]).to eq @planner_note.title
      end

      it "shows calendar events for the course and user" do
        ce = calendar_event_model(start_at: 1.day.from_now)
        ue = @student.calendar_events.create!(start_at: 2.days.from_now, title: "user_event")
        get :index
        response_json = json_parse(response.body)
        course_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == ce.id }
        user_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == ue.id }
        expect(course_event["plannable"]["title"]).to eq ce.title
        expect(user_event["plannable"]["title"]).to eq "user_event"
      end

      it "does not show group events from inactive courses" do
        @course1 = course_factory
        @course2 = course_factory

        @student1 = user_factory(active_all: true)
        @student1_enrollment = course_with_student(course: @course1, user: @student1, active_all: true)
        course_with_student(course: @course2, user: @student1, active_all: true)

        @course1_group = @course1.groups.create(name: "some group")
        @course1_group.add_user(@student1)

        @course2_group = @course2.groups.create(name: "some other group")
        @course2_group.add_user(@student1)

        course1_event = @course1_group.calendar_events.create!(start_at: 2.days.from_now, title: "user_event1")
        course2_event = @course2_group.calendar_events.create!(start_at: 3.days.from_now, title: "user_event2")

        user_session(@student1)
        get :index
        response_json = json_parse(response.body)
        expect(response_json.length).to eq 2
        expect(response_json.find { |i| i["plannable_id"] == course1_event.id }).to_not be_nil
        expect(response_json.find { |i| i["plannable_id"] == course2_event.id }).to_not be_nil

        @student1_enrollment.deactivate
        @student1 = User.find(@student1.id)
        user_session(@student1)

        get :index
        response_json = json_parse(response.body)
        expect(response_json.length).to eq 1
        expect(response_json.find { |i| i["plannable_id"] == course1_event.id }).to be_nil
        expect(response_json.find { |i| i["plannable_id"] == course2_event.id }).to_not be_nil
      end

      it "shows the appropriate section-specific event for the user" do
        other_section = @course.course_sections.create!(name: "Other Section")
        event = @course.calendar_events.build(title: "event", child_event_data:           { "0" => { start_at: 1.hour.from_now.iso8601, end_at: 2.hours.from_now.iso8601, context_code: @course.default_section.asset_string },
                                                                                            "1" => { start_at: 2.hours.from_now.iso8601, end_at: 3.hours.from_now.iso8601, context_code: other_section.asset_string } })
        event.updating_user = @teacher
        event.save!

        get :index
        json = json_parse(response.body)
        event_ids = json.select { |thing| thing["plannable_type"] == "calendar_event" }.pluck("plannable_id")

        my_event_id = @course.default_section.calendar_events.where(parent_calendar_event_id: event).pluck(:id).first
        expect(event_ids).not_to include event.id
        expect(event_ids).to include my_event_id

        event.update(remove_child_events: true)

        get :index
        json = json_parse(response.body)
        event_ids = json.select { |thing| thing["plannable_type"] == "calendar_event" }.pluck("plannable_id")
        expect(event_ids).to include event.id
        expect(event_ids).not_to include my_event_id
      end

      it "shows appointment group reservations" do
        ag = appointment_group_model(title: "appointment group")
        ap = appointment_participant_model(participant: @student, course: @course, appointment_group: ag)
        get :index
        response_json = json_parse(response.body)
        event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == ap.id }
        expect(event["plannable"]["title"]).to eq "appointment group"
      end

      it "only shows section specific announcements to students who can view them" do
        a1 = @course.announcements.create!(message: "for the defaults", is_section_specific: true, course_sections: [@course.default_section])
        sec2 = @course.course_sections.create!
        @course.announcements.create!(message: "for my favorites", is_section_specific: true, course_sections: [sec2])

        get :index
        response_json = json_parse(response.body)
        expect(response_json.select { |i| i["plannable_type"] == "announcement" }.pluck("plannable_id")).to eq [a1.id]
      end

      it "shows planner overrides created on quizzes" do
        quiz = quiz_model(course: @course, due_at: 1.day.from_now)
        PlannerOverride.create!(plannable_id: quiz.id, plannable_type: Quizzes::Quiz, user_id: @student.id)
        get :index
        response_json = json_parse(response.body)
        quiz_json = response_json.find { |rj| rj["plannable_id"] == quiz.id }
        expect(quiz_json["planner_override"]["plannable_id"]).to eq quiz.id
        expect(quiz_json["planner_override"]["plannable_type"]).to eq "quiz"
      end

      it "shows planner overrides created on discussions" do
        discussion = discussion_topic_model(context: @course, todo_date: 1.day.from_now)
        PlannerOverride.create!(plannable_id: discussion.id, plannable_type: DiscussionTopic, user_id: @student.id)
        get :index
        response_json = json_parse(response.body)
        disc_json = response_json.find { |rj| rj["plannable_id"] == discussion.id }
        expect(disc_json["planner_override"]["plannable_id"]).to eq discussion.id
        expect(disc_json["planner_override"]["plannable_type"]).to eq "discussion_topic"
      end

      it "shows planner overrides created on wiki pages" do
        page = wiki_page_model(course: @course, todo_date: 1.day.from_now)
        PlannerOverride.create!(plannable_id: page.id, plannable_type: WikiPage, user_id: @student.id)
        get :index
        response_json = json_parse(response.body)
        page_json = response_json.find { |rj| rj["plannable_id"] == page.id }
        expect(page_json["planner_override"]["plannable_id"]).to eq page.id
        expect(page_json["planner_override"]["plannable_type"]).to eq "wiki_page"
      end

      it "shows peer review tasks for the user" do
        @current_user = @student
        reviewee = course_with_student(course: @course, active_all: true).user
        assignment_model(course: @course, peer_reviews: true)
        submission_model(assignment: @assignment, user: reviewee)
        assessment_request = @assignment.assign_peer_review(@current_user, reviewee)
        get :index
        response_json = json_parse(response.body)
        peer_review = response_json.detect { |i| i["plannable_type"] == "assessment_request" }
        expect(peer_review["plannable"]["id"]).to eq assessment_request.id
        expect(peer_review["plannable"]["title"]).to eq @assignment.title
        expect(peer_review["html_url"]).to match "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      end

      it "shows peer reviews for assignments with no 'everyone' date and no peer review date" do
        @current_user = @student
        reviewee = user_model
        differentiated_assignment(course: @course, peer_reviews: true, due_at: nil)
        @override.update(due_at: Time.zone.now, due_at_overridden: true)
        add_section("section 2").enroll_user(reviewee, "StudentEnrollment", "active")
        create_section_override_for_assignment(@assignment, due_at: nil, course_section: @course_section)
        submission_model(assignment: @assignment, user: reviewee)
        assessment_request = @assignment.assign_peer_review(@current_user, reviewee)
        get :index
        response_json = json_parse(response.body)
        peer_review = response_json.detect { |i| i["plannable_type"] == "assessment_request" }
        expect(peer_review["plannable"]["id"]).to eq assessment_request.id
        expect(peer_review["plannable_date"]).to eq @assignment.submissions.find_by(user: @current_user).cached_due_date.iso8601
      end

      it "marks peer reviews as done when they are completed, if they have been marked as incomplete by an override" do
        @current_user = @student
        reviewee = course_with_student(course: @course, active_all: true).user
        assignment_model(course: @course, peer_reviews: true, due_at: 1.day.ago, peer_reviews_due_at: 1.day.from_now)
        submission_model(assignment: @assignment, user: reviewee)
        assessment_request = @assignment.assign_peer_review(@current_user, reviewee)
        PlannerOverride.create!(user: @current_user, plannable_id: assessment_request.id, plannable_type: "AssessmentRequest", marked_complete: false)
        @submission.add_comment(comment: "comment", author: @current_user, assessment_request:)
        assessment_request.save!
        get :index, params: { start_date: @start_date, end_date: @end_date }
        response_json = json_parse(response.body)
        peer_review = response_json.detect { |i| i["plannable_type"] == "assessment_request" }
        expect(peer_review["planner_override"]["plannable_id"]).to eq assessment_request.id
        expect(peer_review["planner_override"]["marked_complete"]).to be true
      end

      context "include_concluded" do
        before :once do
          @u = User.create!

          # No conclusions
          @c1 = course_with_student(active_all: true, user: @u).course
          @a1 = course_assignment
          @pn1 = planner_note_model(todo_date: 1.day.from_now, course: @c1)

          # Concluded enrollment
          @e2 = course_with_student(active_all: true, user: @u)
          @c2 = @e2.course
          @a2 = course_assignment
          @e2.conclude

          # Soft-concluded course
          @c3 = course_with_student(active_all: true, user: @u).course
          @a3 = course_assignment
          @pn3 = planner_note_model(todo_date: 1.day.from_now, course: @c3)
          @c3.conclude_at = 2.days.ago
          @c3.restrict_enrollments_to_course_dates = true
          @c3.save!
        end

        before do
          user_session(@u)
        end

        it "does not include objects from concluded courses by default" do
          get :index
          response_json = json_parse(response.body)
          items = response_json.map { |i| [i["plannable_type"], i["plannable"]["id"]] }
          expect(items).to include ["assignment", @a1.id]
          expect(items).to include ["planner_note", @pn1.id]
          expect(items).not_to include ["assignment", @a2.id]
          expect(items).not_to include ["assignment", @a3.id]
          expect(items).not_to include ["planner_note", @pn3.id]
        end

        it "includes objects from concluded courses if specified, but never from concluded enrollments" do
          get :index, params: { include: %w[concluded] }
          response_json = json_parse(response.body)
          items = response_json.map { |i| [i["plannable_type"], i["plannable"]["id"]] }
          expect(items).to include ["assignment", @a1.id]
          expect(items).to include ["planner_note", @pn1.id]
          expect(items).not_to include ["assignment", @a2.id]
          expect(items).to include ["assignment", @a3.id]
          expect(items).to include ["planner_note", @pn3.id]
        end
      end

      describe "account calendars" do
        before do
          Account.default.account_calendar_visible = true
          Account.default.save!
          @sub_account1 = Account.default.sub_accounts.create!(name: "SA-1", account_calendar_visible: true)
          @student2 = user_factory(active_all: true)
          @course_ac = course_with_student(active_all: true, user: @student2).course
          course_with_student_logged_in(user: @student2, account: Account.default)
          course_with_student_logged_in(user: @student2, account: @sub_account1)
          @sub_account_event = @sub_account1.calendar_events.create!(title: "Sub account event", start_at: 0.days.from_now)
          @default_account_event = Account.default.calendar_events.create!(title: "Default account event", start_at: 0.days.from_now)

          @student2.set_preference(:enabled_account_calendars, [@sub_account1.id, Account.default.id])
        end

        it "shows calendar events for the enabled account calendars" do
          get :index
          response_json = json_parse(response.body)
          default_account_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == @default_account_event.id }
          sub_account_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == @sub_account_event.id }
          expect(response_json.length).to eq 2
          expect(sub_account_event["plannable"]["title"]).to eq @sub_account_event.title
          expect(default_account_event["plannable"]["title"]).to eq @default_account_event.title
        end

        it "does not show calendar events for hidden account calendars" do
          Account.default.account_calendar_visible = false
          Account.default.save!
          get :index
          response_json = json_parse(response.body)
          account_event = response_json[0]
          expect(response_json.length).to eq 1
          expect(account_event["plannable"]["title"]).to eq @sub_account_event.title
        end

        it "filters by context_codes" do
          get :index, params: { context_codes: [@sub_account1.asset_string] }
          response_json = json_parse(response.body)
          sub_account_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == @sub_account_event.id }
          expect(response_json.length).to eq 1
          expect(sub_account_event["plannable"]["title"]).to eq @sub_account_event.title
        end

        it "returns unauthorized if the context_code is not visible" do
          @sub_account1.account_calendar_visible = false
          @sub_account1.save!
          get :index, params: { context_codes: [@sub_account1.asset_string] }
          assert_unauthorized
        end

        it "does not include account calendar events by default when filtering by context_codes" do
          course_ac_event = @course_ac.calendar_events.create!(title: "Course event", start_at: 0.days.from_now)
          get :index, params: { context_codes: [@course_ac.asset_string] }

          response_json = json_parse(response.body)
          course_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == course_ac_event.id }
          expect(response_json.length).to eq 1
          expect(course_event["plannable"]["title"]).to eq course_ac_event.title
        end

        it "includes account calendar events along with context_codes events if requested" do
          course_ac_event = @course_ac.calendar_events.create!(title: "Course event", start_at: 0.days.from_now)
          get :index, params: { include: %w[account_calendars], context_codes: [@course_ac.asset_string] }

          response_json = json_parse(response.body)
          default_account_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == @default_account_event.id }
          sub_account_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == @sub_account_event.id }
          course_event = response_json.find { |i| i["plannable_type"] == "calendar_event" && i["plannable_id"] == course_ac_event.id }
          expect(response_json.length).to eq 3
          expect(sub_account_event["plannable"]["title"]).to eq @sub_account_event.title
          expect(default_account_event["plannable"]["title"]).to eq @default_account_event.title
          expect(course_event["plannable"]["title"]).to eq course_ac_event.title
        end

        context "with sharding" do
          specs_require_sharding

          it "allows user to request trusted accounts on another shard" do
            @account = Account.default
            @shard2.activate do
              get :index, params: { context_codes: ["account_#{@account.global_id}"] }
              expect(response).to be_successful
            end
          end
        end
      end

      context "with context codes" do
        before :once do
          @course1 = course_with_student(active_all: true).course
          @course2 = course_with_student(active_all: true, user: @student).course
          group_category(context: @course1)
          @group = @group_category.groups.create!(context: @course1)
          @group.add_user(@student, "accepted")
          @assignment1 = assignment_model(course: @course1, due_at: 1.day.from_now)
          @assignment2 = assignment_model(course: @course2, due_at: 1.day.from_now)
          @group_assignment = @course1.assignments.create!(group_category: @group_category, due_at: 1.day.from_now)
          @course_topic = discussion_topic_model(context: @course1, todo_date: 1.day.from_now)
          @group_topic = discussion_topic_model(context: @group, todo_date: 1.day.from_now)
          @course_page = wiki_page_model(course: @course1, todo_date: 1.day.from_now)
          @group_page = wiki_page_model(todo_date: 1.day.from_now, course: @group)
          @assignment3 = assignment_model(course: @course1, due_at: Time.zone.now, only_visible_to_overrides: true)
          create_adhoc_override_for_assignment(@assignment3, @student, { due_at: 2.days.ago })
          @quiz = @course1.quizzes.create!(quiz_type: "practice_quiz", due_at: 1.day.from_now).publish!
          create_adhoc_override_for_assignment(@quiz, @student, { due_at: 2.days.ago })
          @user_note = planner_note_model(user: @student, todo_date: 1.day.ago)
          @course1_note = planner_note_model(user: @student, todo_date: 1.day.from_now, course: @course1)
          @course2_note = planner_note_model(user: @student, todo_date: 1.day.from_now, course: @course2)
          @course1_event = @course1.calendar_events.create!(title: "Course 1 event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @course2_event = @course2.calendar_events.create!(title: "Course 2 event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @group_event = @group.calendar_events.create!(title: "Group event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @user_event = @user.calendar_events.create!(title: "User event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @deleted_page = wiki_page_model(course: @course1, todo_date: 1.day.from_now)
          @deleted_page.destroy
          @deleted_topic = discussion_topic_model(context: @group, todo_date: 1.day.from_now)
          @deleted_topic.destroy
        end

        before do
          user_session(@student)
        end

        it "includes all data by default" do
          get :index, params: { per_page: 50 }
          response_json = json_parse(response.body)
          expect(response_json.length).to be 16
        end

        it "returns data from contexted courses for observed user if specified" do
          observer_in_course(course: @course1, associated_user_id: @student, active_all: true)
          user_session(@observer)
          get :index, params: { per_page: 50, observed_user_id: @student.to_param, context_codes: [@course1.asset_string] }
          response_json = json_parse(response.body)
          expect(response_json.length).to be 8
          response_hash = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(response_hash).to include(["assignment", @assignment1.id])
          expect(response_hash).to include(["assignment", @group_assignment.id])
          expect(response_hash).to include(["discussion_topic", @course_topic.id])
          expect(response_hash).to include(["wiki_page", @course_page.id])
          expect(response_hash).to include(["assignment", @assignment3.id])
          expect(response_hash).to include(["quiz", @quiz.id])
          expect(response_hash).to include(["planner_note", @course1_note.id])
          expect(response_hash).to include(["calendar_event", @course1_event.id])
        end

        it "does not restrict user if session has appropriate permissions for public_to_auth course" do
          @course.update_attribute(:is_public_to_auth_users, true)
          user_factory(active_all: true)
          user_session(@user)
          get :index, params: { context_codes: [@course.asset_string] }
          assert_status(200)
        end

        it "only returns data from contexted courses if specified" do
          get :index, params: { context_codes: [@course1.asset_string] }
          response_json = json_parse(response.body)
          response_hash = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(response_hash).to include(["assignment", @assignment1.id])
          expect(response_hash).to include(["assignment", @group_assignment.id])
          expect(response_hash).to include(["discussion_topic", @course_topic.id])
          expect(response_hash).to include(["wiki_page", @course_page.id])
          expect(response_hash).to include(["assignment", @assignment3.id])
          expect(response_hash).to include(["quiz", @quiz.id])
          expect(response_hash).to include(["planner_note", @course1_note.id])
          expect(response_hash).to include(["calendar_event", @course1_event.id])
          expect(response_hash.length).to be 8
        end

        it "only returns data from contexted users if specified" do
          get :index, params: { context_codes: [@user.asset_string] }
          response_json = json_parse(response.body)
          response_hash = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(response_hash).to include(["planner_note", @user_note.id])
          expect(response_hash).to include(["calendar_event", @user_event.id])
          expect(response_hash.length).to be 2
        end

        it "returns items from all context_codes specified" do
          get :index, params: { context_codes: [@user.asset_string, @group.asset_string] }
          response_json = json_parse(response.body)
          response_hash = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(response_hash).to include(["planner_note", @user_note.id])
          expect(response_hash).to include(["calendar_event", @user_event.id])
          expect(response_hash).to include(["discussion_topic", @group_topic.id])
          expect(response_hash).to include(["wiki_page", @group_page.id])
          expect(response_hash).to include(["calendar_event", @group_event.id])
          expect(response_hash.length).to be 5
        end

        it "returns items from all context_codes specified for group and a different course" do
          get :index, params: { context_codes: [@group.asset_string, @course2.asset_string] }
          response_json = json_parse(response.body)
          response_hash = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          # stuff from course
          expect(response_hash).to include(["assignment", @assignment2.id])
          expect(response_hash).to include(["planner_note", @course2_note.id])
          expect(response_hash).to include(["calendar_event", @course2_event.id])
          # stuff from group of other course
          expect(response_hash).to include(["discussion_topic", @group_topic.id])
          expect(response_hash).to include(["wiki_page", @group_page.id])
          expect(response_hash).to include(["calendar_event", @group_event.id])
          expect(response_hash.length).to be 6
        end

        it "returns unauthorized if the user doesn't have read permission on a context_code" do
          course_with_teacher(active_all: true)
          assignment_model(course: @course, due_at: 1.day.from_now)

          get :index, params: { context_codes: [@course.asset_string] }
          assert_unauthorized
        end

        it "filters ungraded_todo_items" do
          get :index, params: { filter: "ungraded_todo_items" }
          response_json = json_parse(response.body)
          items = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(items).to match_array(
            [["discussion_topic", @course_topic.id],
             ["discussion_topic", @group_topic.id],
             ["wiki_page", @course_page.id],
             ["wiki_page", @group_page.id]]
          )
        end

        it "filters all_ungraded_todo_items for teachers, including unpublished items" do
          @course_page.unpublish
          @group_topic.unpublish
          user_session @course1.teachers.first
          get :index, params: {
            filter: "all_ungraded_todo_items",
            context_codes: [@course1.asset_string, @group.asset_string],
            start_date: 2.weeks.ago.iso8601,
            end_date: 2.weeks.from_now.iso8601
          }
          response_json = json_parse(response.body)
          items = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(items).to match_array(
            [["discussion_topic", @course_topic.id],
             ["discussion_topic", @group_topic.id],
             ["wiki_page", @course_page.id],
             ["wiki_page", @group_page.id]]
          )
        end

        describe "with public syllabus courses" do
          before :once do
            @ps_topic = @course2.discussion_topics.create! title: "ohai", todo_date: 1.day.from_now
            @ps_page = @course2.wiki_pages.create! title: "kthxbai", todo_date: 1.day.from_now
            @course2.public_syllabus = true
            @course2.save!
          end

          it "allows unauthenticated users to view all_ungraded_todo_items" do
            remove_user_session
            get :index, params: {
              filter: "all_ungraded_todo_items",
              context_codes: [@course2.asset_string],
              start_date: 2.weeks.ago.iso8601,
              end_date: 2.weeks.from_now.iso8601
            }
            response_json = json_parse(response.body)
            items = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
            expect(items).to match_array(
              [["discussion_topic", @ps_topic.id],
               ["wiki_page", @ps_page.id]]
            )
          end

          it "allows unenrolled users to view all_ungraded_todo_items" do
            user_session(user_factory)
            get :index, params: {
              filter: "all_ungraded_todo_items",
              context_codes: [@course2.asset_string],
              start_date: 2.weeks.ago.iso8601,
              end_date: 2.weeks.from_now.iso8601
            }
            response_json = json_parse(response.body)
            items = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
            expect(items).to match_array(
              [["discussion_topic", @ps_topic.id],
               ["wiki_page", @ps_page.id]]
            )
          end

          it "returns unauthorized if the course isn't public syllabus" do
            user_session(user_factory)
            get :index, params: {
              filter: "all_ungraded_todo_items",
              context_codes: [@course1.asset_string],
              start_date: 2.weeks.ago.iso8601,
              end_date: 2.weeks.from_now.iso8601
            }
            assert_unauthorized
          end
        end

        it "filters out unpublished todo items for students" do
          @course_page.unpublish
          @group_topic.unpublish
          user_session @course1.students.first
          get :index, params: {
            filter: "all_ungraded_todo_items",
            context_codes: [@course1.asset_string, @group.asset_string],
            start_date: 2.weeks.ago.iso8601,
            end_date: 2.weeks.from_now.iso8601
          }
          response_json = json_parse(response.body)
          items = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(items).to match_array(
            [["discussion_topic", @course_topic.id],
             ["discussion_topic", @group_topic.id], # turns out groups let all members view unpublished items
             ["wiki_page", @group_page.id]]
          )
        end
      end

      context "date sorting" do
        it "returns results in order by date" do
          wiki_page_model(course: @course)
          @page.todo_date = 1.day.from_now
          @page.save!
          @assignment3 = course_assignment
          @assignment3.due_at = 1.week.ago
          @assignment3.save!
          @assignment5 = course_assignment
          @assignment5.due_at = 3.days.from_now
          @assignment5.save!

          get :index
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 5
          expect(response_json.pluck("plannable_id")).to eq [@assignment3.id, @page.id, @assignment5.id, @assignment.id, @assignment2.id]

          get :index, params: { per_page: 2 }
          expect(json_parse(response.body).pluck("plannable_id")).to eq [@assignment3.id, @page.id]

          link = Api.parse_pagination_links(response.headers["Link"]).detect { |p| p[:rel] == "next" }
          expect(link[:uri].path).to include "/api/v1/planner/items"
          get :index, params: { per_page: 2, page: link["page"] }
          expect(json_parse(response.body).pluck("plannable_id")).to eq [@assignment5.id, @assignment.id]

          link = Api.parse_pagination_links(response.headers["Link"]).detect { |p| p[:rel] == "next" }
          get :index, params: { per_page: 2, page: link["page"] }
          expect(json_parse(response.body).pluck("plannable_id")).to eq [@assignment2.id]
        end

        it "behaves consistently with different object types on the same datetime" do
          time = 4.days.from_now
          @assignment.update_attribute(:due_at, time)
          @assignment2.update_attribute(:due_at, time)
          @course.wiki_pages.create!(title: "t1", todo_date: time)
          planner_note_model(todo_date: time)
          discussion_topic_model(context: @course, todo_date: time)

          get :index
          response_json = json_parse(response.body)
          original_order = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }

          get :index, params: { per_page: 3 }
          expect(json_parse(response.body).map { |i| [i["plannable_type"], i["plannable_id"]] }).to eq original_order[0..2]

          next_page = Api.parse_pagination_links(response.headers["Link"]).detect { |p| p[:rel] == "next" }["page"]
          get :index, params: { per_page: 3, page: next_page }
          expect(json_parse(response.body).map { |i| [i["plannable_type"], i["plannable_id"]] }).to eq original_order[3..4]
        end

        it "uses the right bookmarker in different time zones" do
          Account.default.default_time_zone = "America/Denver"
          time = 2.days.from_now
          @assignment.update_attribute(:due_at, time)
          @assignment2.update_attribute(:due_at, time)

          get :index, params: { per_page: 1 }
          expect(json_parse(response.body).pluck("plannable_id")).to eq [@assignment.id]

          next_page = Api.parse_pagination_links(response.headers["Link"]).detect { |p| p[:rel] == "next" }["page"]
          get :index, params: { per_page: 1, page: next_page }
          expect(json_parse(response.body).pluck("plannable_id")).to eq [@assignment2.id]
        end

        it "returns results in reverse order by date if requested" do
          wiki_page_model(course: @course, todo_date: 1.day.from_now)
          @assignment3 = course_assignment
          @assignment3.due_at = 1.week.ago
          @assignment3.save!
          get :index, params: { order: :desc }
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 4
          expect(response_json.pluck("plannable_id")).to eq [@assignment2.id, @assignment.id, @page.id, @assignment3.id]

          get :index, params: { order: :desc, per_page: 2 }
          expect(json_parse(response.body).pluck("plannable_id")).to eq [@assignment2.id, @assignment.id]

          next_page = Api.parse_pagination_links(response.headers["Link"]).detect { |p| p[:rel] == "next" }["page"]
          get :index, params: { order: :desc, per_page: 2, page: next_page }
          expect(json_parse(response.body).pluck("plannable_id")).to eq [@page.id, @assignment3.id]
        end

        it "does not try to compare missing dates" do
          @assignment3 = @course.assignments.create!(submission_types: "online_text_entry")
          # doesn't have a due_at, so it should coalesce to the created_at
          override = @assignment3.assignment_overrides.new(set: @course.default_section)
          override.override_due_at(2.days.from_now)
          override.save!
          @assignment3.submit_homework(@student, submission_type: "online_text_entry", body: "text")
          @assignment3.grade_student @student, grade: 10, grader: @teacher
          get :index
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 3
          expect(response_json.pluck("plannable_id")).to eq [@assignment3.id, @assignment.id, @assignment2.id]
        end

        it "orders with unread items as well" do
          dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 3.days.from_now)
          dt.change_all_read_state("unread", @student)

          @assignment3 = @course.assignments.create!(submission_types: "online_text_entry")
          @assignment3.unmute!
          override = @assignment3.assignment_overrides.new(set: @course.default_section)
          override.override_due_at(2.days.from_now)
          override.save!

          graded_topic = @course.assignments.create!(submission_types: "discussion_topic", due_at: 5.days.from_now).discussion_topic
          graded_topic.change_all_read_state("unread", @student)

          @assignment3.grade_student @student, grade: 10, grader: @teacher
          @assignment.grade_student @student, grade: 10, grader: @teacher

          get :index, params: { filter: "new_activity" }
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 4
          expect(response_json.pluck("plannable_id")).to eq [@assignment3.id, dt.id, graded_topic.id, @assignment.id]
        end

        context "with assignment overrides" do
          before :once do
            course_with_teacher(active_all: true)
            student_in_course(active_all: true)
            @planner_note1 = planner_note_model(user: @student, todo_date: 1.day.ago)
            @planner_note2 = planner_note_model(user: @student, todo_date: 1.day.from_now)
          end

          before do
            user_session(@student)
          end

          it "orders assignments with no overrides correctly" do
            assignment1 = assignment_model(course: @course, due_at: Time.zone.now)
            assignment2 = assignment_model(course: @course, due_at: 2.days.from_now)
            SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)

            get :index, params: { start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601 }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.pluck("plannable_id")).to eq([@planner_note1.id, assignment1.id, @planner_note2.id, assignment2.id])
          end

          it "orders assignments with overridden due dates correctly" do
            assignment1 = assignment_model(course: @course, due_at: Time.zone.now, only_visible_to_overrides: true)
            assign1_override_due_at = 2.days.ago
            create_adhoc_override_for_assignment(assignment1, @student, { due_at: assign1_override_due_at })
            assignment2 = assignment_model(course: @course, due_at: 2.days.from_now)
            assign2_override_due_at = Time.zone.now
            create_adhoc_override_for_assignment(assignment2, @student, { due_at: assign2_override_due_at })
            SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)

            get :index, params: { start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601 }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.pluck("plannable_id")).to eq([assignment1.id, @planner_note1.id, assignment2.id, @planner_note2.id])
          end

          it "orders ungraded quizzes with overridden due dates correctly" do
            quiz1 = @course.quizzes.create!(quiz_type: "practice_quiz", due_at: Time.zone.now).publish!
            quiz1_override_due_at = 2.days.ago
            create_adhoc_override_for_assignment(quiz1, @student, { due_at: quiz1_override_due_at })
            quiz2 = @course.quizzes.create!(quiz_type: "practice_quiz", due_at: 2.days.from_now).publish!
            quiz2_override_due_at = Time.zone.now
            create_adhoc_override_for_assignment(quiz2, @student, { due_at: quiz2_override_due_at })

            get :index, params: { start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601 }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.pluck("plannable_id")).to eq([quiz1.id, @planner_note1.id, quiz2.id, @planner_note2.id])
          end

          it "orders graded discussions with overridden due dates correctly" do
            topic1 = discussion_topic_model(context: @course, todo_date: Time.zone.now)
            topic2 = group_assignment_discussion(course: @course)
            topic2_override_due_at = 2.days.from_now.change(min: 1)
            create_group_override_for_assignment(topic2.assignment, { user: @student, group: @group, due_at: topic2_override_due_at })
            topic2_assign = topic2.assignment
            topic2_assign.due_at = 2.days.ago
            topic2_assign.save!
            SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)

            get :index, params: { start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601 }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| [i["plannable_id"], i["plannable_date"]] }).to eq([
                                                                                               [@planner_note1.id, @planner_note1.todo_date.iso8601],
                                                                                               [topic1.id, topic1.todo_date.iso8601],
                                                                                               [@planner_note2.id, @planner_note2.todo_date.iso8601],
                                                                                               [topic2.root_topic.id, topic2_override_due_at.change(sec: 0).iso8601]
                                                                                             ])
          end

          it "orders mastery path wiki_pages by todo date if applied" do
            page1 = wiki_page_model(course: @course, todo_date: 2.days.ago)
            wiki_page_assignment_model(course: @course)
            @page.todo_date = Time.zone.now
            @page.save!
            SubmissionLifecycleManager.recompute_course(@course, run_immediately: true)

            get :index, params: { start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601 }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.pluck("plannable_id")).to eq([page1.id, @planner_note1.id, @page.id, @planner_note2.id])
          end
        end
      end

      context "with user id" do
        it "allows a student to query her own planner items" do
          get :index, params: { user_id: "self", per_page: 1 }
          expect(response).to be_successful
          link = Api.parse_pagination_links(response.headers["Link"]).detect { |p| p[:rel] == "next" }
          expect(link[:uri].path).to include "/api/v1/users/self/planner/items"
        end

        it "allows a linked observer to query a student's planner items" do
          observer = user_with_pseudonym
          user_session(observer)
          UserObservationLink.create_or_restore(observer:, student: @student, root_account: Account.default)
          get :index, params: { user_id: @student.to_param, per_page: 1 }
          expect(response).to be_successful
          link = Api.parse_pagination_links(response.headers["Link"]).detect { |p| p[:rel] == "next" }
          expect(link[:uri].path).to include "/api/v1/users/#{@student.to_param}/planner/items"
        end

        it "does not allow a user without :read_as_parent to query another user's planner items" do
          rando = user_with_pseudonym
          user_session(rando)
          get :index, params: { user_id: @student.to_param, per_page: 1 }
          expect(response).to be_unauthorized
        end
      end

      context "cross-sharding" do
        specs_require_sharding

        before :once do
          @original_course = @course
          @shard1.activate do
            @another_account = Account.create!
            @another_course = @another_account.courses.create!(id: @course.local_id, workflow_state: "available")
          end
        end

        it "ignores shards other than the current account's" do
          @shard1.activate do
            @another_assignment = @another_course.assignments.create!(title: "title", due_at: 1.day.from_now)
            @student = user_with_pseudonym(active_all: true, account: @another_account)
            @another_course.enroll_student(@student, enrollment_state: "active")
            group_with_user(active_all: true, user: @student, context: @another_course)
            @group.announcements.create!(message: "Hi")
          end
          group_with_user(active_all: true, user: @student, context: @course)
          announcement = @group.announcements.create!(message: "Hi")
          @course.enroll_student(@student, enrollment_state: "active")
          user_session(@student)

          get :index
          response_json = json_parse(response.body)
          expect(response_json.pluck("plannable_id")).to eq [announcement.id, @assignment.id, @assignment2.id]
        end

        it "queries the correct shard-relative context codes for calendar events" do
          @course.enroll_student(@student, enrollment_state: "active")
          @shard1.activate do
            # on the local shard, matching a course id for a course the user is in on their home shard
            @another_course.calendar_events.create!(start_at: Time.zone.now)

            user_session(@student)
            get :index
            response_json = json_parse(response.body)
            expect(response_json).to eq []
          end
        end

        it "returns all_ungraded_todo_items across shards" do
          @shard1.activate do
            @original_topic = @original_course.discussion_topics.create! todo_date: 1.day.from_now, title: "fuh"
            @original_page = @original_course.wiki_pages.create! todo_date: 1.day.from_now, title: "duh"
            @other_topic = @another_course.discussion_topics.create! todo_date: 1.day.from_now, title: "buh"
            @other_page = @another_course.wiki_pages.create! todo_date: 1.day.from_now, title: "uh"
            @another_course.enroll_student(@student).accept!
          end
          user_session @student
          get :index, params: {
            filter: "all_ungraded_todo_items",
            context_codes: [@original_course.asset_string, @another_course.asset_string],
            start_date: 2.weeks.ago.iso8601,
            end_date: 2.weeks.from_now.iso8601
          }
          json = json_parse(response.body)
          items = json.map { |i| [i["plannable_type"], i["plannable_id"]] }
          expect(items).to match_array(
            [["discussion_topic", @original_topic.id],
             ["discussion_topic", @other_topic.id],
             ["wiki_page", @original_page.id],
             ["wiki_page", @other_page.id]]
          )
        end

        it "still works with context code if the student is from another shard" do
          @shard1.activate do
            @cs_student = user_factory(active_all: true, account: Account.create!)
            @original_course.enroll_user(@cs_student, "StudentEnrollment", enrollment_state: "active")
            planner_note_model(course: @original_course, user: @cs_student)
          end
          group_category(context: @original_course)
          @group = @group_category.groups.create!(context: @original_course)
          @group.add_user(@cs_student, "accepted")
          @group_assignment = @original_course.assignments.create!(group_category: @group_category, due_at: 1.day.from_now)
          @original_topic = @original_course.discussion_topics.create! todo_date: 1.day.from_now, title: "fuh"
          @original_page = @original_course.wiki_pages.create! todo_date: 1.day.from_now, title: "duh"

          user_session(@cs_student)

          get :index, params: { context_codes: [@original_course.asset_string, @group.asset_string, @cs_student.asset_string] }
          json = json_parse(response.body)
          expect(json.pluck("plannable_id")).to match_array([
                                                              @planner_note.id, @group_assignment.id, @original_topic.id, @original_page.id
                                                            ])
        end
      end

      context "pagination" do
        let(:per_page) { 5 }

        def test_page(bookmark = nil)
          opts = { per_page: 5 }
          opts.merge(page: bookmark) if bookmark.present?

          page =  get :index, params: opts
          links = Api.parse_pagination_links(page.headers["Link"])
          response_json = json_parse(page.body)
          expect(response_json.length).to eq 5
          ids = response_json.pluck("plannable_id")
          expected_ids = []
          5.times { |i| expected_ids << @assignments[i].id }
          expect(ids).to eq expected_ids

          links.detect { |l| l[:rel] == "next" }["page"]
        end

        before :once do
          @assignments = []
          20.downto(0) do |i|
            asg = course_assignment
            asg.due_at = i.days.ago
            asg.save!
            @assignments << asg
          end
        end

        it "adheres to per_page" do
          get :index, params: { per_page: 2 }
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 2
          expect(response_json.pluck("plannable_id")).to eq [@assignments[0].id, @assignments[1].id]
        end

        it "paginates results in correct order" do
          next_page = ""
          10.times do
            next_page = test_page(next_page)
          end
        end

        it "includes link headers in cached response" do
          enable_cache
          next_link = test_page
          expect(next_link).not_to be_nil
          next_link = test_page
          expect(next_link).not_to be_nil
        end
      end

      context "re-viewing the index with caching" do
        before do
          enable_cache
          @start_date = 2.weeks.ago.iso8601
          @end_date = 2.weeks.from_now.iso8601
        end

        it "shows new activity when a new discussion topic has been created" do
          get :index, params: { start_date: @start_date, end_date: @end_date }
          discussion_topic_model(context: @course, todo_date: 1.day.from_now)
          get :index, params: { start_date: @start_date, end_date: @end_date }
          topic_json = json_parse(response.body).find { |j| j["plannable_id"] == @topic.id && j["plannable_type"] == "discussion_topic" }
          expect(topic_json["new_activity"]).to be true
        end

        it "does not show new activity after an unread discussion has been viewed" do
          discussion_topic_model(context: @course, todo_date: 1.day.from_now)
          get :index, params: { start_date: @start_date, end_date: @end_date }
          topic_json = json_parse(response.body).find { |j| j["plannable_id"] == @topic.id && j["plannable_type"] == "discussion_topic" }
          expect(topic_json["new_activity"]).to be true

          @topic.change_read_state("read", @student)
          get :index, params: { start_date: @start_date, end_date: @end_date }
          topic_json = json_parse(response.body).find { |j| j["plannable_id"] == @topic.id && j["plannable_type"] == "discussion_topic" }
          expect(topic_json["new_activity"]).to be false
        end

        it "shows new activity when a new discussion entry has been created" do
          @topic = discussion_topic_model(context: @course, todo_date: 1.day.from_now)
          @topic.change_read_state("read", @student)
          get :index, params: { start_date: @start_date, end_date: @end_date }
          topic_json = json_parse(response.body).find { |j| j["plannable_id"] == @topic.id && j["plannable_type"] == "discussion_topic" }
          expect(topic_json["new_activity"]).to be false

          @topic.discussion_entries.create!(message: "hi", user: @teacher)
          @student.reload
          get :index, params: { start_date: @start_date, end_date: @end_date }
          topic_json = json_parse(response.body).find { |j| j["plannable_id"] == @topic.id && j["plannable_type"] == "discussion_topic" }
          expect(topic_json["new_activity"]).to be true
        end

        it "does not show new activity after an unread discussion entry has been viewed" do
          @topic = discussion_topic_model(context: @course, todo_date: 1.day.from_now)
          @topic.change_read_state("read", @student)
          entry = @topic.discussion_entries.create!(message: "hi", user: @teacher)
          @student.reload
          get :index, params: { start_date: @start_date, end_date: @end_date }
          topic_json = json_parse(response.body).find { |j| j["plannable_id"] == @topic.id && j["plannable_type"] == "discussion_topic" }
          expect(topic_json["new_activity"]).to be true

          entry.change_read_state("read", @student)
          get :index, params: { start_date: @start_date, end_date: @end_date }
          topic_json = json_parse(response.body).find { |j| j["plannable_id"] == @topic.id && j["plannable_type"] == "discussion_topic" }
          expect(topic_json["new_activity"]).to be false
        end

        it "shows new activity when a new submission comment has been created" do
          @assignment.submit_homework(@student, { url: "http://www.instructure.com/" })
          submission = @assignment.submissions.find_by(user: @student)
          get :index, params: { start_date: @start_date, end_date: @end_date }
          assign_json = json_parse(response.body).find { |j| j["plannable_id"] == @assignment.id && j["plannable_type"] == "assignment" }
          expect(assign_json["new_activity"]).to be false

          submission.submission_comments.create!(author: @teacher, comment: "hi")
          @student.reload
          get :index, params: { start_date: @start_date, end_date: @end_date }
          assign_json = json_parse(response.body).find { |j| j["plannable_id"] == @assignment.id && j["plannable_type"] == "assignment" }
          expect(assign_json["new_activity"]).to be true
        end

        it "does not show new activity when a new submission comment has been viewed" do
          @assignment.submit_homework(@student, { url: "http://www.instructure.com/" })
          submission = @assignment.submissions.find_by(user: @student)
          submission.submission_comments.create!(author: @teacher, comment: "hi")
          @student.reload
          get :index, params: { start_date: @start_date, end_date: @end_date }
          assign_json = json_parse(response.body).find { |j| j["plannable_id"] == @assignment.id && j["plannable_type"] == "assignment" }
          expect(assign_json["new_activity"]).to be true

          submission.mark_item_read("comment")
          get :index, params: { start_date: @start_date, end_date: @end_date }
          assign_json = json_parse(response.body).find { |j| j["plannable_id"] == @assignment.id && j["plannable_type"] == "assignment" }
          expect(assign_json["new_activity"]).to be false
        end
      end

      context "new activity filter" do
        it "returns newly created & unseen items" do
          dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: Time.zone.now)
          dt.change_all_read_state("unread", @student)
          get :index, params: { filter: "new_activity" }
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 1
          expect(response_json.map { |i| i["plannable"]["id"].to_s }).to include(dt.id.to_s)
        end

        it "returns newly graded items" do
          @assignment.grade_student @student, grade: 10, grader: @teacher
          get :index, params: { filter: "new_activity" }
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 1
          expect(response_json.first["plannable"]["id"]).to eq @assignment.id
        end

        it "returns items with new submission comments" do
          @sub = @assignment2.submit_homework(@student)
          @sub.add_comment(comment: "hello", author: @teacher)
          get :index, params: { filter: "new_activity" }
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 1
          expect(response_json.first["plannable"]["id"]).to eq @assignment2.id
        end

        it "marks submitted stuff within start and end dates" do
          @assignment4 = @course.assignments.create!(submission_types: "online_text_entry", due_at: 4.weeks.from_now)
          @assignment5 = @course.assignments.create!(submission_types: "online_text_entry", due_at: 4.weeks.ago)
          @assignment4.submit_homework(@student, submission_type: "online_text_entry")
          @assignment5.submit_homework(@student, submission_type: "online_text_entry")
          get :index, params: { start_date: 5.weeks.ago.to_date.to_s, end_date: 5.weeks.from_now.to_date.to_s }
          response_json = json_parse(response.body)
          found_assignment_4 = false
          found_assignment_5 = false
          response_json.each do |this_response|
            if this_response["plannable_id"] == @assignment4.id
              found_assignment_4 = true
              expect(this_response["submissions"]["submitted"]).to be true
            end
            if this_response["plannable_id"] == @assignment5.id
              found_assignment_5 = true
              expect(this_response["submissions"]["submitted"]).to be true
            end
          end
          # Make sure these two assignments were actually found and their
          # associated expectations run
          expect(found_assignment_4).to be true
          expect(found_assignment_5).to be true
        end

        it "does not return things from other courses" do
          course_with_student(active_all: true) # another course
          @course.discussion_topics.create!(title: "srsly", message: "cmon", todo_date: Time.zone.now)
          other_assignment = course_assignment
          other_sub = other_assignment.submit_homework(@student)
          other_sub.submission_comments.create!(comment: "hellooo", author: @teacher)
          ContentParticipation.delete_all

          get :index, params: { filter: "new_activity" }
          response_json = json_parse(response.body)
          expect(response_json).to be_empty
        end

        context "date range" do
          it "does not return items before the specified start_date" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.ago)
            dt.change_all_read_state("unread", @student)
            get :index, params: { filter: "new_activity", start_date: 1.week.from_now.to_date.to_s }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 0
          end

          it "does not return items after the specified end_date" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.from_now)
            dt.change_all_read_state("unread", @student)
            get :index, params: { filter: "new_activity", end_date: 1.week.ago.to_date.to_s }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 0
          end

          it "returns items within the start_date and end_date" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @student, todo_date: Time.zone.now)
            dt.change_all_read_state("unread", @student)
            get :index, params: { filter: "new_activity",
                                  start_date: 1.week.ago.to_date.to_s,
                                  end_date: 1.week.from_now.to_date.to_s }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.pluck("plannable_id")).to include dt.id
          end
        end

        context "discussion topic read/unread states" do
          before :once do
            discussion_topic_model context: @course
            @topic.todo_date = Time.zone.now
            @topic.save!
          end

          it "returns new discussion topics" do
            get :index, params: { filter: "new_activity" }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @topic.id
          end

          it "does not return read discussion topics" do
            @topic.change_read_state("read", @student)
            get :index, params: { filter: "new_activity" }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 0
          end

          it "returns discussion topics with unread replies" do
            expect(@topic.unread_count(@student)).to eq 0
            @entry = @topic.discussion_entries.create!(message: "Hello!", user: @student)
            @reply = @entry.reply_from(user: @teacher, text: "ohai!")
            @topic.reload
            expect(@topic.unread?(@student)).to be true
            expect(@topic.unread_count(@student)).to eq 1

            get :index, params: { filter: "new_activity" }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @topic.id

            @reply.change_read_state("read", @student)
            @topic.change_read_state("read", @student)

            get :index, params: { filter: "new_activity" }
            expect(json_parse(response.body)).to be_empty

            @reply2 = @entry.reply_from(user: @teacher, text: "ohai again...")

            get :index, params: { filter: "new_activity" }
            expect(json_parse(response.body).length).to eq 1
          end

          it "returns graded discussions with unread replies" do
            @topic.change_read_state("read", @student)
            assign = assignment_model(course: @course, due_at: Time.zone.now)
            topic = @course.discussion_topics.create!(course: @course, assignment: assign)
            topic.change_read_state("read", @student)

            get :index, params: { filter: "new_activity" }
            expect(json_parse(response.body)).to be_empty

            entry = topic.discussion_entries.create!(message: "Hello!", user: @student)
            reply = entry.reply_from(user: @teacher, text: "ohai!")
            topic.reload

            get :index, params: { filter: "new_activity" }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable_id"]).to eq topic.id
            expect(response_json.first["plannable"]["id"]).to eq topic.id

            reply.change_read_state("read", @student)
            get :index, params: { filter: "new_activity" }
            expect(json_parse(response.body)).to be_empty
          end

          it "excludes unpublished graded discussion topics" do
            @topic.change_read_state("read", @student)
            assign = assignment_model(course: @course, due_at: Time.zone.now)
            topic = @course.discussion_topics.create!(course: @course, assignment: assign)
            topic.publish!

            get :index, params: { filter: "new_activity" }
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable_id"]).to eq topic.id
            expect(response_json.first["plannable"]["id"]).to eq topic.id

            topic.unpublish!
            get :index, params: { filter: "new_activity" }
            expect(json_parse(response.body)).to be_empty
          end

          it "calculates unread count correctly" do
            get :index
            topic_json = json_parse(response.body).first
            expect(topic_json["plannable"]["unread_count"]).to be 0
            entry = @topic.discussion_entries.create!(message: "Hello!", user: @teacher)
            get :index
            topic_json = json_parse(response.body).first
            expect(topic_json["plannable"]["unread_count"]).to be 1
            @topic.change_read_state("read", @student)
            entry.change_read_state("read", @student)
            get :index
            topic_json = json_parse(response.body).first
            expect(topic_json["plannable"]["unread_count"]).to be 0
            entry.reply_from(user: @student, text: "wat?")
            entry.reply_from(user: @teacher, text: "ohai!")
            get :index
            topic_json = json_parse(response.body).first
            expect(topic_json["plannable"]["unread_count"]).to be 1
          end
        end
      end

      context "date ranges" do
        let(:start_date) { Time.parse("2020-01-1T00:00:00") }
        let(:end_date) { Time.parse("2020-01-1T23:59:59Z") }

        it "only returns items between (inclusive) the specified dates" do
          pn = planner_note_model(course: @course, todo_date: end_date)
          calendar_event_model(start_at: end_date + 1.second)
          get :index, params: { start_date: start_date.iso8601, end_date: end_date.iso8601 }
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 1
          note = response_json.detect { |i| i["plannable_type"] == "planner_note" }
          expect(note["plannable"]["title"]).to eq pn.title
        end
      end
    end
  end

  context "as observer" do
    before :once do
      @original_enrollment = observer_in_course(active_all: true, associated_user_id: @student)
    end

    before do
      user_session(@observer)
    end

    context "GET #index" do
      it "requires context_codes" do
        get :index, params: { observed_user_id: @student.to_param }
        assert_unauthorized
      end

      it "requires the current user to be observing the observed user" do
        user_session(@teacher)
        get :index, params: { observed_user_id: @student.to_param, context_codes: [@course.asset_string] }
        assert_unauthorized
      end

      it "requires the user to be observing observed_user_id in context_codes" do
        other_course = course_model
        other_course.enroll_student(@observer, enrollment_state: "active")
        get :index, params: { observed_user_id: @student.to_param, context_codes: [other_course.asset_string] }
        assert_unauthorized
      end

      it "does not require context_codes if all visible courses are requested" do
        get :index, params: { observed_user_id: @student.to_param, include: %w[all_courses] }
        expect(response).to be_successful
      end

      it "allows an observer to query their observed user's planner items for valid context_codes" do
        get :index, params: { observed_user_id: @student.to_param, context_codes: [@course.asset_string] }
        expect(response).to be_successful
        response_json = json_parse(response.body)
        expect(response_json.count).to eq 2
        response_hash = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }
        expect(response_hash).to include(["assignment", @assignment.id])
        expect(response_hash).to include(["assignment", @assignment2.id])
      end

      it "requires that the enrollment be active" do
        @original_enrollment.destroy
        get :index, params: { observed_user_id: @student.to_param, context_codes: [@course.asset_string] }
        assert_unauthorized
      end

      it "allows an observer to query their student's items in a concluded course" do
        @course.update!(settings: @course.settings.merge(restrict_student_past_view: true))
        @course.enrollment_term.set_overrides(@course.account, "StudentEnrollment" => { end_at: 1.month.ago })

        get :index, params: { observed_user_id: @student.to_param, context_codes: [@course.asset_string] }
        expect(response).to be_successful
      end
    end
  end
end
