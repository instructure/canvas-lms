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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Enrollment do
  before(:each) do
    @user = User.create! #mock_model(User)
    @course = Course.create! #mock_model(Course)
    @enrollment = Enrollment.new(valid_enrollment_attributes)
  end

  it "should be valid" do
    @enrollment.should be_valid
  end
  
  it "should have an interesting state machine" do
    enrollment_model
    list = {}
    list.stub!(:find_all_by_context_id_and_context_type).and_return([])
    @user.stub!(:dashboard_messages).and_return(list)
    @enrollment.state.should eql(:invited)
    @enrollment.accept
    @enrollment.state.should eql(:active)
    @enrollment.reject
    @enrollment.state.should eql(:rejected)
    enrollment_model
    @enrollment.complete
    @enrollment.state.should eql(:completed)
    enrollment_model
    @enrollment.reject
    @enrollment.state.should eql(:rejected)
    enrollment_model
    @enrollment.accept
    @enrollment.state.should eql(:active)
  end
  
  it "should find students" do
    @student_list = mock('student list')
    @student_list.stub!(:map).and_return(['student list'])
    Enrollment.should_receive(:find).and_return(@student_list)
    Enrollment.students.should eql(['student list'])
  end
  
  it "should be pending if it is invited or creation_pending" do
    enrollment_model(:workflow_state => 'invited')
    @enrollment.should be_pending

    enrollment_model(:workflow_state => 'creation_pending')
    @enrollment.should be_pending
  end
  
  it "should have a context_id as the course_id" do
    @enrollment.course.id.should_not be_nil
    @enrollment.context_id.should eql(@enrollment.course.id)
  end
  
  it "should have a readable_type of Teacher for a TeacherEnrollment" do
    e = TeacherEnrollment.new
    e.type = 'TeacherEnrollment'
    e.readable_type.should eql('Teacher')
  end
  
  it "should have a readable_type of Student for a StudentEnrollment" do
    e = StudentEnrollment.new
    e.type = 'StudentEnrollment'
    e.readable_type.should eql('Student')
  end
  
  it "should have a readable_type of TaEnrollment for a TA" do
    e = TaEnrollment.new(valid_enrollment_attributes)
    e.type = 'TaEnrollment'
    e.readable_type.should eql('TA')
  end
  
  it "should have a defalt readable_type of Student" do
    e = Enrollment.new
    e.type = 'Other'
    e.readable_type.should eql('Student')
  end
  
  context "typed_enrollment" do
    it "should allow StudentEnrollment" do
      Enrollment.typed_enrollment('StudentEnrollment').should eql(StudentEnrollment)
    end
    it "should allow TeacherEnrollment" do
      Enrollment.typed_enrollment('TeacherEnrollment').should eql(TeacherEnrollment)
    end
    it "should allow TaEnrollment" do
      Enrollment.typed_enrollment('TaEnrollment').should eql(TaEnrollment)
    end
    it "should allow ObserverEnrollment" do
      Enrollment.typed_enrollment('ObserverEnrollment').should eql(ObserverEnrollment)
    end
    it "should allow DesignerEnrollment" do
      Enrollment.typed_enrollment('DesignerEnrollment').should eql(DesignerEnrollment)
    end
    it "should allow not NothingEnrollment" do
      Enrollment.typed_enrollment('NothingEnrollment').should eql(nil)
    end
  end
  
  context "drop scores" do
    before(:each) do
      course_with_student
      @group = @course.assignment_groups.create!(:name => "some group", :group_weight => 50, :rules => "drop_lowest:1")
      @assignment = @group.assignments.build(:title => "some assignments", :points_possible => 10)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(:title => "some assignment 2", :points_possible => 40)
      @assignment2.context = @course
      @assignment2.save!
    end
    
    it "should drop high scores for groups when specified" do
      @group.update_attribute(:rules, "drop_highest:1")
      @user.enrollments.first.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission[0].score.should eql(9.0)
      @user.enrollments.should_not be_empty
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(50.0)
      @group.reload
      @group.rules = nil
      @group.save
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(58.0)
    end

    it "should drop low scores for groups when specified" do
      @user.enrollments.first.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @group.update_attribute(:rules, "")
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(58.0)
    end
    
    it "should not drop the last score for a group, even if the settings say it should be dropped" do
      @group.update_attribute(:rules, "drop_lowest:2")
      @user.enrollments.first.computed_current_score.should eql(nil)
      @submission = @assignment.grade_student(@user, :grade => "9")
      @submission[0].score.should eql(9.0)
      @user.enrollments.should_not be_empty
      @user.enrollments.first.computed_current_score.should eql(90.0)
      @submission2 = @assignment2.grade_student(@user, :grade => "20")
      @submission2[0].score.should eql(20.0)
      @user.reload
      @user.enrollments.first.computed_current_score.should eql(90.0)
    end
  end
  
  context "notifications" do
    it "should send out invitations if the course is already published" do
      Notification.create!(:name => "Enrollment Registration")
      course_with_teacher(:active_all => true)
      user_with_pseudonym
      e = @course.enroll_student(@user)
      e.messages_sent.should be_include("Enrollment Registration")
    end
    
    it "should not send out invitations if the course is not yet published" do
      Notification.create!(:name => "Enrollment Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      e.messages_sent.should_not be_include("Enrollment Registration")
    end
    
    it "should send out invitations for previously-created enrollments when the course is published" do
      n = Notification.create(:name => "Enrollment Registration", :category => "Registration")
      course_with_teacher
      user_with_pseudonym
      e = @course.enroll_student(@user)
      e.messages_sent.should_not be_include("Enrollment Registration")
      @user.pseudonym.should_not be_nil
      @course.offer
      e.reload
      e.should be_invited
      e.user.should_not be_nil
      e.user.pseudonym.should_not be_nil
      Message.last.should_not be_nil
      Message.last.notification.should eql(n)
      Message.last.to.should eql(@user.email)
    end
  end
  
  context "atom" do
    it "should use the course and user name to derive a title" do
      @enrollment.to_atom.title.should eql("#{@enrollment.user.name} in #{@enrollment.course.name}")
    end
    
    it "should link to the enrollment" do
      link_path = @enrollment.to_atom.links.first.to_s
      link_path.should eql("/courses/#{@enrollment.course.id}/enrollments/#{@enrollment.id}")
    end
  end
  
  context "permissions" do
    it "should be able to read grades if the course grants management rights to the enrollment" do
      @new_user = user_model
      @enrollment.grants_rights?(@new_user, nil, :read_grades)[:read_grades].should be_false
      @course.admins << @new_user
      @course.save!
      @enrollment.grants_rights?(@user, nil, :read_grades).should be_true
    end
    
    it "should allow the user itself to read its own grades" do
      @enrollment.grants_rights?(@user, nil, :read_grades).should be_true
    end
  end
  
end
