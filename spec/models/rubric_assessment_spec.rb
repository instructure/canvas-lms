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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe RubricAssessment do
  before :once do
    assignment_model
    @teacher = user_factory(active_all: true)
    @course.enroll_teacher(@teacher).accept
    @student = user_factory(active_all: true)
    @course.enroll_student(@student).accept
    @observer = user_factory(active_all: true)
    @course.enroll_user(@observer, 'ObserverEnrollment', {:associated_user_id => @student.id})
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
  end

  it "should htmlify the rating comments" do
    comment = "Hi, please see www.example.com.\n\nThanks."
    assessment = @association.assess({
      :user => @student,
      :assessor => @teacher,
      :artifact => @assignment.find_or_create_submission(@student),
      :assessment => {
        :assessment_type => 'grading',
        :criterion_crit1 => {
          :points => 5,
          :comments => comment,
        }
      }
    })
    expect(assessment.data.first[:comments]).to eq comment
    t = Class.new
    t.extend HtmlTextHelper
    expected = t.format_message(comment).first
    expect(assessment.data.first[:comments_html]).to eq expected
  end

  context "grading" do
    it "should update scores if used for grading" do
      assessment = @association.assess({
        :user => @student,
        :assessor => @teacher,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 5
          }
        }
      })
      expect(assessment).not_to be_nil
      expect(assessment.user).to eql(@student)
      expect(assessment.assessor).to eql(@teacher)
      expect(assessment.artifact).not_to be_nil
      expect(assessment.artifact).to be_is_a(Submission)
      expect(assessment.artifact.user).to eql(@student)
      expect(assessment.artifact.grader).to eql(@teacher)
      expect(assessment.artifact.score).to eql(5.0)
      expect(assessment.data.first[:comments_html]).to be_nil
    end

    it "should allow observers the ability to view rubric assessments with course association" do
      submission = @assignment.find_or_create_submission(@student)
      assessment = @association.assess(
          {
              :user => @student,
              :assessor => @teacher,
              :artifact => submission,
              :assessment => {
                  :assessment_type => 'grading',
                  :criterion_crit1 => {
                      :points => 5
                  }
              }
          })
      visible_rubric_assessments = submission.visible_rubric_assessments_for(@observer)
      expect(visible_rubric_assessments.length).to eql(1)
    end

    it "should allow observers the ability to view rubric assessments with account association" do
      submission = @assignment.find_or_create_submission(@student)
      account_association = @rubric.associate_with(@assignment, @account, :purpose => 'grading', :use_for_grading => true)
      assessment = account_association.assess(
          {
              :user => @student,
              :assessor => @teacher,
              :artifact => submission,
              :assessment => {
                  :assessment_type => 'grading',
                  :criterion_crit1 => {
                      :points => 5
                  }
              }
          })
      visible_rubric_assessments = submission.visible_rubric_assessments_for(@observer)
      expect(visible_rubric_assessments.length).to eql(1)
    end

    it "should update scores anonymously if graded anonymously" do
      assessment = @association.assess({
          :graded_anonymously => true,
          :user => @student,
          :assessor => @teacher,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            :criterion_crit1 => { :points => 5 }
          }
        })
      expect(assessment.artifact.graded_anonymously).to be_truthy
    end

    it "should not mutate null/empty string score text to 0" do
      assessment = @association.assess({
        :user => @student,
        :assessor => @teacher,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => ""
          }
        }
      })
      expect(assessment.score).to be_nil
      expect(assessment.artifact.score).to eql(nil)
    end

    it "should allow points to exceed max points possible for criterion" do
      assessment = @association.assess({
        :user => @student,
        :assessor => @teacher,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => "11"
          }
        }
      })
      expect(assessment.score).to eql(11.0)
      expect(assessment.artifact.score).to eql(11.0)
    end

    context "outcome criterion" do
      before :once do
        assignment_model
        outcome_with_rubric
        @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
      end

      it 'should use default ratings for scoring' do
        @outcome.update!(data: nil)
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        assessment = @association.assess({
          :user => @student,
          :assessor => @teacher,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            criterion_id => {
              :points => '3'
            }
          }
        })
        expect(assessment.score).to be 3.0
        expect(assessment.artifact.score).to be 3.0
      end

      it "should not allow points to exceed max points possible" do
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        assessment = @association.assess({
          :user => @student,
          :assessor => @teacher,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            criterion_id => {
              :points => "5"
            }
          }
        })
        expect(assessment.score).to eql(3.0)
        expect(assessment.artifact.score).to eql(3.0)
      end

      it "should allow points to exceed max points possible " +
       "if Allow Outcome Extra Credit feature is enabled" do
        @course.enable_feature!(:outcome_extra_credit)
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        assessment = @association.assess({
          :user => @student,
          :assessor => @teacher,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            criterion_id => {
              :points => "5"
            }
          }
        })
        expect(assessment.score).to be 5.0
        expect(assessment.artifact.score).to be 5.0
      end

      it "propagates hide_points value" do
        @association.update!(hide_points: true)
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        assessment = @association.assess({
          :user => @student,
          :assessor => @teacher,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            criterion_id => {
              :points => "3"
            }
          }
        })
        expect(assessment.hide_points).to be true
        expect(LearningOutcomeResult.last.hide_points).to be true
      end

      it "propagates hide_outcome_results value" do
        @association.update!(hide_outcome_results: true)
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        @association.assess({
          :user => @student,
          :assessor => @teacher,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            criterion_id => {
              :points => "3"
            }
          }
        })
        expect(LearningOutcomeResult.last.hidden).to be true
      end

      it "does not update outcomes on a peer assessment" do
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        expect do
          @association.assess({
            :user => @student,
            :assessor => @student,
            :artifact => @assignment.find_or_create_submission(@student),
            :assessment => {
              :assessment_type => 'peer_review',
              criterion_id => {
                :points => "3"
              }
            }
          })
        end.to_not change { LearningOutcomeResult.count }
      end

      it "does not update outcomes on a provisional grade" do
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        expect do
          submission = @assignment.find_or_create_submission(@student)
          provisional_grade = submission.find_or_create_provisional_grade!(@teacher, grade: 3)
          @association.assess({
            :user => @student,
            :assessor => @student,
            :artifact => provisional_grade,
            :assessment => {
              :assessment_type => 'grading',
              criterion_id => {
                :points => "3"
              }
            }
          })
        end.to_not change { LearningOutcomeResult.count }
      end
    end

    it "should not update scores if not used for grading" do
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => false)
      assessment = @association.assess({
        :user => @student,
        :assessor => @teacher,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 5
          }
        }
      })
      expect(assessment).not_to be_nil
      expect(assessment.user).to eql(@student)
      expect(assessment.assessor).to eql(@teacher)
      expect(assessment.artifact).not_to be_nil
      expect(assessment.artifact).to be_is_a(Submission)
      expect(assessment.artifact.user).to eql(@student)
      expect(assessment.artifact.grader).to eql(nil)
      expect(assessment.artifact.score).to eql(nil)
    end

    it "should not update scores if not a valid grader" do
      @student2 = user_factory(active_all: true)
      @course.enroll_student(@student2).accept
      assessment = @association.assess({
        :user => @student,
        :assessor => @student2,
        :artifact => @assignment.find_or_create_submission(@student),
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 5
          }
        }
      })
      expect(assessment).not_to be_nil
      expect(assessment.user).to eql(@student)
      expect(assessment.assessor).to eql(@student2)
      expect(assessment.artifact).not_to be_nil
      expect(assessment.artifact).to be_is_a(Submission)
      expect(assessment.artifact.user).to eql(@student)
      expect(assessment.artifact.grader).to eql(nil)
      expect(assessment.artifact.score).to eql(nil)
    end

    describe "when saving comments is requested" do
      it "saves comments normally" do
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        @association.assess({
          :user => @student,
          :assessor => @student,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            criterion_id => {
              :points => "3",
              :comments => "Some comment",
              :save_comment => '1'
            }
          }
        })
        expect(@association.summary_data[:saved_comments]["crit1"]).to eq(["Some comment"])
      end

      it "does not save comments for peer assessments" do
        criterion_id = "criterion_#{@rubric.data[0][:id]}".to_sym
        @association.assess({
          :user => @student,
          :assessor => @student,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'peer_review',
            criterion_id => {
              :points => "3",
              :comments => "Some obscene comment",
              :save_comment => '1'
            }
          }
        })
        expect(@association.summary_data).to be_nil
      end
    end

    describe "for assignment requiring anonymous peer reviews" do
      before(:once) do
        @assignment.update_attribute(:anonymous_peer_reviews, true)
        @reviewed = @student
        @reviewer = student_in_course(:active_all => true).user
        @assignment.assign_peer_review(@reviewer, @reviewed)
        @assessment = @association.assess({
          :user => @reviewed,
          :assessor => @reviewer,
          :artifact => @assignment.find_or_create_submission(@reviewed),
          :assessment => {
            :assessment_type => 'peer_review',
            :criterion_crit1 => {
              :points => 5,
              :comments => "Hey, it's a comment."
            }
          }
        })
        @teacher_assessment = @association.assess({
          :user => @reviewed,
          :assessor => @teacher,
          :artifact => @assignment.find_or_create_submission(@student),
          :assessment => {
            :assessment_type => 'grading',
            :criterion_crit1 => {
              :points => 3,
              :comments => "Hey, it's a teacher comment."
            }
          }
        })
      end

      it "should prevent reviewed from seeing reviewer's name" do
        expect(@assessment.grants_right?(@reviewed, :read_assessor)).to be_falsey
      end

      it "should allow reviewer to see own name" do
        expect(@assessment.grants_right?(@reviewer, :read_assessor)).to be_truthy
      end

      it "should allow teacher to see reviewer's name" do
        expect(@assessment.grants_right?(@teacher, :read_assessor)).to be_truthy
      end

      it "should allow reviewed to see reviewer's name if reviewer is teacher" do
        expect(@teacher_assessment.grants_right?(@reviewed, :read_assessor)).to be_truthy
      end

    end


    describe "#considered_anonymous?" do
      let_once(:assessment) {
        RubricAssessment.create!({
          artifact: @assignment.find_or_create_submission(@student),
          assessment_type: 'peer_review',
          assessor: student_in_course(active_all: true).user,
          rubric: @rubric,
          user: @student
        })
      }

      it "should not blow up without a rubric_association" do
        expect{assessment.considered_anonymous?}.not_to raise_error
      end
    end
  end

  describe "read permissions" do
    before(:once) do
      @account = @course.root_account
      @assessment = @association.assess({
                                          :user => @student,
                                          :assessor => @teacher,
                                          :artifact => @assignment.find_or_create_submission(@student),
                                          :assessment => {
                                            :assessment_type => 'grading',
                                            :criterion_crit1 => {
                                              :points => 5,
                                              :comments => "comments",
                                            }
                                          }
                                        })
    end

    it "grants :read to the user" do
      expect(@assessment.grants_right?(@student, :read)).to eq true
    end

    it "grants :read to the assessor" do
      expect(@assessment.grants_right?(@teacher, :read)).to eq true
    end

    it "does not grant :read to an account user without :manage_courses or :view_all_grades" do
      user_factory
      role = custom_account_role('custom', :account => @account)
      @account.account_users.create!(user: @user, role: role)
      expect(@assessment.grants_right?(@user, :read)).to eq false
    end

    it "grants :read to an account user with :view_all_grades but not :manage_courses" do
      user_factory
      role = custom_account_role('custom', :account => @account)
      RoleOverride.create!(:context => @account, :permission => 'view_all_grades', :role => role, :enabled => true)
      RoleOverride.create!(:context => @account, :permission => 'manage_courses', :role => role, :enabled => false)
      @account.account_users.create!(user: @user, role: role)
      expect(@assessment.grants_right?(@user, :read)).to eq true
    end
  end
end
