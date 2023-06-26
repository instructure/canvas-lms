# frozen_string_literal: true

#
# Copyright (C) 2012 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe "Outcomes API", type: :request do
  def context_outcome(context)
    @outcome_group ||= context.root_outcome_group
    @outcome = context.created_learning_outcomes.create!(title: "outcome")
    @outcome_group.add_outcome(@outcome)
  end

  def course_outcome
    context_outcome(@course)
  end

  def account_outcome
    context_outcome(@account)
  end

  def outcome_json(outcome = @outcome, presets = {})
    retval = {
      "id" => presets[:id] || outcome.id,
      "context_id" => presets[:context_id] || outcome.context_id,
      "context_type" => presets[:context_type] || outcome.context_type,
      "title" => presets[:title] || outcome.title,
      "display_name" => presets[:display_name] || outcome.display_name,
      "friendly_description" => presets[:friendly_description] || nil,
      "url" => presets[:url] || api_v1_outcome_path(id: outcome.id),
      "vendor_guid" => presets[:vendor_guid] || outcome.vendor_guid,
      "can_edit" => presets[:can_edit] || true,
      "description" => presets[:description] || outcome.description,
      "assessed" => presets[:assessed] || outcome.assessed?,
      "calculation_method" => presets[:calculation_method] || outcome.calculation_method,
      "mastery_points" => outcome.mastery_points,
      "points_possible" => outcome.points_possible,
      "ratings" => outcome.rubric_criterion[:ratings].map(&:stringify_keys)
    }

    retval["has_updateable_rubrics"] = if presets[:has_updateable_rubrics].nil?
                                         outcome.updateable_rubrics?
                                       else
                                         presets[:has_updateable_rubrics]
                                       end

    if @account.feature_enabled?(:account_level_mastery_scales)
      calculation_method = OutcomeCalculationMethod.find_or_create_default!(@account)
      retval["calculation_method"] = presets[:calculation_method] || calculation_method.calculation_method
      retval["calculation_int"] = presets.key?(:calculation_int) ? presets[:calculation_int] : calculation_method.calculation_int
    elsif %w[decaying_average n_mastery].include?(retval["calculation_method"])
      retval["calculation_int"] = presets[:calculation_int] || outcome.calculation_int
    end

    if @account.feature_enabled?(:account_level_mastery_scales)
      proficiency = OutcomeProficiency.find_or_create_default!(@account)
      retval["points_possible"] = presets[:points_possible] || proficiency.points_possible
      retval["mastery_points"]  = presets[:mastery_points]  || proficiency.mastery_points
      retval["ratings"]         = presets[:ratings]         || proficiency.ratings_hash.map(&:stringify_keys)
    elsif (criterion = outcome.data && outcome.data[:rubric_criterion])
      retval["points_possible"] = presets[:points_possible] || criterion[:points_possible].to_i
      retval["mastery_points"]  = presets[:mastery_points]  || criterion[:mastery_points].to_i
      retval["ratings"]         = presets[:ratings]         || criterion[:ratings].map(&:stringify_keys)
    end

    retval
  end

  def assess_outcome(outcome = @outcome, assess = true)
    @rubric = Rubric.create!(context: @course)
    @rubric.data = [
      {
        points: 3,
        description: "Outcome row",
        id: 1,
        ratings: [
          {
            points: 3,
            description: "Rockin'",
            criterion_id: 1,
            id: 2
          },
          {
            points: 0,
            description: "Lame",
            criterion_id: 1,
            id: 3
          }
        ],
        learning_outcome_id: outcome.id
      }
    ]
    @rubric.save!
    return unless assess

    @e = @course.enroll_student(@student)
    @a = @rubric.associate_with(@assignment, @course, purpose: "grading")
    @assignment.reload
    @submission = @assignment.grade_student(@student, grade: "10", grader: @teacher).first
    @assessment = @a.assess({
                              user: @student,
                              assessor: @teacher,
                              artifact: @submission,
                              assessment: {
                                assessment_type: "grading",
                                criterion_1: {
                                  points: 2,
                                  comments: "cool, yo"
                                }
                              }
                            })
    @result = outcome.learning_outcome_results.first
    @assessment = @a.assess({
                              user: @student,
                              assessor: @teacher,
                              artifact: @submission,
                              assessment: {
                                assessment_type: "grading",
                                criterion_1: {
                                  points: 3,
                                  comments: "cool, yo"
                                }
                              }
                            })
    @result.reload
    @rubric.reload
  end

  def outcomes_json(outcomes = @outcomes, _presets = {})
    outcomes.map { |o| outcome_json(o) }
  end

  let(:calc_method_no_int) { %w[highest latest average] }

  context "account outcomes" do
    before :once do
      user_with_pseudonym(active_all: true)
      @account = Account.default
      @account_user = @user.account_users.create(account: @account)
      @outcome = @account.created_learning_outcomes.create!(
        title: "My Outcome",
        description: "Description of my outcome",
        vendor_guid: "vendorguid9000"
      )
    end

    def revoke_permission(account_user, permission)
      RoleOverride.manage_role_override(account_user.account, account_user.role, permission.to_s, override: false)
    end

    describe "show" do
      it "does not require manage permission" do
        revoke_permission(@account_user, :manage_outcomes)
        raw_api_call(:get,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "show",
                     id: @outcome.id.to_s,
                     format: "json")
        expect(response).to be_successful
      end

      it "requires read permission" do
        # new user, doesn't have a tie to the account
        user_with_pseudonym(account: Account.create!, active_all: true)
        allow_any_instantiation_of(@pseudonym).to receive(:works_for_account?).and_return(true)
        raw_api_call(:get,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "show",
                     id: @outcome.id.to_s,
                     format: "json")
        assert_status(401)
      end

      it "does not require any permission for global outcomes" do
        user_with_pseudonym(account: Account.create!, active_all: true)
        @outcome = LearningOutcome.create!(title: "My Outcome")
        raw_api_call(:get,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "show",
                     id: @outcome.id.to_s,
                     format: "json")
        expect(response).to be_successful
      end

      it "still requires a user for global outcomes" do
        @outcome = LearningOutcome.create!(title: "My Outcome")
        @user = nil
        raw_api_call(:get,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "show",
                     id: @outcome.id.to_s,
                     format: "json")
        assert_status(401)
      end

      it "404s for deleted outcomes" do
        @outcome.destroy
        raw_api_call(:get,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "show",
                     id: @outcome.id.to_s,
                     format: "json")
        assert_status(404)
      end

      it "returns the outcome json" do
        json = api_call(:get,
                        "/api/v1/outcomes/#{@outcome.id}",
                        controller: "outcomes_api",
                        action: "show",
                        id: @outcome.id.to_s,
                        format: "json")
        expect(json).to eq({
                             "id" => @outcome.id,
                             "context_id" => @account.id,
                             "context_type" => "Account",
                             "calculation_int" => 65,
                             "calculation_method" => "decaying_average",
                             "title" => @outcome.title,
                             "display_name" => nil,
                             "friendly_description" => nil,
                             "url" => api_v1_outcome_path(id: @outcome.id),
                             "vendor_guid" => "vendorguid9000",
                             "can_edit" => true,
                             "has_updateable_rubrics" => false,
                             "description" => @outcome.description,
                             "assessed" => false,
                             "mastery_points" => @outcome.mastery_points,
                             "points_possible" => @outcome.points_possible,
                             "ratings" => @outcome.rubric_criterion[:ratings].map(&:stringify_keys)
                           })
      end

      it "includes criterion if it has one" do
        criterion = {
          mastery_points: 3,
          ratings: [
            { points: 5, description: "Exceeds Expectations" },
            { points: 3, description: "Meets Expectations" },
            { points: 0, description: "Does Not Meet Expectations" }
          ]
        }
        @outcome.rubric_criterion = criterion
        @outcome.save!

        json = api_call(:get,
                        "/api/v1/outcomes/#{@outcome.id}",
                        controller: "outcomes_api",
                        action: "show",
                        id: @outcome.id.to_s,
                        format: "json")

        expect(json).to eq({
                             "id" => @outcome.id,
                             "context_id" => @account.id,
                             "context_type" => "Account",
                             "title" => @outcome.title,
                             "display_name" => nil,
                             "friendly_description" => nil,
                             "url" => api_v1_outcome_path(id: @outcome.id),
                             "vendor_guid" => "vendorguid9000",
                             "can_edit" => true,
                             "has_updateable_rubrics" => false,
                             "description" => @outcome.description,
                             "points_possible" => 5,
                             "mastery_points" => 3,
                             "calculation_int" => 65,
                             "calculation_method" => "decaying_average",
                             "assessed" => false,
                             "ratings" => @outcome.rubric_criterion[:ratings].map(&:stringify_keys)
                           })
      end

      it "reports calculation methods that are nil as highest so old outcomes continue to behave the same before we added a calculation_method" do
        criterion = {
          mastery_points: 3,
          ratings: [
            { points: 5, description: "Exceeds Expectations" },
            { points: 3, description: "Meets Expectations" },
            { points: 0, description: "Does Not Meet Expectations" }
          ]
        }

        @outcome.rubric_criterion = criterion
        @outcome.save!

        # The order here is intentional.  We don't want to trigger the before_save callback on LearningOutcome
        # because it will take away our nil calculation_method.  The nil is required in order to
        # simulate pre-existing learning outcome records that have nil calculation_methods
        @outcome.update_column(:calculation_method, nil)

        json = api_call(:get,
                        "/api/v1/outcomes/#{@outcome.id}",
                        controller: "outcomes_api",
                        action: "show",
                        id: @outcome.id.to_s,
                        format: "json")
        expect(json).to eq(outcome_json(@outcome, { calculation_method: "highest", can_edit: true }))
      end

      it "reports as assessed if assessments exist in any aligned course" do
        course_with_teacher(active_all: true)
        student_in_course(active_all: true)
        assignment_model({ course: @course })
        assess_outcome(@outcome)
        raw_api_call(:get,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "show",
                     id: @outcome.id.to_s,
                     format: "json")
        json = controller.outcome_json(@outcome, @account_user.user, session, { assessed_outcomes: [@outcome] })
        expect(json["assessed"]).to be true
      end

      describe "with the account_level_mastery_scales FF" do
        describe "enabled" do
          before :once do
            @account.enable_feature!(:account_level_mastery_scales)
          end

          describe "within the account context" do
            it "returns the account's mastery scale and calculation_method" do
              proficiency = outcome_proficiency_model(@account)
              method = outcome_calculation_method_model(@account)
              raw_api_call(
                :get,
                "/api/v1/outcomes/#{@outcome.id}",
                controller: "outcomes_api",
                action: "show",
                id: @outcome.id.to_s,
                format: "json"
              )
              json = controller.outcome_json(@outcome, @account_user.user, session, { context: @account })
              expect(json).to eq(outcome_json(@outcome, {
                                                points_possible: proficiency.points_possible,
                                                mastery_points: proficiency.mastery_points,
                                                ratings: proficiency.ratings_hash.map(&:stringify_keys),
                                                calculation_method: method.calculation_method,
                                                calculation_int: method.calculation_int,
                                              }))
            end

            it "returns the default outcome_proficiency and calculation_method if neither exists" do
              raw_api_call(
                :get,
                "/api/v1/outcomes/#{@outcome.id}",
                controller: "outcomes_api",
                action: "show",
                id: @outcome.id.to_s,
                format: "json"
              )
              json = controller.outcome_json(@outcome, @account_user.user, session, { context: @account })
              proficiency = OutcomeProficiency.find_or_create_default!(@account)
              method = OutcomeCalculationMethod.find_or_create_default!(@account)
              expect(json).to eq(outcome_json(@outcome, {
                                                points_possible: proficiency.points_possible,
                                                mastery_points: proficiency.mastery_points,
                                                ratings: proficiency.ratings_hash.map(&:stringify_keys),
                                                calculation_method: method.calculation_method,
                                                calculation_int: method.calculation_int,
                                              }))
            end
          end

          describe "with no context provided" do
            it "does not return mastery scale data" do
              raw_api_call(
                :get,
                "/api/v1/outcomes/#{@outcome.id}",
                controller: "outcomes_api",
                action: "show",
                id: @outcome.id.to_s,
                format: "json"
              )
              json = controller.outcome_json(@outcome, @account_user.user, session)
              %w[points_possible mastery_points ratings calculation_method calculation_int].each do |key|
                expect(json).not_to have_key(key)
              end
            end
          end
        end

        describe "disabled" do
          it "ignores the outcome_proficiency and calculation_method values if one exists" do
            outcome_calculation_method_model(@account)
            outcome_proficiency_model(@account)
            json = api_call(:get,
                            "/api/v1/outcomes/#{@outcome.id}",
                            controller: "outcomes_api",
                            action: "show",
                            id: @outcome.id.to_s,
                            format: "json")
            expect(json).to eq(outcome_json(@outcome))
          end
        end
      end
    end

    describe "update" do
      it "requires manage permission" do
        revoke_permission(@account_user, :manage_outcomes)
        raw_api_call(:put,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json")
        assert_status(401)
      end

      it "requires manage_global_outcomes permission for global outcomes" do
        @account_user = @user.account_users.create(account: Account.site_admin)
        @outcome = LearningOutcome.global.create!(title: "global")
        revoke_permission(@account_user, :manage_global_outcomes)
        raw_api_call(:put,
                     "/api/v1/outcomes/#{@outcome.id}",
                     controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json")
        assert_status(401)
      end

      it "fails (400) if the outcome is invalid" do
        too_long_description = ([0] * (ActiveRecord::Base.maximum_text_length + 1)).join
        raw_api_call(:put,
                     "/api/v1/outcomes/#{@outcome.id}",
                     { controller: "outcomes_api",
                       action: "update",
                       id: @outcome.id.to_s,
                       format: "json" },
                     { title: "Updated Outcome",
                       description: too_long_description,
                       mastery_points: 5,
                       ratings: [
                         { points: 10, description: "Exceeds Expectations" },
                         { points: 5, description: "Meets Expectations" },
                         { points: 0, description: "Does Not Meet Expectations" }
                       ] })
        assert_status(400)
      end

      it "updates the outcome" do
        api_call(:put,
                 "/api/v1/outcomes/#{@outcome.id}",
                 { controller: "outcomes_api",
                   action: "update",
                   id: @outcome.id.to_s,
                   format: "json" },
                 { title: "Updated Outcome",
                   description: "Description of updated outcome",
                   mastery_points: 5,
                   ratings: [
                     { points: 10, description: "Exceeds Expectations" },
                     { points: 5, description: "Meets Expectations" },
                     { points: 0, description: "Does Not Meet Expectations" }
                   ] })
        @outcome.reload
        expect(@outcome.title).to eq "Updated Outcome"
        expect(@outcome.description).to eq "Description of updated outcome"
        expect(@outcome.data[:rubric_criterion]).to eq({
                                                         description: "Updated Outcome",
                                                         mastery_points: 5,
                                                         points_possible: 10,
                                                         ratings: [
                                                           { points: 10, description: "Exceeds Expectations" },
                                                           { points: 5, description: "Meets Expectations" },
                                                           { points: 0, description: "Does Not Meet Expectations" }
                                                         ]
                                                       })
      end

      it "leaves alone fields not provided" do
        api_call(:put,
                 "/api/v1/outcomes/#{@outcome.id}",
                 { controller: "outcomes_api",
                   action: "update",
                   id: @outcome.id.to_s,
                   format: "json" },
                 { title: "New Title" })

        @outcome.reload
        expect(@outcome.title).to eq "New Title"
        expect(@outcome.description).to eq "Description of my outcome"
      end

      it "returns the updated outcome json" do
        json = api_call(:put,
                        "/api/v1/outcomes/#{@outcome.id}",
                        { controller: "outcomes_api",
                          action: "update",
                          id: @outcome.id.to_s,
                          format: "json" },
                        { title: "New Title",
                          description: "New Description",
                          vendor_guid: "vendorguid9000" })

        expect(json).to eq({
                             "id" => @outcome.id,
                             "context_id" => @account.id,
                             "context_type" => "Account",
                             "calculation_int" => 65,
                             "calculation_method" => "decaying_average",
                             "vendor_guid" => "vendorguid9000",
                             "title" => "New Title",
                             "display_name" => nil,
                             "friendly_description" => nil,
                             "url" => api_v1_outcome_path(id: @outcome.id),
                             "can_edit" => true,
                             "has_updateable_rubrics" => false,
                             "description" => "New Description",
                             "assessed" => false,
                             "mastery_points" => @outcome.mastery_points,
                             "points_possible" => @outcome.points_possible,
                             "ratings" => @outcome.rubric_criterion[:ratings].map(&:stringify_keys)
                           })
      end

      context "calculation options" do
        before :once do
          # set criterion so we get back our calculation_method
          criterion = {
            mastery_points: 3,
            ratings: [
              { points: 5, description: "Exceeds Expectations" },
              { points: 3, description: "Meets Expectations" },
              { points: 0, description: "Does Not Meet Expectations" }
            ]
          }
          @outcome.rubric_criterion = criterion
          @outcome.save!
        end

        it "allows updating calculation method" do
          # Check pre-condition to make sure we're really updating with our API call
          expect(@outcome.calculation_method).not_to eq("n_mastery")

          json = api_call(:put,
                          "/api/v1/outcomes/#{@outcome.id}",
                          { controller: "outcomes_api",
                            action: "update",
                            id: @outcome.id.to_s,
                            format: "json" },
                          { title: "New Title",
                            description: "New Description",
                            vendor_guid: "vendorguid9000",
                            calculation_method: "n_mastery",
                            calculation_int: "3" })
          @outcome.reload
          expect(json).to eq(outcome_json)
          expect(@outcome.calculation_method).to eq("n_mastery")
        end

        it "allows updating the calculation int" do
          # Check pre-condition to make sure we're really updating with our API call
          expect(@outcome.calculation_int).not_to eq(3)

          json = api_call(:put,
                          "/api/v1/outcomes/#{@outcome.id}",
                          { controller: "outcomes_api",
                            action: "update",
                            id: @outcome.id.to_s,
                            format: "json" },
                          { title: "New Title",
                            description: "New Description",
                            vendor_guid: "vendorguid9000",
                            calculation_method: "n_mastery",
                            calculation_int: 3 })

          expect(json["calculation_int"]).to be(3)
          expect(json["calculation_method"]).to eql("n_mastery")

          @outcome.reload
          expect(json).to eq(outcome_json)
          expect(@outcome.calculation_method).to eql("n_mastery")
          expect(@outcome.calculation_int).to be(3)
        end

        context "should not allow updating the calculation_int to an illegal value for the calculation_method" do
          before :once do
            # outcome calculation_method needs to be something not used as a test case
            @outcome.calculation_method = "decaying_average"
            @outcome.calculation_int = 75
            @outcome.save!
          end

          method_to_int = {
            "decaying_average" => { good: 67, bad: 125 },
            "n_mastery" => { good: 7, bad: 11 },
            "highest" => { good: nil, bad: 4 },
            "latest" => { good: nil, bad: 79 },
            "average" => { good: nil, bad: 59 },
          }

          method_to_int.each do |method, int|
            it "does not allow updating the calculation_int to an illegal value for the calculation_method '#{method}'" do
              expect do
                api_call(:put,
                         "/api/v1/outcomes/#{@outcome.id}",
                         { controller: "outcomes_api",
                           action: "update",
                           id: @outcome.id.to_s,
                           format: "json" },
                         { title: "New Title",
                           description: "New Description",
                           vendor_guid: "vendorguid9000",
                           calculation_method: method,
                           calculation_int: int[:good] })
                @outcome.reload
              end.to change { @outcome.calculation_int }.to(int[:good])

              expect do
                api_call(:put,
                         "/api/v1/outcomes/#{@outcome.id}",
                         { controller: "outcomes_api",
                           action: "update",
                           id: @outcome.id.to_s,
                           format: "json" },
                         { title: "New Title",
                           description: "New Description",
                           vendor_guid: "vendorguid9000",
                           calculation_method: method,
                           calculation_int: int[:bad] },
                         {},
                         { expected_status: 400 })
                @outcome.reload
              end.to_not change { @outcome.calculation_int }

              expect(@outcome.calculation_method).to eql(method)
            end
          end
        end

        it "sets a default calculation_method of 'decaying_average' if the record is being re-saved (previously created)" do
          # The order here is intentional.  We don't want to trigger any callbacks on LearningOutcome
          # because it will take away our nil calculation_method.  The nil is required in order to
          # simulate pre-existing learning outcome records that have nil calculation_methods
          @outcome.update_column(:calculation_method, nil)

          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { title: "New Title",
                     description: "New Description",
                     vendor_guid: "vendorguid9000",
                     calculation_method: nil })

          @outcome.reload
          expect(@outcome.calculation_method).to eq("decaying_average")
        end

        it "returns a sensible error message for an incorrect calculation_method" do
          bad_calc_method = "foo bar baz quz"
          expect(@outcome.calculation_method).not_to eq(bad_calc_method)

          json = api_call(:put,
                          "/api/v1/outcomes/#{@outcome.id}",
                          { controller: "outcomes_api",
                            action: "update",
                            id: @outcome.id.to_s,
                            format: "json" },
                          { title: "New Title",
                            description: "New Description",
                            vendor_guid: "vendorguid9000",
                            calculation_method: bad_calc_method,
                            calculation_int: "3" },
                          {}, # Empty headers dict
                          { expected_status: 400 })

          @outcome.reload
          expect(json).not_to eq(outcome_json)
          expect(@outcome.calculation_method).not_to eq(bad_calc_method)
          expect(json["errors"]).not_to be_nil
          expect(json["errors"]["calculation_method"]).not_to be_nil
          # make sure there's no errors except on calculation_method
          expect(json["errors"].except("calculation_method")).to be_empty
          expect(json["errors"]["calculation_method"][0]["message"]).to include("calculation_method must be one of")
        end

        context "sensible error message for an incorrect calculation_int" do
          method_to_int = {
            "decaying_average" => 77,
            "n_mastery" => 4,
            "highest" => nil,
            "latest" => nil,
            "average" => nil,
          }
          norm_error_message = "not a valid value for this calculation method"
          no_calc_int_error_message = "A calculation value is not used with this calculation method"
          bad_calc_int = 1500

          method_to_int.each do |method, int|
            it "returns a sensible error message for an incorrect calculation_int when calculation_method is #{method}" do
              @outcome.calculation_method = method
              @outcome.calculation_int = int
              @outcome.save!
              @outcome.reload
              expect(@outcome.calculation_method).to eq(method)
              expect(@outcome.calculation_int).to eq(int)

              json = api_call(:put,
                              "/api/v1/outcomes/#{@outcome.id}",
                              { controller: "outcomes_api",
                                action: "update",
                                id: @outcome.id.to_s,
                                format: "json" },
                              { title: "New Title",
                                description: "New Description",
                                vendor_guid: "vendorguid9000",
                                # :calculation_method => bad_calc_method,
                                calculation_int: bad_calc_int },
                              {}, # Empty headers dict
                              { expected_status: 400 })

              @outcome.reload
              expect(json).not_to eq(outcome_json)
              expect(@outcome.calculation_method).to eq(method)
              expect(@outcome.calculation_int).to eq(int)
              expect(json["errors"]).not_to be_nil
              expect(json["errors"]["calculation_int"]).not_to be_nil
              # make sure there's no errors except on calculation_method
              expect(json["errors"].except("calculation_int")).to be_empty
              if calc_method_no_int.include?(method)
                expect(json["errors"]["calculation_int"][0]["message"]).to include(no_calc_int_error_message)
              else
                expect(json["errors"]["calculation_int"][0]["message"]).to include(norm_error_message)
              end
            end
          end
        end
      end

      context "with account_level_mastery_scales enabled" do
        before do
          @outcome.context.root_account.set_feature_flag!(:account_level_mastery_scales, "on")
        end

        it "fails when updating mastery points" do
          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { mastery_points: 5 })
          assert_forbidden
          expect(JSON.parse(response.body)["error"]).to eq "Individual outcome mastery points cannot be modified."
        end

        it "fails when updating ratings" do
          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { ratings: [
                     { points: 10, description: "Exceeds Expectations" },
                     { points: 5, description: "Meets Expectations" },
                     { points: 0, description: "Does Not Meet Expectations" }
                   ] })
          assert_forbidden
          expect(JSON.parse(response.body)["error"]).to eq "Individual outcome ratings cannot be modified."
        end

        it "fails when updating calculation values" do
          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { calculation_method: "decaying_average",
                     calculation_int: 65 })
          assert_forbidden
          expect(JSON.parse(response.body)["error"]).to eq "Individual outcome calculation values cannot be modified."
        end
      end
    end

    context "with the outcomes_new_decaying_average_calculation FF enabled" do
      before :once do
        @account.enable_feature!(:outcomes_new_decaying_average_calculation)
      end

      describe "show" do
        it "returns the outcome json" do
          json = api_call(:get,
                          "/api/v1/outcomes/#{@outcome.id}",
                          controller: "outcomes_api",
                          action: "show",
                          id: @outcome.id.to_s,
                          format: "json")
          expect(json).to eq({
                               "id" => @outcome.id,
                               "context_id" => @account.id,
                               "context_type" => "Account",
                               "calculation_int" => 65,
                               "calculation_method" => "decaying_average",
                               "title" => @outcome.title,
                               "display_name" => nil,
                               "friendly_description" => nil,
                               "url" => api_v1_outcome_path(id: @outcome.id),
                               "vendor_guid" => "vendorguid9000",
                               "can_edit" => true,
                               "has_updateable_rubrics" => false,
                               "description" => @outcome.description,
                               "assessed" => false,
                               "mastery_points" => @outcome.mastery_points,
                               "points_possible" => @outcome.points_possible,
                               "ratings" => @outcome.rubric_criterion[:ratings].map(&:stringify_keys)
                             })
        end

        it "returns updated calculation_method name" do
          @outcome.calculation_method = "standard_decaying_average"
          @outcome.save!

          expect(@outcome.calculation_method).to eq("standard_decaying_average")
          json = api_call(:get,
                          "/api/v1/outcomes/#{@outcome.id}",
                          controller: "outcomes_api",
                          action: "show",
                          id: @outcome.id.to_s,
                          format: "json")
          expect(json["calculation_method"]).to eq("standard_decaying_average")
        end
      end

      describe "update" do
        it "updates the outcome" do
          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { title: "Updated Outcome",
                     description: "Description of updated outcome",
                     mastery_points: 5,
                     ratings: [
                       { points: 10, description: "Exceeds Expectations" },
                       { points: 5, description: "Meets Expectations" },
                       { points: 0, description: "Does Not Meet Expectations" }
                     ] })
          @outcome.reload
          expect(@outcome.title).to eq "Updated Outcome"
          expect(@outcome.description).to eq "Description of updated outcome"
          expect(@outcome.data[:rubric_criterion]).to eq({
                                                           description: "Updated Outcome",
                                                           mastery_points: 5,
                                                           points_possible: 10,
                                                           ratings: [
                                                             { points: 10, description: "Exceeds Expectations" },
                                                             { points: 5, description: "Meets Expectations" },
                                                             { points: 0, description: "Does Not Meet Expectations" }
                                                           ]
                                                         })
        end

        it "calculation_method to decaying_average" do
          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { calculation_method: "decaying_average",
                     calculation_int: 70 })

          @outcome.reload
          expect(@outcome.calculation_method).to eq "decaying_average"
          expect(@outcome.calculation_int).to eq(70)
        end

        it "calculation_method to standard_decaying_average" do
          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { calculation_method: "standard_decaying_average",
                     calculation_int: 75 })

          @outcome.reload
          expect(@outcome.calculation_method).to eq "standard_decaying_average"
          expect(@outcome.calculation_int).to eq(75)
        end

        it "calculation_method to weighted_average will translate to decaying_average" do
          api_call(:put,
                   "/api/v1/outcomes/#{@outcome.id}",
                   { controller: "outcomes_api",
                     action: "update",
                     id: @outcome.id.to_s,
                     format: "json" },
                   { calculation_method: "weighted_average",
                     calculation_int: 75 })

          @outcome.reload
          expect(@outcome.calculation_method).to eq "decaying_average"
          expect(@outcome.calculation_int).to eq(75)
        end
      end
    end
  end

  context "course outcomes" do
    before :once do
      user_with_pseudonym(active_all: true)
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      assignment_model({ course: @course })
      @account = Account.default
      account_admin_user
      @outcome = @course.created_learning_outcomes.create!(
        title: "My Outcome",
        description: "Description of my outcome",
        vendor_guid: "vendorguid9000"
      )
    end

    describe "show" do
      context "properly reports whether it has been assessed" do
        it "reports not being assessed" do
          json = api_call(:get,
                          "/api/v1/outcomes/#{@outcome.id}",
                          controller: "outcomes_api",
                          action: "show",
                          id: @outcome.id.to_s,
                          format: "json")
          expect(json).to eq(outcome_json(@outcome, { assessed: false }))
        end

        it "reports being assessed" do
          assess_outcome(@outcome)
          json = api_call(:get,
                          "/api/v1/outcomes/#{@outcome.id}",
                          controller: "outcomes_api",
                          action: "show",
                          id: @outcome.id.to_s,
                          format: "json")
          expect(json).to eq(outcome_json(@outcome, { assessed: true }))
        end
      end

      context "properly reports whether it has updateable rubrics" do
        it "reports with no updateable rubrics" do
          assess_outcome(@outcome)
          json = api_call(:get,
                          "/api/v1/outcomes/#{@outcome.id}",
                          controller: "outcomes_api",
                          action: "show",
                          id: @outcome.id.to_s,
                          format: "json")
          expect(json).to eq(outcome_json(@outcome, { has_updateable_rubrics: false }))
        end

        it "reports with updateable rubrics" do
          assess_outcome(@outcome, false)
          json = api_call(:get,
                          "/api/v1/outcomes/#{@outcome.id}",
                          controller: "outcomes_api",
                          action: "show",
                          id: @outcome.id.to_s,
                          format: "json")
          expect(json).to eq(outcome_json(@outcome, { has_updateable_rubrics: true }))
        end
      end
    end

    describe "unpublished assignments and quizzes" do
      before :once do
        student_in_course(active_all: true)
        observer_in_course(active_all: true).tap do |enrollment|
          enrollment.update_attribute(:associated_user_id, @student.id)
        end
        @assignment = assignment_model({ course: @course })
        @assignment.unpublish
        outcome_with_rubric
        @rubric.associate_with(@assignment, @course, purpose: "grading")
        quiz_with_submission(true, true)
        @quiz.unpublish!
        bank = @quiz.quiz_questions[0].assessment_question.assessment_question_bank
        @outcome.align(bank, @course, mastery_score: 6.0)
      end

      it "does not allow student to return aligned assignments" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        student_id: @student.id.to_s,
                        format: "json")
        expect(json.pluck("assignment_id").sort).to eq([])
      end

      it "allows teacher to return aligned assignments for a student" do
        @user = @teacher
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        student_id: @student.id.to_s,
                        format: "json")
        expect(json.pluck("assignment_id").sort).to eq([@assignment.id, @quiz.assignment_id].sort)
      end
    end

    describe "alignments_for_student" do
      before :once do
        student_in_course(active_all: true)
        observer_in_course(active_all: true).tap do |enrollment|
          enrollment.update_attribute(:associated_user_id, @student.id)
        end
        @assignment1 = assignment_model({ course: @course })
        @assignment2 = assignment_model({ course: @course })
        outcome_with_rubric
        @rubric.associate_with(@assignment1, @course, purpose: "grading")
        @rubric.associate_with(@assignment2, @course, purpose: "grading")
        quiz_with_submission
        bank = @quiz.quiz_questions[0].assessment_question.assessment_question_bank
        @outcome.align(bank, @course, mastery_score: 6.0)
        @live_assessment = LiveAssessments::Assessment.create!(
          key: "live_assess",
          title: "MagicMarker",
          context: @course
        )
        @outcome.align(@live_assessment, @course)
        LiveAssessments::Result.create!(
          user: @student,
          assessor_id: @teacher.id,
          assessment_id: @live_assessment.id,
          passed: true,
          assessed_at: Time.zone.now
        )
        @live_assessment.generate_submissions_for([@student])
      end

      it "returns aligned assignments and assessments for a student" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        student_id: @student.id.to_s,
                        format: "json")
        expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id].sort)
        expect(json.filter_map { |j| j["assessment_id"] }.sort).to eq([@live_assessment.id].sort)
      end

      it "allows teacher to return aligned assignments for a student" do
        @user = @teacher
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        student_id: @student.id.to_s,
                        format: "json")
        expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id].sort)
      end

      it "allows observer to return aligned assignments for a student" do
        @user = @observer
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        student_id: @student.id.to_s,
                        format: "json")
        expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id].sort)
      end

      it "does not return outcomes aligned to quizzes in other courses" do
        course = Course.create!(account: @account, name: "2nd course")
        outcome = course.created_learning_outcomes.create!(valid_outcome_attributes)
        quiz = generate_quiz(course)
        bank = quiz.quiz_questions[0].assessment_question.assessment_question_bank
        outcome.align(bank, course)
        generate_quiz_submission(quiz, student: @student)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        student_id: @student.id.to_s,
                        format: "json")
        expect(json.pluck("learning_outcome_id").uniq).to eq([@outcome.id])
      end

      it "does not return assignments that a student does not have visibility for" do
        assignment_model({ course: @course, only_visible_to_overrides: true })
        section = @course.course_sections.create!(name: "test section")
        create_section_override_for_assignment(@assignment, course_section: section)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        student_id: @student.id.to_s,
                        format: "json")
        expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id].sort)
      end

      it "requires a student_id to be present" do
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/outcome_alignments",
                        controller: "outcomes_api",
                        action: "outcome_alignments",
                        course_id: @course.id.to_s,
                        format: "json")
        expect(json["message"]).to eq("student_id is required")
      end

      describe "#find_outcomes_service_assignment_alignments" do
        def mock_get_outcome_alignments(outcome, artifact_type, artifact_id, alignments, associated_asset_id, associated_asset_type)
          if alignments.nil?
            alignments = [
              {
                id: 30,
                artifact_type:,
                artifact_id:,
                alignment_set_id: 36,
                aligned_at: "2022-11-03T15:37:19.343Z",
                created_at: "2022-11-03T15:35:53.240Z",
                updated_at: "2022-11-03T15:37:25.566Z",
                deleted_at: nil,
                context_id: nil,
                associated_asset_id:,
                associated_asset_type:
              }
            ]
          end

          {
            id: "12",
            guid: nil,
            group: false,
            label: "",
            title: "Outcome title",
            description: "",
            external_id: outcome.id,
            alignments:
          }
        end

        def mock_get_lmgb_results(student, outcome, artifact_type, artifact_id, metadata, associated_asset_id, associated_asset_type)
          if metadata.nil?
            metadata = {
              quiz_metadata: {
                quiz_id: "1",
                title: "Quiz title",
                points_possible: 1.0,
                points: 1.0
              },
              question_metadata: [{
                quiz_item_id: "1",
                title: "Question title",
                points_possible: 1.0,
                points: 1.0
              }]
            }
          end

          {
            user_uuid: student.uuid,
            percent_score: 1.0,
            points: 1.0,
            points_possible: 1.0,
            external_outcome_id: outcome.id,
            submitted_at: "2022-09-16T04:17:11.637Z",
            attempts: [{
              id: 1,
              authoritative_result_id: 1,
              points: 1.0,
              points_possible: 1.0,
              event_created_at: "2022-09-16T04:17:11.637Z",
              event_updated_at: "2022-09-16T04:17:11.637Z",
              deleted_at: nil,
              created_at: "2022-09-16T04:17:18.153Z",
              updated_at: "2022-09-16T04:17:18.153Z",
              submitted_at: "2022-09-16T04:17:18.153Z",
              metadata:
            }],
            associated_asset_type:,
            associated_asset_id:,
            artifact_type:,
            artifact_id:,
            mastery: nil
          }
        end

        it "returns empty array for alignments when FF is disabled" do
          @course.disable_feature!(:outcome_service_results_to_canvas)
          expect_any_instance_of(OutcomesApiController).to receive(:find_outcomes_service_assignment_alignments).with(any_args).and_return([])
          json = api_call(:get,
                          "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                          controller: "outcomes_api",
                          action: "outcome_alignments",
                          course_id: @course.id.to_s,
                          student_id: @student.id.to_s,
                          format: "json")
          expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id].sort)
        end

        context "outcome_service_results_to_canvas FF is enabled" do
          before do
            @course.enable_feature!(:outcome_service_results_to_canvas)
          end

          describe "returns empty array" do
            it "no alignments found in os" do
              # returns empty array for both os calls
              expect_any_instance_of(OutcomesApiController).to receive(:get_lmgb_results).with(any_args).and_return([])
              expect_any_instance_of(OutcomesApiController).to receive(:get_outcome_alignments).with(any_args).and_return([])
              json = api_call(:get,
                              "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                              controller: "outcomes_api",
                              action: "outcome_alignments",
                              course_id: @course.id.to_s,
                              student_id: @student.id.to_s,
                              format: "json")
              expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id].sort)
            end

            describe "has alignments but not asset information" do
              it "asset info is nil in os outcome alignment & os results" do
                # both calls return nil for associated asset id & type
                expect_any_instance_of(OutcomesApiController).to receive(:get_lmgb_results).with(any_args).and_return(
                  [mock_get_lmgb_results(@student, @outcome, "quizzes.quiz", "1", nil, nil, nil)]
                )
                expect_any_instance_of(OutcomesApiController).to receive(:get_outcome_alignments).with(any_args).and_return(
                  [mock_get_outcome_alignments(@outcome, "quizzes.quiz", "1", nil, nil, nil)]
                )
                json = api_call(:get,
                                "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                                controller: "outcomes_api",
                                action: "outcome_alignments",
                                course_id: @course.id.to_s,
                                student_id: @student.id.to_s,
                                format: "json")
                expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id].sort)
              end
            end
          end

          describe "aligning asset information found in os outcome alignment" do
            # right now quizzes are the only one that will have asset alignment
            # once item banks and item alignment issues are solved, this will need
            # to be revisited
            it "returns new quiz alignment" do
              # only need to call alignment mock and return new quiz in alignments
              new_quiz = new_quizzes_assignment(course: @course, title: "New Quiz")
              expect_any_instance_of(OutcomesApiController).to receive(:get_outcome_alignments).with(any_args).and_return(
                [mock_get_outcome_alignments(@outcome, "quizzes.quiz", "1", nil, new_quiz.id, "canvas.assignment.quizzes")]
              )
              expect_any_instance_of(OutcomesApiController).to receive(:get_lmgb_results).with(any_args).and_return(
                []
              )
              json = api_call(:get,
                              "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                              controller: "outcomes_api",
                              action: "outcome_alignments",
                              course_id: @course.id.to_s,
                              student_id: @student.id.to_s,
                              format: "json")
              expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id, new_quiz.id].sort)
            end
          end

          describe "finds asset info from get_lmgb_results results when outcome alignment is missing asset info" do
            it "returns quiz alignment for question" do
              # mock alignment with question as the artifact type and id
              # mock results with the attempt question metadata matching the alignment artifact type and id
              new_quiz = new_quizzes_assignment(course: @course, title: "New Quiz")

              # student, outcome, artifact_type, artifact_id, metadata, associated_asset_id, associated_asset_type
              expect_any_instance_of(OutcomesApiController).to receive(:get_lmgb_results).with(any_args).and_return(
                [mock_get_lmgb_results(@student, @outcome, "quizzes.quiz", "1", nil, new_quiz.id, "canvas.assignment.quizzes")]
              )
              # outcome, artifact_type, artifact_id, alignments, associated_asset_id, associated_asset_type
              expect_any_instance_of(OutcomesApiController).to receive(:get_outcome_alignments).with(any_args).and_return(
                [mock_get_outcome_alignments(@outcome, "quizzes.item", "1", nil, nil, nil)]
              )
              json = api_call(:get,
                              "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                              controller: "outcomes_api",
                              action: "outcome_alignments",
                              course_id: @course.id.to_s,
                              student_id: @student.id.to_s,
                              format: "json")
              expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id, new_quiz.id].sort)
            end

            it "returns quiz alignment" do
              # mock alignment with the quiz as the artifact type and id with nil asset
              # mock results with the artifact type and id matching the alignment artifact type and id
              new_quiz = new_quizzes_assignment(course: @course, title: "New Quiz")

              # student, outcome, artifact_type, artifact_id, metadata, associated_asset_id, associated_asset_type
              expect_any_instance_of(OutcomesApiController).to receive(:get_lmgb_results).with(any_args).and_return(
                [mock_get_lmgb_results(@student, @outcome, "quizzes.quiz", "1", nil, new_quiz.id, "canvas.assignment.quizzes")]
              )
              # outcome, artifact_type, artifact_id, alignments, associated_asset_id, associated_asset_type
              expect_any_instance_of(OutcomesApiController).to receive(:get_outcome_alignments).with(any_args).and_return(
                [mock_get_outcome_alignments(@outcome, "quizzes.quiz", "1", nil, nil, nil)]
              )
              json = api_call(:get,
                              "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                              controller: "outcomes_api",
                              action: "outcome_alignments",
                              course_id: @course.id.to_s,
                              student_id: @student.id.to_s,
                              format: "json")
              expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id, new_quiz.id].sort)
            end
          end

          describe "when outcome is aligned to quiz and question" do
            it "returns only one new quiz outcome alignment" do
              # mock alignments has two alignments one with a quiz and an item both with nil
              # mock os results has a result attempt containing the quiz and question
              new_quiz = new_quizzes_assignment(course: @course, title: "New Quiz")
              alignments = [
                {
                  id: 30,
                  artifact_type: "quizzes.quiz",
                  artifact_id: "1",
                  alignment_set_id: 36,
                  aligned_at: "2022-11-03T15:37:19.343Z",
                  created_at: "2022-11-03T15:35:53.240Z",
                  updated_at: "2022-11-03T15:37:25.566Z",
                  deleted_at: nil,
                  context_id: nil,
                  associated_asset_id: new_quiz.id,
                  associated_asset_type: "canvas.assignment.quizzes"
                },
                {
                  id: 31,
                  artifact_type: "quizzes.item",
                  artifact_id: "1",
                  alignment_set_id: 36,
                  aligned_at: "2022-11-03T15:37:19.343Z",
                  created_at: "2022-11-03T15:35:53.240Z",
                  updated_at: "2022-11-03T15:37:25.566Z",
                  deleted_at: nil,
                  context_id: nil,
                  associated_asset_id: nil,
                  associated_asset_type: nil
                }
              ]
              expect_any_instance_of(OutcomesApiController).to receive(:get_outcome_alignments).with(any_args).and_return(
                [mock_get_outcome_alignments(@outcome, "quizzes.quiz", "1", alignments, new_quiz.id, "canvas.assignment.quizzes")]
              )
              expect_any_instance_of(OutcomesApiController).to receive(:get_lmgb_results).with(any_args).and_return(
                [mock_get_lmgb_results(@student, @outcome, "quizzes.quiz", "1", nil, new_quiz.id, "canvas.assignment.quizzes")]
              )
              json = api_call(:get,
                              "/api/v1/courses/#{@course.id}/outcome_alignments?student_id=#{@student.id}",
                              controller: "outcomes_api",
                              action: "outcome_alignments",
                              course_id: @course.id.to_s,
                              student_id: @student.id.to_s,
                              format: "json")
              expect(json.filter_map { |j| j["assignment_id"] }.sort).to eq([@assignment1.id, @assignment2.id, @quiz.assignment_id, new_quiz.id].sort)
            end
          end
        end
      end
    end

    describe "update" do
      context "mastery calculations" do
        context "not allow updating the outcome after being used for assessing" do
          before do
            @outcome.calculation_method = "decaying_average"
            @outcome.calculation_int = 62
            @outcome.save!
            @outcome.reload

            assess_outcome(@outcome)
          end

          let(:update_outcome_api) do
            lambda do |attrs|
              api_call(:put,
                       "/api/v1/outcomes/#{@outcome.id}",
                       { controller: "outcomes_api",
                         action: "update",
                         id: @outcome.id.to_s,
                         format: "json" },
                       attrs,
                       {},
                       { expected_status: 400 })
            end
          end

          let(:update_hash) do
            {
              title: "Here I am",
              display_name: "Rock you like a hurricane",
              description: "Winds of Change",
              vendor_guid: "Eye of the Tiger",
              calculation_method: "n_mastery",
              calculation_int: "2",
              mastery_points: "4",
              ratings: "none",
            }
          end

          it "allows updating calculation method after being used for assessing" do
            expect(@outcome).to be_assessed
            expect(@outcome.calculation_method).to eq("decaying_average")

            json = api_call(:put,
                            "/api/v1/outcomes/#{@outcome.id}",
                            { controller: "outcomes_api",
                              action: "update",
                              id: @outcome.id.to_s,
                              format: "json" },
                            { title: "New Title",
                              description: "New Description",
                              vendor_guid: "vendorguid9000",
                              calculation_method: "highest" },
                            {},
                            { expected_status: 200 })

            @outcome.reload
            expect(json).to eq(outcome_json)
            expect(@outcome.calculation_method).to eq("highest")
          end

          it "allows updating calculation int after being used for assessing" do
            expect(@outcome).to be_assessed
            expect(@outcome.calculation_method).to eq("decaying_average")
            expect(@outcome.calculation_int).to eq(62)

            json = api_call(:put,
                            "/api/v1/outcomes/#{@outcome.id}",
                            { controller: "outcomes_api",
                              action: "update",
                              id: @outcome.id.to_s,
                              format: "json" },
                            { title: "New Title",
                              description: "New Description",
                              vendor_guid: "vendorguid9000",
                              calculation_int: "59" },
                            {},
                            { expected_status: 200 })

            @outcome.reload
            expect(json).to eq(outcome_json)
            expect(@outcome.calculation_method).to eq("decaying_average")
            expect(@outcome.calculation_int).to eq(59)
          end

          it "allows updating text-only fields even when assessed" do
            new_title = "some new title"
            new_display_name = "some display name"
            new_desc = "some new description or something"
            api_call(:put,
                     "/api/v1/outcomes/#{@outcome.id}",
                     { controller: "outcomes_api",
                       action: "update",
                       id: @outcome.id.to_s,
                       format: "json" },
                     { title: new_title, description: new_desc, display_name: new_display_name },
                     {},
                     { expected_status: 200 })
            @outcome.reload
            expect(@outcome.title).to eq new_title
            expect(@outcome.display_name).to eq new_display_name
            expect(@outcome.description).to eq new_desc
          end

          context "updating rubric criterion when assessed" do
            before do
              @outcome2 = @course.created_learning_outcomes.create!(title: "outcome")
              @course.root_outcome_group.add_outcome(@outcome2)
              @outcome2.rubric_criterion = {
                mastery_points: 5,
                ratings: [{ description: "Strong work", points: 5 }, { description: "Weak sauce", points: 1 }],
              }
              @outcome2.save!
              assess_outcome(@outcome2)
            end

            it "allows updating rating descriptions even when assessed" do
              new_ratings = [{ description: "some new desc1", points: 5 },
                             { description: "some new desc2", points: 1 }]
              api_call(:put,
                       "/api/v1/outcomes/#{@outcome2.id}",
                       { controller: "outcomes_api",
                         action: "update",
                         id: @outcome2.id.to_s,
                         format: "json" },
                       { ratings: new_ratings },
                       {},
                       { expected_status: 200 })
              @outcome2.reload
              expect(@outcome2.rubric_criterion[:ratings]).to eq new_ratings
            end

            it "allows updating rating points" do
              new_ratings = [{ description: "some new desc1", points: 5 },
                             { description: "some new desc2", points: 3 }]
              api_call(:put,
                       "/api/v1/outcomes/#{@outcome2.id}",
                       { controller: "outcomes_api",
                         action: "update",
                         id: @outcome2.id.to_s,
                         format: "json" },
                       { ratings: new_ratings },
                       {},
                       { expected_status: 200 })
              @outcome2.reload
              expect(@outcome2.rubric_criterion[:ratings]).to eq new_ratings
            end

            it "allows updating mastery points" do
              api_call(:put,
                       "/api/v1/outcomes/#{@outcome2.id}",
                       { controller: "outcomes_api",
                         action: "update",
                         id: @outcome2.id.to_s,
                         format: "json" },
                       { mastery_points: 7 },
                       {},
                       { expected_status: 200 })
              @outcome2.reload
              expect(@outcome2.rubric_criterion[:mastery_points]).to eq 7
            end
          end
        end
      end
    end
  end
end
