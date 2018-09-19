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

require_relative '../sharding_spec_helper'

describe PlannerController do
  include PlannerHelper

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @group = @course.assignment_groups.create(:name => "some group")
    @assignment = course_assignment
    @assignment2 = course_assignment
  end

  def course_assignment
    assignment = @course.assignments.create(
      :title => "some assignment #{@course.assignments.count}",
      :assignment_group => @group,
      :due_at => Time.zone.now + 1.week
    )
    assignment
  end

  context "unauthenticated" do
    it "should return unauthorized" do
      get :index
      assert_unauthorized
    end
  end

  context "feature disabled" do
    before :each do
      user_session(@student)
    end

    it "should return forbidden" do
      get :index
      assert_forbidden
    end
  end

  context "as student" do
    before :each do
      user_session(@student)
      @course.root_account.enable_feature!(:student_planner)
    end

    describe "GET #index" do
      it "returns http success" do
        get :index
        expect(response).to be_successful
      end

      it "checks the planner cache" do
        @current_user = @student
        found_planner_meta_request = false
        found_planner_items_request = false
        allow(Rails.cache).to receive(:fetch) do |cache_key, &block|
          if cache_key == planner_meta_cache_key
            found_planner_meta_request = true
            'meta-cache-key'
          elsif cache_key.include?('meta-cache-key')
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

      it "should show wiki pages with todo dates" do
        wiki_page_model(course: @course)
        @page.todo_date = 1.day.from_now
        @page.save!
        get :index
        response_json = json_parse(response.body)
        expect(response_json.length).to eq 3
        page = response_json.detect { |i| i["plannable_id"] == @page.id }
        expect(page["plannable_type"]).to eq 'wiki_page'
      end

      it "should show planner notes for the user" do
        planner_note_model(course: @course)
        get :index
        response_json = json_parse(response.body)
        note = response_json.detect { |i| i["plannable_type"] == 'planner_note' }
        expect(response_json.length).to eq 3
        expect(note["plannable"]["title"]).to eq @planner_note.title
      end

      it "should show calendar events for the course and user" do
        ce = calendar_event_model(start_at: 1.day.from_now)
        ue = @student.calendar_events.create!(start_at: 2.days.from_now, title: 'user_event')
        get :index
        response_json = json_parse(response.body)
        course_event = response_json.find { |i| i['plannable_type'] == 'calendar_event' && i['plannable_id'] == ce.id }
        user_event = response_json.find { |i| i['plannable_type'] == 'calendar_event' && i['plannable_id'] == ue.id }
        expect(course_event['plannable']['title']).to eq ce.title
        expect(user_event['plannable']['title']).to eq 'user_event'
      end

      it "should show appointment groups" do
        ag = appointment_group_model(title: 'appointment group')
        ap = appointment_participant_model(participant: @student, course: @course, appointment_group: ag)
        get :index
        response_json = json_parse(response.body)
        event = response_json.find { |i| i['plannable_type'] == 'calendar_event' && i['plannable_id'] == ap.id }
        expect(event['plannable']['title']).to eq 'appointment group'
      end

      it "should only show section specific announcements to students who can view them" do
        a1 = @course.announcements.create!(:message => "for the defaults", :is_section_specific => true, :course_sections => [@course.default_section])
        sec2 = @course.course_sections.create!
        a2 = @course.announcements.create!(:message => "for my favorites", :is_section_specific => true, :course_sections => [sec2])

        get :index
        response_json = json_parse(response.body)
        expect(response_json.select{|i| i['plannable_type'] == 'announcement'}.map{|i| i['plannable_id']}).to eq [a1.id]
      end


      it "should show planner overrides created on quizzes" do
        quiz = quiz_model(course: @course, due_at: 1.day.from_now)
        PlannerOverride.create!(plannable_id: quiz.id, plannable_type: Quizzes::Quiz, user_id: @student.id)
        get :index
        response_json = json_parse(response.body)
        quiz_json = response_json.find {|rj| rj['plannable_id'] == quiz.id}
        expect(quiz_json['planner_override']['plannable_id']).to eq quiz.id
        expect(quiz_json['planner_override']['plannable_type']).to eq 'quiz'
      end

      it "should show planner overrides created on discussions" do
        discussion = discussion_topic_model(context: @course, todo_date: 1.day.from_now)
        PlannerOverride.create!(plannable_id: discussion.id, plannable_type: DiscussionTopic, user_id: @student.id)
        get :index
        response_json = json_parse(response.body)
        disc_json = response_json.find {|rj| rj['plannable_id'] == discussion.id}
        expect(disc_json['planner_override']['plannable_id']).to eq discussion.id
        expect(disc_json['planner_override']['plannable_type']).to eq 'discussion_topic'
      end

      it "should show planner overrides created on wiki pages" do
        page = wiki_page_model(course: @course, todo_date: 1.day.from_now)
        PlannerOverride.create!(plannable_id: page.id, plannable_type: WikiPage, user_id: @student.id)
        get :index
        response_json = json_parse(response.body)
        page_json = response_json.find {|rj| rj['plannable_id'] == page.id}
        expect(page_json['planner_override']['plannable_id']).to eq page.id
        expect(page_json['planner_override']['plannable_type']).to eq 'wiki_page'
      end

      context "include_concluded" do
        before :once do
          @u = User.create!

          @c1 = course_with_student(:active_all => true, :user => @u).course
          @a1 = course_assignment
          @pn1 = planner_note_model(:todo_date => 1.day.from_now, :course => @c1)

          @e2 = course_with_student(:active_all => true, :user => @u)
          @c2 = @e2.course
          @a2 = course_assignment
          @pn2 = planner_note_model(:todo_date => 1.day.from_now, :course => @c2)
          @e2.conclude
        end

        before :each do
          user_session(@u)
        end

        it "should not include objects from concluded courses by default" do
          get :index
          response_json = json_parse(response.body)
          items = response_json.map { |i| [i["plannable_type"], i["plannable"]["id"]] }
          expect(items).to include ['assignment', @a1.id]
          expect(items).to include ['planner_note', @pn1.id]
          expect(items).not_to include ['assignment', @a2.id]
          expect(items).not_to include ['planner_note', @pn2.id]
        end

        it "should include objects from concluded courses if specified" do
          get :index, params: {include: %w{concluded}}
          response_json = json_parse(response.body)
          items = response_json.map { |i| [i["plannable_type"], i["plannable"]["id"]] }
          expect(items).to include ['assignment', @a1.id]
          expect(items).to include ['planner_note', @pn1.id]
          expect(items).to include ['assignment', @a2.id]
          expect(items).to include ['planner_note', @pn2.id]
        end
      end

      context "with context codes" do
        before :once do
          @course1 = course_with_student(active_all: true).course
          @course2 = course_with_student(active_all: true, user: @student).course
          group_category(context: @course1)
          @group = @group_category.groups.create!(context: @course1)
          @group.add_user(@student, 'accepted')
          @assignment1 = assignment_model(course: @course1, due_at: 1.day.from_now)
          @assignment2 = assignment_model(course: @course2, due_at: 1.day.from_now)
          @group_assignment = @course1.assignments.create!(group_category: @group_category, due_at: 1.day.from_now)
          @course_topic = discussion_topic_model(context: @course1, todo_date: 1.day.from_now)
          @group_topic = discussion_topic_model(context: @group, todo_date: 1.day.from_now)
          @course_page = wiki_page_model(course: @course1, todo_date: 1.day.from_now)
          @group_page = wiki_page_model(todo_date: 1.day.from_now, course: @group)
          @assignment3 = assignment_model(course: @course1, due_at: Time.zone.now, only_visible_to_overrides: true)
          create_adhoc_override_for_assignment(@assignment3, @student, {due_at: 2.days.ago})
          @quiz = @course1.quizzes.create!(quiz_type: 'practice_quiz', due_at: 1.day.from_now).publish!
          create_adhoc_override_for_assignment(@quiz, @student, {due_at: 2.days.ago})
          @user_note = planner_note_model(user: @student, todo_date: 1.day.ago)
          @course1_note = planner_note_model(user: @student, todo_date: 1.day.from_now, course: @course1)
          @course2_note = planner_note_model(user: @student, todo_date: 1.day.from_now, course: @course2)
          @course1_event = @course1.calendar_events.create!(title: "Course 1 event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @course2_event = @course2.calendar_events.create!(title: "Course 2 event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @group_event = @group.calendar_events.create!(title: "Group event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @user_event = @user.calendar_events.create!(title: "User event", start_at: 1.minute.from_now, end_at: 1.hour.from_now)
          @deleted_page = wiki_page_model(course: @course1, todo_date: 1.day.from_now); @deleted_page.destroy
          @deleted_topic = discussion_topic_model(context: @group, todo_date: 1.day.from_now); @deleted_topic.destroy
        end

        before :each do
          user_session(@student)
        end

        it "should include all data by default" do
          get :index, params: {per_page: 50}
          response_json = json_parse(response.body)
          expect(response_json.length).to be 16
        end

        it "should only return data from contexted courses if specified" do
          get :index, params: {context_codes: [@course1.asset_string]}
          response_json = json_parse(response.body)
          response_hash = response_json.map{|i| [i['plannable_type'], i['plannable_id']]}
          expect(response_hash).to include(['assignment', @assignment1.id])
          expect(response_hash).to include(['assignment', @group_assignment.id])
          expect(response_hash).to include(['discussion_topic', @course_topic.id])
          expect(response_hash).to include(['wiki_page', @course_page.id])
          expect(response_hash).to include(['assignment', @assignment3.id])
          expect(response_hash).to include(['quiz', @quiz.id])
          expect(response_hash).to include(['planner_note', @course1_note.id])
          expect(response_hash).to include(['calendar_event', @course1_event.id])
          expect(response_hash.length).to be 8
        end

        it "should only return data from contexted users if specified" do
          get :index, params: {context_codes: [@user.asset_string]}
          response_json = json_parse(response.body)
          response_hash = response_json.map{|i| [i['plannable_type'], i['plannable_id']]}
          expect(response_hash).to include(['planner_note', @user_note.id])
          expect(response_hash).to include(['calendar_event', @user_event.id])
          expect(response_hash.length).to be 2
        end

        it "should return items from all context_codes specified" do
          get :index, params: {context_codes: [@user.asset_string, @group.asset_string]}
          response_json = json_parse(response.body)
          response_hash = response_json.map{|i| [i['plannable_type'], i['plannable_id']]}
          expect(response_hash).to include(['planner_note', @user_note.id])
          expect(response_hash).to include(['calendar_event', @user_event.id])
          expect(response_hash).to include(['discussion_topic', @group_topic.id])
          expect(response_hash).to include(['wiki_page', @group_page.id])
          expect(response_hash).to include(['calendar_event', @group_event.id])
          expect(response_hash.length).to be 5
        end

        it "should not return any data if context_codes are specified but none are valid for the user" do
          course_with_teacher(active_all: true)
          assignment_model(course: @course, due_at: 1.day.from_now)

          get :index, params: {context_codes: [@course.asset_string]}
          response_json = json_parse(response.body)
          expect(response_json).to eq []
        end

        it "filters ungraded_todo_items" do
          get :index, params: {filter: 'ungraded_todo_items'}
          response_json = json_parse(response.body)
          items = response_json.map{|i| [i['plannable_type'], i['plannable_id']]}
          expect(items).to match_array(
            [['discussion_topic', @course_topic.id],
             ['discussion_topic', @group_topic.id],
             ['wiki_page', @course_page.id],
             ['wiki_page', @group_page.id]]
          )
        end

        it "filters all_ungraded_todo_items for teachers, including unpublished items" do
          @course_page.unpublish
          @group_topic.unpublish
          user_session @course1.teachers.first
          get :index, params: {
            filter: 'all_ungraded_todo_items',
            context_codes: [@course1.asset_string, @group.asset_string],
            start_date: 2.weeks.ago.iso8601,
            end_date: 2.weeks.from_now.iso8601
          }
          response_json = json_parse(response.body)
          items = response_json.map{|i| [i['plannable_type'], i['plannable_id']]}
          expect(items).to match_array(
            [['discussion_topic', @course_topic.id],
             ['discussion_topic', @group_topic.id],
             ['wiki_page', @course_page.id],
             ['wiki_page', @group_page.id]]
          )
        end

        it "filters out unpublished todo items for students" do
          @course_page.unpublish
          @group_topic.unpublish
          user_session @course1.students.first
          get :index, params: {
            filter: 'all_ungraded_todo_items',
            context_codes: [@course1.asset_string, @group.asset_string],
            start_date: 2.weeks.ago.iso8601,
            end_date: 2.weeks.from_now.iso8601
          }
          response_json = json_parse(response.body)
          items = response_json.map{|i| [i['plannable_type'], i['plannable_id']]}
          expect(items).to match_array(
            [['discussion_topic', @course_topic.id],
             ['discussion_topic', @group_topic.id], # turns out groups let all members view unpublished items
             ['wiki_page', @group_page.id]]
          )
        end
      end

      context "date sorting" do
        it "should return results in order by date" do
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
          expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignment3.id, @page.id, @assignment5.id, @assignment.id, @assignment2.id]

          get :index, params: {:per_page => 2}
          expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment3.id, @page.id]

          next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
          get :index, params: {:per_page => 2, :page => next_page}
          expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment5.id, @assignment.id]

          next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
          get :index, params: {:per_page => 2, :page => next_page}
          expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment2.id]
        end

        it "should behave consistently with different object types on the same datetime" do
          time = 4.days.from_now
          @assignment.update_attribute(:due_at, time)
          @assignment2.update_attribute(:due_at, time)
          @course.wiki_pages.create!(:title => "t1", :todo_date => time)
          planner_note_model(:todo_date => time)
          discussion_topic_model(context: @course, todo_date: time)

          get :index
          response_json = json_parse(response.body)
          original_order = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }

          get :index, params: {:per_page => 3}
          expect(json_parse(response.body).map { |i| [i["plannable_type"], i["plannable_id"]] }).to eq original_order[0..2]

          next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
          get :index, params: {:per_page => 3, :page => next_page}
          expect(json_parse(response.body).map { |i| [i["plannable_type"], i["plannable_id"]] }).to eq original_order[3..4]
        end

        it "should use the right bookmarker in different time zones" do
          Account.default.default_time_zone = "America/Denver"
          time = 2.days.from_now
          @assignment.update_attribute(:due_at, time)
          @assignment2.update_attribute(:due_at, time)

          get :index, params: {:per_page => 1}
          expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment.id]

          next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
          get :index, params: {:per_page => 1, :page => next_page}
          expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment2.id]
        end

        it "should return results in reverse order by date if requested" do
          wiki_page_model(course: @course, todo_date: 1.day.from_now)
          @assignment3 = course_assignment
          @assignment3.due_at = 1.week.ago
          @assignment3.save!
          get :index, params: {:order => :desc}
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 4
          expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignment2.id, @assignment.id, @page.id, @assignment3.id]

          get :index, params: {:order => :desc, :per_page => 2}
          expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment2.id, @assignment.id]

          next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
          get :index, params: {:order => :desc, :per_page => 2, :page => next_page}
          expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@page.id, @assignment3.id]
        end

        it "should not try to compare missing dates" do
          @assignment3 = @course.assignments.create!(:submission_types => "online_text_entry")
          # doesn't have a due_at, so it should coalesce to the created_at
          override = @assignment3.assignment_overrides.new(:set => @course.default_section)
          override.override_due_at(2.days.from_now)
          override.save!
          @assignment3.submit_homework(@student, :submission_type => "online_text_entry", :body => "text")
          @assignment3.grade_student @student, grade: 10, grader: @teacher
          get :index
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 3
          expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignment3.id, @assignment.id, @assignment2.id]
        end

        it "should order with unread items as well" do
          dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 3.days.from_now)
          dt.change_all_read_state("unread", @student)

          @assignment3 = @course.assignments.create!(:submission_types => "online_text_entry")
          override = @assignment3.assignment_overrides.new(:set => @course.default_section)
          override.override_due_at(2.days.from_now)
          override.save!

          graded_topic = @course.assignments.create!(submission_types: 'discussion_topic', due_at: 5.days.from_now).discussion_topic
          graded_topic.change_all_read_state('unread', @student)

          @assignment3.grade_student @student, grade: 10, grader: @teacher
          @assignment.grade_student @student, grade: 10, grader: @teacher

          get :index, params: {filter: "new_activity"}
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 4
          expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignment3.id, dt.id, graded_topic.id, @assignment.id]
        end

        context "with assignment overrides" do
          before :once do
            course_with_teacher(active_all: true)
            student_in_course(active_all: true)
            @planner_note1 = planner_note_model(user: @student, todo_date: 1.day.ago)
            @planner_note2 = planner_note_model(user: @student, todo_date: 1.day.from_now)
          end

          before :each do
            user_session(@student)
          end

          it "should order assignments with no overrides correctly" do
            assignment1 = assignment_model(course: @course, due_at: Time.zone.now)
            assignment2 = assignment_model(course: @course, due_at: 2.days.from_now)
            DueDateCacher.recompute_course(@course, run_immediately: true)

            get :index, params: {start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| i["plannable_id"] }).to eq([@planner_note1.id, assignment1.id, @planner_note2.id, assignment2.id])
          end

          it "should order assignments with overridden due dates correctly" do
            assignment1 = assignment_model(course: @course, due_at: Time.zone.now, only_visible_to_overrides: true)
            assign1_override_due_at = 2.days.ago
            create_adhoc_override_for_assignment(assignment1, @student, {due_at: assign1_override_due_at})
            assignment2 = assignment_model(course: @course, due_at: 2.days.from_now)
            assign2_override_due_at = Time.zone.now
            create_adhoc_override_for_assignment(assignment2, @student, {due_at: assign2_override_due_at})
            DueDateCacher.recompute_course(@course, run_immediately: true)

            get :index, params: {start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| i["plannable_id"] }).to eq([assignment1.id, @planner_note1.id, assignment2.id, @planner_note2.id])
          end

          it "should order ungraded quizzes with overridden due dates correctly" do
            quiz1 = @course.quizzes.create!(quiz_type: 'practice_quiz', due_at: Time.zone.now).publish!
            quiz1_override_due_at = 2.days.ago
            create_adhoc_override_for_assignment(quiz1, @student, {due_at: quiz1_override_due_at})
            quiz2 = @course.quizzes.create!(quiz_type: 'practice_quiz', due_at: 2.days.from_now).publish!
            quiz2_override_due_at = Time.zone.now
            create_adhoc_override_for_assignment(quiz2, @student, {due_at: quiz2_override_due_at})

            get :index, params: {start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| i["plannable_id"] }).to eq([quiz1.id, @planner_note1.id, quiz2.id, @planner_note2.id])
          end

          it "should order graded discussions with overridden due dates correctly" do
            topic1 = discussion_topic_model(context: @course, todo_date: Time.zone.now)
            topic2 = group_assignment_discussion(course: @course)
            topic2_override_due_at = 2.days.from_now
            create_group_override_for_assignment(topic2.assignment, {user: @student, group: @group, due_at: topic2_override_due_at})
            topic2_assign = topic2.assignment
            topic2_assign.due_at = 2.days.ago
            topic2_assign.save!
            DueDateCacher.recompute_course(@course, run_immediately: true)

            get :index, params: {start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| [i["plannable_id"], i['plannable_date']] }).to eq([
              [@planner_note1.id, @planner_note1.todo_date.iso8601],
              [topic1.id, topic1.todo_date.iso8601],
              [@planner_note2.id, @planner_note2.todo_date.iso8601],
              [topic2.root_topic.id, topic2_override_due_at.change(sec: 0).iso8601]
            ])
          end

          it "should order mastery path wiki_pages by todo date if applied" do
            page1 = wiki_page_model(course: @course, todo_date: 2.days.ago)
            wiki_page_assignment_model(course: @course)
            @page.todo_date = Time.zone.now
            @page.save!
            DueDateCacher.recompute_course(@course, run_immediately: true)

            get :index, params: {start_date: 2.weeks.ago.iso8601, end_date: 2.weeks.from_now.iso8601}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| i["plannable_id"] }).to eq([page1.id, @planner_note1.id, @page.id, @planner_note2.id])
          end
        end
      end

      context "cross-sharding" do
        specs_require_sharding

        before :once do
          @original_course = @course
          @shard1.activate do
            @another_account = Account.create!
            @another_course = @another_account.courses.create!(:workflow_state => 'available')
         end
        end

        it "should ignore shards other than the current account's" do
          @shard1.activate do
            @another_assignment = @another_course.assignments.create!(:title => "title", :due_at => 1.day.from_now)
            @student = user_with_pseudonym(:active_all => true, :account => @another_account)
            @another_course.enroll_student(@student, :enrollment_state => 'active')
            group_with_user(active_all: true, user: @student, context: @another_course)
            @group.announcements.create!(message: 'Hi')
          end
          group_with_user(active_all: true, user: @student, context: @course)
          announcement = @group.announcements.create!(message: 'Hi')
          @course.enroll_student(@student, :enrollment_state => 'active')
          user_session(@student)

          get :index
          response_json = json_parse(response.body)
          expect(response_json.map { |i| i["plannable_id"]}).to eq [announcement.id, @assignment.id, @assignment2.id]
        end

        it "returns all_ungraded_todo_items across shards" do
          @shard1.activate do
            @original_topic = @original_course.discussion_topics.create! todo_date: 1.day.from_now, title: 'fuh'
            @original_page = @original_course.wiki_pages.create! todo_date: 1.day.from_now, title: 'duh'
            @other_topic = @another_course.discussion_topics.create! todo_date: 1.day.from_now, title: 'buh'
            @other_page = @another_course.wiki_pages.create! todo_date: 1.day.from_now, title: 'uh'
            @another_course.enroll_student(@student).accept!
          end
          user_session @student
          get :index, params: {
            filter: 'all_ungraded_todo_items',
            context_codes: [@original_course.asset_string, @another_course.asset_string],
            start_date: 2.weeks.ago.iso8601,
            end_date: 2.weeks.from_now.iso8601
          }
          json = json_parse(response.body)
          items = json.map{|i| [i['plannable_type'], i['plannable_id']]}
          expect(items).to match_array(
            [['discussion_topic', @original_topic.id],
             ['discussion_topic', @other_topic.id],
             ['wiki_page', @original_page.id],
             ['wiki_page', @other_page.id]]
          )
        end
      end

      context "pagination" do
        PER_PAGE = 5

        def test_page(bookmark = nil)
          opts = { per_page: PER_PAGE }
          opts.merge(page: bookmark) if bookmark.present?

          page =  get :index, params: opts
          links = Api.parse_pagination_links(page.headers['Link'])
          response_json = json_parse(page.body)
          expect(response_json.length).to eq PER_PAGE
          ids = response_json.map { |i| i["plannable_id"] }
          expected_ids = []
          PER_PAGE.times {|i| expected_ids << @assignments[i].id}
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

        it "should adhere to per_page" do
          get :index, params: {per_page: 2}
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 2
          expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignments[0].id, @assignments[1].id]
        end

        it "should paginate results in correct order" do
          next_page = ''
          10.times do
            next_page = test_page(next_page)
          end
        end

        it "should include link headers in cached response" do
          enable_cache
          next_link = test_page
          expect(next_link).not_to be_nil
          next_link = test_page
          expect(next_link).not_to be_nil
        end

      end


      context "new activity filter" do
        it "should return newly created & unseen items" do
          dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: Time.zone.now)
          dt.change_all_read_state("unread", @student)
          get :index, params: {filter: "new_activity"}
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 1
          expect(response_json.map { |i| i["plannable"]["id"].to_s }).to include(dt.id.to_s)
        end

        it "should return newly graded items" do
          @assignment.grade_student @student, grade: 10, grader: @teacher
          get :index, params: {filter: "new_activity"}
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 1
          expect(response_json.first["plannable"]["id"]).to eq @assignment.id
        end

        it "should return items with new submission comments" do
          @sub = @assignment2.submit_homework(@student)
          @sub.submission_comments.create!(comment: "hello", author: @teacher)
          get :index, params: {filter: "new_activity"}
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 1
          expect(response_json.first["plannable"]["id"]).to eq @assignment2.id
        end

        it "should mark submitted stuff within start and end dates" do
          @assignment4 = @course.assignments.create!(:submission_types => "online_text_entry", :due_at => 4.weeks.from_now)
          @assignment5 = @course.assignments.create!(:submission_types => "online_text_entry", :due_at => 4.weeks.ago)
          @assignment4.submit_homework(@student, :submission_type => "online_text_entry")
          @assignment5.submit_homework(@student, :submission_type => "online_text_entry")
          get :index, params: {:start_date => 5.weeks.ago.to_date.to_s, :end_date => 5.weeks.from_now.to_date.to_s}
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

        it "shouldn't return things from other courses" do
          course_with_student(:active_all => true) # another course
          @course.discussion_topics.create!(title: "srsly", message: "cmon", todo_date: Time.zone.now)
          other_assignment = course_assignment
          other_sub = other_assignment.submit_homework(@student)
          other_sub.submission_comments.create!(comment: "hellooo", author: @teacher)
          ContentParticipation.delete_all

          get :index, params: {filter: "new_activity"}
          response_json = json_parse(response.body)
          expect(response_json).to be_empty
        end

        context "date range" do
          it "should not return items before the specified start_date" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.ago)
            dt.change_all_read_state("unread", @student)
            get :index, params: {filter: "new_activity", start_date: 1.week.from_now.to_date.to_s}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 0
          end

          it "should not return items after the specified end_date" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.from_now)
            dt.change_all_read_state("unread", @student)
            get :index, params: {filter: "new_activity", end_date: 1.week.ago.to_date.to_s}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 0
          end

          it "should return items within the start_date and end_date" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @student, todo_date: Time.zone.now)
            dt.change_all_read_state("unread", @student)
            get :index, params: {filter: "new_activity",
                              start_date: 1.week.ago.to_date.to_s,
                              end_date: 1.week.from_now.to_date.to_s}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.map { |i| i["plannable_id"] }).to include dt.id
          end
        end

        context "discussion topic read/unread states" do
          before :once do
            discussion_topic_model context: @course
            @topic.todo_date = Time.zone.now
            @topic.save!
          end

          it "should return new discussion topics" do
            get :index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @topic.id
          end

          it "should not return read discussion topics" do
            @topic.change_read_state("read", @student)
            get :index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 0
          end

          it "should return discussion topics with unread replies" do
            expect(@topic.unread_count(@student)).to eq 0
            @entry = @topic.discussion_entries.create!(:message => "Hello!", :user => @student)
            @reply = @entry.reply_from(:user => @teacher, :text => "ohai!")
            @topic.reload
            expect(@topic.unread?(@student)).to eq true
            expect(@topic.unread_count(@student)).to eq 1

            get :index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @topic.id

            @reply.change_read_state('read', @student)
            @topic.change_read_state('read', @student)

            get :index, params: {filter: "new_activity"}
            expect(json_parse(response.body)).to be_empty

            @reply2 = @entry.reply_from(:user => @teacher, :text => "ohai again...")

            get :index, params: {filter: "new_activity"}
            expect(json_parse(response.body).length).to eq 1
          end

          it "should return graded discussions with unread replies" do
            @topic.change_read_state('read', @student)
            assign = assignment_model(course: @course, due_at: Time.zone.now)
            topic = @course.discussion_topics.create!(course: @course, assignment: assign)
            topic.change_read_state('read', @student)

            get :index, params: {filter: "new_activity"}
            expect(json_parse(response.body)).to be_empty

            entry = topic.discussion_entries.create!(:message => "Hello!", :user => @student)
            reply = entry.reply_from(:user => @teacher, :text => "ohai!")
            topic.reload

            get :index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable_id"]).to eq topic.id
            expect(response_json.first["plannable"]["id"]).to eq topic.id

            reply.change_read_state('read', @student)
            get :index, params: {filter: "new_activity"}
            expect(json_parse(response.body)).to be_empty
          end
        end
      end
    end
  end
end
