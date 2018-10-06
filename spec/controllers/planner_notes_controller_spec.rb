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

require_relative '../spec_helper'

describe PlannerNotesController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @course_1 = @course
    course_with_student(user: @student, active_all: true)
    @course_2 = @course
    @student_note = planner_note_model(user: @student, todo_date: 1.week.from_now)
    @teacher_note = planner_note_model(user: @teacher, todo_date: 1.week.from_now)
    @course_1_note = planner_note_model(user: @student, todo_date: 1.week.ago, course: @course_1)
    @course_2_note = planner_note_model(user: @student, todo_date: 3.weeks.ago, course: @course_2)
  end

  context "unauthenticated" do
    it "should return unauthorized" do
      get :index
      assert_unauthorized

      post :create, params: {:title => "thing",
                     :todo_date => 1.day.from_now}
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

      post :create, params: {title: 'thing', todo_date: 1.day.from_now}
      assert_forbidden
    end
  end

  context "authenticated" do
    before :once do
      @course_1.root_account.enable_feature!(:student_planner)
      @course_2.root_account.enable_feature!(:student_planner)
    end

    context "as student" do
      before :each do
        user_session(@student)
      end

      describe "GET #index" do
        it "returns http success" do
          get :index
          expect(response).to be_successful
        end

        it "excludes deleted courses" do
          @course_1.destroy
          get :index
          note_ids = json_parse(response.body).map{|n| n["id"]}
          expect(note_ids).to_not include(@course_1_note.id)
          expect(note_ids).to include(@course_2_note.id)

          get :index, params: {context_codes: ["course_#{@course_1.id}"]}
          course_notes = json_parse(response.body)
          expect(course_notes.length).to eq 0
        end

        it "filters by context codes when specified" do
          get :index, params: {context_codes: ["course_#{@course_1.id}"]}
          course_notes = json_parse(response.body)
          expect(course_notes.length).to eq 1
          expect(course_notes.first["id"]).to eq @course_1_note.id

          get :index, params: {context_codes: ["course_#{@course_2.id}"]}
          course_notes = json_parse(response.body)
          expect(course_notes.length).to eq 1
          expect(course_notes.first["id"]).to eq @course_2_note.id
        end

        it "includes own notes if specified" do
          get :index, params: {context_codes: ["course_#{@course_1.id}", "user_#{@user.id}"]}
          course_notes = json_parse(response.body)
          expect(course_notes.length).to eq 2
          expect(course_notes.map{|n| n["id"]}).to match_array [@course_1_note.id, @student_note.id]
        end

        it "filters by start and end dates when specified" do
          get :index, params: {start_date: 2.weeks.ago.to_date.to_s}
          all_notes = json_parse(response.body)
          expect(all_notes.length).to eq 2
          expect(all_notes.pluck("id").sort).to eq [@student_note.id, @course_1_note.id].sort

          get :index, params: {end_date: 1.day.from_now.to_date.to_s}
          all_notes = json_parse(response.body)
          expect(all_notes.length).to eq 2
          expect(all_notes.pluck("id").sort).to eq [@course_1_note.id, @course_2_note.id].sort

          get :index, params: {start_date: 4.weeks.ago.to_date.to_s, end_date: 2.weeks.from_now.to_date.to_s}
          all_notes = json_parse(response.body)
          expect(all_notes.length).to eq 3
          expect(all_notes.pluck("id").sort).to eq [@student_note.id, @course_1_note.id, @course_2_note.id].sort
        end

        it 'should 400 for bad start dates' do
          get :index, params: {start_date: '123-456-7890'}
          expect(response.code).to eq '400'
          json = json_parse(response.body)
          expect(json['errors']).to eq 'Invalid date or datetime for start_date'
        end

        it 'should 400 for bad end dates' do
          get :index, params: {end_date: '5678-90'}
          expect(response.code).to eq '400'
          json = json_parse(response.body)
          expect(json['errors']).to eq 'Invalid date or datetime for end_date'
        end
      end

      describe "GET #show" do
        it "returns http success for accessing your notes" do
          get :show, params: {id: @student_note.id}
          expect(response).to be_successful
        end

        it "returns http not found for notes not yours" do
          u = user_factory(active_all: true)
          u_note = planner_note_model(user: u, todo_date: 1.week.from_now)
          get :show, params: {id: u_note.id}
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          updated_title = "updated note title"
          put :update, params: {id: @student_note.id, title: updated_title}
          expect(response).to be_successful
          expect(@student_note.reload.title).to eq updated_title
        end

        it "invalidates the planner cache" do
          expect(Rails.cache).to receive(:delete).with(/#{controller.planner_meta_cache_key}/)
          put :update, params: {id: @student_note.id, title: 'update'}
        end

        it "links to a course" do
          put :update, params: {id: @student_note.id, course_id: @course_1.to_param}
          expect(response).to be_successful
          expect(@student_note.reload.course_id).to eq @course_1.id
        end

        it "removes course link" do
          @student_note.course = @course_1
          @student_note.save!
          put :update, params: {id: @student_note.id, course_id: ''}
          expect(response).to be_successful
          expect(@student_note.reload.course_id).to be_nil
        end

        context "linked planner note" do
          before :once do
            assignment = @course_1.assignments.create!(title: 'blah')
            @student_note.course = @course_1
            @student_note.linked_object = assignment
            @student_note.save!
          end

          it "does not remove course link if a learning object link is present" do
            put :update, params: {id: @student_note.id, course_id: ''}
            expect(response).to have_http_status(:bad_request)
          end

          it "does not allow linking to a different course" do
            put :update, params: {id: @student_note.id, course_id: @course_2.to_param}
            expect(response).to have_http_status(:bad_request)
          end

          it "does allow other updates" do
            put :update, params: {id: @student_note.id, details: 'this assignment is terrible'}
            expect(response).to be_successful
            expect(@student_note.reload.details).to eq 'this assignment is terrible'
          end
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, params: {title: "A title about things", details: "Details about now", todo_date: 1.day.from_now}
          expect(response).to have_http_status(:created)
          expect(PlannerNote.where(user_id: @student.id).count).to eq 4
        end

        it "invalidates the planner cache" do
          expect(Rails.cache).to receive(:delete).with(/#{controller.planner_meta_cache_key}/)
          post :create, params: {title: "A title about things", details: "Details about now", todo_date: 1.day.from_now}
        end

        describe "linked_object" do
          it "links to an assignment" do
            a = @course_1.assignments.create!(title: 'Foo')

            post :create, params: {course_id: @course_1.to_param, details: 'foo', todo_date: 1.day.from_now,
                                   linked_object_type: 'assignment', linked_object_id: a.to_param}
            expect(response).to have_http_status(:created)

            json = JSON.parse(response.body)
            expect(json['title']).to eq 'Foo'
            expect(json['details']).to eq 'foo'
            expect(json['linked_object_type']).to eq 'assignment'
            expect(json['linked_object_id']).to eq a.id
            expect(json['linked_object_url']).to eq "http://test.host/api/v1/courses/#{@course_1.id}/assignments/#{a.id}"
            expect(json['linked_object_html_url']).to eq "http://test.host/courses/#{@course_1.id}/assignments/#{a.id}"

            note = PlannerNote.find(json['id'])
            expect(note.linked_object_type).to eq 'Assignment'
            expect(note.linked_object_id).to eq a.id
          end

          it "links to an announcement" do
            a = @course_1.announcements.create!(title: 'Bar', message: 'eh')

            post :create, params: {course_id: @course_1.to_param, details: 'bar', todo_date: 1.day.from_now,
                                   linked_object_type: 'announcement', linked_object_id: a.to_param}
            expect(response).to have_http_status(:created)

            json = JSON.parse(response.body)
            expect(json['title']).to eq 'Bar'
            expect(json['details']).to eq 'bar'
            expect(json['linked_object_type']).to eq 'discussion_topic'
            expect(json['linked_object_id']).to eq a.id
            expect(json['linked_object_url']).to eq "http://test.host/api/v1/courses/#{@course_1.id}/discussion_topics/#{a.id}"
            expect(json['linked_object_html_url']).to eq "http://test.host/courses/#{@course_1.id}/discussion_topics/#{a.id}"

            note = PlannerNote.find(json['id'])
            expect(note.linked_object_type).to eq 'DiscussionTopic'
            expect(note.linked_object_id).to eq a.id
          end

          it "links to a discussion topic" do
            dt = @course_1.discussion_topics.create!(title: 'Baz')

            post :create, params: {course_id: @course_1.to_param, details: 'baz', todo_date: 1.day.from_now,
                                   linked_object_type: "discussion_topic", linked_object_id: dt.to_param}
            expect(response).to have_http_status(:created)

            json = JSON.parse(response.body)
            expect(json['title']).to eq 'Baz'
            expect(json['details']).to eq 'baz'
            expect(json['linked_object_type']).to eq 'discussion_topic'
            expect(json['linked_object_id']).to eq dt.id
            expect(json['linked_object_url']).to eq "http://test.host/api/v1/courses/#{@course_1.id}/discussion_topics/#{dt.id}"
            expect(json['linked_object_html_url']).to eq "http://test.host/courses/#{@course_1.id}/discussion_topics/#{dt.id}"

            note = PlannerNote.find(json['id'])
            expect(note.linked_object_type).to eq 'DiscussionTopic'
            expect(note.linked_object_id).to eq dt.id
          end

          it "links to a wiki page" do
            wp = @course_1.wiki_pages.create!(title: 'Quux')

            post :create, params: {course_id: @course_1.to_param, details: 'quux', todo_date: 1.day.from_now,
                                   linked_object_type: "wiki_page", linked_object_id: wp.id.to_s}
            expect(response).to have_http_status(:created)

            json = JSON.parse(response.body)
            expect(json['title']).to eq 'Quux'
            expect(json['details']).to eq 'quux'
            expect(json['linked_object_type']).to eq 'wiki_page'
            expect(json['linked_object_id']).to eq wp.id
            expect(json['linked_object_url']).to eq "http://test.host/api/v1/courses/#{@course_1.id}/pages/page_id:#{wp.id}"
            expect(json['linked_object_html_url']).to eq "http://test.host/courses/#{@course_1.id}/pages/page_id:#{wp.id}"

            note = PlannerNote.find(json['id'])
            expect(note.linked_object_type).to eq 'WikiPage'
            expect(note.linked_object_id).to eq wp.id
          end

          it "links to a quiz" do
            q = @course_1.quizzes.create!(title: 'Quuux')
            q.publish!

            post :create, params: {course_id: @course_1.to_param, details: 'quuux', todo_date: 1.day.from_now,
                                   linked_object_type: 'quiz', linked_object_id: q.to_param}
            expect(response).to have_http_status(:created)

            json = JSON.parse(response.body)
            expect(json['title']).to eq 'Quuux'
            expect(json['details']).to eq 'quuux'
            expect(json['linked_object_type']).to eq 'quiz'
            expect(json['linked_object_id']).to eq q.id
            expect(json['linked_object_url']).to eq "http://test.host/api/v1/courses/#{@course_1.id}/quizzes/#{q.id}"
            expect(json['linked_object_html_url']).to eq "http://test.host/courses/#{@course_1.id}/quizzes/#{q.id}"

            note = PlannerNote.find(json['id'])
            expect(note.linked_object_type).to eq 'Quizzes::Quiz'
            expect(note.linked_object_id).to eq q.id
          end

          it "returns 404 when the linked object doesn't exist" do
            post :create, params: {course_id: @course_1.to_param, details: 'quuux', todo_date: 1.day.from_now,
                                   linked_object_type: "discussion_topic", linked_object_id: 0}
            expect(response).to have_http_status(:not_found)
          end

          it "checks :read permission on the linked object" do
            a = @course_1.assignments.create!(title: 'Foo', workflow_state: 'unpublished')
            post :create, params: {course_id: @course_1.to_param, details: 'quuux', todo_date: 1.day.from_now,
                                   linked_object_type: "assignment", linked_object_id: a.id}
            expect(response).to have_http_status(:unauthorized)
          end

          it "returns 400 when attempting to link to an unsupported type" do
            outcome = @course_1.learning_outcomes.create!(title: 'eh')
            post :create, params: {course_id: @course_1.to_param, details: 'quuux', todo_date: 1.day.from_now,
                                   linked_object_type: 'learning_outcome', linked_object_id: outcome.id}
            expect(response).to have_http_status(:bad_request)
          end

          it "returns 400 if the course_id is omitted" do
            a = @course_1.assignments.create!(title: 'Foo')
            post :create, params: {details: 'foo', todo_date: 1.day.from_now,
                                   linked_object_type: "assignment", linked_object_id: a.id}
            expect(response).to have_http_status(:bad_request)
          end

          it "returns 400 if a non-deleted planner note link to the object already exists" do
            a = @course_1.assignments.create!(title: 'Foo')
            n = @student.planner_notes.create!(title: 'Foo', todo_date: 1.day.from_now, course_id: @course_1,
                                               linked_object: a)
            post :create, params: {details: 'bar', todo_date: 2.days.from_now, linked_object_type: 'assignment',
                                   course_id: @course_1.id, linked_object_id: a.id}
            expect(response).to have_http_status(:bad_request)
            expect(response.body).to include 'a planner note linked to that object already exists'

            n.destroy
            post :create, params: {details: 'bar', todo_date: 2.days.from_now, linked_object_type: 'assignment',
                                   course_id: @course_1.id, linked_object_id: a.id}
            expect(response).to be_successful

            scope = @student.planner_notes.where(linked_object_id: a.id, linked_object_type: 'Assignment')
            expect(scope.count).to eq 2
            expect(scope.active.count).to eq 1
          end

          context "sharding" do
            specs_require_sharding

            before :once do
              @shard1.activate do
                @remote_account = Account.create!
                @remote_course = course_with_student(account: @remote_account, user: @student, active_all: true).course
                @remote_assignment = @remote_course.assignments.create!(title: 'Over there')
              end
            end

            it "links to an object in another shard" do
              post :create, params: {todo_date: 1.day.from_now, course_id: @remote_course.id,
                linked_object_type: 'assignment', linked_object_id: @remote_assignment.id}
              expect(response).to be_successful

              json = JSON.parse(response.body)
              note = PlannerNote.find(json['id'])
              expect(note.linked_object_id).to eq @remote_assignment.global_id
            end
          end
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, params: {id: @student_note.id}
          expect(response).to be_successful
          expect(@student_note.reload).to be_deleted
        end

        it "invalidates the planner cache" do
          expect(Rails.cache).to receive(:delete).with(/#{controller.planner_meta_cache_key}/)
          delete :destroy, params: {id: @student_note.id}
        end
      end
    end

    context "as teacher" do
      before :each do
        user_session(@teacher)
      end

      describe "GET #index" do
        it "returns http success" do
          get :index
          expect(response).to be_successful
        end
      end

      describe "GET #show" do
        it "returns http success" do
          get :show, params: {id: @teacher_note.id}
          expect(response).to be_successful
        end

        it "returns http not found for notes not yours" do
          u = user_factory(active_all: true)
          u_note = u.planner_notes.create(
            :title => "Other User's Note",
            :details => "Other Details",
            :todo_date => 1.week.from_now
          )
          get :show, params: {id: u_note.id}
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "PUT #update" do
        it "returns http success" do
          updated_title = "updated note title"
          put :update, params: {id: @teacher_note.id, title: updated_title}
          expect(response).to be_successful
          expect(@teacher_note.reload.title).to eq updated_title
        end

        it "invalidates the planner cache" do
          expect(Rails.cache).to receive(:delete).with(/#{controller.planner_meta_cache_key}/)
          put :update, params: {id: @teacher_note.id, title: 'updated title'}
        end
      end

      describe "POST #create" do
        it "returns http success" do
          post :create, params: {title: "A title about things", details: "Details about now", todo_date: 1.day.from_now}
          expect(response).to have_http_status(:created)
          expect(PlannerNote.where(user_id: @teacher.id).count).to be 2
        end

        it "invalidates the planner cache" do
          expect(Rails.cache).to receive(:delete).with(/#{controller.planner_meta_cache_key}/)
          post :create, params: {title: "A title about things", details: "Details about now", todo_date: 1.day.from_now}
        end
      end

      describe "DELETE #destroy" do
        it "returns http success" do
          delete :destroy, params: {id: @teacher_note.id}
          expect(response).to be_successful
          expect(@teacher_note.reload).to be_deleted
        end

        it "invalidates the planner cache" do
          expect(Rails.cache).to receive(:delete).with(/#{controller.planner_meta_cache_key}/)
          delete :destroy, params: {id: @teacher_note.id}
        end
      end
    end
  end
end
