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

describe RubricAssociation do
  context "when course has multiple students enrolled" do
    before :each do
      # Create a course, 2 students and enroll them
      @test_course = course(:active_course => true)
      @teacher = @test_course.teachers.first
      @student_1 = user(:active_user => true)
      @student_2 = user(:active_user => true)
      @test_course.enroll_student(@student_1)
      @test_course.enroll_student(@student_2)
    end

    context "when a peer-review assignment has been completed AFTER rubric created" do
      before :each do
        # Create the assignment
        @assignment = course.assignments.create!(:title => 'Test Assignment', :peer_reviews => true)
        @assignment.workflow_state = 'published'
        @assignment.submission_types = 'online_text_entry'
        @assignment.context = @test_course

        # Create the rubric
        @rubric = @test_course.rubrics.build
        @rubric.user = @teacher
        @rubric.save!
        rubric_association = HashWithIndifferentAccess.new({"hide_score_total"=>"0", "purpose"=>"grading",
                                                            "skip_updating_points_possible"=>false, "update_if_existing"=>true,
                                                            "use_for_grading"=>"1", "association"=>@assignment}) #, "id"=>3})

        @rubric_assoc = RubricAssociation.generate_with_invitees(@teacher, @rubric, @test_course, rubric_association)

        # students complete it
        @assignment.submit_homework(@student_1, :submission_type => 'online_text_entry', :body => 'Finished first')
        @assignment.submit_homework(@student_2, :submission_type => 'online_text_entry', :body => 'Finished second')
      end

      context "and students are assigned to peer review" do
        before :each do
          # Assign students to peer review
          @assignment.assign_peer_review(@student_1, @student_2)
          @assignment.assign_peer_review(@student_2, @student_1)
        end

        it "should have 2 assessment_requests" do
          @rubric_assoc.assessment_requests.count.should == 2
        end
      end
    end

    context "when a peer-review assignment has been completed BEFORE rubric created" do
      before :each do
        # Create the assignment
        @assignment = course.assignments.create!(:title => 'Test Assignment', :peer_reviews => true)
        @assignment.workflow_state = 'published'
        @assignment.submission_types = 'online_text_entry'
        @assignment.context = @test_course

        # students complete it
        @assignment.submit_homework(@student_1, :submission_type => 'online_text_entry', :body => 'Finished first')
        @assignment.submit_homework(@student_2, :submission_type => 'online_text_entry', :body => 'Finished second')
      end

      context "and students are assigned to peer review" do
        before :each do
          # Assign students to peer review
          @assignment.assign_peer_review(@student_1, @student_2)
          @assignment.assign_peer_review(@student_2, @student_1)
        end

        context "and a rubric is created" do
          before :each do
            @rubric = @test_course.rubrics.build
            @rubric.user = @teacher
            @rubric.save!
            rubric_association = HashWithIndifferentAccess.new({"hide_score_total"=>"0", "purpose"=>"grading",
                                                                "skip_updating_points_possible"=>false, "update_if_existing"=>true,
                                                                "use_for_grading"=>"1", "association"=>@assignment}) #, "id"=>3})

            @rubric_assoc = RubricAssociation.generate_with_invitees(@teacher, @rubric, @test_course, rubric_association)
          end

          it "should have 2 assessment_requests" do
            @rubric_assoc.assessment_requests.count.should == 2
          end
        end
      end
    end
  end

  context "when a rubric is associated with an account" do
    it "should not try to link to assessments" do
      site_admin_user
      user_session(@user)
      @account = @user.account
      @rubric = @account.rubrics.build
      rubric_params = HashWithIndifferentAccess.new({"title"=>"Some Rubric", "criteria"=>{"0"=>{"learning_outcome_id"=>"", "ratings"=>{"0"=>{"points"=>"5", "id"=>"blank", "description"=>"Full Marks"}, "1"=>{"points"=>"0", "id"=>"blank_2", "description"=>"No Marks"}}, "points"=>"5", "long_description"=>"", "id"=>"", "description"=>"Description of criterion"}}, "points_possible"=>"5", "free_form_criterion_comments"=>"0"})
      rubric_association_params = HashWithIndifferentAccess.new({:association=>@account, :hide_score_total=>"0", :use_for_grading=>"0", :purpose=>"bookmark"})
      #8864: the below raised a MethodNotFound error by trying to call @account.submissions
      lambda { @rubric.update_with_association(@user, rubric_params, @account, rubric_association_params, nil) }.should_not raise_error
    end
  end
end
