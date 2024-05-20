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

describe RubricAssessment do
  before :once do
    assignment_model
    @teacher = user_factory(active_all: true)
    @course.enroll_teacher(@teacher).accept
    @student = user_factory(active_all: true)
    @course.enroll_student(@student).accept
    @observer = user_factory(active_all: true)
    @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
  end

  describe "related_group_submissions_and_assessments" do
    def assess_using_rubric(rubric, rubric_params, rubric_association_params)
      association = rubric.update_with_association(
        @user,
        rubric_params,
        @course,
        rubric_association_params
      )

      assessment = association.assess({
                                        user: @student,
                                        assessor: @teacher,
                                        artifact: @assignment.find_or_create_submission(@student),
                                        assessment: {
                                          assessment_type: "grading",
                                          criterion_crit1: {
                                            points: 5,
                                            comments: "comments",
                                          }
                                        }
                                      })
      [association, assessment.related_group_submissions_and_assessments.first[:rubric_assessments]]
    end

    before(:once) do
      @assessment = @association.assess({
                                          user: @student,
                                          assessor: @teacher,
                                          artifact: @assignment.find_or_create_submission(@student),
                                          assessment: {
                                            assessment_type: "grading",
                                            criterion_crit1: {
                                              points: 5,
                                              comments: "comments",
                                            }
                                          }
                                        })
    end

    it "uses the current rubric association" do
      # assess using another rubric
      r_association, r_assessments = assess_using_rubric(
        @course.rubrics.build,
        {
          title: "Some Rubric1",
          criteria: {
            "0": {
              learning_outcome_id: "",
              ratings: {
                "0": {
                  points: "5",
                  id: "blank",
                  description: "Full Marks"
                },
                "1": {
                  points: "0",
                  id: "blank_2",
                  description: "No Marks"
                }
              },
              points: "5",
              long_description: "",
              id: "",
              description: "Description of criterion"
            }
          },
          points_possible: "5",
          free_form_criterion_comments: "0"
        }.with_indifferent_access,
        {
          association_object: @assignment,
          hide_score_total: "0",
          use_for_grading: "1",
          purpose: "grading",
          update_if_existing: "1"
        }.with_indifferent_access
      )

      expect(r_assessments.count).to eq 1
      expect(r_assessments.first["rubric_assessment"]["rubric_association_id"]).to eq(r_association.id)
    end
  end

  describe "active_rubric_association?" do
    before(:once) do
      @assessment = @association.assess({
                                          user: @student,
                                          assessor: @teacher,
                                          artifact: @assignment.find_or_create_submission(@student),
                                          assessment: {
                                            assessment_type: "grading",
                                            criterion_crit1: {
                                              points: 5,
                                              comments: "comments",
                                            }
                                          }
                                        })
    end

    it "returns false if there is no rubric association" do
      @assessment.update!(rubric_association: nil)
      expect(@assessment).not_to be_active_rubric_association
    end

    it "returns false if the rubric association is soft-deleted" do
      @association.destroy
      expect(@assessment).not_to be_active_rubric_association
    end

    it "returns true if the rubric association exists and is active" do
      expect(@assessment).to be_active_rubric_association
    end

    context "triggering a rubric_assessed live event" do
      it "does not trigger if there is not rubric association" do
        expect(Canvas::LiveEvents).not_to receive(:rubric_assessed)
        @assessment.update!(rubric_association: nil)
      end

      it "does not trigger if the rubric association is soft-deleted" do
        expect(Canvas::LiveEvents).not_to receive(:rubric_assessed)
        @association.destroy
      end

      context "if the rubric association exists and is active" do
        before do
          @assignment = assignment_model
          @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
          @course.enroll_student(@student, enrollment_state: :active)
          @artifact = @assignment.find_or_create_submission(@student)
        end

        def assess_assignment(criterion_points)
          @association.assess({
                                user: @student,
                                assessor: @teacher,
                                artifact: @artifact,
                                assessment: {
                                  assessment_type: "grading",
                                  criterion_crit1: {
                                    points: criterion_points,
                                    comments: "comments",
                                  }
                                }
                              })
        end

        it "does trigger an event when saving the initial assessment" do
          expect(Canvas::LiveEvents).to receive(:rubric_assessed)
          @assessment = assess_assignment("3")
        end

        it "does trigger an event when reassessing an assessment" do
          expect(Canvas::LiveEvents).to receive(:rubric_assessed).twice
          first_assessment = assess_assignment("3")
          expect(first_assessment.versions.count).to eq 1

          second_assessment = assess_assignment("5")
          expect(second_assessment.versions.count).to eq 2
        end
      end
    end
  end

  it { is_expected.to have_many(:learning_outcome_results).dependent(:destroy) }

  it "htmlifies the rating comments" do
    comment = "Hi, please see www.example.com.\n\nThanks."
    submission = @assignment.find_or_create_submission(@student)
    assessment = @association.assess({
                                       user: @student,
                                       assessor: @teacher,
                                       artifact: submission,
                                       assessment: {
                                         assessment_type: "grading",
                                         criterion_crit1: {
                                           points: 5,
                                           comments: comment,
                                         }
                                       }
                                     })
    expect(assessment.data.first[:comments]).to eq comment
    t = Class.new
    t.extend HtmlTextHelper
    expected = t.format_message(comment).first
    expect(assessment.data.first[:comments_html]).to eq expected
    participations = [submission].map(&:content_participations).flatten
    unread_items = ContentParticipation.items_by_submission(participations, "unread")
    expect(unread_items.length).to eq 1
  end

  context "grading" do
    it "updates scores if used for grading" do
      assessment = @association.assess({
                                         user: @student,
                                         assessor: @teacher,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: {
                                             points: 5
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
      expect(assessment.artifact.score).to be(5.0)
      expect(assessment.data.first[:comments_html]).to be_nil
    end

    it "allows observers the ability to view rubric assessments with course association" do
      submission = @assignment.find_or_create_submission(@student)
      @association.assess(
        {
          user: @student,
          assessor: @teacher,
          artifact: submission,
          assessment: {
            assessment_type: "grading",
            criterion_crit1: {
              points: 5
            }
          }
        }
      )
      visible_rubric_assessments = submission.visible_rubric_assessments_for(@observer)
      expect(visible_rubric_assessments.length).to be(1)
    end

    it "allows observers the ability to view rubric assessments with account association" do
      submission = @assignment.find_or_create_submission(@student)
      account_association = @rubric.associate_with(@assignment, @account, purpose: "grading", use_for_grading: true)
      account_association.assess(
        {
          user: @student,
          assessor: @teacher,
          artifact: submission,
          assessment: {
            assessment_type: "grading",
            criterion_crit1: {
              points: 5
            }
          }
        }
      )
      visible_rubric_assessments = submission.visible_rubric_assessments_for(@observer)
      expect(visible_rubric_assessments.length).to be(1)
    end

    it "updates scores anonymously if graded anonymously" do
      assessment = @association.assess({
                                         graded_anonymously: true,
                                         user: @student,
                                         assessor: @teacher,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: { points: 5 }
                                         }
                                       })
      expect(assessment.artifact.graded_anonymously).to be_truthy
    end

    it "does not mutate null/empty string score text to 0" do
      assessment = @association.assess({
                                         user: @student,
                                         assessor: @teacher,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: {
                                             points: ""
                                           }
                                         }
                                       })
      expect(assessment.score).to be_nil
      expect(assessment.artifact.score).to be_nil
    end

    it "allows points to exceed max points possible for criterion" do
      assessment = @association.assess({
                                         user: @student,
                                         assessor: @teacher,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: {
                                             points: "11"
                                           }
                                         }
                                       })
      expect(assessment.score).to be 11.0
      expect(assessment.artifact.score).to be 11.0
    end

    it "rounds the final score to avoid floating-point arithmetic issues" do
      def criteria(id)
        {
          description: "Some criterion",
          points: 10,
          id:,
          ratings: [
            { description: "Good", points: 10, id: "rat1", criterion_id: id },
            { description: "Medium", points: 5, id: "rat2", criterion_id: id },
            { description: "Bad", points: 0, id: "rat3", criterion_id: id }
          ]
        }
      end

      rubric = rubric_model(data: %w[crit1 crit2 crit3 crit4].map { |n| criteria(n) })
      association = rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)

      # in an ideal world these would be stored using the DECIMAL type, but we
      # don't live in that world
      assessment = association.assess({
                                        user: @student,
                                        assessor: @teacher,
                                        artifact: @assignment.find_or_create_submission(@student),
                                        assessment: {
                                          assessment_type: "grading",
                                          criterion_crit1: {
                                            points: 1.2,
                                            rating_id: "rat2"
                                          },
                                          criterion_crit2: {
                                            points: 1.2,
                                            rating_id: "rat2"
                                          },
                                          criterion_crit3: {
                                            points: 1.2,
                                            rating_id: "rat2"
                                          },
                                          criterion_crit4: {
                                            points: 0.4,
                                            rating_id: "rat2"
                                          }
                                        }
                                      })

      expect(assessment.score).to eq(4.0)
    end

    context "moderated grading" do
      before(:once) do
        @assignment.update!(moderated_grading: true, grader_count: 1)
        submission = @assignment.find_or_create_submission(@student)
        @provisional_grade = submission.find_or_create_provisional_grade!(@teacher, score: 3, grade: "3")
      end

      let(:assessment_opts) do
        {
          user: @student,
          assessor: @teacher,
          artifact: @provisional_grade,
          assessment: {
            assessment_type: "grading",
            criterion_crit1: { points: 5 }
          }
        }
      end

      it "updates provisional grades if used for grading" do
        expect { @association.assess(assessment_opts) }.to change {
          @provisional_grade.reload.grade
        }.from("3").to("5")
      end

      it "updates provisional scores if used for grading" do
        expect { @association.assess(assessment_opts) }.to change {
          @provisional_grade.reload.score
        }.from(3).to(5)
      end
    end

    context "aligned_outcome_ids" do
      it "returns ids if rubric is aligned with outcomes" do
        assignment_model
        outcome_with_rubric
        @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        @course.enroll_student(@student, enrollment_state: :active)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @teacher,
                                           artifact: @assignment.find_or_create_submission(@student),
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "3"
                                             }
                                           }
                                         })
        expect(assessment.aligned_outcome_ids).to eq [@rubric.data[0][:learning_outcome_id]]
      end

      it "returns emptry array if rubric is aligned with outcomes" do
        assignment_model
        rubric_model
        @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        @course.enroll_student(@student, enrollment_state: :active)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @teacher,
                                           artifact: @assignment.find_or_create_submission(@student),
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "3"
                                             }
                                           }
                                         })
        expect(assessment.aligned_outcome_ids).to eq []
      end
    end

    context "outcome criterion" do
      before :once do
        assignment_model
        outcome_with_rubric
        @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
        @course.enroll_student(@student, enrollment_state: :active)
      end

      it "assessing a rubric with outcome criterion should increment datadog counter" do
        allow(InstStatsd::Statsd).to receive(:increment)
        @outcome.update!(data: nil)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        @association.assess({
                              user: @student,
                              assessor: @teacher,
                              artifact: @assignment.find_or_create_submission(@student),
                              assessment: {
                                :assessment_type => "grading",
                                criterion_id => {
                                  points: "3"
                                }
                              }
                            })
        expect(InstStatsd::Statsd).to have_received(:increment).with("feature_flag_check", any_args).at_least(:once)
        expect(InstStatsd::Statsd).to have_received(:increment).with("learning_outcome_result.create")
      end

      it "uses default ratings for scoring" do
        @outcome.update!(data: nil)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @teacher,
                                           artifact: @assignment.find_or_create_submission(@student),
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "3"
                                             }
                                           }
                                         })
        expect(assessment.score).to be 3.0
        expect(assessment.artifact.score).to be 3.0
      end

      it "does not allow points to exceed max points possible" do
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @teacher,
                                           artifact: @assignment.find_or_create_submission(@student),
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "5"
                                             }
                                           }
                                         })
        expect(assessment.score).to be 3.0
        expect(assessment.artifact.score).to be 3.0
      end

      it "allows points to exceed max points possible if Allow Outcome Extra Credit feature is enabled" do
        @course.enable_feature!(:outcome_extra_credit)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @teacher,
                                           artifact: @assignment.find_or_create_submission(@student),
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "5"
                                             }
                                           }
                                         })
        expect(assessment.score).to be 5.0
        expect(assessment.artifact.score).to be 5.0
      end

      it "propagates hide_points value" do
        @association.update!(hide_points: true)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        assessment = @association.assess({
                                           user: @student,
                                           assessor: @teacher,
                                           artifact: @assignment.find_or_create_submission(@student),
                                           assessment: {
                                             :assessment_type => "grading",
                                             criterion_id => {
                                               points: "3"
                                             }
                                           }
                                         })
        expect(assessment.hide_points).to be true
        expect(LearningOutcomeResult.last.hide_points).to be true
      end

      it "truncates the learning outcome result title to 250 characters" do
        @association.update!(title: "a" * 255)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        @association.assess({
                              user: @student,
                              assessor: @teacher,
                              artifact: @assignment.find_or_create_submission(@student),
                              assessment: {
                                :assessment_type => "grading",
                                criterion_id => {
                                  points: "5"
                                }
                              }
                            })
        expect(LearningOutcomeResult.last.title.length).to eq 250
      end

      it "propagates hide_outcome_results value" do
        @association.update!(hide_outcome_results: true)
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        @association.assess({
                              user: @student,
                              assessor: @teacher,
                              artifact: @assignment.find_or_create_submission(@student),
                              assessment: {
                                :assessment_type => "grading",
                                criterion_id => {
                                  points: "3"
                                }
                              }
                            })
        expect(LearningOutcomeResult.last.hidden).to be true
      end

      it "restores a deleted result" do
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        @association.assess({
                              user: @student,
                              assessor: @teacher,
                              artifact: @assignment.find_or_create_submission(@student),
                              assessment: {
                                :assessment_type => "grading",
                                criterion_id => {
                                  points: "3"
                                }
                              }
                            })
        result = LearningOutcomeResult.last
        result.destroy

        @association.assess({
                              user: @student,
                              assessor: @teacher,
                              artifact: @assignment.find_or_create_submission(@student),
                              assessment: {
                                :assessment_type => "grading",
                                criterion_id => {
                                  points: "3"
                                }
                              }
                            })
        expect(result.reload).to be_active
      end

      it "does not update outcomes on a peer assessment" do
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        expect do
          @association.assess({
                                user: @student,
                                assessor: @student,
                                artifact: @assignment.find_or_create_submission(@student),
                                assessment: {
                                  :assessment_type => "peer_review",
                                  criterion_id => {
                                    points: "3"
                                  }
                                }
                              })
        end.to_not change { LearningOutcomeResult.count }
      end

      it "does not update outcomes on a provisional grade" do
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        expect do
          submission = @assignment.find_or_create_submission(@student)
          provisional_grade = submission.find_or_create_provisional_grade!(@teacher, grade: 3)
          @association.assess({
                                user: @student,
                                assessor: @student,
                                artifact: provisional_grade,
                                assessment: {
                                  :assessment_type => "grading",
                                  criterion_id => {
                                    points: "3"
                                  }
                                }
                              })
        end.to_not change { LearningOutcomeResult.count }
      end
    end

    it "does not update scores if not used for grading" do
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: false)
      assessment = @association.assess({
                                         user: @student,
                                         assessor: @teacher,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: {
                                             points: 5
                                           }
                                         }
                                       })
      expect(assessment).not_to be_nil
      expect(assessment.user).to eql(@student)
      expect(assessment.assessor).to eql(@teacher)
      expect(assessment.artifact).not_to be_nil
      expect(assessment.artifact).to be_is_a(Submission)
      expect(assessment.artifact.user).to eql(@student)
      expect(assessment.artifact.grader).to be_nil
      expect(assessment.artifact.score).to be_nil
    end

    it "does not update scores if not a valid grader" do
      @student2 = user_factory(active_all: true)
      @course.enroll_student(@student2).accept
      assessment = @association.assess({
                                         user: @student,
                                         assessor: @student2,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: {
                                             points: 5
                                           }
                                         }
                                       })
      expect(assessment).not_to be_nil
      expect(assessment.user).to eql(@student)
      expect(assessment.assessor).to eql(@student2)
      expect(assessment.artifact).not_to be_nil
      expect(assessment.artifact).to be_is_a(Submission)
      expect(assessment.artifact.user).to eql(@student)
      expect(assessment.artifact.grader).to be_nil
      expect(assessment.artifact.score).to be_nil
    end

    describe "when saving comments is requested" do
      it "saves comments normally" do
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        @association.assess({
                              user: @student,
                              assessor: @student,
                              artifact: @assignment.find_or_create_submission(@student),
                              assessment: {
                                :assessment_type => "grading",
                                criterion_id => {
                                  points: "3",
                                  comments: "Some comment",
                                  save_comment: "1"
                                }
                              }
                            })
        expect(@association.summary_data[:saved_comments]["crit1"]).to eq(["Some comment"])
      end

      it "does not save comments for peer assessments" do
        criterion_id = :"criterion_#{@rubric.data[0][:id]}"
        @association.assess({
                              user: @student,
                              assessor: @student,
                              artifact: @assignment.find_or_create_submission(@student),
                              assessment: {
                                :assessment_type => "peer_review",
                                criterion_id => {
                                  points: "3",
                                  comments: "Some obscene comment",
                                  save_comment: "1"
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
        @reviewer = student_in_course(active_all: true).user
        @assignment.assign_peer_review(@reviewer, @reviewed)
        @assessment = @association.assess({
                                            user: @reviewed,
                                            assessor: @reviewer,
                                            artifact: @assignment.find_or_create_submission(@reviewed),
                                            assessment: {
                                              assessment_type: "peer_review",
                                              criterion_crit1: {
                                                points: 5,
                                                comments: "Hey, it's a comment."
                                              }
                                            }
                                          })
        @teacher_assessment = @association.assess({
                                                    user: @reviewed,
                                                    assessor: @teacher,
                                                    artifact: @assignment.find_or_create_submission(@student),
                                                    assessment: {
                                                      assessment_type: "grading",
                                                      criterion_crit1: {
                                                        points: 3,
                                                        comments: "Hey, it's a teacher comment."
                                                      }
                                                    }
                                                  })
      end

      it "prevents reviewed from seeing reviewer's name" do
        expect(@assessment.grants_right?(@reviewed, :read_assessor)).to be_falsey
      end

      it "allows reviewer to see own name" do
        expect(@assessment.grants_right?(@reviewer, :read_assessor)).to be_truthy
      end

      it "allows teacher to see reviewer's name" do
        expect(@assessment.grants_right?(@teacher, :read_assessor)).to be_truthy
      end

      it "allows reviewed to see reviewer's name if reviewer is teacher" do
        expect(@teacher_assessment.grants_right?(@reviewed, :read_assessor)).to be_truthy
      end
    end

    describe "#considered_anonymous?" do
      let_once(:assessment) do
        RubricAssessment.create!({
                                   artifact: @assignment.find_or_create_submission(@student),
                                   assessment_type: "peer_review",
                                   assessor: student_in_course(active_all: true).user,
                                   rubric: @rubric,
                                   user: @student
                                 })
      end

      it "does not blow up without a rubric_association" do
        expect { assessment.considered_anonymous? }.not_to raise_error
      end
    end

    describe "#update_artifact" do
      describe "grade_posting_in_progress" do
        subject_once(:ra) do
          RubricAssessment.new(
            score: 2.0,
            assessment_type: :grading,
            rubric:,
            artifact: submission,
            assessor: @teacher
          )
        end

        let_once(:rubric) { rubric_model }
        let_once(:submission) { @assignment.submissions.find_by!(user: @student) }

        before do
          submission.score = 1
          ra.build_rubric_association(
            use_for_grading: true,
            association_object: @assignment
          )
        end

        it "is nil by default" do
          expect(@assignment).to receive(:grade_student).with(
            ra.submission.student,
            score: ra.score,
            grader: ra.assessor,
            graded_anonymously: nil,
            grade_posting_in_progress: nil
          )
          ra.save!
        end

        it "passes grade_posting_in_progress from submission" do
          submission.grade_posting_in_progress = true

          expect(@assignment).to receive(:grade_student).with(
            ra.submission.student,
            score: ra.score,
            grader: ra.assessor,
            graded_anonymously: nil,
            grade_posting_in_progress: submission.grade_posting_in_progress
          )
          ra.save!
        end
      end

      it "sets group on submission" do
        group_category = @course.group_categories.create!(name: "Test Group Set")
        group = @course.groups.create!(name: "Group A", group_category:)
        group.add_user @student
        group.save!

        assignment = @course.assignments.create!(
          assignment_valid_attributes.merge(
            group_category:,
            grade_group_students_individually: false
          )
        )
        submission = assignment.find_or_create_submission(@student)
        association = @rubric.associate_with(
          assignment, @course, purpose: "grading", use_for_grading: true
        )
        association.assess({
                             user: @student,
                             assessor: @teacher,
                             artifact: submission,
                             assessment: {
                               assessment_type: "grading",
                               criterion_crit1: {
                                 points: 5
                               }
                             }
                           })
        expect(submission.reload.group).to eq group
      end

      describe "submission posting" do
        let(:assessment_params) do
          {
            user: @student,
            assessor: @teacher,
            artifact: submission,
            assessment: {
              assessment_type: "grading",
              criterion_crit1: {
                points: 5
              }
            }
          }
        end

        let(:assignment) { @course.assignments.create!(assignment_valid_attributes) }
        let(:submission) { assignment.submission_for_student(@student) }
        let(:rubric_association) { @rubric.associate_with(assignment, @course, purpose: "grading", use_for_grading: true) }

        it "posts the submission if the assignment is automatically posted" do
          rubric_association.assess(assessment_params)
          expect(submission.reload).to be_posted
        end

        it "does not post the submission if the assignment is manually posted" do
          assignment.post_policy.update!(post_manually: true)
          rubric_association.assess(assessment_params)
          expect(submission.reload).not_to be_posted
        end

        it "posts submissions for all members of the group if the assignment is graded by group" do
          group_category = @course.group_categories.create!(name: "Test Group Set")
          group = @course.groups.create!(name: "Group A", group_category:)
          group.add_user(@student)

          other_student_in_group = @course.enroll_student(User.create!, enrollment_state: :active).user
          group.add_user(other_student_in_group)
          group.save!

          assignment.update!(group_category:, grade_group_students_individually: false)

          rubric_association.assess(assessment_params)
          expect(assignment.submission_for_student(other_student_in_group)).to be_posted
        end
      end
    end
  end

  describe "read permissions" do
    before(:once) do
      @account = @course.root_account
      @assessment = @association.assess({
                                          user: @student,
                                          assessor: @teacher,
                                          artifact: @assignment.find_or_create_submission(@student),
                                          assessment: {
                                            assessment_type: "grading",
                                            criterion_crit1: {
                                              points: 5,
                                              comments: "comments",
                                            }
                                          }
                                        })
    end

    it "grants :read to the user" do
      expect(@assessment.grants_right?(@student, :read)).to be true
    end

    it "grants :read to the assessor" do
      expect(@assessment.grants_right?(@teacher, :read)).to be true
    end

    it "does not grant :read to an account user without :manage_courses or :view_all_grades" do
      user_factory
      role = custom_account_role("custom", account: @account)
      @account.account_users.create!(user: @user, role:)
      expect(@assessment.grants_right?(@user, :read)).to be false
    end

    it "grants :read to an account user with :view_all_grades but not :manage_courses" do
      @account.disable_feature!(:granular_permissions_manage_courses)
      user_factory
      role = custom_account_role("custom", account: @account)
      RoleOverride.create!(
        context: @account,
        permission: "view_all_grades",
        role:,
        enabled: true
      )
      RoleOverride.create!(
        context: @account,
        permission: "manage_courses",
        role:,
        enabled: false
      )
      @account.account_users.create!(user: @user, role:)
      expect(@assessment.grants_right?(@user, :read)).to be true
    end

    it "grants :read to an account user with :view_all_grades but not :manage_courses_admin (granular permissions)" do
      @account.enable_feature!(:granular_permissions_manage_courses)
      user_factory
      role = custom_account_role("custom", account: @account)
      RoleOverride.create!(
        context: @account,
        permission: "view_all_grades",
        role:,
        enabled: true
      )
      RoleOverride.create!(
        context: @account,
        permission: "manage_courses_admin",
        role:,
        enabled: false
      )
      @account.account_users.create!(user: @user, role:)
      expect(@assessment.grants_right?(@user, :read)).to be true
    end
  end

  describe "create" do
    it "sets the root_account_id using rubric" do
      assessment = @association.assess({
                                         user: @student,
                                         assessor: @teacher,
                                         artifact: @assignment.find_or_create_submission(@student),
                                         assessment: {
                                           assessment_type: "grading",
                                           criterion_crit1: {
                                             points: 5,
                                             comments: "abcdefg",
                                           }
                                         }
                                       })

      expect(assessment.root_account_id).to_not be_nil
      expect(assessment.root_account_id).to eq @rubric.root_account_id
    end
  end

  describe "mark_unread_assessments" do
    before do
      @submission = @assignment.find_or_create_submission(@student)
    end

    it "is unread after assessing with comments or points" do
      @assessment = @association.assess({
                                          user: @student,
                                          assessor: @teacher,
                                          artifact: @submission,
                                          assessment: {
                                            assessment_type: "grading",
                                            criterion_crit1: {
                                              points: 5,
                                              comments: "comments",
                                            }
                                          }
                                        })

      expect(@submission.unread_item?(@student, "rubric")).to be_truthy
    end

    it "does not save participation if assessment is missing comments and points" do
      expect do
        @assessment = @association.assess({
                                            user: @student,
                                            assessor: @teacher,
                                            artifact: @submission,
                                            assessment: {
                                              assessment_type: "grading",
                                              criterion_crit1: {}
                                            }
                                          })
      end.not_to change(ContentParticipation, :count)
    end
  end
end
