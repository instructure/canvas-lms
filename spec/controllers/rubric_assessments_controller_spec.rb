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

describe RubricAssessmentsController do
  describe "GET 'index'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      get 'index', :course_id => @course.id, :rubric_association_id => @rubric_association.id
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      get 'index', :course_id => @course.id, :rubric_association_id => @rubric_association.id
      response.should be_success
    end
  end
  
  describe "GET 'show'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      get 'show', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      get 'show', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id
      response.should be_success
    end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course, :purpose => 'grading')
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @user.id, :assessment_type => "no_reason"}
      response.should be_success
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id, :rubric_assessment => {:user_id => @user.id}
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course, :purpose => 'grading')
      put 'update', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id, :rubric_assessment => {:user_id => @user.id, :assessment_type => "no_reason"}
      response.should be_success
    end
    it "should update the assessment" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course, :purpose => 'grading')
      put 'update', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id, :rubric_assessment => {:comments => "dude!", :user_id => @user.id, :assessment_type => "no_reason"}
      response.should be_success
      assigns[:assessment].should_not be_nil
      assigns[:assessment].comments.should eql("dude!")
    end
  end
  
  describe "POST 'remind'" do
    before do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      assessor = User.create!
      @course.enroll_student(assessor)
      assessor_asset = @rubric_association.association.find_or_create_submission(assessor)
      user_asset = @rubric_association.association.find_or_create_submission(assessor)
      @assessment_request = @rubric_association.assessment_requests.create!(user: @user, asset: user_asset, assessor: assessor, assessor_asset: assessor_asset)
    end

    it "should require authorization" do
      post 'remind', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :assessment_request_id => @assessment_request.id
      assert_unauthorized
    end
    it "should send reminder" do
      user_session(@teacher)
      post 'remind', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :assessment_request_id => @assessment_request.id
      assigns[:request].should_not be_nil
      assigns[:request].should eql(@assessment_request)
      response.should be_success
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      delete 'destroy', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id
      assert_unauthorized
    end
    it "should delete the assessment" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      delete 'destroy', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id
      response.should be_success
      assigns[:assessment].should be_frozen
    end
  end
  
  describe "Assignment assessments" do
    it "should follow: actions from two teachers should only create one assessment" do
      setup_course_assessment
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "grading"}
      response.should be_success
      @assessment = assigns[:assessment]
      @assessment.should_not be_nil
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "grading"}
      response.should be_success
      assigns[:assessment].should eql(@assessment)
    end
    
    it "should follow: multiple peer reviews for the same submission should work fine" do
      setup_course_assessment
      user_session(@student2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "peer_review"}
      response.should be_success
      @assessment = assigns[:assessment]
      @assessment.should_not be_nil
      
      user_session(@student3)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "peer_review"}
      response.should be_success
      assigns[:assessment].should_not eql(@assessment)
      
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "peer_review"}
      response.should be_success
      assigns[:assessment].should_not eql(@assessment)
    end
    
    it "should follow: multiple peer reviews for the same submission should work fine, even with a teacher assessment in play" do
      setup_course_assessment
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "grading"}
      response.should be_success
      @grading_assessment = assigns[:assessment]
      @grading_assessment.should_not be_nil

      user_session(@student2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "peer_review"}
      response.should be_success
      @assessment = assigns[:assessment]
      @assessment.should_not be_nil
      
      user_session(@student3)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "peer_review"}
      response.should be_success
      assigns[:assessment].should_not eql(@assessment)
      
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.id, :assessment_type => "peer_review"}
      response.should be_success
      assigns[:assessment].should_not eql(@assessment)
      assigns[:assessment].should_not eql(@grading_assessment)
    end
        
    it "should not allow assessing fellow students for a submission" do
      setup_course_assessment
      user_session(@student1)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student2.id, :assessment_type => 'peer_review'}
      assert_unauthorized
      
      @assignment.submit_homework(@student1, :url => "http://www.google.com")
      @assignment.submit_homework(@student2, :url => "http://www.google.com")
      @assignment.submit_homework(@student3, :url => "http://www.google.com")
      @assignment.update_attributes(:peer_review_count => 2)
      res = @assignment.assign_peer_reviews
      res.should_not be_empty
      # two of the six possible combinations have already been created
      res.length.should eql(4)
      res.to_a.find{|r| r.assessor == @student1 && r.user == @student2}.should_not be_nil
      
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student2.id, :assessment_type => 'peer_review'}
      response.should be_success
    end
  end
end

def setup_course_assessment
  course_with_teacher_logged_in(:active_all => true)
  @student1 = factory_with_protected_attributes(User, :name => "student 1", :workflow_state => "registered")
  @student2 = factory_with_protected_attributes(User, :name => "student 2", :workflow_state => "registered")
  @student3 = factory_with_protected_attributes(User, :name => "student 3", :workflow_state => "registered")
  @teacher2 = factory_with_protected_attributes(User, :name => "teacher 2", :workflow_state => "registered")
  @course.enroll_student(@student1).accept!
  @course.enroll_student(@student2).accept!
  @course.enroll_student(@student3).accept!
  @course.enroll_teacher(@teacher2).accept!
  @assignment = @course.assignments.create!(:title => "Some Assignment")
  rubric_assessment_model(:user => @user, :context => @course, :association => @assignment, :purpose => 'grading')
  student1_asset = @assignment.find_or_create_submission(@student1)
  student2_asset = @assignment.find_or_create_submission(@student2)
  student3_asset = @assignment.find_or_create_submission(@student3)
  @rubric_association.assessment_requests.create!(user: @student1, asset: student1_asset, assessor: @student2, assessor_asset: student2_asset)
  @rubric_association.assessment_requests.create!(user: @student1, asset: student1_asset, assessor: @student3, assessor_asset: student3_asset)
end
