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

  def rubric_association_params_for_assignment(assign)
    HashWithIndifferentAccess.new({
      hide_score_total: "0",
      purpose: "grading",
      skip_updating_points_possible: false,
      update_if_existing: true,
      use_for_grading: "1",
      association_object: assign
    })
  end

  context "assignment rubrics" do
    before :once do
      # Create a course, 2 students and enroll them
      course_with_teacher(:active_course => true, :active_user => true)
      @student_1 = student_in_course(:active_user => true).user
      @student_2 = student_in_course(:active_user => true).user

      # Create the assignment
      @assignment = @course.assignments.create!(
        :title => 'Test Assignment',
        :peer_reviews => true,
        :submission_types => 'online_text_entry'
      )
    end

    context "when a peer-review assignment has been completed AFTER rubric created" do
      before :each do
        # Create the rubric
        @rubric = @course.rubrics.create! { |r| r.user = @teacher }

        ra_params = rubric_association_params_for_assignment(@assignment)
        @rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)

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
          expect(@rubric_assoc.assessment_requests.count).to eq 2
        end
      end
    end

    context "when a peer-review assignment has been completed BEFORE rubric created" do
      before :each do
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
            @rubric = @course.rubrics.create! { |r| r.user = @teacher }
            ra_params = rubric_association_params_for_assignment(@assignment)
            @rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)
          end

          it "should have 2 assessment_requests" do
            expect(@rubric_assoc.assessment_requests.count).to eq 2
          end
        end
      end
    end

    context "#update_alignments" do
      it "should do nothing if it is not associated to an assignment" do
        rubric = @course.rubrics.create!
        ra = RubricAssociation.create!(
          :rubric => rubric,
          :association_object => @course,
          :context => @course,
          :purpose => 'bookmark'
        )
        LearningOutcome.expects(:update_alignments).never
        ra.update_alignments
      end

      it "should align the outcome to the assignment when created and remove when destroyed" do
        assignment = @course.assignments.create!(
          :title => 'Test Assignment',
          :peer_reviews => true,
          :submission_types => 'online_text_entry'
        )
        outcome_with_rubric
        ra = @rubric.rubric_associations.create!(
          :association_object => assignment,
          :context => @course,
          :purpose => 'grading'
        )
        expect(assignment.reload.learning_outcome_alignments.count).to eq 1

        ra.destroy
        expect(assignment.reload.learning_outcome_alignments.count).to eq 0
      end
    end

    it "should not delete assessments when an association is destroyed" do
      assignment = @course.assignments.create!(
        :title => 'Test Assignment',
        :peer_reviews => true,
        :submission_types => 'online_text_entry'
      )
      outcome_with_rubric
      ra = @rubric.rubric_associations.create!(
        :association_object => assignment,
        :context => @course,
        :purpose => 'grading'
      )
      assess = ra.assess({
        :user => @student_1,
        :assessor => @teacher,
        :artifact => assignment.find_or_create_submission(@student_1),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 5
          }
        }
      })

      expect(assess).not_to be_nil
      ra.destroy
      expect(assess.reload).not_to be_nil
    end

    it "should let account admins without manage_courses do things" do
      @rubric = @course.rubrics.create! { |r| r.user = @teacher }
      ra_params = rubric_association_params_for_assignment(@assignment)
      ra = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)

      admin = account_admin_user_with_role_changes(:active_all => true, :role_changes => {:manage_courses => false})

      [:manage, :delete, :assess].each do |permission|
        expect(ra.grants_right?(admin, permission)).to be_truthy
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
      rubric_association_params = HashWithIndifferentAccess.new({:association_object=>@account, :hide_score_total=>"0", :use_for_grading=>"0", :purpose=>"bookmark"})
      #8864: the below raised a MethodNotFound error by trying to call @account.submissions
      expect { @rubric.update_with_association(@user, rubric_params, @account, rubric_association_params) }.not_to raise_error
    end
  end

  context "when a rubric is associated with a course" do
    it "should not try to link to assessments" do
      course_with_teacher(:active_all => true)
      @rubric = @course.rubrics.build
      rubric_params = HashWithIndifferentAccess.new({"title"=>"Some Rubric", "criteria"=>{"0"=>{"learning_outcome_id"=>"", "ratings"=>{"0"=>{"points"=>"5", "id"=>"blank", "description"=>"Full Marks"}, "1"=>{"points"=>"0", "id"=>"blank_2", "description"=>"No Marks"}}, "points"=>"5", "long_description"=>"", "id"=>"", "description"=>"Description of criterion"}}, "points_possible"=>"5", "free_form_criterion_comments"=>"0"})
      rubric_association_params = HashWithIndifferentAccess.new({:association_object=>@course, :hide_score_total=>"0", :use_for_grading=>"0", :purpose=>"bookmark"})
      @course.any_instantiation.expects(:submissions).never
      @rubric.update_with_association(@user, rubric_params, @course, rubric_association_params)
    end
  end
end
