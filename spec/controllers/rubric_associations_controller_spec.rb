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
      expect(response).to be_success
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
      expect(response).to be_success
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
      expect(response).to be_success
    end
    it "should update the rubric if updateable" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', params: {:course_id => @course.id, :id => @rubric_association.id, :rubric => {:title => "new title"}, :rubric_association => {:title => "some association"}}
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric].title).to eql("new title")
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association].title).to eql("some association")
      expect(response).to be_success
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
      expect(response).to be_success
    end
    it "should update the association" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', params: {:course_id => @course.id, :id => @rubric_association.id, :rubric_association => {:title => "some association"}}
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association].title).to eql("some association")
      expect(response).to be_success
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
      expect(response).to be_success
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to be_frozen
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).to be_deleted
    end
    it "should_not delete the rubric if still created at the context level instead of the assignment level" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      @rubric.associate_with(@course, @course, :purpose => 'bookmark')
      delete 'destroy', params: {:course_id => @course.id, :id => @rubric_association.id}
      expect(response).to be_success
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to be_deleted
      expect(assigns[:rubric]).not_to be_frozen
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to be_frozen
    end
    it "should delete only the association if the rubric is not deletable" do
      rubric_association_model
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course, :rubric => @rubric, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'grading')
      @rubric.associate_with(@course, @course, :purpose => 'bookmark')
      delete 'destroy', params: {:course_id => @course.id, :id => @rubric_association.id}
      expect(response).to be_success
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to be_deleted
      expect(assigns[:rubric]).not_to be_frozen
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to be_frozen
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
  end
end
