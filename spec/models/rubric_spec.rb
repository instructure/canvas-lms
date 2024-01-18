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

describe Rubric do
  context "with outcomes" do
    before do
      outcome_with_rubric({ mastery_points: 3 })
    end

    before :once do
      assignment_model
    end

    def assessment_data(opts = {})
      crit_id = "criterion_#{@rubric.data[0][:id]}"
      {
        user: @user,
        assessor: @user,
        artifact: @submission,
        assessment: {
          assessment_type: "grading",
          "#{crit_id}": {
            points: opts[:points],
            comments: "cool, yo"
          }
        }
      }
    end

    context "updating criteria" do
      context "from outcomes" do
        before do
          @outcome.short_description = "alpha"
          @outcome.description = "beta"
          criterion = {
            mastery_points: 3,
            ratings: [
              { points: 7, description: "Exceeds Expectations" },
              { points: 3, description: "Meets Expectations" },
              { points: 0, description: "Does Not Meet Expectations" }
            ]
          }
          @outcome.rubric_criterion = criterion
        end

        it "allows updating learning outcome criteria" do
          @rubric.update_learning_outcome_criteria(@outcome)
          rubric_criterion = @rubric.criteria_object.first
          expect(rubric_criterion.description).to eq "alpha"
          expect(rubric_criterion.long_description).to eq "beta"
          expect(rubric_criterion.ratings.length).to eq 3
          expect(rubric_criterion.mastery_points).to eq 3
          expect(rubric_criterion.ratings.map(&:description)).to eq [
            "Exceeds Expectations",
            "Meets Expectations",
            "Does Not Meet Expectations"
          ]
          expect(rubric_criterion.ratings.map(&:points)).to eq [7.0, 3.0, 0.0]
          expect(@rubric.points_possible).to eq 12
        end

        it "only updates learning outcome text when mastery scales are enabled" do
          Account.default.enable_feature! :account_level_mastery_scales
          @rubric.update_learning_outcome_criteria(@outcome)
          rubric_criterion = @rubric.criteria_object.first
          expect(rubric_criterion.description).to eq "alpha"
          expect(rubric_criterion.long_description).to eq "beta"
          expect(rubric_criterion.ratings.length).to eq 2
          expect(@rubric.points_possible).to eq 8
        end

        it "when friendly descriptions found" do
          @rubric.update_learning_outcome_criteria(@outcome)
          rubric_criterion = @rubric.criteria_object.first
          friendly_description = "a friendly description"
          OutcomeFriendlyDescription.create!({ learning_outcome: @outcome, context: @course, description: friendly_description })
          learning_outcome_friendly_description = @rubric.outcome_friendly_descriptions.first
          expect(rubric_criterion.learning_outcome_id).to eq learning_outcome_friendly_description.learning_outcome_id
          expect(learning_outcome_friendly_description.description).to eq "a friendly description"
        end

        it "when friendly descriptions not found" do
          @rubric.update_learning_outcome_criteria(@outcome)
          outcome_friendly_descriptions = @rubric.outcome_friendly_descriptions
          expect(outcome_friendly_descriptions).to eq []
        end
      end

      context "from mastery scales" do
        before do
          Account.default.enable_feature! :account_level_mastery_scales
          @outcome_proficiency = outcome_proficiency_model(Account.default)
          @rubric.update_mastery_scales
        end

        it "updates scale and points from mastery scales" do
          rubric_criterion = @rubric.criteria_object.first
          expect(rubric_criterion.description).to eq "Outcome row"
          expect(rubric_criterion.long_description).to eq @outcome.description
          expect(rubric_criterion.ratings.map(&:description)).to eq ["best", "worst"]
          expect(@rubric.points_possible).to eq 15
        end

        context "it should update" do
          it "when number of ratings changes" do
            @outcome_proficiency.outcome_proficiency_ratings.create! description: "new", points: 5, color: "abbaab", mastery: false
            @rubric.reload.update_mastery_scales

            rubric_criterion = @rubric.criteria_object.first
            expect(rubric_criterion.ratings.map(&:description)).to eq %w[best new worst]
            expect(rubric_criterion.ratings.map(&:points)).to eq [10, 5, 0]
          end

          it "when text of rating changes" do
            ratings = @outcome_proficiency.ratings_hash
            ratings.first[:description] = "new best"
            @outcome_proficiency.replace_ratings(ratings)
            @outcome_proficiency.save!
            @rubric.reload.update_mastery_scales

            rubric_criterion = @rubric.criteria_object.first
            expect(rubric_criterion.ratings.map(&:description)).to eq ["new best", "worst"]
            expect(rubric_criterion.ratings.map(&:points)).to eq [10, 0]
          end

          it "when score of rating changes" do
            ratings = @outcome_proficiency.ratings_hash
            ratings.first[:points] = 3
            @outcome_proficiency.replace_ratings(ratings)
            @outcome_proficiency.save!
            @rubric.reload.update_mastery_scales

            rubric_criterion = @rubric.criteria_object.first
            expect(rubric_criterion.ratings.map(&:description)).to eq ["best", "worst"]
            expect(rubric_criterion.ratings.map(&:points)).to eq [3, 0]
            expect(rubric_criterion[:points]).to eq 3
          end

          it "when proficiency is destroyed" do
            @outcome_proficiency.destroy
            @rubric.reload.update_mastery_scales

            rubric_criterion = @rubric.criteria_object.first
            expect(rubric_criterion.ratings.map(&:description)).to eq OutcomeProficiency.default_ratings.pluck(:description)
          end
        end

        context "it should not update" do
          before do
            @rubric.update_mastery_scales
            @last_update = 2.days.ago
            @rubric.touch(time: @last_update)
          end

          it "when mastery scale unchanged" do
            @rubric.update_mastery_scales
            expect(@rubric.reload.updated_at).to eq @last_update
          end

          it "when only color is changed" do
            ratings = @outcome_proficiency.ratings_hash
            ratings[0]["color"] = "ffffff"
            @outcome_proficiency.replace_ratings(ratings)

            @rubric.update_mastery_scales
            expect(@rubric.reload.updated_at).to eq @last_update
          end
        end
      end
    end

    context "rubric_criteria" do
      before do
        root_account_id = @course.root_account.id
        RubricCriterion.create!(rubric: @rubric, description: "criterion", points: 10, order: 1, created_by: @teacher, root_account_id:)
      end

      it "returns the rubric_criteria" do
        expect(@rubric.rubric_criteria.length).to eq 1
        expect(@rubric.rubric_criteria.first.description).to eq "criterion"
        expect(@rubric.rubric_criteria.first.points).to eq 10
      end

      it "marks all rubric_criteria as deleted when rubric deleted" do
        root_account_id = @course.root_account.id
        RubricCriterion.create!(rubric: @rubric, description: "criterion 2", points: 10, order: 2, created_by: @teacher, root_account_id:)
        @rubric.destroy
        expect(@rubric.rubric_criteria.first.workflow_state).to eq "deleted"
        expect(@rubric.rubric_criteria.second.workflow_state).to eq "deleted"
      end
    end

    it "allows learning outcome rows in the rubric" do
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
    end

    it "deletes learning outcome tags when they no longer exist" do
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      @rubric.data[0][:learning_outcome_id] = nil
      @rubric.save!
      expect(@rubric.learning_outcome_alignments.active).to be_empty
    end

    it "creates learning outcome associations for multiple outcome rows" do
      outcome2 = @course.created_learning_outcomes.create!(title: "outcome2")
      @rubric.data[1][:learning_outcome_id] = outcome2.id
      @rubric.save!
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.map(&:learning_outcome_id).sort).to eql([@outcome.id, outcome2.id].sort)
    end

    it "prevents an outcome to be aligned more then once" do
      @rubric.data[1][:learning_outcome_id] = @rubric.data[0][:learning_outcome_id]
      @rubric.save

      expect(@rubric).not_to be_valid
      expect(@rubric.errors.to_a[0]).to eql("This rubric has Outcomes aligned more than once")
    end

    it "prevents an aligned outcome from being removed if it was assessed" do
      user = user_factory(active_all: true)
      @course.enroll_student(user)
      a = @rubric.associate_with(@assignment, @course, purpose: "grading")
      @submission = @assignment.grade_student(user, grade: "10", grader: @teacher).first
      a.assess(assessment_data({ points: 2 }))
      @rubric.data[0][:learning_outcome_id] = nil
      @rubric.save

      expect(@rubric).not_to be_valid
      expect(@rubric.errors.to_a[0]).to eql("This rubric removes criterions that have learning outcome results")
    end

    it "creates outcome results when outcome-aligned rubrics are assessed" do
      expect(@rubric).not_to be_new_record
      expect(@rubric.learning_outcome_alignments.reload).not_to be_empty
      expect(@rubric.learning_outcome_alignments.first.learning_outcome_id).to eql(@outcome.id)
      user = user_factory(active_all: true)
      @course.enroll_student(user)
      a = @rubric.associate_with(@assignment, @course, purpose: "grading")
      @assignment.reload
      expect(@assignment.learning_outcome_alignments).not_to be_empty
      @submission = @assignment.grade_student(user, grade: "10", grader: @teacher).first
      a.assess(assessment_data({ points: 2 }))
      expect(@outcome.learning_outcome_results).not_to be_empty
      result = @outcome.learning_outcome_results.first
      expect(result.user_id).to be(user.id)
      expect(result.score).to be(2.0)
      expect(result.possible).to be(3.0)
      expect(result.original_score).to be(2.0)
      expect(result.original_possible).to be(3.0)
      expect(result.mastery).to be_falsey
      n = result.version_number
      a.assess(assessment_data({ points: 3 }))
      result.reload
      expect(result.version_number).to be > n
      expect(result.score).to be(3.0)
      expect(result.possible).to be(3.0)
      expect(result.original_score).to be(2.0)
      expect(result.mastery).to be_truthy
      expect(@rubric.learning_outcome_results).to eq([result])
      expect(@rubric.learning_outcome_ids_from_results).to eq([result.learning_outcome_id])
    end

    it "destroys an outcome link after the assignment using it is destroyed (if it's not used anywhere else)" do
      outcome2 = @course.account.created_learning_outcomes.create!(title: "outcome")
      link = @course.root_outcome_group.add_outcome(outcome2)
      rubric = rubric_model
      rubric.data[0][:learning_outcome_id] = outcome2.id
      rubric.save!
      assignment2 = @course.assignments.create!(assignment_valid_attributes)
      rubric.associate_with(@assignment, @course, purpose: "grading")
      a2 = rubric.associate_with(assignment2, @course, purpose: "grading")

      assignment2.destroy
      expect(RubricAssociation.where(id: a2).first).to be_deleted

      rubric.reload
      expect(rubric).to be_active

      @assignment.destroy
      rubric.reload
      expect(rubric).to be_deleted

      link.reload
      expect(link.destroy).to be_truthy
    end
  end

  context "with fractional_points" do
    it "allows fractional points" do
      course_factory
      data = [
        {
          points: 0.5,
          description: "Fraction row",
          id: 1,
          ratings: [
            { points: 0.5, description: "Rockin'", criterion_id: 1, id: 2 },
            { points: 0, description: "Lame", criterion_id: 1, id: 3 }
          ]
        }
      ]
      rubric = rubric_model({ context: @course, data: })
      expect(rubric.data.first[:points]).to be(0.5)
      expect(rubric.data.first[:ratings].first[:points]).to be(0.5)
    end

    it "rounds the total points to four decimal places" do
      course_factory

      criteria = {
        "0" => {
          points: 0.33333,
          description: "a criterion",
          id: "1",
          ratings: {
            "0" => { points: 0.33333, description: "ok", id: "2" },
            "1" => { points: 0, description: "not ok", id: "3" }
          }
        },
        "1" => {
          points: 0.33333,
          description: "also a criterion",
          id: "4",
          ratings: {
            "0" => { points: 0.33333, description: "ok", id: "5" },
            "1" => { points: 0, description: "not ok", id: "6" }
          }
        }
      }

      rubric = rubric_model({ context: @course })
      rubric.update_criteria({ criteria: })
      expect(rubric.points_possible).to eq 0.6667
    end
  end

  it "changes workflow state properly when archiving when enhanced_rubrics FF enabled" do
    Account.site_admin.enable_feature!(:enhanced_rubrics)
    course_with_teacher
    rubric = rubric_model({ context: @course })
    rubric.archive
    expect(rubric.workflow_state).to eq "archived"
  end

  it "changes workflow state propertly when unarchiving when enhanced_rubrics FF enabled" do
    Account.site_admin.enable_feature!(:enhanced_rubrics)
    course_with_teacher
    rubric = rubric_model({ context: @course })
    rubric.archive
    expect(rubric.workflow_state).to eq "archived"
    rubric.unarchive
    expect(rubric.workflow_state).to eq "active"
  end

  it "does not change workflow state when archiving when enhanced_rubrics FF disabled" do
    # remove this test when FF is removed
    Account.site_admin.disable_feature!(:enhanced_rubrics)
    course_with_teacher
    rubric = rubric_model({ context: @course })
    rubric.archive
    expect(rubric.workflow_state).to eq "active"
    Account.site_admin.enable_feature!(:enhanced_rubrics)
  end

  it "is cool about duplicate titles" do
    course_with_teacher

    r1 = rubric_model({ context: @course, title: "rubric" })
    expect(r1.title).to eql "rubric"

    r2 = rubric_model({ context: @course, title: "rubric" })
    expect(r2.title).to eql "rubric (1)"

    r1.destroy

    r3 = rubric_model({ context: @course, title: "rubric" })
    expect(r3.title).to eql "rubric"

    r3.title = "rubric"
    r3.save!
    expect(r3.title).to eql "rubric"
  end

  describe "#update_with_association group 1" do
    before :once do
      course_with_teacher
      assignment_model(points_possible: 20)
      @rubric = Rubric.new title: "r", context: @course
    end

    def test_rubric_associations(opts)
      expect(@rubric).to be_new_record
      # need to run the test 2x because the code path is different for new rubrics
      2.times do
        @rubric.update_with_association(@teacher,
                                        {
                                          id: @rubric.id,
                                          title: @rubric.title,
                                          criteria: {
                                            "0" => {
                                              description: "correctness",
                                              points: 15,
                                              ratings: { "0" => { points: 15, description: "asdf" } },
                                            },
                                          },
                                        },
                                        @course,
                                        {
                                          association_object: @assignment,
                                          update_if_existing: true,
                                          use_for_grading: "1",
                                          purpose: "grading",
                                          skip_updating_points_possible: opts[:leave_different]
                                        })
        yield
      end
    end

    it "doesn't accidentally update assignment points" do
      test_rubric_associations(leave_different: true) do
        expect(@rubric.points_possible).to eq 15
        expect(@assignment.reload.points_possible).to eq 20
      end
    end

    it "does update assignment points if you want it to" do
      test_rubric_associations(leave_different: false) do
        expect(@rubric.points_possible).to eq 15
        expect(@assignment.reload.points_possible).to eq 15
      end
    end
  end

  describe "#destroy_for" do
    before do
      course_factory
      assignment_model
      rubric_model
    end

    it "does not destroy associations when deleted from an account" do
      @rubric.associate_with(@assignment, @course, purpose: "grading")
      @rubric.destroy_for(@course.account)
      expect(@rubric.rubric_associations).to be_present
    end

    it "destroys rubric associations within context when deleted from a course" do
      course_factory
      course1 = Course.first
      course2 = Course.last
      assignment2 = course2.assignments.create! title: "Assignment 2: Electric Boogaloo",
                                                points_possible: 20
      @rubric.associate_with(@assignment, course1, purpose: "grading")
      @rubric.associate_with(assignment2, course2, purpose: "grading")
      expect(@rubric.rubric_associations.length).to eq 2
      @rubric.destroy_for(course1)
      @rubric.reload
      expect(@rubric.rubric_associations.length).to eq 1
    end

    context "when associated with a context containing an auditable assignment" do
      let(:course) { Course.create! }
      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:assignment) { course.assignments.create!(anonymous_grading: true) }
      let(:rubric) { Rubric.create!(title: "hi", context: course) }

      let(:last_event) { AnonymousOrModerationEvent.where(event_type: "rubric_deleted").last }

      before do
        rubric.update_with_association(teacher, {}, course, association_object: assignment)
      end

      it "records a rubric_deleted AnonymousOrModerationEvent for the assignment" do
        expect { rubric.destroy_for(course, current_user: teacher) }
          .to change { AnonymousOrModerationEvent.where(event_type: "rubric_deleted").count }.by(1)
      end

      it "includes the ID of the destroyed rubric in the payload" do
        rubric.destroy_for(course, current_user: teacher)
        expect(last_event.payload["id"]).to eq rubric.id
      end

      it "includes the current user in the event data" do
        rubric.destroy_for(course, current_user: teacher)
        expect(last_event.user_id).to eq teacher.id
      end
    end
  end

  describe "#update_with_association" do
    let(:course) { Course.create! }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:assignment) { course.assignments.create!(anonymous_grading: true) }
    let(:rubric) { Rubric.create!(title: "hi", context: course) }

    describe "AnonymousOrModerationEvent creation for auditable assignments" do
      context "when the assignment has a prior grading rubric" do
        let(:old_rubric) { Rubric.create!(title: "zzz", context: course) }
        let(:last_updated_event) { AnonymousOrModerationEvent.where(event_type: "rubric_updated").last }

        before do
          old_rubric.update_with_association(
            teacher,
            {},
            course,
            association_object: assignment,
            purpose: "grading"
          )

          assignment.reload
        end

        it "records a rubric_updated event for the assignment" do
          expect do
            rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          end.to change {
            AnonymousOrModerationEvent.where(event_type: "rubric_updated").count
          }.by(1)
        end

        it "includes the ID of the removed rubric in the payload" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.payload["id"].first).to eq old_rubric.id
        end

        it "includes the ID of the added rubric in the payload" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.payload["id"].second).to eq rubric.id
        end

        it "includes the updating user on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.user_id).to eq teacher.id
        end

        it "includes the associated assignment on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.assignment_id).to eq assignment.id
        end
      end

      context "when the assignment has no prior grading rubric" do
        let(:last_created_event) { AnonymousOrModerationEvent.where(event_type: "rubric_created").last }

        it "records a rubric_created event for the assignment" do
          expect do
            rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          end.to change {
            AnonymousOrModerationEvent.where(event_type: "rubric_created", assignment:).count
          }.by(1)
        end

        it "includes the ID of the added rubric in the payload" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_created_event.payload["id"]).to eq rubric.id
        end

        it "includes the updating user on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_created_event.user_id).to eq teacher.id
        end

        it "includes the associated assignment on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_created_event.assignment_id).to eq assignment.id
        end
      end
    end
  end

  it "normalizes criteria for comparison" do
    criteria = [{ id: "45_392",
                  description: "Description of criterion",
                  long_description: "",
                  points: 5,
                  mastery_points: nil,
                  ignore_for_scoring: nil,
                  learning_outcome_migration_id: nil,
                  title: "Description of criterion",
                  ratings: [{ description: "Full Marks",
                              id: "blank",
                              criterion_id: "45_392",
                              points: 5 },
                            { description: "No Marks",
                              id: "blank_2",
                              criterion_id: "45_392",
                              points: 0 }] }]
    expect(Rubric.normalize(criteria)).to eq(
      [{ "description" => "Description of criterion",
         "points" => 5.0,
         "id" => "45_392",
         "ratings" =>
          [{ "description" => "Full Marks",
             "points" => 5.0,
             "criterion_id" => "45_392",
             "id" => "blank" },
           { "description" => "No Marks",
             "points" => 0.0,
             "criterion_id" => "45_392",
             "id" => "blank_2" }] }]
    )
  end

  describe "#update_criteria" do
    context "populates blank titles" do
      before do
        rubric_model
        @rubric.update_criteria(
          criteria: {
            "0" => {
              description: "",
              ratings: {
                "0" => {
                  description: ""
                }
              }
            }
          }
        )
      end

      it "populates blank criterion title" do
        expect(@rubric.criteria[0][:description]).to eq "No Description"
      end

      it "populates blank rating title" do
        expect(@rubric.criteria[0][:ratings][0][:description]).to eq "No Description"
      end
    end

    context "updates description to be xss safe" do
      before do
        assignment_model
        outcome_with_rubric({ mastery_points: 3 })
        @rubric.update_criteria(
          criteria: {
            "0" => {
              long_description: "<script>alert('danger');</script>",
              ratings: {
                "0" => {
                  description: ""
                }
              }
            },
            "1" => {
              long_description: "<script>alert('danger');</script>",
              learning_outcome_id: @outcome.id
            }
          }
        )
      end

      it "cannot be used for XSS when edited directly" do
        expect(@rubric.criteria[0][:long_description]).to eq "&lt;script&gt;alert(&#39;danger&#39;);&lt;/script&gt;"
      end

      it "uses the sanitized outcome description when an id is provided" do
        @outcome.description = "<b>beta</b>"
        expect(@rubric.criteria[1][:long_description]).to eq "<p>This is <b>awesome</b>.</p>"
      end
    end

    describe "ordering of contents" do
      let(:rubric) { Rubric.new }

      it "sorts criteria based on the numerical values of their hash keys" do
        rubric.update_criteria(
          criteria: {
            "206000" => {
              description: "aaaaa",
              ratings: { "0" => { description: "" } }
            },
            "106215" => {
              description: "bbbbb",
              ratings: { "0" => { description: "" } }
            },
            "6043341" => {
              description: "ccccc",
              ratings: { "0" => { description: "" } }
            },
            "fred" => {
              description: "ddddd",
              ratings: { "0" => { description: "" } }
            }
          },
          title: "my rubric"
        )

        expect(rubric.criteria.pluck(:description)).to eq %w[ddddd bbbbb aaaaa ccccc]
      end

      it "sorts ratings within each criterion by the number of points in descending order" do
        rubric.update_criteria(
          criteria: {
            "1" => {
              description: "aaaaa",
              ratings: {
                "0" => { description: "ok", points: 5 },
                "1" => { description: "good", points: 10 },
                "2" => { description: "bad" }
              }
            }
          },
          title: "my rubric"
        )

        criterion = rubric.criteria.first
        expect(criterion[:ratings].pluck(:description)).to eq %w[good ok bad]
      end

      it "sorts ratings with the same number of points by description" do
        rubric.update_criteria(
          criteria: {
            "1" => {
              description: "aaaaa",
              ratings: {
                "0" => { description: "ok", points: 5 },
                "1" => { description: "also ok", points: 5 },
                "2" => { description: "ok too", points: 5 }
              }
            }
          },
          title: "my rubric"
        )

        criterion = rubric.criteria.first
        expect(criterion[:ratings].pluck(:description)).to eq ["also ok", "ok", "ok too"]
      end
    end
  end

  describe "create" do
    let(:root_account) { Account.default }

    it "sets the root_account_id using course" do
      course_model
      rubric_for_course
      expect(@rubric.root_account_id).to eq @course.root_account_id
    end

    it "sets the root_account_id using root account" do
      rubric_model
      expect(@rubric.root_account_id).to eq root_account.id
    end

    it "sets the root_account_id using sub account" do
      sub_account = root_account.sub_accounts.create!
      rubric_model({ context: sub_account })
      expect(@rubric.root_account_id).to eq sub_account.root_account_id
    end
  end

  context "scope methods" do
    before do
      student_in_course
    end

    def make_rubric(*attributes, **opts)
      opts[:context] ||= @course
      opts[:user] ||= @student
      rubric = attributes.include?(:aligned) ? outcome_with_rubric(opts) : rubric_model(opts)
      association = nil

      if attributes.intersect?([:assessed, :associated])
        (opts[:association_count] || 1).times do
          assignment = assignment_model(course: @course)
          association = rubric_association_model(**opts, rubric:, association_object: assignment, purpose: "grading")

          if attributes.include? :assessed
            rubric_assessment_model(**opts, rubric:, rubric_association: association)
          end
        end
      end

      rubric
    end

    describe "aligned_to_outcomes" do
      it "distinguishes aligned from unaligned" do
        course_aligned = make_rubric(:aligned)
        _course_unaligned = make_rubric
        account_aligned = make_rubric(:aligned, context: @account)
        _account_unaligned = make_rubric(context: @account)
        mixed_aligned = make_rubric(:aligned, outcome_context: @account)

        expect(Rubric.aligned_to_outcomes).to contain_exactly(course_aligned, account_aligned, mixed_aligned)
      end

      it "returns rubric only once despite multiple alignments" do
        aligned_twice = make_rubric(:aligned)
        second_outcome = outcome_model(context: @course)
        aligned_twice.criteria << {
          points: 5,
          **second_outcome.rubric_criterion
        }
        aligned_twice.save!

        expect(Rubric.aligned_to_outcomes).to contain_exactly(aligned_twice)
      end

      it "mixes with other scopes" do
        rubric1 = make_rubric(:aligned)
        rubric2 = make_rubric(:aligned)
        rubric1.destroy
        expect(Rubric.active.aligned_to_outcomes).to contain_exactly(rubric2)
      end
    end

    describe "unassessed" do
      it "distinguishes assessed from unassessed" do
        _assessed_account_rubric = make_rubric(:assessed, context: @account)
        _assessed_course_rubric = make_rubric(:assessed)
        unassessed_account_rubric = make_rubric(:associated, context: @account)
        unassessed_course_rubric = make_rubric(:associated)
        new_account_rubric = make_rubric(context: @account)
        new_course_rubric = make_rubric

        expect(Rubric.unassessed).to contain_exactly(new_account_rubric, new_course_rubric, unassessed_account_rubric, unassessed_course_rubric)
      end

      it "mixes with other scopes" do
        _assessed_rubric_with_outcome = make_rubric(:aligned, :assessed)
        _assessed_rubric_without_outcome = make_rubric(:assessed)
        unassessed_rubric_with_outcome = make_rubric(:aligned, :associated)
        _unassessed_rubric_without_outcome = make_rubric(:associated)
        new_rubric_with_outcome = make_rubric(:aligned)
        _new_rubric_without_outcome = make_rubric

        expect(Rubric.aligned_to_outcomes.unassessed).to contain_exactly(new_rubric_with_outcome, unassessed_rubric_with_outcome)

        new_rubric_with_outcome.destroy
        expect(Rubric.active.aligned_to_outcomes.unassessed).to contain_exactly(unassessed_rubric_with_outcome)
      end
    end

    describe "with_at_most_one_association" do
      it "distinguishes several associations with at most one" do
        not_associated = make_rubric
        associated_once = make_rubric(:associated)
        _associated_twice = make_rubric(:associated, association_count: 2)
        _associated_three_times = make_rubric(:associated, association_count: 3)

        expect(Rubric.with_at_most_one_association).to contain_exactly(not_associated, associated_once)
      end

      it "mixes with other scopes" do
        not_associated = make_rubric
        associated_once = make_rubric(:associated)
        _associated_twice = make_rubric(:associated, association_count: 2)
        aligned_not_associated = make_rubric(:aligned)
        aligned_associated_once = make_rubric(:aligned, :associated)
        _aligned_associated_twice = make_rubric(:aligned, :associated, association_count: 2)
        _assessed_not_associated = make_rubric(:assessed)
        _assessed_associated_once = make_rubric(:assessed, :associated)
        _assessed_associated_twice = make_rubric(:assessed, :associated, association_count: 2)
        aligned_assessed = make_rubric(:aligned, :assessed)
        aligned_assessed_associated_once = make_rubric(:aligned, :assessed)
        _aligned_assessed_associated_twice = make_rubric(:aligned, :assessed, association_count: 2)

        expect(Rubric.aligned_to_outcomes.with_at_most_one_association).to contain_exactly(
          aligned_not_associated,
          aligned_associated_once,
          aligned_assessed,
          aligned_assessed_associated_once
        )
        expect(Rubric.with_at_most_one_association.unassessed).to contain_exactly(
          not_associated,
          associated_once,
          aligned_not_associated,
          aligned_associated_once
        )
        expect(Rubric.with_at_most_one_association.unassessed.aligned_to_outcomes).to contain_exactly(aligned_not_associated, aligned_associated_once)
        expect(Rubric.unassessed_and_with_at_most_one_association).to contain_exactly(
          not_associated,
          associated_once,
          aligned_not_associated,
          aligned_associated_once
        )
        expect(Rubric.unassessed_and_with_at_most_one_association.aligned_to_outcomes).to contain_exactly(aligned_not_associated, aligned_associated_once)
      end

      it "works for rubrics with multiple alignments" do
        aligned_twice = make_rubric(:aligned, :associated)
        second_outcome = outcome_model(context: @course)
        aligned_twice.criteria << {
          points: 5,
          **second_outcome.rubric_criterion
        }
        aligned_twice.save!

        expect(Rubric.aligned_to_outcomes.with_at_most_one_association).to contain_exactly(aligned_twice)
      end
    end
  end
end
