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

describe RubricsController do
  describe "GET 'index'" do
    it "requires authorization" do
      course_with_teacher(active_all: true)
      @course.disable_feature!(:enhanced_rubrics)
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    describe "variables" do
      before { course_with_teacher_logged_in(active_all: true) }

      it "is assigned with a course" do
        get "index", params: { course_id: @course.id }
        expect(response).to be_successful
        expect(response).to render_template("rubrics/index")
      end

      it "is assigned with a user" do
        get "index", params: { user_id: @user.id }
        expect(response).to be_successful
      end

      it "includes managed_outcomes permission" do
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS][:manage_outcomes]).to be true
      end

      it "includes manage_rubrics permission" do
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be true
      end

      it "returns non_scoring_rubrics if enabled" do
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:NON_SCORING_RUBRICS]).to be true
      end
    end

    describe "after a course has concluded" do
      before do
        course_with_teacher_logged_in(active_all: true)
        @course.complete!
        @course.disable_feature!(:enhanced_rubrics)
      end

      it "can access rubrics" do
        get "index", params: { course_id: @course.id }

        expect(response).to be_successful
      end

      it "does not allow the teacher to manage_rubrics" do
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be false
      end

      it "sets correct permissions with enhanced_rubrics enabled" do
        @course.enable_feature!(:enhanced_rubrics)
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be false
      end
    end

    describe "with enhanced_rubrics enabled" do
      before do
        course_with_teacher_logged_in(active_all: true)
        @course.enable_feature!(:enhanced_rubrics)
      end

      it "can access rubrics" do
        get "index", params: { course_id: @course.id }

        expect(response).to render_template("layouts/application")
      end

      it "can access rubrics for /create route" do
        get "index", params: { course_id: "create" }

        expect(response).to render_template("layouts/application")
      end

      it "sets correct breadcrumbs" do
        @course.enable_feature!(:enhanced_rubrics)
        get "index", params: { course_id: @course.id }
        expected_breadcrumbs = [
          { name: "Unnamed", url: "/courses/#{@course.id}" },
          { name: "Rubrics", url: "/courses/#{@course.id}/rubrics" },
        ]
        expect(assigns[:js_env][:breadcrumbs]).to eq(expected_breadcrumbs)
      end

      it "sets correct env variables" do
        @course.enable_feature!(:enhanced_rubrics)
        Account.site_admin.enable_feature!(:enhanced_rubrics_assignments)
        get "index", params: { course_id: @course.id }

        expect(assigns[:js_env][:enhanced_rubrics_enabled]).to be true
        expect(assigns[:js_env][:enhanced_rubric_assignments_enabled]).to be true
      end
    end
  end

  describe "POST 'create' for course" do
    it "requires authorization" do
      course_with_teacher(active_all: true)
      post "create", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "assigns variables" do
      course_with_teacher_logged_in(active_all: true)
      request.content_type = "application/json"
      post "create", params: { course_id: @course.id, rubric: {} }
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to be_new_record
      expect(response).to be_successful
    end

    it "creates an association if specified" do
      course_with_teacher_logged_in(active_all: true)
      association = @course.assignments.create!(assignment_valid_attributes)
      request.content_type = "application/json"
      post "create", params: { course_id: @course.id,
                               rubric: {},
                               rubric_association: { association_type: association.class.to_s,
                                                     association_id: association.id } }
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to be_new_record
      expect(assigns[:rubric].rubric_associations.length).to be(1)
      expect(response).to be_successful
    end

    it "creates an association if specified without manage_rubrics permission" do
      course_with_teacher_logged_in(active_all: true)
      allow(@course).to receive(:grants_any_rights?).and_return(false)
      association = @course.assignments.create!(assignment_valid_attributes)
      request.content_type = "application/json"
      post "create", params: { course_id: @course.id,
                               rubric: {},
                               rubric_association: { association_type: association.class.to_s,
                                                     association_id: association.id } }
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to be_new_record
      expect(assigns[:rubric].rubric_associations.length).to be(1)
      expect(response).to be_successful
    end

    it "associates outcomes correctly" do
      course_with_teacher_logged_in(active_all: true)
      assignment = @course.assignments.create!(assignment_valid_attributes)
      outcome_group = @course.root_outcome_group
      outcome = @course.created_learning_outcomes.create!(
        description: "hi",
        short_description: "hi"
      )
      outcome_group.add_outcome(outcome)
      outcome_group.save!

      create_params = {
        "course_id" => @course.id,
        "points_possible" => "5",
        "rubric" => {
          "criteria" => {
            "0" => {
              "description" => "hi",
              "id" => "",
              "learning_outcome_id" => outcome.id,
              "long_description" => "",
              "mastery_points" => "3",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Exceeds Expectations",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "Meets Expectations",
                  "id" => "blank",
                  "points" => "3"
                },
                "2" => {
                  "description" => "Does Not Meet Expectations",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            }
          },
          "free_form_criterion_comments" => "0",
          "points_possible" => "5",
          "title" => "Some Rubric"
        },
        "rubric_association" => {
          "association_id" => assignment.id,
          "association_type" => "Assignment",
          "hide_score_total" => "0",
          "id" => "",
          "purpose" => "grading",
          "use_for_grading" => "1"
        },
        "rubric_association_id" => "",
        "rubric_id" => "new",
        "skip_updating_points_possible" => "false",
        "title" => "Some Rubric"
      }

      post "create", params: create_params

      expect(assignment.reload.learning_outcome_alignments.count).to eq 1
      expect(Rubric.last.learning_outcome_alignments.count).to eq 1
    end

    it "generates criterion record if enhanced_rubrics is turned on" do
      course_with_teacher_logged_in(active_all: true)
      @course.enable_feature!(:enhanced_rubrics)
      assignment = @course.assignments.create!(assignment_valid_attributes)
      create_params = {
        "course_id" => @course.id,
        "points_possible" => "5",
        "rubric" => {
          "criteria" => {
            "0" => {
              "description" => "hi",
              "long_description" => "even longer version of hi",
              "mastery_points" => "3",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Exceeds Expectations",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "Meets Expectations",
                  "id" => "blank",
                  "points" => "3"
                },
                "2" => {
                  "description" => "Does Not Meet Expectations",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            }
          },
          "free_form_criterion_comments" => "0",
          "points_possible" => "5",
          "title" => "Some Rubric"
        },
        "rubric_association" => {
          "association_id" => assignment.id,
          "association_type" => "Assignment",
          "hide_score_total" => "0",
          "id" => "",
          "purpose" => "grading",
          "use_for_grading" => "1"
        },
        "rubric_association_id" => "",
        "rubric_id" => "new",
        "skip_updating_points_possible" => "false",
        "title" => "Some Rubric"
      }
      expect { post("create", params: create_params) }.to change { RubricCriterion.count }.by(1)
    end
  end

  describe "POST 'create' for assignment" do
    describe "AnonymousOrModerationEvent creation for auditable assignments" do
      let(:course) { Course.create! }
      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:assignment) { course.assignments.create!(anonymous_grading: true) }

      let(:association_params) do
        { association_id: assignment.id, association_type: "Assignment" }
      end

      let(:rubric_params) do
        {
          criteria: { "0" => { description: "ok", points: 5 } },
          points_possible: 10,
          title: "hi"
        }
      end

      let(:request_params) do
        { course_id: course.id, rubric_association: association_params, rubric: rubric_params }
      end

      let(:last_created_event) { AnonymousOrModerationEvent.where(event_type: "rubric_created").last }

      before do
        user_session(teacher)
      end

      it "records a rubric_created event for the assignment" do
        expect do
          post("create", params: request_params)
        end.to change {
          AnonymousOrModerationEvent.where(event_type: "rubric_created", assignment:).count
        }.by(1)
      end

      it "includes the ID of the newly-created rubric in the payload" do
        post("create", params: request_params)
        # (since we don't have a specific ID to match against)
        expect(last_created_event.payload["id"]).to be > 0
      end

      it "includes the updating user on the event" do
        post("create", params: request_params)
        expect(last_created_event.user_id).to eq teacher.id
      end

      it "includes the associated assignment on the event" do
        post("create", params: request_params)
        expect(last_created_event.assignment_id).to eq assignment.id
      end
    end
  end

  describe "PUT 'update'" do
    it "requires authorization" do
      course_with_teacher(active_all: true)
      rubric_association_model(user: @user, context: @course)
      put "update", params: { course_id: @course.id, id: @rubric.id }
      assert_unauthorized
    end

    it "assigns variables" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      expect(@course.rubrics).to include(@rubric)
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: {} }
      expect(assigns[:rubric]).to eql(@rubric)
      expect(response).to be_successful
    end

    it "updates the rubric if updateable" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" } }
      expect(assigns[:rubric]).to eql(@rubric)
      expect(assigns[:rubric].title).to eql("new title")
      expect(assigns[:association]).to be_nil
      expect(response).to be_successful
    end

    it "updates the rubric even if it doesn't belong to the context, just an association" do
      course_model
      @course2 = @course
      course_with_teacher_logged_in(active_all: true)
      @e = @course2.enroll_teacher(@user)
      @e.accept
      rubric_association_model(user: @user, context: @course)
      @rubric.context = @course2
      @rubric.save
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" }, rubric_association_id: @rubric_association.id }
      expect(assigns[:rubric]).to eql(@rubric)
      expect(assigns[:rubric].title).to eql("new title")
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to eql(@rubric_association)
      expect(response).to be_successful
    end

    # this happens after a importing content into a new course, before a new
    # association is set up
    it "creates a new rubric (and not update the existing rubric) if it doesn't belong to the context or to an association" do
      course_model
      @course2 = @course
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      @rubric.context = @course2
      @rubric.save
      @rubric_association.context = @course2
      @rubric_association.save
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" }, rubric_association_id: @rubric_association.id }
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to eql(@rubric)
      expect(assigns[:rubric].title).to eql("new title")
    end

    it "creates a new rubric (and not update the existing rubric) if it doesn't belongs to the same context" do
      course_model
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      @rubric.context = @course.root_account
      @rubric.save
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" }, rubric_association_id: @rubric_association.id }
      expect(assigns[:rubric]).not_to be_nil
      expect(assigns[:rubric]).not_to eql(@rubric)
      expect(assigns[:rubric].title).to eql("new title")
    end

    it "does not update the rubric if not updateable (should make a new one instead)" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course, purpose: "grading")
      @rubric.rubric_associations.create!(purpose: "grading", context: @course, association_object: @course)
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" }, rubric_association_id: @rubric_association.id }
      expect(assigns[:rubric]).not_to eql(@rubric)
      expect(assigns[:rubric]).not_to be_new_record
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to eql(@rubric_association)
      expect(assigns[:association].rubric).to eql(assigns[:rubric])
      expect(assigns[:rubric].title).to eql("new title")
      expect(response).to be_successful
    end

    it "marks the blueprint associated assignment as having it's rubric changed if moved to a new rubric" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course, purpose: "grading")

      @rubric_association_object.update(migration_id: "#{MasterCourses::MIGRATION_ID_PREFIX}_blah")
      mc_course = Course.create!
      @template = MasterCourses::MasterTemplate.set_as_master_course(mc_course)
      sub = @template.add_child_course!(@course)
      child_tag = sub.content_tag_for(@rubric_association_object) # create a fake content tag

      @rubric.rubric_associations.create!(purpose: "grading", context: @course, association_object: @course)
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" }, rubric_association_id: @rubric_association.id }
      expect(response).to be_successful
      expect(child_tag.reload.downstream_changes).to include("rubric")
    end

    it "does not update the rubric and not create a new one if the parameters don't change the rubric" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course, purpose: "grading")
      params = {
        title: "new title",
        criteria: {
          "0" => {
            description: "desc",
            long_description: "long_desc",
            points: "5",
            id: "id_5",
            ratings: {
              "0" => {
                description: "a",
                points: "5",
                id: "id_6"
              },
              "1" => {
                description: "b",
                points: "0",
                id: "id_7"
              }
            }
          }
        }
      }
      @rubric.update_criteria(params)
      @rubric.save!
      @rubric.rubric_associations.create!(purpose: "grading", context: @course, association_object: @course)
      criteria = @rubric.criteria
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: params, rubric_association_id: @rubric_association.id }
      expect(assigns[:rubric]).to eql(@rubric)
      expect(assigns[:rubric].criteria).to eql(criteria)
      expect(assigns[:rubric]).not_to be_new_record
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to eql(@rubric_association)
      expect(assigns[:association].rubric).to eql(assigns[:rubric])
      expect(assigns[:rubric].title).to eql("new title")
      expect(response).to be_successful
    end

    it "updates the criteria records if changed and enhanced_rubrics is turned on" do
      course_with_teacher_logged_in(active_all: true)
      @course.enable_feature!(:enhanced_rubrics)
      assignment = @course.assignments.create!(assignment_valid_attributes)
      create_params = {
        "course_id" => @course.id,
        "points_possible" => "5",
        "rubric" => {
          "criteria" => {
            "0" => {
              "description" => "hi",
              "long_description" => "even longer version of hi",
              "mastery_points" => "3",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Exceeds Expectations",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "Meets Expectations",
                  "id" => "blank",
                  "points" => "3"
                },
                "2" => {
                  "description" => "Does Not Meet Expectations",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            },
            "1" => {
              "description" => "another one",
              "long_description" => "the second criterion on the rubric",
              "mastery_points" => "3",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Exceeds Expectations",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "Meets Expectations",
                  "id" => "blank",
                  "points" => "3"
                },
                "2" => {
                  "description" => "Does Not Meet Expectations",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            }
          },
          "free_form_criterion_comments" => "0",
          "points_possible" => "5",
          "title" => "Some Rubric"
        },
        "rubric_association" => {
          "association_id" => assignment.id,
          "association_type" => "Assignment",
          "hide_score_total" => "0",
          "id" => "",
          "purpose" => "grading",
          "use_for_grading" => "1"
        },
        "rubric_association_id" => "",
        "rubric_id" => "new",
        "skip_updating_points_possible" => "false",
        "title" => "Some Rubric"
      }
      post("create", params: create_params)
      @rubric = Rubric.last
      new_params = {
        title: "new title",
        criteria: {
          "0" => {
            description: "updated description",
            long_description: "even longer description",
            points: "5",
          }
        }
      }
      expect do
        put "update", params: { course_id: @course.id, id: @rubric.id, rubric: new_params }
      end.to change { @rubric.reload.rubric_criteria.count }.from(2).to(1)
      expect(@rubric.reload.rubric_criteria.first.description).to eq "updated description"
    end

    it "updates the newly-created rubric if updateable, even if the old id is specified" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" }, rubric_association_id: @rubric_association.id }
      expect(assigns[:rubric]).to eql(@rubric)
      expect(assigns[:rubric].title).to eql("new title")
      @rubric2 = assigns[:rubric]
      expect(assigns[:association]).not_to be_nil
      expect(assigns[:association]).to eql(@rubric_association)
      expect(response).to be_successful
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "newer title" }, rubric_association_id: @rubric_association.id }
      expect(assigns[:rubric]).to eql(@rubric2)
      expect(assigns[:rubric].title).to eql("newer title")
      expect(response).to be_successful
    end

    it "updates the association if specified" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" }, rubric_association: { association_type: @rubric_association.association_object.class.to_s, association_id: @rubric_association.association_object.id, title: "some title", id: @rubric_association.id } }
      expect(assigns[:rubric]).to eql(@rubric)
      expect(assigns[:rubric].title).to eql("new title")
      expect(assigns[:association]).to eql(@rubric_association)
      expect(assigns[:rubric].rubric_associations.where(id: @rubric_association).first.title).to eql("some title")
      expect(response).to be_successful
    end

    it "updates attributes on the association if specified" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      update_params = {
        course_id: @course.id,
        id: @rubric.id,
        rubric: {
          title: "new title"
        },
        rubric_association: {
          association_type: @rubric_association.association_object.class.to_s,
          association_id: @rubric_association.association_object.id,
          id: @rubric_association.id,
          hide_points: "1",
          hide_score_total: "1",
          hide_outcome_results: "1"
        }
      }
      put "update", params: update_params
      @rubric_association.reload
      expect(@rubric_association.hide_points).to be true
      expect(@rubric_association.hide_score_total).to be false
      expect(@rubric_association.hide_outcome_results).to be true
    end

    it "adds an outcome association if one is linked" do
      course_with_teacher_logged_in(active_all: true)
      assignment = @course.assignments.create!(assignment_valid_attributes)
      rubric_association_model(user: @user, context: @course)
      outcome_group = @course.root_outcome_group
      outcome = @course.created_learning_outcomes.create!(
        description: "hi",
        short_description: "hi"
      )
      outcome_group.add_outcome(outcome)
      outcome_group.save!

      update_params = {
        "course_id" => @course.id,
        "id" => @rubric.id,
        "points_possible" => "5",
        "rubric" => {
          "criteria" => {
            "0" => {
              "description" => "hi",
              "id" => "",
              "learning_outcome_id" => outcome.id,
              "long_description" => "",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Exceeds Expectations",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "Meets Expectations",
                  "id" => "blank",
                  "points" => "3"
                },
                "2" => {
                  "description" => "Does Not Meet Expectations",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            }
          },
          "free_form_criterion_comments" => "0",
          "points_possible" => "5",
          "title" => "Some Rubric"
        },
        "rubric_association" => {
          "association_id" => assignment.id,
          "association_type" => "Assignment",
          "hide_score_total" => "0",
          "id" => @rubric_association.id,
          "purpose" => "grading",
          "use_for_grading" => "1"
        },
        "rubric_association_id" => @rubric_association.id,
        "rubric_id" => @rubric.id,
        "skip_updating_points_possible" => "false",
        "title" => "Some Rubric"
      }

      expect(assignment.reload.learning_outcome_alignments.count).to eq 0
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 0

      put "update", params: update_params

      expect(assignment.reload.learning_outcome_alignments.count).to eq 1
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 1
    end

    it "returns an error if an outcome is aligned more than once" do
      # TODO: refactor copy-pasted updated_params
      course_with_teacher_logged_in(active_all: true)
      assignment = @course.assignments.create!(assignment_valid_attributes)
      rubric_association_model(user: @user, context: @course)
      outcome_group = @course.root_outcome_group
      outcome = @course.created_learning_outcomes.create!(
        description: "hi",
        short_description: "hi"
      )
      outcome_group.add_outcome(outcome)
      outcome_group.save!

      update_params = {
        "course_id" => @course.id,
        "id" => @rubric.id,
        "points_possible" => "5",
        "rubric" => {
          "criteria" => {
            "0" => {
              "description" => "hi",
              "id" => "",
              "learning_outcome_id" => outcome.id,
              "long_description" => "",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Exceeds Expectations",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "Meets Expectations",
                  "id" => "blank",
                  "points" => "3"
                },
                "2" => {
                  "description" => "Does Not Meet Expectations",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            },
            "1" => {
              "description" => "hi",
              "id" => "",
              "learning_outcome_id" => outcome.id,
              "long_description" => "",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Exceeds Expectations",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "Meets Expectations",
                  "id" => "blank",
                  "points" => "3"
                },
                "2" => {
                  "description" => "Does Not Meet Expectations",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            }
          },
          "free_form_criterion_comments" => "0",
          "points_possible" => "5",
          "title" => "Some Rubric"
        },
        "rubric_association" => {
          "association_id" => assignment.id,
          "association_type" => "Assignment",
          "hide_score_total" => "0",
          "id" => @rubric_association.id,
          "purpose" => "grading",
          "use_for_grading" => "1"
        },
        "rubric_association_id" => @rubric_association.id,
        "rubric_id" => @rubric.id,
        "skip_updating_points_possible" => "false",
        "title" => "Some Rubric"
      }

      expect(assignment.reload.learning_outcome_alignments.count).to eq 0
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 0

      response = JSON.parse(put("update", params: update_params).body).symbolize_keys

      expect(response[:error]).to be_truthy
      expect(response[:messages]).to include I18n.t("rubric.alignments.duplicated_outcome", "This rubric has Outcomes aligned more than once")
    end

    it "removes an outcome association if one is removed" do
      course_with_teacher_logged_in(active_all: true)
      outcome_with_rubric
      assignment = @course.assignments.create!(assignment_valid_attributes)
      association = @rubric.associate_with(assignment, @course, purpose: "grading")

      update_params = {
        "course_id" => @course.id,
        "id" => @rubric.id,
        "points_possible" => "5",
        "rubric" => {
          "criteria" => {
            "0" => {
              "description" => "Description of criterion",
              "id" => "",
              "learning_outcome_id" => "",
              "long_description" => "",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Full Marks",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "No Marks",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            }
          },
          "free_form_criterion_comments" => "0",
          "points_possible" => "5",
          "title" => "Some Rubric"
        },
        "rubric_association" => {
          "association_id" => assignment.id,
          "association_type" => "Assignment",
          "hide_score_total" => "0",
          "id" => association.id,
          "purpose" => "grading",
          "use_for_grading" => "1"
        },
        "rubric_association_id" => association.id,
        "rubric_id" => @rubric.id,
        "skip_updating_points_possible" => "false",
        "title" => "Some Rubric"
      }

      expect(assignment.reload.learning_outcome_alignments.count).to eq 1
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 1

      put "update", params: update_params

      expect(assignment.reload.learning_outcome_alignments.count).to eq 0
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 0
    end

    it "removes an outcome association for all associations" do
      course_with_teacher_logged_in(active_all: true)
      outcome_with_rubric
      assignment = @course.assignments.create!(assignment_valid_attributes)
      @rubric.associate_with(assignment, @course, purpose: "grading")

      update_params = {
        "course_id" => @course.id,
        "id" => @rubric.id,
        "points_possible" => "5",
        "rubric" => {
          "criteria" => {
            "0" => {
              "description" => "Description of criterion",
              "id" => "",
              "learning_outcome_id" => "",
              "long_description" => "",
              "points" => "5",
              "ratings" => {
                "0" => {
                  "description" => "Full Marks",
                  "id" => "blank",
                  "points" => "5"
                },
                "1" => {
                  "description" => "No Marks",
                  "id" => "blank_2",
                  "points" => "0"
                }
              }
            }
          },
          "free_form_criterion_comments" => "0",
          "points_possible" => "5",
          "title" => "Some Rubric"
        },
        "rubric_association" => {
          "association_id" => @course.id,
          "association_type" => "Course",
          "hide_score_total" => "0",
          "id" => "",
          "purpose" => "bookmark",
          "use_for_grading" => "0"
        },
        "rubric_association_id" => "",
        "rubric_id" => @rubric.id,
        "skip_updating_points_possible" => "false",
        "title" => "Some Rubric"
      }

      expect(assignment.reload.learning_outcome_alignments.count).to eq 1
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 1

      put "update", params: update_params

      expect(assignment.reload.learning_outcome_alignments.count).to eq 0
      expect(@rubric.reload.learning_outcome_alignments.count).to eq 0
    end
  end

  describe "DELETE 'destroy'" do
    it "requires authorization" do
      course_with_teacher(active_all: true)
      rubric_association_model(user: @user, context: @course)
      delete "destroy", params: { course_id: @course.id, id: @rubric.id }
      assert_unauthorized
    end

    it "deletes the rubric" do
      course_with_teacher_logged_in(active_all: true)
      rubric_association_model(user: @user, context: @course)
      delete "destroy", params: { course_id: @course.id, id: @rubric.id }
      expect(response).to be_successful
      expect(assigns[:rubric]).to be_deleted
    end

    # This should probably be fixed, but I want to document how this currently behaves.
    it "returns a 500 if the rubric cannot be found" do
      course_with_teacher_logged_in(active_all: true)
      association = rubric_association_model(user: @user, context: @course)
      association.destroy
      delete "destroy", params: { course_id: @course.id, id: @rubric.id }

      expect(response).to have_http_status :internal_server_error
    end

    it "deletes the rubric if the rubric is only associated with a course" do
      course_with_teacher_logged_in active_all: true
      Account.site_admin.account_users.create!(user: @user)
      Account.default.account_users.create!(user: @user)

      @rubric = Rubric.create!(user: @user, context: @course)
      RubricAssociation.create!(rubric: @rubric, context: @course, purpose: :bookmark, association_object: @course)
      expect(@course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).uniq(&:rubric_id).sort_by { |a| a.rubric.title }.map(&:rubric)).to eq [@rubric]

      delete "destroy", params: { course_id: @course.id, id: @rubric.id }
      expect(response).to be_successful
      expect(@course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).uniq(&:rubric_id).sort_by { |a| a.rubric.title }.map(&:rubric)).to eq []
      @rubric.reload
      expect(@rubric.deleted?).to be_truthy
    end

    it "deletes the rubric association even if the rubric doesn't belong to a course" do
      course_with_teacher_logged_in active_all: true
      Account.site_admin.account_users.create!(user: @user)
      Account.default.account_users.create!(user: @user)
      @user.reload

      @rubric = Rubric.create!(user: @user, context: Account.default)
      RubricAssociation.create!(rubric: @rubric, context: @course, purpose: :bookmark, association_object: @course)
      RubricAssociation.create!(rubric: @rubric, context: Account.default, purpose: :bookmark, association_object: @course)
      expect(@course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).uniq(&:rubric_id).sort_by { |a| a.rubric.title }.map(&:rubric)).to eq [@rubric]

      delete "destroy", params: { course_id: @course.id, id: @rubric.id }
      expect(response).to be_successful
      expect(@course.rubric_associations.bookmarked.include_rubric.to_a.select(&:rubric_id).uniq(&:rubric_id).sort_by { |a| a.rubric.title }.map(&:rubric)).to eq []
      @rubric.reload
      expect(@rubric.deleted?).to be_falsey
    end

    context "when associated with an auditable assignment" do
      let(:course) { Course.create! }
      let(:assignment) { course.assignments.create!(anonymous_grading: true) }
      let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
      let(:rubric) { Rubric.create!(title: "aaa", context: course) }

      before do
        rubric.update_with_association(
          teacher,
          {},
          course,
          association_object: assignment,
          purpose: "grading"
        )
        user_session(teacher)
      end

      it "creates an AnonymousOrModerationEvent capturing the deletion" do
        expect do
          delete("destroy", params: { course_id: course.id, id: rubric.id })
        end.to change {
          AnonymousOrModerationEvent.where(event_type: "rubric_deleted", assignment:, user: teacher).count
        }.by(1)
      end

      it "includes the removed rubric in the event payload" do
        delete("destroy", params: { course_id: course.id, id: rubric.id })

        event = AnonymousOrModerationEvent.find_by(event_type: "rubric_deleted", assignment:, user: teacher)
        expect(event.payload["id"]).to eq rubric.id
      end
    end
  end

  describe "GET 'show'" do
    before { course_with_teacher_logged_in(active_all: true) }

    it "doesn't load nonsense" do
      assert_page_not_found do
        get "show", params: { id: "cats", course_id: @course.id }
      end
    end

    it "returns 404 if record doesn't exist" do
      assert_page_not_found do
        get "show", params: { id: "1", course_id: @course.id }
      end
    end

    it "returns 404 if rubric is deleted" do
      rubric = Rubric.create!(user: @teacher, context: Account.default)
      RubricAssociation.create!(
        rubric:,
        context: @course,
        purpose: :bookmark,
        association_object: @course
      )
      rubric.destroy
      assert_page_not_found do
        get "show", params: { id: rubric.id, course_id: @course.id }
      end
    end

    describe "with a valid rubric" do
      before do
        @r = Rubric.create! user: @teacher, context: Account.default
        RubricAssociation.create! rubric: @r,
                                  context: @course,
                                  purpose: :bookmark,
                                  association_object: @course
      end

      it "works" do
        get "show", params: { id: @r.id, course_id: @course.id }
        expect(response).to be_successful
        expect(response).to render_template("rubrics/show")
      end

      it "allows the teacher to manage_rubrics" do
        get "show", params: { id: @r.id, course_id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be true
      end

      describe "after a course has concluded" do
        before { @course.complete! }

        it "can access the rubric" do
          get "show", params: { id: @r.id, course_id: @course.id }
          expect(response).to be_successful
        end

        it "does not allow the teacher to manage_rubrics" do
          get "show", params: { id: @r.id, course_id: @course.id }
          expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be false
        end

        it "sets correct permissions with enhanced_rubrics enabled" do
          @course.enable_feature!(:enhanced_rubrics)
          get "show", params: { id: @r.id, course_id: @course.id }
          expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be false
        end
      end
    end

    describe "with enhanced_rubrics enabled" do
      before do
        @course.enable_feature!(:enhanced_rubrics)
        course_with_teacher_logged_in(active_all: true)
      end

      it "can access rubrics" do
        get "index", params: { course_id: @course.id }

        expect(response).to render_template("layouts/application")
      end
    end

    describe "track metrics" do
      before do
        course_with_teacher_logged_in(active_all: true)
        @assignment = @course.assignments.create!(assignment_valid_attributes)
        allow(InstStatsd::Statsd).to receive(:distributed_increment).and_call_original
      end

      let(:create_params) do
        {
          "course_id" => @course.id,
          "points_possible" => "5",
          "rubric" => {
            "criteria" => {
              "0" => {
                "description" => "hi",
                "id" => "",
                "long_description" => "",
                "mastery_points" => "3",
                "points" => "5",
                "ratings" => {
                  "0" => {
                    "description" => "Exceeds Expectations",
                    "id" => "blank",
                    "points" => "5"
                  },
                  "1" => {
                    "description" => "Meets Expectations",
                    "id" => "blank",
                    "points" => "3"
                  },
                  "2" => {
                    "description" => "Does Not Meet Expectations",
                    "id" => "blank_2",
                    "points" => "0"
                  }
                }
              }
            },
            "free_form_criterion_comments" => "0",
            "points_possible" => "5",
            "title" => "Some Rubric"
          },
          "rubric_association" => {
            "association_id" => @assignment.id,
            "association_type" => "Assignment",
            "hide_score_total" => "0",
            "id" => "",
            "purpose" => "grading",
            "use_for_grading" => "1"
          },
          "rubric_association_id" => "",
          "rubric_id" => "new",
          "skip_updating_points_possible" => "false",
          "title" => "Some Rubric"
        }
      end

      context "enhanced version disabled" do
        before do
          @course.disable_feature!(:enhanced_rubrics)
        end

        it "track rubric created with old version" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with("course.rubrics.created_old").at_least(:once)

          post "create", params: create_params
        end

        it "track creationfrom assignments ui" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with("course.rubrics.created_from_assignment").at_least(:once)

          post "create", params: create_params
        end

        it "track rubric updated with old version" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with("course.rubrics.updated_old").at_least(:once)

          rubric_association_model(user: @user, context: @course)
          put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" } }
        end
      end

      context "enhanced version enabled" do
        before do
          @course.enable_feature!(:enhanced_rubrics)
        end

        it "track rubric created with enhanced version" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with("course.rubrics.created_enhanced").at_least(:once)

          post "create", params: create_params
        end

        it "track rubric duplicate" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with("course.rubrics.duplicated_enhanced").at_least(:once)
          create_params["rubric"]["is_duplicate"] = true
          post "create", params: create_params
        end

        it "track rubric updated with enhanced version" do
          expect(InstStatsd::Statsd).to receive(:distributed_increment).with("course.rubrics.updated_enhanced").at_least(:once)

          rubric_association_model(user: @user, context: @course)
          put "update", params: { course_id: @course.id, id: @rubric.id, rubric: { title: "new title" } }
        end

        it "track rubric aligned with outcome" do
          allow(InstStatsd::Statsd).to receive(:distributed_increment).and_call_original
          expect(InstStatsd::Statsd).to receive(:distributed_increment)
            .with("rubrics_management.rubric_criterion.aligned_with_outcome_used_for_scoring")
            .at_least(:once)
          outcome_group = @course.root_outcome_group
          outcome = @course.created_learning_outcomes.create!(
            description: "hi",
            short_description: "hi"
          )
          outcome_group.add_outcome(outcome)
          outcome_group.save!

          create_params["rubric"]["criteria"]["0"]["learning_outcome_id"] = outcome.id

          post "create", params: create_params
        end
      end
    end
  end

  # Shared examples for AI rubric generation endpoints
  shared_examples "requires enabled features" do |endpoint|
    it "returns error when features are disabled" do
      @course.disable_feature!(:enhanced_rubrics)
      @course.disable_feature!(:ai_rubrics)

      post endpoint, params: request_params, format: :json
      expect(response).to be_forbidden
    end
  end

  shared_examples "requires manage rubric permission" do |endpoint|
    it "returns error when user lacks permissions" do
      course_with_student_logged_in(active_all: true, course: @course)
      post endpoint, params: request_params, format: :json
      expect(response).to be_forbidden
    end
  end

  shared_examples "validates parameter bounds" do |endpoint|
    it "returns error when criteria_count is out of bounds" do
      params = request_params.deep_merge(generate_options: { criteria_count: 1 })
      post endpoint, params:, format: :json
      expect(response).to be_bad_request
      expect(response.parsed_body["error"]).to include("criteria_count must be between 2 and 8")
    end

    it "returns error when rating_count is out of bounds" do
      params = request_params.deep_merge(generate_options: { rating_count: 9 })
      post endpoint, params:, format: :json
      expect(response).to be_bad_request
      expect(response.parsed_body["error"]).to include("rating_count must be between 2 and 8")
    end
  end

  shared_examples "validates association" do |endpoint|
    it "returns unauthorized when association_object is invalid" do
      params = request_params.deep_merge(
        rubric_association: { association_type: "Assignment", association_id: 999_999 }
      )
      post endpoint, params:, format: :json
      expect(response).to be_forbidden
    end
  end

  describe "ai rubrics" do
    let(:cedar_response_struct) { Struct.new(:response, keyword_init: true) }
    let(:mock_cedar_prompt_response) do
      Struct.new(:response, keyword_init: true).new(response: "<RUBRIC_DATA>\n</RUBRIC_DATA>")
    end

    let(:mock_cedar_conversation_response) do
      Struct.new(:response, keyword_init: true).new(response: '{"criteria": []}')
    end

    before do
      allow(Rails.env).to receive(:test?).and_return(true)
      stub_const("CedarClient", Class.new do
        def self.prompt(*)
          mock_cedar_prompt_response
        end

        def self.conversation(*)
          mock_cedar_conversation_response
        end
      end)
    end

    describe "POST 'llm_criteria'" do
      before do
        course_with_teacher_logged_in(active_all: true)
        @assignment = @course.assignments.create!(assignment_valid_attributes)

        @course.enable_feature!(:enhanced_rubrics)
        @course.enable_feature!(:ai_rubrics)
      end

      let(:request_params) do
        {
          course_id: @course.id,
          rubric_association: { association_type: "Assignment", association_id: @assignment.id },
          generate_options: { criteria_count: 2, rating_count: 3, points_per_criterion: 5, use_range: true, grade_level: "college" }
        }
      end

      it "queues job for generation of criteria via LLM when features are enabled" do
        llm_response = {
          criteria: [
            {
              name: "Critical Analysis",
              description: "Demonstrates thorough understanding and analysis",
              ratings: [
                { title: "Excellent", description: "Thoroughly demonstrated understanding" },
                { title: "Good", description: "Partially demonstrated understanding" },
                { title: "Needs Improvement", description: "Failed to demonstrate understanding" }
              ]
            },
            {
              name: "Detailed Diagrams",
              description: "Demonstrates diagramming ability ",
              ratings: [
                { title: "Excellent", description: "Thoroughly demonstrated diagramming" },
                { title: "Good", description: "Partially demonstrated diagramming" },
                { title: "Needs Improvement", description: "Failed to demonstrate diagramming" }
              ]
            }
          ]
        }
        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: llm_response.to_json[1..])
        )

        post "llm_criteria",
             params: {
               course_id: @course.id,
               rubric_association: { association_type: "Assignment", association_id: @assignment.id },
               generate_options: { criteria_count: 2, rating_count: 3, points_per_criterion: 5, use_range: true, additional_prompt_info: "Focus on content", grade_level: "second" }
             },
             format: :json

        expect(response).to be_successful
        json = response.parsed_body
        expect(json).to be_present
        expect(json["workflow_state"]).to eq "queued"

        run_jobs

        progress = Progress.find(json["id"])
        expect(progress.results).to be_present
        expect(progress.results[:criteria].length).to eq 2
        expect(progress.results[:criteria][0][:criterion_use_range]).to be_truthy
      end

      context "authorization and feature flags" do
        include_examples "requires enabled features", "llm_criteria"
        include_examples "requires manage rubric permission", "llm_criteria"
      end

      context "validation" do
        include_examples "validates parameter bounds", "llm_criteria"
        include_examples "validates association", "llm_criteria"

        it "accepts request when criteria_count is missing" do
          params = request_params.tap { |p| p[:generate_options].delete(:criteria_count) }
          post "llm_criteria", params:, format: :json
          expect(response).to be_successful
        end
      end
    end

    describe "POST 'llm_regenerate_criteria'" do
      before do
        course_with_teacher_logged_in(active_all: true)
        @assignment = @course.assignments.create!(assignment_valid_attributes)

        @course.enable_feature!(:enhanced_rubrics)
        @course.enable_feature!(:ai_rubrics)

        # Set up existing criteria structure
        @existing_criteria = {
          "0" => {
            id: "1",
            description: "Original Criterion 1",
            long_description: "Original long description 1",
            points: 10,
            criterion_use_range: false,
            ratings: [
              { id: "1", criterion_id: "1", description: "Excellent", long_description: "Excellent work", points: 10 },
              { id: "2", criterion_id: "1", description: "Good", long_description: "Good work", points: 7 },
              { id: "3", criterion_id: "1", description: "Poor", long_description: "Poor work", points: 4 }
            ]
          },
          "1" => {
            id: "2",
            description: "Original Criterion 2",
            long_description: "Original long description 2",
            points: 10,
            criterion_use_range: true,
            ratings: [
              { id: "4", criterion_id: "2", description: "Excellent", long_description: "Excellent work", points: 10 },
              { id: "5", criterion_id: "2", description: "Good", long_description: "Good work", points: 7 },
              { id: "6", criterion_id: "2", description: "Poor", long_description: "Poor work", points: 4 }
            ]
          }
        }
      end

      let(:request_params) do
        {
          course_id: @course.id,
          rubric_association: { association_type: "Assignment", association_id: @assignment.id },
          criteria: @existing_criteria,
          generate_options: { criteria_count: 2, rating_count: 3, points_per_criterion: 10, use_range: true, grade_level: "higher-ed" }
        }
      end

      it "regenerates criteria via LLM when features are enabled" do
        llm_response = "<RUBRIC_DATA>
          criterion:_new_c_1:description=Critical Thinking
          criterion:_new_c_1:long_description=Ability to analyze ideas, identify assumptions, and evaluate arguments
          rating:_new_r_1:description=Excellent
          rating:_new_r_1:long_description=Consistently demonstrates deep analysis and evaluation of ideas
          rating:_new_r_2:description=Good
          rating:_new_r_2:long_description=Shows some analysis and evaluation but lacks consistency
          rating:_new_r_3:description=Needs Improvement
          rating:_new_r_3:long_description=Minimal or no analysis demonstrated

          criterion:_new_c_2:description=Clarity of Communication
          criterion:_new_c_2:long_description=Ability to express ideas clearly and effectively in writing
          rating:_new_r_4:description=Excellent
          rating:_new_r_4:long_description=Writing is consistently clear, well-structured, and easy to understand
          rating:_new_r_5:description=Good
          rating:_new_r_5:long_description=Writing is understandable but may have lapses in clarity or structure
          rating:_new_r_6:description=Needs Improvement
          rating:_new_r_6:long_description=Writing is unclear, disorganized, or difficult to follow
        </RUBRIC_DATA>"

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_response)
        )

        post "llm_regenerate_criteria",
             params: {
               course_id: @course.id,
               rubric_association: { association_type: "Assignment", association_id: @assignment.id },
               criteria: @existing_criteria,
               additional_user_prompt: "Make this more comprehensive",
               regenerate_options: { additional_user_prompt: "Make this more comprehensive" },
               generate_options: { criteria_count: 2, rating_count: 3, points_per_criterion: 10, use_range: true, grade_level: "college" }
             },
             format: :json
        expect(response).to be_successful
        json = response.parsed_body
        expect(json).to be_present
        expect(json["workflow_state"]).to eq "queued"
        run_jobs
        progress = Progress.find(json["id"])
        expect(progress.results).to be_present
        expect(progress.results[:criteria].length).to eq 2
      end

      it "regenerates criterion when criterion_id is provided" do
        llm_response = "<RUBRIC_DATA>
          criterion:1:description=Modified Criterion 1
          criterion:1:long_description=Modified long description 1
          rating:1:description=Excellent
          rating:1:long_description=Excellent work
          rating:2:description=Good
          rating:2:long_description=Good work
          rating:3:description=Poor
          rating:3:long_description=Poor work
        </RUBRIC_DATA>"

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_response)
        )

        post "llm_regenerate_criteria",
             params: {
               course_id: @course.id,
               rubric_association: { association_type: "Assignment", association_id: @assignment.id },
               criteria: @existing_criteria,
               regenerate_options: { additional_user_prompt: "update criterion", criterion_id: 1 },
               generate_options: {
                 criteria_count: 2,
                 rating_count: 3,
                 points_per_criterion: 20,
                 use_range: false,
                 grade_level: "higher-ed"
               }
             },
             format: :json
        expect(response).to be_successful
        json = response.parsed_body
        expect(json["workflow_state"]).to eq "queued"
        run_jobs
        progress = Progress.find(json["id"])
        expect(progress.results).to be_present
        expect(progress.results[:criteria].length).to eq 2

        expect(progress.results[:criteria][0][:id]).to eq("1")
        expect(progress.results[:criteria][0][:description]).to eq("Modified Criterion 1")

        expect(progress.results[:criteria][1][:id]).to eq("2")
        expect(progress.results[:criteria][1][:description]).to eq("Original Criterion 2")
      end

      context "criteria count management" do
        it "extends criteria when criteria_count is higher than original, keeping old IDs untouched" do
          # Add a 3rd criterion to the existing criteria
          existing_criteria_with_three = @existing_criteria.merge(
            "2" => {
              id: "3",
              description: "Original Criterion 3",
              long_description: "Original long description 3",
              points: 10,
              criterion_use_range: false,
              ratings: [
                { id: "7", criterion_id: "3", description: "Excellent", long_description: "Excellent work", points: 10 },
                { id: "8", criterion_id: "3", description: "Good", long_description: "Good work", points: 7 },
                { id: "9", criterion_id: "3", description: "Poor", long_description: "Poor work", points: 4 }
              ]
            }
          )

          llm_response = "<RUBRIC_DATA>
            criterion:1:description=Original Criterion 1
            criterion:1:long_description=Original long description 1
            rating:1:description=Excellent
            rating:1:long_description=Excellent work
            rating:2:description=Good
            rating:2:long_description=Good work
            rating:3:description=Poor
            rating:3:long_description=Poor work

            criterion:2:description=Original Criterion 2
            criterion:2:long_description=Original long description 2
            rating:4:description=Excellent
            rating:4:long_description=Excellent work
            rating:5:description=Good
            rating:5:long_description=Good work
            rating:6:description=Poor
            rating:6:long_description=Poor work

            criterion:3:description=Added Criterion 3
            criterion:3:long_description=Newly generated criterion
            rating:7:description=Excellent
            rating:7:long_description=Excellent work
            rating:8:description=Good
            rating:8:long_description=Good work
            rating:9:description=Poor
            rating:9:long_description=Poor work
          </RUBRIC_DATA>"

          expect(CedarClient).to receive(:prompt).and_return(
            cedar_response_struct.new(response: llm_response)
          )

          post "llm_regenerate_criteria",
               params: {
                 course_id: @course.id,
                 rubric_association: { association_type: "Assignment", association_id: @assignment.id },
                 criteria: existing_criteria_with_three,
                 generate_options: { criteria_count: 3, rating_count: 3, points_per_criterion: 10 }
               },
               format: :json

          expect(response).to be_successful
          json = response.parsed_body
          run_jobs
          progress = Progress.find(json["id"])

          expect(progress.results[:criteria].length).to eq 3
          expect(progress.results[:criteria].pluck(:id)).to include("1", "2", "3")
          expect(progress.results[:criteria].last[:description]).to eq("Added Criterion 3")
        end

        it "preserves all incoming criteria count even when generate_options specifies different count" do
          # Start with 3 criteria
          existing_criteria_with_three = @existing_criteria.merge(
            "2" => {
              id: "3",
              description: "Original Criterion 3",
              long_description: "Original long description 3",
              points: 10,
              criterion_use_range: false,
              ratings: [
                { id: "7", criterion_id: "3", description: "Excellent", long_description: "Excellent work", points: 10 },
                { id: "8", criterion_id: "3", description: "Good", long_description: "Good work", points: 7 },
                { id: "9", criterion_id: "3", description: "Poor", long_description: "Poor work", points: 4 }
              ]
            }
          )

          llm_response = "<RUBRIC_DATA>
            criterion:1:description=Retained Criterion 1
            criterion:1:long_description=Still present
            rating:1:description=Excellent
            rating:1:long_description=Excellent work
            rating:2:description=Good
            rating:2:long_description=Good work
            rating:3:description=Poor
            rating:3:long_description=Poor work

            criterion:2:description=Retained Criterion 2
            criterion:2:long_description=Still present
            rating:4:description=Excellent
            rating:4:long_description=Excellent work
            rating:5:description=Good
            rating:5:long_description=Good work
            rating:6:description=Poor
            rating:6:long_description=Poor work

            criterion:3:description=Retained Criterion 3
            criterion:3:long_description=Still present
            rating:7:description=Excellent
            rating:7:long_description=Excellent work
            rating:8:description=Good
            rating:8:long_description=Good work
            rating:9:description=Poor
            rating:9:long_description=Poor work
          </RUBRIC_DATA>"

          expect(CedarClient).to receive(:prompt).and_return(
            cedar_response_struct.new(response: llm_response)
          )

          post "llm_regenerate_criteria",
               params: {
                 course_id: @course.id,
                 rubric_association: { association_type: "Assignment", association_id: @assignment.id },
                 criteria: existing_criteria_with_three,
                 generate_options: { criteria_count: 2, rating_count: 3, points_per_criterion: 10 }
               },
               format: :json

          expect(response).to be_successful
          json = response.parsed_body
          run_jobs
          progress = Progress.find(json["id"])

          # Verify it preserved all 3 criteria (incoming count takes precedence over generate_options)
          expect(progress.results[:criteria].length).to eq 3
          expect(progress.results[:criteria].pluck(:id)).to include("1", "2", "3")
        end
      end

      context "authorization and feature flags" do
        include_examples "requires enabled features", "llm_regenerate_criteria"
        include_examples "requires manage rubric permission", "llm_regenerate_criteria"
      end

      context "parameter validation" do
        include_examples "validates parameter bounds", "llm_regenerate_criteria"
        include_examples "validates association", "llm_regenerate_criteria"

        context "string length limits" do
          it "returns error when additional_user_prompt is too long" do
            long_prompt = "a" * 1001
            params = request_params.deep_merge(
              regenerate_options: { additional_user_prompt: long_prompt }
            )
            post "llm_regenerate_criteria", params:, format: :json
            expect(response).to be_bad_request
            expect(response.parsed_body["error"]).to eq "additional_user_prompt must be less than 1000 characters"
          end

          it "returns error when additional_prompt_info is too long in generate_options" do
            long_info = "b" * 1001
            params = request_params.deep_merge(
              generate_options: { additional_prompt_info: long_info }
            )
            post "llm_regenerate_criteria", params:, format: :json
            expect(response).to be_bad_request
            expect(response.parsed_body["error"]).to eq "additional_prompt_info must be less than 1000 characters"
          end

          it "returns error when standard in regenerate_options is too long" do
            long_standard = "s" * 1001
            params = request_params.deep_merge(
              regenerate_options: { standard: long_standard }
            )
            post "llm_regenerate_criteria", params:, format: :json
            expect(response).to be_bad_request
            expect(response.parsed_body["error"]).to eq "standard must be less than 1000 characters"
          end
        end

        context "criteria parameter validation" do
          it "returns 400 when criteria is empty or missing" do
            [{}].each do |invalid_criteria|
              params = request_params.merge(criteria: invalid_criteria)
              post "llm_regenerate_criteria", params:, format: :json
              expect(response).to have_http_status(:bad_request)
              expect(response.parsed_body["error"]).to include("criteria must be provided")
            end
          end

          it "returns 400 when criteria param is missing entirely" do
            params = request_params.tap { |p| p.delete(:criteria) }
            post "llm_regenerate_criteria", params:, format: :json
            expect(response).to have_http_status(:bad_request)
            expect(response.parsed_body["error"]).to include("criteria must be provided")
          end

          it "accepts malformed rating data (fails later in service layer)" do
            malformed_criteria = {
              "0" => {
                id: "c1",
                description: "Clarity",
                points: 10,
                ratings: "not_an_array"
              }
            }
            params = request_params.merge(criteria: malformed_criteria)
            post "llm_regenerate_criteria", params:, format: :json
            # Controller accepts it, validation happens in service layer
            expect(response).to be_successful
          end
        end
      end

      context "edge cases" do
        it "accepts regenerate_options without standard" do
          params = request_params.deep_merge(
            regenerate_options: { additional_user_prompt: "refine clarity" }
          )
          post "llm_regenerate_criteria", params:, format: :json
          expect(response).to be_successful
          expect(response.parsed_body["workflow_state"]).to eq "queued"
        end

        it "accepts use_range = false and grade_level = higher-ed in generate_options" do
          params = request_params.deep_merge(
            regenerate_options: { criterion_id: "1", additional_user_prompt: "add detail" },
            generate_options: {
              criteria_count: 5,
              rating_count: 4,
              points_per_criterion: 20,
              use_range: false,
              grade_level: "higher-ed"
            }
          )
          post "llm_regenerate_criteria", params:, format: :json
          expect(response).to be_successful
          expect(response.parsed_body["workflow_state"]).to eq "queued"
        end

        it "queues job successfully when both generate_options and regenerate_options are empty" do
          params = request_params.tap do |p|
            p.delete(:regenerate_options)
            p[:generate_options] = {}
          end
          post "llm_regenerate_criteria", params:, format: :json
          expect(response).to be_successful
          expect(response.parsed_body["workflow_state"]).to eq "queued"
        end

        it "handles nonexistent criterion_id gracefully in background job" do
          params = request_params.deep_merge(
            regenerate_options: {
              criterion_id: "nonexistent_id",
              additional_user_prompt: "Improve it"
            }
          )
          post "llm_regenerate_criteria", params:, format: :json
          expect(response).to be_successful
        end
      end

      context "LLM response error handling" do
        before do
          allow(LLMConfigs).to receive(:config_for).with("rubric_regenerate_criteria").and_return(
            double("LLMConfig",
                   name: "rubric-regenerate-criteriaV2",
                   model_id: "anthropic.claude-3-haiku-20240307-v1:0",
                   generate_prompt_and_options: ["PROMPT", { temperature: 1.0 }])
          )
        end

        it "handles empty RUBRIC_DATA responses during regeneration" do
          expect(CedarClient).to receive(:prompt).and_return(
            cedar_response_struct.new(response: "<RUBRIC_DATA></RUBRIC_DATA>")
          )

          post "llm_regenerate_criteria", params: request_params, format: :json
          expect(response).to be_successful
          run_jobs

          progress = Progress.find(response.parsed_body["id"])
          expect(progress.workflow_state).to eq "failed"
          expect(progress.results[:error]).to eq "There was an error with the criteria regeneration. Please try again later."
        end

        it "handles missing RUBRIC_DATA tags" do
          expect(CedarClient).to receive(:prompt).and_return(
            cedar_response_struct.new(response: "This response has no proper tags for regeneration")
          )

          post "llm_regenerate_criteria", params: request_params, format: :json
          expect(response).to be_successful
          run_jobs

          progress = Progress.find(response.parsed_body["id"])
          expect(progress.workflow_state).to eq "failed"
          expect(progress.results[:error]).to eq "There was an error with the criteria regeneration. Please try again later."
        end
      end
    end

    describe "End-to-end LLM criteria generation" do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)

        course_with_teacher_logged_in(active_all: true)
        @assignment = @course.assignments.create!(
          title: "Essay Assignment",
          description: "Write a well-structured argumentative essay about climate change, focusing on evidence-based reasoning and clear communication.",
          points_possible: 100
        )

        @course.enable_feature!(:enhanced_rubrics)
        @course.enable_feature!(:ai_rubrics)
      end

      it "creates rubric with LLM-generated criteria from controller to service with proper LLMResponse persistence" do
        llm_response_payload = {
          criteria: [
            {
              name: "Evidence-Based Reasoning",
              description: "Demonstrates use of credible sources and logical reasoning",
              ratings: [
                { title: "Exemplary", description: "Uses multiple credible sources with sophisticated analysis" },
                { title: "Proficient", description: "Uses credible sources with clear analysis" },
                { title: "Developing", description: "Uses some sources but analysis is limited" },
                { title: "Beginning", description: "Limited or unreliable sources used" }
              ]
            },
            {
              name: "Clear Communication",
              description: "Demonstrates clear writing and organization",
              ratings: [
                { title: "Exemplary", description: "Writing is exceptionally clear and well-organized" },
                { title: "Proficient", description: "Writing is clear with good organization" },
                { title: "Developing", description: "Writing is somewhat clear but organization needs work" },
                { title: "Beginning", description: "Writing lacks clarity and organization" }
              ]
            }
          ]
        }

        expect(CedarClient).to receive(:conversation).and_return(
          cedar_response_struct.new(response: llm_response_payload.to_json[1..])
        )

        # Record initial LLMResponse count
        initial_llm_response_count = LLMResponse.count

        # Test the controller endpoint
        post "llm_criteria",
             params: {
               course_id: @course.id,
               rubric_association: { association_type: "Assignment", association_id: @assignment.id },
               generate_options: {
                 criteria_count: 2,
                 rating_count: 4,
                 points_per_criterion: 25,
                 use_range: true,
                 additional_prompt_info: "Focus on academic writing skills",
                 grade_level: "college"
               }
             },
             format: :json

        expect(response).to be_successful
        json = response.parsed_body
        expect(json["workflow_state"]).to eq "queued"

        # Execute the background job - this is where LLMResponse gets created
        run_jobs

        # Verify Progress object completion
        progress = Progress.find(json["id"])
        expect(progress.workflow_state).to eq "completed"
        expect(progress.results).to have_key(:criteria)
        expect(progress.results[:criteria].length).to eq 2

        # Verify LLMResponse was created during job execution
        expect(LLMResponse.count).to eq(initial_llm_response_count + 1)

        # Verify LLMResponse was persisted correctly
        llm_response = LLMResponse.last
        expect(llm_response.prompt_name).to eq "rubric-create-V3"
        expect(llm_response.prompt_model_id).to eq "anthropic.claude-3-haiku-20240307-v1:0"
        expect(llm_response.associated_assignment).to eq @assignment
        expect(llm_response.user).to eq @teacher
        expect(llm_response.input_tokens).to eq 0
        expect(llm_response.output_tokens).to eq 0
        expect(llm_response.raw_response).to include("Evidence-Based Reasoning")

        # Verify generated criteria structure
        first_criterion = progress.results[:criteria].first
        expect(first_criterion[:description]).to eq "Evidence-Based Reasoning"
        expect(first_criterion[:long_description]).to eq "Demonstrates use of credible sources and logical reasoning"
        expect(first_criterion[:criterion_use_range]).to be true
        expect(first_criterion[:points]).to eq 25
        expect(first_criterion[:ratings].length).to eq 4

        # Verify ratings are properly sorted by points
        points = first_criterion[:ratings].pluck(:points)
        expect(points).to eq points.sort.reverse
      end
    end

    describe "End-to-end integration tests for llm_regenerate_criteria" do
      before do
        allow(Rails.env).to receive(:test?).and_return(true)

        course_with_teacher_logged_in(active_all: true)
        @assignment = @course.assignments.create!(
          title: "Essay Assignment",
          description: "Write a persuasive essay analyzing a contemporary social issue"
        )

        @course.enable_feature!(:enhanced_rubrics)
        @course.enable_feature!(:ai_rubrics)

        # Set up LLM config mocks for both full regeneration and single criterion regeneration
        allow(LLMConfigs).to receive(:config_for).with("rubric_regenerate_criteria").and_return(
          double("LLMConfig",
                 name: "rubric-regenerate-criteriaV2",
                 model_id: "anthropic.claude-3-haiku-20240307-v1:0",
                 generate_prompt_and_options: ["PROMPT", { temperature: 1.0 }])
        )

        allow(LLMConfigs).to receive(:config_for).with("rubric_regenerate_criterion").and_return(
          double("LLMConfig",
                 name: "rubric-regenerate-criterionV2",
                 model_id: "anthropic.claude-3-haiku-20240307-v1:0",
                 generate_prompt_and_options: ["PROMPT", { temperature: 1.0 }])
        )

        # Set up existing criteria structure for regeneration (3 criteria)
        @existing_criteria = {
          "0" => {
            id: "existing_c1",
            description: "Original Argument",
            long_description: "Presents a clear central argument",
            points: 20,
            criterion_use_range: true,
            ratings: [
              { id: "existing_r1", criterion_id: "existing_c1", description: "Excellent", long_description: "Compelling argument", points: 20 },
              { id: "existing_r2", criterion_id: "existing_c1", description: "Good", long_description: "Clear argument", points: 15 },
              { id: "existing_r3", criterion_id: "existing_c1", description: "Fair", long_description: "Basic argument", points: 10 },
              { id: "existing_r4", criterion_id: "existing_c1", description: "Poor", long_description: "Weak argument", points: 0 }
            ]
          },
          "1" => {
            id: "existing_c2",
            description: "Original Evidence",
            long_description: "Uses credible sources effectively",
            points: 15,
            criterion_use_range: true,
            ratings: [
              { id: "existing_r5", criterion_id: "existing_c2", description: "Excellent", long_description: "Multiple credible sources", points: 15 },
              { id: "existing_r6", criterion_id: "existing_c2", description: "Good", long_description: "Some credible sources", points: 10 },
              { id: "existing_r7", criterion_id: "existing_c2", description: "Fair", long_description: "Limited sources", points: 5 },
              { id: "existing_r8", criterion_id: "existing_c2", description: "Poor", long_description: "No credible sources", points: 0 }
            ]
          },
          "2" => {
            id: "_new_c_3",
            description: "Writing Mechanics",
            long_description: "Grammar and style",
            points: 25,
            criterion_use_range: true,
            ratings: [
              { id: "_new_r_9", criterion_id: "_new_c_3", description: "Excellent", long_description: "Flawless", points: 25 },
              { id: "_new_r_10", criterion_id: "_new_c_3", description: "Good", long_description: "Strong", points: 18 },
              { id: "_new_r_11", criterion_id: "_new_c_3", description: "Fair", long_description: "Generally correct", points: 10 },
              { id: "_new_r_12", criterion_id: "_new_c_3", description: "Poor", long_description: "Frequent errors", points: 0 }
            ]
          }
        }
      end

      it "regenerates entire criteria set with LLM from controller to service with proper LLMResponse persistence" do
        llm_regeneration_response = <<~TEXT
          <RUBRIC_DATA>
            criterion:existing_c1:description=Enhanced Argument Development
            criterion:existing_c1:long_description=Develops sophisticated and nuanced arguments with clear thesis
            rating:existing_r1:description=Exemplary
            rating:existing_r1:long_description=Presents exceptionally sophisticated and original arguments
            rating:existing_r2:description=Proficient
            rating:existing_r2:long_description=Develops clear and well-reasoned arguments
            rating:existing_r3:description=Developing
            rating:existing_r3:long_description=Presents basic arguments with some clarity
            rating:existing_r4:description=Beginning
            rating:existing_r4:long_description=Arguments are unclear or poorly developed

            criterion:existing_c2:description=Research Integration
            criterion:existing_c2:long_description=Effectively integrates research to support arguments
            rating:existing_r5:description=Exemplary
            rating:existing_r5:long_description=Seamlessly integrates diverse, high-quality sources
            rating:existing_r6:description=Proficient
            rating:existing_r6:long_description=Effectively uses credible sources to support points
            rating:existing_r7:description=Developing
            rating:existing_r7:long_description=Uses some sources but integration needs improvement
            rating:existing_r8:description=Beginning
            rating:existing_r8:long_description=Limited or inappropriate use of sources

            criterion:_new_c_3:description=Writing Mechanics
            criterion:_new_c_3:long_description=Demonstrates command of grammar, syntax, and style
            rating:_new_r_9:description=Exemplary
            rating:_new_r_9:long_description=Flawless grammar and sophisticated writing style
            rating:_new_r_10:description=Proficient
            rating:_new_r_10:long_description=Strong grammar and clear writing style
            rating:_new_r_11:description=Developing
            rating:_new_r_11:long_description=Generally correct grammar with some style issues
            rating:_new_r_12:description=Beginning
            rating:_new_r_12:long_description=Frequent grammar errors that impede understanding
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_regeneration_response)
        )

        # Record initial LLMResponse count
        initial_llm_response_count = LLMResponse.count

        # Test the controller endpoint for full criteria regeneration
        post "llm_regenerate_criteria",
             params: {
               course_id: @course.id,
               rubric_association: { association_type: "Assignment", association_id: @assignment.id },
               criteria: @existing_criteria,
               generate_options: { criteria_count: 3, rating_count: 4, points_per_criterion: 25, use_range: true, grade_level: "higher-ed" },
               regenerate_options: { additional_user_prompt: "Make the criteria more detailed and add writing mechanics" }
             },
             format: :json

        expect(response).to be_successful
        progress_id = response.parsed_body["id"]
        expect(progress_id).to be_present

        # Execute the background job
        run_jobs

        # Verify job completion and results
        progress = Progress.find(progress_id)
        expect(progress.workflow_state).to eq "completed"
        expect(progress.results[:criteria]).to be_present
        expect(progress.results[:criteria].length).to eq 3

        # Verify LLMResponse was created during job execution
        expect(LLMResponse.count).to eq(initial_llm_response_count + 1)

        # Verify LLMResponse was persisted correctly
        llm_response = LLMResponse.last
        expect(llm_response.prompt_name).to eq "rubric-regenerate-criteriaV2"
        expect(llm_response.prompt_model_id).to eq "anthropic.claude-3-haiku-20240307-v1:0"
        expect(llm_response.associated_assignment).to eq @assignment
        expect(llm_response.user).to eq @teacher
        expect(llm_response.input_tokens).to eq 0
        expect(llm_response.output_tokens).to eq 0
        expect(llm_response.raw_response).to include("Enhanced Argument Development")

        # Verify regenerated criteria structure preserved existing IDs and added new ones
        criteria_results = progress.results[:criteria]

        # First criterion should be updated but keep existing ID
        first_criterion = criteria_results.find { |c| c[:id] == "existing_c1" }
        expect(first_criterion).to be_present
        expect(first_criterion[:description]).to eq "Enhanced Argument Development"
        expect(first_criterion[:long_description]).to eq "Develops sophisticated and nuanced arguments with clear thesis"
        expect(first_criterion[:criterion_use_range]).to be true
        expect(first_criterion[:points]).to eq 25
        expect(first_criterion[:ratings].length).to eq 4

        # Second criterion should be updated but keep existing ID
        second_criterion = criteria_results.find { |c| c[:id] == "existing_c2" }
        expect(second_criterion).to be_present
        expect(second_criterion[:description]).to eq "Research Integration"
        expect(second_criterion[:long_description]).to eq "Effectively integrates research to support arguments"

        # Third criterion should be new with generated ID
        third_criterion = criteria_results.find { |c| c[:description] == "Writing Mechanics" }
        expect(third_criterion).to be_present
        expect(third_criterion[:id]).not_to start_with("_new_c_") # Should have real generated ID
        expect(third_criterion[:long_description]).to eq "Demonstrates command of grammar, syntax, and style"

        # Verify all ratings are properly sorted by points descending
        criteria_results.each do |criterion|
          points = criterion[:ratings].pluck(:points)
          expect(points).to eq points.sort.reverse
        end
      end

      it "regenerates single criterion with LLM while preserving other criteria" do
        llm_criterion_response = <<~TEXT
          <RUBRIC_DATA>
          criterion:existing_c1:description=Refined Argument Quality
          criterion:existing_c1:long_description=Constructs well-reasoned arguments with clear evidence
          rating:existing_r1:description=Outstanding
          rating:existing_r1:long_description=Arguments are exceptionally well-crafted and persuasive
          rating:existing_r2:description=Proficient
          rating:existing_r2:long_description=Arguments are clear and well-supported
          rating:existing_r3:description=Developing
          rating:existing_r3:long_description=Arguments show promise but need refinement
          rating:existing_r4:description=Inadequate
          rating:existing_r4:long_description=Arguments are poorly constructed or unsupported
          </RUBRIC_DATA>
        TEXT

        expect(CedarClient).to receive(:prompt).and_return(
          cedar_response_struct.new(response: llm_criterion_response)
        )

        # Record initial LLMResponse count
        initial_llm_response_count = LLMResponse.count

        # Test the controller endpoint for single criterion regeneration
        post "llm_regenerate_criteria",
             params: {
               course_id: @course.id,
               rubric_association: { association_type: "Assignment", association_id: @assignment.id },
               criteria: @existing_criteria,
               generate_options: { criteria_count: 3, rating_count: 4, points_per_criterion: 20, use_range: false },
               regenerate_options: { criterion_id: "existing_c1", standard: "Focus on logical reasoning and evidence quality" }
             },
             format: :json

        expect(response).to be_successful
        progress_id = response.parsed_body["id"]
        expect(progress_id).to be_present

        # Execute the background job
        run_jobs

        # Verify job completion and results
        progress = Progress.find(progress_id)
        expect(progress.workflow_state).to eq "completed"
        expect(progress.results[:criteria]).to be_present
        expect(progress.results[:criteria].length).to eq 3

        # Verify LLMResponse was created during job execution with single criterion config
        expect(LLMResponse.count).to eq(initial_llm_response_count + 1)

        # Verify LLMResponse was persisted correctly for single criterion regeneration
        llm_response = LLMResponse.last
        expect(llm_response.prompt_name).to eq "rubric-regenerate-criterionV2"
        expect(llm_response.prompt_model_id).to eq "anthropic.claude-3-haiku-20240307-v1:0"
        expect(llm_response.associated_assignment).to eq @assignment
        expect(llm_response.user).to eq @teacher
        expect(llm_response.input_tokens).to eq 0
        expect(llm_response.output_tokens).to eq 0
        expect(llm_response.raw_response).to include("Refined Argument Quality")

        # Verify regenerated criteria structure
        criteria_results = progress.results[:criteria]

        # First criterion should be updated
        first_criterion = criteria_results.find { |c| c[:id] == "existing_c1" }
        expect(first_criterion).to be_present
        expect(first_criterion[:description]).to eq "Refined Argument Quality"
        expect(first_criterion[:long_description]).to eq "Constructs well-reasoned arguments with clear evidence"
        expect(first_criterion[:criterion_use_range]).to be false
        expect(first_criterion[:points]).to eq 20
        expect(first_criterion[:ratings].length).to eq 4

        # Verify existing ratings were preserved and updated
        ratings = first_criterion[:ratings]
        expect(ratings.find { |r| r[:id] == "existing_r1" }[:description]).to eq "Outstanding"
        expect(ratings.find { |r| r[:id] == "existing_r2" }[:description]).to eq "Proficient"
        expect(ratings.find { |r| r[:id] == "existing_r3" }[:description]).to eq "Developing"
        expect(ratings.find { |r| r[:id] == "existing_r4" }[:description]).to eq "Inadequate"

        # Second criterion should remain unchanged
        second_criterion = criteria_results.find { |c| c[:id] == "existing_c2" }
        expect(second_criterion).to be_present
        expect(second_criterion[:description]).to eq "Original Evidence"
        expect(second_criterion[:long_description]).to eq "Uses credible sources effectively"
      end
    end
  end
end
