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
  before do
    Account.site_admin.disable_feature!(:enhanced_rubrics)
  end

  describe "GET 'index'" do
    it "requires authorization" do
      course_with_teacher(active_all: true)
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
        Account.site_admin.enable_feature!(:enhanced_rubrics)
        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be false
      end
    end

    describe "with enhanced_rubrics enabled" do
      before do
        Account.site_admin.enable_feature!(:enhanced_rubrics)
        course_with_teacher_logged_in(active_all: true)
      end

      it "can access rubrics" do
        get "index", params: { course_id: @course.id }

        expect(response).to render_template("layouts/application")
      end

      it "can access rubrics for /create route" do
        get "index", params: { course_id: "create" }

        expect(response).to render_template("layouts/application")
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
      Account.site_admin.enable_feature!(:enhanced_rubrics)
      course_with_teacher_logged_in(active_all: true)
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
      Account.site_admin.enable_feature!(:enhanced_rubrics)
      course_with_teacher_logged_in(active_all: true)
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
          Account.site_admin.enable_feature!(:enhanced_rubrics)
          get "show", params: { id: @r.id, course_id: @course.id }
          expect(assigns[:js_env][:PERMISSIONS][:manage_rubrics]).to be false
        end
      end
    end

    describe "with enhanced_rubrics enabled" do
      before do
        Account.site_admin.enable_feature!(:enhanced_rubrics)
        course_with_teacher_logged_in(active_all: true)
      end

      it "can access rubrics" do
        get "index", params: { course_id: @course.id }

        expect(response).to render_template("layouts/application")
      end
    end
  end
end
