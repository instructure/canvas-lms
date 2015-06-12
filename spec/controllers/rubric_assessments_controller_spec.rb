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
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @user.to_param}
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course, :purpose => 'grading')
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @user.to_param, :assessment_type => "no_reason"}
      expect(response).to be_success
    end

    it "should not pass invalid ids through to the database" do
      course_with_teacher_logged_in(:active_all => true)
      assert_page_not_found do
        rubric_assessment_model(:user => @user, :context => @course, :purpose => 'grading')
        post 'create', :course_id => @course.id,
          :rubric_association_id => @rubric_association.id,
          :rubric_assessment => {:user_id => 'garbage', :assessment_type => "no_reason"}
      end
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course)
      put 'update', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id, :rubric_assessment => {:user_id => @user.to_param}
      assert_unauthorized
    end
    it "should assign variables" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course, :purpose => 'grading')
      put 'update', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id, :rubric_assessment => {:user_id => @user.to_param, :assessment_type => "no_reason"}
      expect(response).to be_success
    end
    it "should update the assessment" do
      course_with_teacher_logged_in(:active_all => true)
      rubric_assessment_model(:user => @user, :context => @course, :purpose => 'grading')
      put 'update', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :id => @rubric_assessment.id, :rubric_assessment => {:comments => "dude!", :user_id => @user.to_param, :assessment_type => "no_reason"}
      expect(response).to be_success
      expect(assigns[:assessment]).not_to be_nil
      expect(assigns[:assessment].comments).to eql("dude!")
    end
  end
  
  describe "POST 'remind'" do
    before do
      course_with_teacher(:active_all => true)
      rubric_association_model(:user => @user, :context => @course)
      assessor = User.create!
      @course.enroll_student(assessor)
      assessor_asset = @rubric_association.association_object.find_or_create_submission(assessor)
      user_asset = @rubric_association.association_object.find_or_create_submission(assessor)
      @assessment_request = @rubric_association.assessment_requests.create!(user: @user, asset: user_asset, assessor: assessor, assessor_asset: assessor_asset)
    end

    it "should require authorization" do
      post 'remind', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :assessment_request_id => @assessment_request.id
      assert_unauthorized
    end
    it "should send reminder" do
      user_session(@teacher)
      post 'remind', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :assessment_request_id => @assessment_request.id
      expect(assigns[:request]).not_to be_nil
      expect(assigns[:request]).to eql(@assessment_request)
      expect(response).to be_success
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
      expect(response).to be_success
      expect(assigns[:assessment]).to be_frozen
    end
  end
  
  describe "Assignment assessments" do
    it "should follow: actions from two teachers should only create one assessment" do
      setup_course_assessment
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "grading"}
      expect(response).to be_success
      @assessment = assigns[:assessment]
      expect(@assessment).not_to be_nil
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "grading"}
      expect(response).to be_success
      expect(assigns[:assessment]).to eql(@assessment)
    end
    
    it "should follow: multiple peer reviews for the same submission should work fine" do
      setup_course_assessment
      user_session(@student2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "peer_review"}
      expect(response).to be_success
      @assessment = assigns[:assessment]
      expect(@assessment).not_to be_nil
      
      user_session(@student3)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "peer_review"}
      expect(response).to be_success
      expect(assigns[:assessment]).not_to eql(@assessment)
      
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "peer_review"}
      expect(response).to be_success
      expect(assigns[:assessment]).not_to eql(@assessment)
    end
    
    it "should follow: multiple peer reviews for the same submission should work fine, even with a teacher assessment in play" do
      setup_course_assessment
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "grading"}
      expect(response).to be_success
      @grading_assessment = assigns[:assessment]
      expect(@grading_assessment).not_to be_nil

      user_session(@student2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "peer_review"}
      expect(response).to be_success
      @assessment = assigns[:assessment]
      expect(@assessment).not_to be_nil
      
      user_session(@student3)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "peer_review"}
      expect(response).to be_success
      expect(assigns[:assessment]).not_to eql(@assessment)
      
      user_session(@teacher2)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student1.to_param, :assessment_type => "peer_review"}
      expect(response).to be_success
      expect(assigns[:assessment]).not_to eql(@assessment)
      expect(assigns[:assessment]).not_to eql(@grading_assessment)
    end
        
    it "should not allow assessing fellow students for a submission" do
      setup_course_assessment
      user_session(@student1)
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student2.to_param, :assessment_type => 'peer_review'}
      assert_unauthorized
      
      @assignment.submit_homework(@student1, :url => "http://www.google.com")
      @assignment.submit_homework(@student2, :url => "http://www.google.com")
      @assignment.submit_homework(@student3, :url => "http://www.google.com")
      @assignment.update_attributes(:peer_review_count => 2)
      res = @assignment.assign_peer_reviews
      expect(res).not_to be_empty
      # two of the six possible combinations have already been created
      expect(res.length).to eql(4)
      expect(res.to_a.find{|r| r.assessor == @student1 && r.user == @student2}).not_to be_nil
      
      post 'create', :course_id => @course.id, :rubric_association_id => @rubric_association.id, :rubric_assessment => {:user_id => @student2.to_param, :assessment_type => 'peer_review'}
      expect(response).to be_success
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
  rubric_assessment_model(:user => @user, :context => @course, :association_object => @assignment, :purpose => 'grading')
  student1_asset = @assignment.find_or_create_submission(@student1)
  student2_asset = @assignment.find_or_create_submission(@student2)
  student3_asset = @assignment.find_or_create_submission(@student3)
  @rubric_association.assessment_requests.create!(user: @student1, asset: student1_asset, assessor: @student2, assessor_asset: student2_asset)
  @rubric_association.assessment_requests.create!(user: @student1, asset: student1_asset, assessor: @student3, assessor_asset: student3_asset)
end
