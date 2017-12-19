#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe PlannerOverridesController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @group = @course.assignment_groups.create(:name => "some group")
    @assignment = course_assignment
    @assignment2 = course_assignment
    @planner_override = PlannerOverride.create!(plannable_id: @assignment.id,
                                                plannable_type: "Assignment",
                                                marked_complete: false,
                                                user_id: @student.id)
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

      post :create, params: {:plannable_type => "assignment",
                     :plannable_id => @assignment.id,
                     :marked_complete => false}
      assert_unauthorized
    end
  end

  context "authenticated" do
    context "as student" do
      before :each do
        user_session(@student)
        @course.root_account.enable_feature!(:student_planner)
      end

      describe "GET #items_index" do
        it "returns http success" do
          get :items_index
          expect(response).to have_http_status(:success)
        end

        it "should show wiki pages with todo dates" do
          wiki_page_model(course: @course)
          @page.todo_date = 1.day.from_now
          @page.save!
          get :items_index
          response_json = json_parse(response.body)
          expect(response_json.length).to eq 3
          page = response_json.detect { |i| i["plannable_id"] == @page.id }
          expect(page["plannable_type"]).to eq 'wiki_page'
        end

        it "should show planner notes for the user" do
          planner_note_model(course: @course)
          get :items_index
          response_json = json_parse(response.body)
          note = response_json.detect { |i| i["plannable_type"] == 'planner_note' }
          expect(response_json.length).to eq 3
          expect(note["plannable"]["title"]).to eq @planner_note.title
        end

        it "should show planner overrides created on quizzes" do
          quiz = quiz_model(course: @course, due_at: 1.day.from_now)
          PlannerOverride.create!(plannable_id: quiz.id, plannable_type: Quizzes::Quiz, user_id: @student.id)
          get :items_index
          response_json = json_parse(response.body)
          quiz_json = response_json.find {|rj| rj['plannable_id'] == quiz.id}
          expect(quiz_json['planner_override']['plannable_id']).to eq quiz.id
          expect(quiz_json['planner_override']['plannable_type']).to eq 'quiz'
        end

        it "should show planner overrides created on discussions" do
          discussion = discussion_topic_model(context: @course, todo_date: 1.day.from_now)
          PlannerOverride.create!(plannable_id: discussion.id, plannable_type: DiscussionTopic, user_id: @student.id)
          get :items_index
          response_json = json_parse(response.body)
          disc_json = response_json.find {|rj| rj['plannable_id'] == discussion.id}
          expect(disc_json['planner_override']['plannable_id']).to eq discussion.id
          expect(disc_json['planner_override']['plannable_type']).to eq 'discussion_topic'
        end

        it "should show planner overrides created on wiki pages" do
          page = wiki_page_model(course: @course, todo_date: 1.day.from_now)
          PlannerOverride.create!(plannable_id: page.id, plannable_type: WikiPage, user_id: @student.id)
          get :items_index
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
            get :items_index
            response_json = json_parse(response.body)
            items = response_json.map { |i|  [i["plannable_type"], i["plannable"]["id"]] }
            expect(items).to include ['assignment', @a1.id]
            expect(items).to include ['planner_note', @pn1.id]
            expect(items).to_not include ['assignment', @a2.id]
            expect(items).to_not include ['planner_note', @pn2.id]
          end

          it "should include objects from concluded courses if specified" do
            get :items_index, params: {include: %w{concluded}}
            response_json = json_parse(response.body)
            items = response_json.map { |i|  [i["plannable_type"], i["plannable"]["id"]] }
            expect(items).to include ['assignment', @a1.id]
            expect(items).to include ['planner_note', @pn1.id]
            expect(items).to include ['assignment', @a2.id]
            expect(items).to include ['planner_note', @pn2.id]
          end
        end

        context "only_favorites" do
          before :once do
            @u = User.create!

            @c1 = course_with_student(:active_all => true, :user => @u).course
            @u.favorites.create!(:context_type => "Course", :context_id => @c1)
            @a1 = course_assignment

            @c2 = course_with_student(:active_all => true, :user => @u).course
            @u.favorites.where(:context_type => "Course", :context_id => @c2).first.destroy
            @a2 = course_assignment
          end

          before :each do
            user_session(@u)
          end

          it "should include all course data by default" do
            get :items_index
            response_json = json_parse(response.body)
            expect(response_json.map { |i| i["plannable"]["id"] }).to be_include(@a2.id)
          end

          it "should only return data from favorite courses if specified" do
            get :items_index, params: {include: %w{only_favorites}}
            response_json = json_parse(response.body)
            expect(response_json.map { |i| i["plannable"]["id"] }).not_to be_include(@a2.id)
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

            get :items_index
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 5
            expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignment3.id, @page.id, @assignment5.id, @assignment.id, @assignment2.id]

            get :items_index, params: {:per_page => 2}
            expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment3.id, @page.id]

            next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
            get :items_index, params: {:per_page => 2, :page => next_page}
            expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment5.id, @assignment.id]

            next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
            get :items_index, params: {:per_page => 2, :page => next_page}
            expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment2.id]
          end

          it "should behave consistently with different object types on the same datetime" do
            time = 4.days.from_now
            @assignment.update_attribute(:due_at, time)
            @assignment2.update_attribute(:due_at, time)
            page = @course.wiki_pages.create!(:title => "t1", :todo_date => time)
            note = planner_note_model(:todo_date => time)
            discussion = discussion_topic_model(context: @course, todo_date: time)

            get :items_index
            response_json = json_parse(response.body)
            original_order = response_json.map { |i| [i["plannable_type"], i["plannable_id"]] }

            get :items_index, params: {:per_page => 3}
            expect(json_parse(response.body).map { |i| [i["plannable_type"], i["plannable_id"]] }).to eq original_order[0..2]

            next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
            get :items_index, params: {:per_page => 3, :page => next_page}
            expect(json_parse(response.body).map { |i| [i["plannable_type"], i["plannable_id"]] }).to eq original_order[3..4]
          end

          it "should use the right bookmarker in different time zones" do
            Account.default.default_time_zone = "America/Denver"
            time = 2.days.from_now
            @assignment.update_attribute(:due_at, time)
            @assignment2.update_attribute(:due_at, time)

            get :items_index, params: {:per_page => 1}
            expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment.id]

            next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
            get :items_index, params: {:per_page => 1, :page => next_page}
            expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment2.id]
          end

          it "should return results in reverse order by date if requested" do
            wiki_page_model(course: @course)
            @page.todo_date = 1.day.from_now
            @page.save!
            @assignment3 = course_assignment
            @assignment3.due_at = 1.week.ago
            @assignment3.save!
            get :items_index, params: {:order => :desc}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignment2.id, @assignment.id, @page.id, @assignment3.id]

            get :items_index, params: {:order => :desc, :per_page => 2}
            expect(json_parse(response.body).map { |i| i["plannable_id"] }).to eq [@assignment2.id, @assignment.id]

            next_page = Api.parse_pagination_links(response.headers['Link']).detect{|p| p[:rel] == "next"}['page']
            get :items_index, params: {:order => :desc, :per_page => 2, :page => next_page}
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
            get :items_index
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

            graded_topic = @course.assignments.create!(submission_types: 'discussion_topic', due_at: 5.days.from_now)
            graded_topic.discussion_topic.change_all_read_state('unread', @student)

            @assignment3.grade_student @student, grade: 10, grader: @teacher
            @assignment.grade_student @student, grade: 10, grader: @teacher

            get :items_index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 4
            expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignment3.id, dt.id, graded_topic.id, @assignment.id]
          end
        end

        context "cross-sharding" do
          specs_require_sharding

          it "should ignore shards other than the current account's" do
            @shard1.activate do
              @another_account = Account.create!
              @another_course = @another_account.courses.create!(:workflow_state => 'available')
              @another_assignment = @another_course.assignments.create!(:title => "title", :due_at => 1.day.from_now)
              @student = user_with_pseudonym(:active_all => true, :account => @another_account)
              @another_course.enroll_student(@student, :enrollment_state => 'active')
            end
            @course.enroll_student(@student, :enrollment_state => 'active')
            user_session(@student)

            get :items_index
            response_json = json_parse(response.body)
            expect(response_json.map { |i| i["plannable_id"]}).to eq [@assignment.id, @assignment2.id]
          end
        end

        context "pagination" do
          PER_PAGE = 5

          def test_page(idx = 0, bookmark = nil)
            opts = { per_page: PER_PAGE }
            opts.merge(page: bookmark) if bookmark.present?

            page =  get :items_index, params: opts
            links = Api.parse_pagination_links(page.headers['Link'])
            response_json = json_parse(page.body)
            expect(response_json.length).to eq PER_PAGE
            ids = response_json.map { |i| i["plannable_id"] }
            expected_ids = []
            PER_PAGE.times.with_index(idx) {|i| expected_ids << @assignments[i].id}
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
            get :items_index, params: {per_page: 2}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 2
            expect(response_json.map { |i| i["plannable_id"] }).to eq [@assignments[0].id, @assignments[1].id]
          end

          it "should paginate results in correct order" do
            next_page = ''
            10.times do |i|
              next_page = test_page(i, next_page)
            end
          end

        end


        context "new activity filter" do
          it "should return newly created & unseen items" do
            dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: Time.zone.now)
            dt.change_all_read_state("unread", @student)
            get :items_index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.map { |i| i["plannable"]["id"].to_s }).to be_include(dt.id.to_s)
          end

          it "should return newly graded items" do
            @assignment.grade_student @student, grade: 10, grader: @teacher
            get :items_index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @assignment.id
          end

          it "should return items with new submission comments" do
            @sub = @assignment2.submit_homework(@student)
            @sub.submission_comments.create!(comment: "hello", author: @teacher)
            get :items_index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json.length).to eq 1
            expect(response_json.first["plannable"]["id"]).to eq @assignment2.id
          end

          it "should mark submitted stuff within start and end dates" do
            @assignment4 = @course.assignments.create!(:submission_types => "online_text_entry", :due_at => 4.weeks.from_now)
            @assignment5 = @course.assignments.create!(:submission_types => "online_text_entry", :due_at => 4.weeks.ago)
            @assignment4.submit_homework(@student, :submission_type => "online_text_entry")
            @assignment5.submit_homework(@student, :submission_type => "online_text_entry")
            get :items_index, params: {:start_date => 5.weeks.ago.to_date.to_s, :end_date => 5.weeks.from_now.to_date.to_s}
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
            other_student = @student
            other_dt = @course.discussion_topics.create!(title: "srsly", message: "cmon", todo_date: Time.zone.now)
            other_assignment = course_assignment
            other_sub = other_assignment.submit_homework(@student)
            other_sub.submission_comments.create!(comment: "hellooo", author: @teacher)
            ContentParticipation.delete_all

            get :items_index, params: {filter: "new_activity"}
            response_json = json_parse(response.body)
            expect(response_json).to be_empty
          end

          context "date range" do
            it "should not return items before the specified start_date" do
              dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.ago)
              dt.change_all_read_state("unread", @student)
              get :items_index, params: {filter: "new_activity", start_date: 1.week.from_now.to_date.to_s}
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 0
            end

            it "should not return items after the specified end_date" do
              dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @teacher, todo_date: 1.week.from_now)
              dt.change_all_read_state("unread", @student)
              get :items_index, params: {filter: "new_activity", end_date: 1.week.ago.to_date.to_s}
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 0
            end

            it "should return items within the start_date and end_date" do
              dt = @course.discussion_topics.create!(title: "Yes", message: "Please", user: @student, todo_date: Time.zone.now)
              dt.change_all_read_state("unread", @student)
              get :items_index, params: {filter: "new_activity",
                                start_date: 1.week.ago.to_date.to_s,
                                end_date: 1.week.from_now.to_date.to_s}
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 1
              expect(response_json.map { |i| i["plannable_id"] }).to be_include dt.id
            end
          end

          context "discussion topic read/unread states" do
            before :once do
              discussion_topic_model context: @course
              @topic.todo_date = Time.zone.now
              @topic.save!
            end

            it "should return new discussion topics" do
              get :items_index, params: {filter: "new_activity"}
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 1
              expect(response_json.first["plannable"]["id"]).to eq @topic.id
            end

            it "should not return read discussion topics" do
              @topic.change_read_state("read", @student)
              get :items_index, params: {filter: "new_activity"}
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

              get :items_index, params: {filter: "new_activity"}
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 1
              expect(response_json.first["plannable"]["id"]).to eq @topic.id

              @reply.change_read_state('read', @student)
              @topic.change_read_state('read', @student)

              get :items_index, params: {filter: "new_activity"}
              expect(json_parse(response.body)).to be_empty

              @reply2 = @entry.reply_from(:user => @teacher, :text => "ohai again...")

              get :items_index, params: {filter: "new_activity"}
              expect(json_parse(response.body).length).to eq 1
            end

            it "should return graded discussions with unread replies" do
              @topic.change_read_state('read', @student)
              assign = assignment_model(course: @course, due_at: Time.zone.now)
              topic = @course.discussion_topics.create!(course: @course, assignment: assign)
              topic.change_read_state('read', @student)

              get :items_index, params: {filter: "new_activity"}
              expect(json_parse(response.body)).to be_empty

              entry = topic.discussion_entries.create!(:message => "Hello!", :user => @student)
              reply = entry.reply_from(:user => @teacher, :text => "ohai!")
              topic.reload

              get :items_index, params: {filter: "new_activity"}
              response_json = json_parse(response.body)
              expect(response_json.length).to eq 1
              expect(response_json.first["plannable_id"]).to eq assign.id
              expect(response_json.first["plannable"]["id"]).to eq topic.id

              reply.change_read_state('read', @student)
              get :items_index, params: {filter: "new_activity"}
              expect(json_parse(response.body)).to be_empty
            end
          end
        end
      end

      describe "GET #index" do
        it "returns http success" do
          get :index
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET #show" do
        it "returns http success" do
          get :show, params: {id: @planner_override.id}
          expect(response).to have_http_status(:success)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          expect(@planner_override.marked_complete).to be_falsey
          put :update, params: {id: @planner_override.id, marked_complete: true, dismissed: true}
          expect(response).to have_http_status(:success)
          expect(@planner_override.reload.marked_complete).to be_truthy
          expect(@planner_override.dismissed).to be_truthy
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, params: {plannable_type: "assignment", plannable_id: @assignment2.id, marked_complete: true}
          expect(response).to have_http_status(:created)
          expect(PlannerOverride.where(user_id: @student.id).count).to be 2
        end

        it "should save announcement overrides with a plannable_type of discussion_topic" do
          announcement_model(context: @course)
          post :create, params: {plannable_type: 'announcement', plannable_id: @a.id, user_id: @student.id, marked_complete: true}
          json = json_parse(response.body)
          expect(json["plannable_type"]).to eq 'discussion_topic'
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, params: {id: @planner_override.id}
          expect(response).to have_http_status(:success)
          expect(@planner_override.reload).to be_deleted
        end
      end
    end
  end
end
