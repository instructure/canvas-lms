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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RubricAssociationsController do
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      post 'create', params: {:course_id => @course.id, :rubric_association => {:rubric_id => @rubric.id}}
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      post 'create', params: {:course_id => @course.id,
                              :rubric_association => {:rubric_id => @rubric.id,
                                                      :title => "some association",
                                                      :association_type =>
                                                        @rubric_association.association_object.class.name,
                                                      :association_id => @rubric_association.association_object.id}}
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association].title).to eql("some association")
      expect(response).to be_successful
    end
    it "should create without manager_rubrics permission" do
      course_with_teacher_logged_in(:active_all => true)
      @course.account.role_overrides.create! :role => teacher_role, :permission => 'manage_rubrics', :enabled => false
      rubric_association_model(:user => @user, :context => @course)
      post 'create', params: {:course_id => @course.id,
                              :rubric_association => {:rubric_id => @rubric.id,
                                                      :title => "some association",
                                                      :association_type =>
                                                        @rubric_association.association_object.class.name,
                                                      :association_id => @rubric_association.association_object.id}}
      expect(response).to be_successful
    end

    describe 'AnonymousOrModerationEvent creation for auditable assignments' do
      let(:course) { Course.create! }
      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:assignment) { course.assignments.create!(anonymous_grading: true) }
      let(:rubric) { Rubric.create!(title: 'hi', context: course) }

      let(:association_params) do
        {association_id: assignment.id, association_type: 'Assignment', rubric_id: rubric.id}
      end
      let(:request_params) do
        {course_id: course.id, assignment_id: assignment.id, rubric_association: association_params}
      end

      let(:last_created_event) { AnonymousOrModerationEvent.where(event_type: 'rubric_created').last }

      before(:each) do
        user_session(teacher)
      end

      it 'records a rubric_created event for the assignment' do
        expect {
          post('create', params: request_params)
        }.to change {
          AnonymousOrModerationEvent.where(event_type: 'rubric_created', assignment: assignment).count
        }.by(1)
      end

      it 'includes the ID of the added rubric in the payload' do
        post('create', params: request_params)
        expect(last_created_event.payload['id']).to eq rubric.id
      end

      it 'includes the updating user on the event' do
        post('create', params: request_params)
        expect(last_created_event.user_id).to eq teacher.id
      end

      it 'includes the associated assignment on the event' do
        post('create', params: request_params)
        expect(last_created_event.assignment_id).to eq assignment.id
      end
    end

    describe "rubrics associated in a different" do
      describe "course" do
        before do
          course_factory
          outcome_with_rubric({mastery_points: 3, context: @context})
          @course2 = course_factory
          course_with_teacher_logged_in(active_all: true, course: @course2)
        end

        it "should duplicate the associated rubric" do
          expect {
            post 'create', params: {course_id: @course2.id, rubric_association: {rubric_id: @rubric.id}}
          }.to change {
            Rubric.count
          }.by(1)
          expect(assigns[:rubric].context).to eq @course2
          expect(assigns[:rubric].data).to eq @rubric.data
        end

        describe "with the account_level_mastery_scales FF" do
          describe "enabled" do
            before do
              @course2.root_account.enable_feature!(:account_level_mastery_scales)
              @proficiency = outcome_proficiency_model(@course2)
            end

            it "should use the new course mastery scales for learning outcome criterion" do
              post 'create', params: {course_id: @course2.id, rubric_association: {rubric_id: @rubric.id}}
              outcome_criterion = assigns[:rubric].data[0]
              expect(outcome_criterion[:ratings].length).to eq 2
              expect(outcome_criterion[:points]).to eq 10
              expect(outcome_criterion[:mastery_points]).to eq 10
              expect(outcome_criterion[:ratings].map { |rating| rating[:description] }).to eq ["best", "worst"]
            end
          end

          describe "disabled" do
            before do
              @course2.root_account.disable_feature!(:account_level_mastery_scales)
              @proficiency = outcome_proficiency_model(@course2)
            end

            it "should not change the existing criterions" do
              post 'create', params: {course_id: @course2.id, rubric_association: {rubric_id: @rubric.id}}
              expect(assigns[:rubric].data). to eq @rubric.data
            end
          end
        end
      end

      describe "account" do
        before do
          account_model
          outcome_with_rubric({mastery_points: 3, context: @account})
          course_with_teacher_logged_in(active_all: true, course: @course)
        end

        it "should not duplicate the rubric" do
          expect {
            post 'create', params: {course_id: @course.id, rubric_association: {rubric_id: @rubric.id}}
          }.to change {
            Rubric.count
          }.by(0)
          expect(assigns[:rubric]).to eq @rubric
        end
      end
    end
  end

  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', params: {:course_id => @course.id, :id => @rubric_association.id}
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', params: {:course_id => @course.id, :id => @rubric_association.id, :rubric_association => {:title => "some association"}}
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association].title).to eql("some association")
      expect(response).to be_successful
    end
    it "should update the rubric if updateable" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', params: {:course_id => @course.id, :id => @rubric_association.id, :rubric => {:title => "new title"}, :rubric_association => {:title => "some association"}}
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric].title).to eql("new title")
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association].title).to eql("some association")
      expect(response).to be_successful
    end
    it "should not update the rubric if not updateable (should make a new one instead)" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'grading')
      put 'update', params: {:course_id => @course.id, :id => @rubric_association.id, :rubric => {:title => "new title"}, :rubric_association => {:title => "some association"}}
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric].title).not_to eql("new title")
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association].title).to eql("some association")
      expect(response).to be_successful
    end
    it "should update the association" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', params: {:course_id => @course.id, :id => @rubric_association.id, :rubric_association => {:title => "some association"}}
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association].title).to eql("some association")
      expect(response).to be_successful
    end

    describe 'AnonymousOrModerationEvent creation for auditable assignments' do
      let(:course) { Course.create! }
      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:assignment) { course.assignments.create!(anonymous_grading: true) }
      let(:rubric) { Rubric.create!(title: 'hi', context: course) }

      let(:association_params) do
        {association_id: assignment.id, association_type: 'Assignment', rubric_id: rubric.id}
      end
      let(:request_params) do
        {course_id: course.id, assignment_id: assignment.id, rubric_association: association_params}
      end

      let(:old_rubric) { Rubric.create!(title: 'zzz', context: course) }
      let(:last_updated_event) { AnonymousOrModerationEvent.where(event_type: 'rubric_updated').last }

      before(:each) do
        RubricAssociation.generate(
          teacher,
          old_rubric,
          course,
          association_object: assignment,
          purpose: 'grading'
        )

        user_session(teacher)
      end

      it 'records a rubric_updated event for the assignment' do
        expect {
          put('update', params: request_params)
        }.to change {
          AnonymousOrModerationEvent.where(
            event_type: 'rubric_updated',
            assignment: assignment
          ).count
        }.by(1)
      end

      it 'includes the ID of the removed rubric in the payload' do
        put('update', params: request_params)
        expect(last_updated_event.payload['id'].first).to eq old_rubric.id
      end

      it 'includes the ID of the added rubric in the payload' do
        put('update', params: request_params)
        expect(last_updated_event.payload['id'].second).to eq rubric.id
      end

      it 'includes the updating user on the event' do
        put('update', params: request_params)
        expect(last_updated_event.user_id).to eq teacher.id
      end

      it 'includes the associated assignment on the event' do
        put('update', params: request_params)
        expect(last_updated_event.assignment_id).to eq assignment.id
      end
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      delete 'destroy', params: {:course_id => @course.id, :id => @rubric_association.id}
      assert_unauthorized
    end

    it "should delete the rubric if deletable" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      delete 'destroy', params: {:course_id => @course.id, :id => @rubric_association.id}
      expect(response).to be_successful
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to be_deleted
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).to be_deleted
    end

    it "should_not delete the rubric if still created at the context level instead of the assignment level" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      @rubric.associate_with(@course, @course, :purpose => 'bookmark')
      delete 'destroy', params: {:course_id => @course.id, :id => @rubric_association.id}
      expect(response).to be_successful
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to be_deleted
      expect(assigns[:rubric]).not_to be_frozen
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to be_deleted
    end

    it "should delete only the association if the rubric is not deletable" do
      rubric_association_model
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course, :rubric => @rubric, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'bookmark')
      delete 'destroy', params: {:course_id => @course.id, :id => @rubric_association.id}
      expect(response).to be_successful
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to be_deleted
      expect(assigns[:rubric]).not_to be_frozen
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to be_deleted
    end

    it "should remove aligments links" do
      course_with_teacher_logged_in(:active_all => true)
      outcome_with_rubric
      rubric_association_model(:user => @user, :context => @course, :rubric => @rubric)

      expect(@rubric_association_object.reload.learning_outcome_alignments.count).to eq 1
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 1

      delete 'destroy', params: {:course_id => @course.id, :id => @rubric_association.id}

      expect(@rubric.reload.deleted?).to be_truthy
      expect(@rubric_association_object.reload.learning_outcome_alignments.count).to eq 0
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 0
    end

    context 'when associated with an auditable assignment' do
      let(:course) { Course.create! }
      let(:assignment) { course.assignments.create!(anonymous_grading: true) }
      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:rubric) { Rubric.create!(title: 'aaa', context: course) }
      let!(:rubric_association) do
        RubricAssociation.generate(teacher, rubric, course, purpose: 'grading', association_object: assignment)
      end

      before(:each) do
        user_session(teacher)
      end

      it 'creates an AnonymousOrModerationEvent capturing the deletion' do
        expect {
          delete('destroy', params: {course_id: course.id, id: rubric_association.id})
        }.to change {
          AnonymousOrModerationEvent.where(event_type: 'rubric_deleted', assignment: assignment, user: teacher).count
        }.by(1)
      end

      it 'includes the removed rubric in the event payload' do
        delete('destroy', params: {course_id: course.id, id: rubric_association.id})

        event = AnonymousOrModerationEvent.find_by(event_type: 'rubric_deleted', assignment: assignment, user: teacher)
        expect(event.payload['id']).to eq rubric.id
      end
    end
  end
end
