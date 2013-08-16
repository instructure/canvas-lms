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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RubricsController do
  describe "GET 'index'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    describe 'variables' do
      before { course_with_teacher_logged_in(:active_all => true) }

      it "should be assigned with a course" do
        get 'index', :course_id => @course.id
        response.should be_success
      end

      it "should be assigned with a user" do
        get 'index', :user_id => @user.id
        response.should be_success
      end
    end
  end

  describe "POST 'create' for course" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'create', :course_id => @course.id
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :rubric => {}
      assigns[:rubric].should_not be_nil
      assigns[:rubric].should_not be_new_record
      response.should be_success
      
    end
    it "should create an association if specified" do
      course_with_teacher_logged_in(:active_all => true)
      association = @course.assignments.create!(assignment_valid_attributes)
      post 'create', :course_id => @course.id, :rubric => {}, :rubric_association => {:association_type => association.class.to_s, :association_id => association.id}
      assigns[:rubric].should_not be_nil
      assigns[:rubric].should_not be_new_record
      assigns[:rubric].rubric_associations.length.should eql(1)
      response.should be_success
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric.id
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      @course.rubrics.should be_include(@rubric)
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {}
      assigns[:rubric].should eql(@rubric)
      response.should be_success
    end
    it "should update the rubric if updateable" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {:title => "new title"}
      assigns[:rubric].should eql(@rubric)
      assigns[:rubric].title.should eql("new title")
      assigns[:association].should be_nil
      response.should be_success
    end
    it "should update the rubric even if it doesn't belong to the context, just an association" do
      course_model
      @course2 = @course
      course_with_teacher_logged_in(:active_all => true)
      @e = @course2.enroll_teacher(@user)
      @e.accept
      rubric_association_model(:user => @user, :context => @course)
      @rubric.context = @course2
      @rubric.save
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {:title => "new title"}, :rubric_association_id => @rubric_association.id
      assigns[:rubric].should eql(@rubric)
      assigns[:rubric].title.should eql("new title")
      assigns[:association].should_not be_nil
      assigns[:association].should eql(@rubric_association)
      response.should be_success
    end

    # this happens after a importing content into a new course, before a new
    # association is set up
    it "should create a new rubrice (and not update the existing rubric) if it doesn't belong to the context or to an association" do
      course_model
      @course2 = @course
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      @rubric.context = @course2
      @rubric.save
      @rubric_association.context = @course2
      @rubric_association.save
      rescue_action_in_public!
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {:title => "new title"}, :rubric_association_id => @rubric_association.id
      assigns[:rubric].should_not be_nil
      assigns[:rubric].should_not eql(@rubric)
      assigns[:rubric].title.should eql("new title")
    end
    it "should not update the rubric if not updateable (should make a new one instead)" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course, :purpose => 'grading')
      @rubric.rubric_associations.create!(:purpose => 'grading')
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {:title => "new title"}, :rubric_association_id => @rubric_association.id
      assigns[:rubric].should_not eql(@rubric)
      assigns[:rubric].should_not be_new_record
      assigns[:association].should_not be_nil
      assigns[:association].should eql(@rubric_association)
      assigns[:association].rubric.should eql(assigns[:rubric])
      assigns[:rubric].title.should eql("new title")
      response.should be_success
    end
    it "should not update the rubric and not create a new one if the parameters don't change the rubric" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course, :purpose => 'grading')
      params = {
        :title => 'new title',
        :criteria => {
          '0' => {
            :description => 'desc',
            :long_description => 'long_desc',
            :points => '5',
            :id => 'id_5',
            :ratings => {
              '0' => {
                :description => 'a',
                :points => '5',
                :id => 'id_6'
              },
              '1' => {
                :description => 'b',
                :points => '0',
                :id => 'id_7'
              }
            }
          }
        }
      }
      @rubric.update_criteria(params)
      @rubric.save!
      @rubric.rubric_associations.create!(:purpose => 'grading')
      criteria = @rubric.criteria
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => params, :rubric_association_id => @rubric_association.id
      assigns[:rubric].should eql(@rubric)
      assigns[:rubric].criteria.should eql(criteria)
      assigns[:rubric].should_not be_new_record
      assigns[:association].should_not be_nil
      assigns[:association].should eql(@rubric_association)
      assigns[:association].rubric.should eql(assigns[:rubric])
      assigns[:rubric].title.should eql("new title")
      response.should be_success
    end

    it "should update the newly-created rubric if updateable, even if the old id is specified" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {:title => "new title"}, :rubric_association_id => @rubric_association.id
      assigns[:rubric].should eql(@rubric)
      assigns[:rubric].title.should eql("new title")
      @rubric2 = assigns[:rubric]
      assigns[:association].should_not be_nil
      assigns[:association].should eql(@rubric_association)
      response.should be_success
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {:title => "newer title"}, :rubric_association_id => @rubric_association.id
      assigns[:rubric].should eql(@rubric2)
      assigns[:rubric].title.should eql("newer title")
      response.should be_success
    end
    it "should update the association if specified" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :id => @rubric.id, :rubric => {:title => "new title"}, :rubric_association => {:association_type => @rubric_association.association.class.to_s, :association_id => @rubric_association.association.id, :title => "some title", :id => @rubric_association.id}
      assigns[:rubric].should eql(@rubric)
      assigns[:rubric].title.should eql("new title")
      assigns[:association].should eql(@rubric_association)
      assigns[:rubric].rubric_associations.find_by_id(@rubric_association.id).title.should eql("some title")
      response.should be_success
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      delete 'destroy', :course_id => @course.id, :id => @rubric.id
      assert_unauthorized
    end
    it "should delete the rubric" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      delete 'destroy', :course_id => @course.id, :id => @rubric.id
      response.should be_success
      assigns[:rubric].should be_deleted
    end
    it "should delete the rubric if the rubric is only associated with a course" do
      course_with_teacher_logged_in :active_all => true
      Account.site_admin.add_user(@user, 'AccountAdmin')
      Account.default.add_user(@user, 'AccountAdmin')

      @rubric = Rubric.create!(:user => @user, :context => @course)
      RubricAssociation.create!(:rubric => @rubric, :context => @course, :purpose => :bookmark)
      @course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).once_per(&:rubric_id).sort_by{|a| a.rubric.title }.map(&:rubric).should == [@rubric]

      delete 'destroy', :course_id => @course.id, :id => @rubric.id
      response.should be_success
      @course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).once_per(&:rubric_id).sort_by{|a| a.rubric.title }.map(&:rubric).should == []
      @rubric.reload
      @rubric.deleted?.should be_true
    end
    it "should delete the rubric association even if the rubric doesn't belong to a course" do
      course_with_teacher_logged_in :active_all => true
      Account.site_admin.add_user(@user, 'AccountAdmin')
      Account.default.add_user(@user, 'AccountAdmin')
      @user.reload

      @rubric = Rubric.create!(:user => @user, :context => Account.default)
      RubricAssociation.create!(:rubric => @rubric, :context => @course, :purpose => :bookmark)
      RubricAssociation.create!(:rubric => @rubric, :context => Account.default, :purpose => :bookmark)
      @course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).once_per(&:rubric_id).sort_by{|a| a.rubric.title }.map(&:rubric).should == [@rubric]
      
      delete 'destroy', :course_id => @course.id, :id => @rubric.id
      response.should be_success
      @course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).once_per(&:rubric_id).sort_by{|a| a.rubric.title }.map(&:rubric).should == []
      @rubric.reload
      @rubric.deleted?.should be_false
    end
  end
end
