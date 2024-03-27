# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../../conditional_release_spec_helper"
require_relative "../../api_spec_helper"

module ConditionalRelease
  describe RulesController, type: :request do
    before(:once) do
      course_with_teacher(active_all: true)
      @user = @teacher
      @assignment = @course.assignments.create!(title: "an assignment")
    end

    def verify_positions_for(rule)
      rule.scoring_ranges.each.with_index(1) do |range, range_idx|
        expect(range.position).to be range_idx
        range.assignment_sets.each.with_index(1) do |set, set_idx|
          expect(set.position).to be set_idx
          set.assignment_set_associations.each.with_index(1) do |asg, asg_idx|
            expect(asg.position).to be asg_idx
          end
        end
      end
    end

    describe "GET index" do
      before(:once) do
        create(:rule_with_scoring_ranges,
               course: @course,
               trigger_assignment: @assignment)
        create(:rule_with_scoring_ranges,
               course: @course,
               trigger_assignment: @assignment,
               assignment_count: 0)
        create(:rule_with_scoring_ranges, course: @course)

        other_course = Course.create!
        create(:rule_with_scoring_ranges, course: other_course)

        @url = "/api/v1/courses/#{@course.id}/mastery_paths/rules"
        @base_params = {
          controller: "conditional_release/rules",
          action: "index",
          format: "json",
          course_id: @course.id.to_s,
        }
      end

      it "requires authorization" do
        @user = user_factory
        api_call(:get, @url, @base_params, {}, {}, { expected_status: 401 })
      end

      it "returns all rules for a course" do
        json = api_call(:get, @url, @base_params, {}, {}, { expected_status: 200 })
        expect(json.length).to eq 3
      end

      it "allows students to view" do
        student_in_course(course: @course, active_all: true)
        json = api_call(:get, @url, @base_params, {}, {}, { expected_status: 200 })
        expect(json.length).to eq 3
      end

      it "filters based on assignment id" do
        json = api_call(:get, @url, @base_params.merge(trigger_assignment_id: @assignment.id), {}, {}, { expected_status: 200 })
        expect(json.length).to eq 2
      end

      it "does not include scoring ranges by default" do
        json = api_call(:get, @url, @base_params, {}, {}, { expected_status: 200 })
        expect(json[0]).not_to have_key "scoring_ranges"
      end

      it "includes scoring ranges and assignments when requested" do
        json = api_call(:get, @url, @base_params.merge(include: ["all"]), {}, {}, { expected_status: 200 })
        ranges_json = json[0]["scoring_ranges"]
        expect(ranges_json.length).to eq(2)
        sets_json = ranges_json.last["assignment_sets"]
        expect(sets_json.length).to eq(1)
        expect(sets_json.last["assignment_set_associations"].length).to eq(2)
      end

      it 'includes only rules with assignments when "active" requested' do
        json = api_call(:get, @url, @base_params.merge(active: true), {}, {}, { expected_status: 200 })
        expect(json.length).to eq(2)
      end
    end

    describe "GET show" do
      before :once do
        @rule = create(:rule_with_scoring_ranges,
                       course: @course,
                       scoring_range_count: 2,
                       assignment_set_count: 2,
                       assignment_count: 3)

        @url = "/api/v1/courses/#{@course.id}/mastery_paths/rules/#{@rule.id}"
        @base_params = {
          controller: "conditional_release/rules",
          action: "show",
          format: "json",
          course_id: @course.id.to_s,
          id: @rule.id.to_s
        }
      end

      it "fails for deleted rule" do
        @rule.destroy
        api_call(:get, @url, @base_params, {}, {}, { expected_status: 404 })
      end

      it "does not show scoring ranges by default" do
        json = api_call(:get, @url, @base_params, {}, {}, { expected_status: 200 })
        expect(json["scoring_ranges"]).to be_nil
      end

      it "does show assignments when asked" do
        json = api_call(:get, @url, @base_params.merge(include: ["all"]), {}, {}, { expected_status: 200 })
        ranges_json = json["scoring_ranges"]
        expect(ranges_json.length).to eq(2)
        sets_json = ranges_json.last["assignment_sets"]
        expect(sets_json.length).to eq(2)
        expect(sets_json.last["assignment_set_associations"].length).to eq(3)
      end

      it "shows assignments in order" do
        first_assoc = @rule.scoring_ranges.first.assignment_sets.first.assignment_set_associations.first
        last_assoc = @rule.scoring_ranges.last.assignment_sets.last.assignment_set_associations.last
        first_assoc.move_to_bottom
        last_assoc.move_to_top
        json = api_call(:get, @url, @base_params.merge(include: ["all"]), {}, {}, { expected_status: 200 })
        expect(json["scoring_ranges"].last["assignment_sets"].last["assignment_set_associations"].first["id"]).to eq last_assoc.id
        expect(json["scoring_ranges"].first["assignment_sets"].first["assignment_set_associations"].last["id"]).to eq first_assoc.id
        ranges_json = json["scoring_ranges"]
        ranges_json.each.with_index(1) do |range, range_idx|
          expect(range["position"]).to eq(range_idx)

          range["assignment_sets"].each.with_index(1) do |set, set_idx|
            expect(set["position"]).to eq(set_idx)

            set["assignment_set_associations"].each.with_index(1) do |asg, asg_idx|
              expect(asg["position"]).to eq(asg_idx)
            end
          end
        end
      end
    end

    describe "POST create" do
      before :once do
        @url = "/api/v1/courses/#{@course.id}/mastery_paths/rules"
        @base_params = {
          controller: "conditional_release/rules",
          action: "create",
          format: "json",
          course_id: @course.id.to_s,
          trigger_assignment_id: @assignment.id
        }
      end

      it "requires management rights" do
        student_in_course(course: @course)
        @user = @student
        api_call(:post, @url, @base_params, {}, {}, { expected_status: 401 })
      end

      it "creates successfully" do
        json = api_call(:post, @url, @base_params, {}, {}, { expected_status: 200 })
        rule = @course.conditional_release_rules.find(json["id"])
        expect(rule.trigger_assignment).to eq @assignment
      end

      it "creates with scoring range and assignments" do
        ranges = Array.new(3) do |range_pos|
          assignment_sets = Array.new(2) do |set_pos|
            associations = Array.new(3) do |assoc_pos|
              assignment = @course.assignments.create!
              { "position" => assoc_pos + 1, "assignment_id" => assignment.id }
            end
            { "position" => set_pos + 1, "assignment_set_associations" => associations }
          end
          { "position" => range_pos + 1, "lower_bound" => 65, "upper_bound" => 95, "assignment_sets" => assignment_sets }
        end

        json = api_call(:post, @url, @base_params.merge("scoring_ranges" => ranges), {}, {}, { expected_status: 200 })
        rule = @course.conditional_release_rules.find(json["id"])
        expect(rule.scoring_ranges.length).to eq(3)
        expect(rule.scoring_ranges.last.assignment_sets.length).to eq(2)
        expect(rule.scoring_ranges.last.assignment_sets.last.assignment_set_associations.length).to eq(3)
        expect(rule.assignment_set_associations.length).to eq(18)
        verify_positions_for rule
      end

      it "does not create with invalid scoring range" do
        expect do
          api_call(:post, @url, @base_params.merge("scoring_ranges" => [{ foo: 3 }]), {}, {}, { expected_status: 400 })
        end.not_to change { Rule.count }
      end

      it "does not create with invalid assignment" do
        sr = { "lower_bound" => 65, "upper_bound" => 95 }
        sr["assignment_sets"] = [{ assignment_set_associations: [{ foo: 3 }] }]
        expect do
          api_call(:post, @url, @base_params.merge("scoring_ranges" => [sr]), {}, {}, { expected_status: 400 })
        end.not_to change { Rule.count }
      end

      it "does not create with trigger assignment in other course" do
        other_course = Course.create!
        other_assignment = other_course.assignments.create!

        expect do
          api_call(:post, @url, @base_params.merge(trigger_assignment_id: other_assignment.id), {}, {}, { expected_status: 400 })
        end.not_to change { Rule.count }
      end

      it "does not create with assignment in other course" do
        other_course = Course.create!
        other_assignment = other_course.assignments.create!

        sr = { "lower_bound" => 65, "upper_bound" => 95 }
        sr["assignment_sets"] = [{ assignment_set_associations: [{ assignment_id: other_assignment.id }] }]
        expect do
          api_call(:post, @url, @base_params.merge("scoring_ranges" => [sr]), {}, {}, { expected_status: 400 })
        end.not_to change { Rule.count }
      end
    end

    describe "PUT update" do
      before :once do
        @rule = create(:rule, course: @course, trigger_assignment: @assignment)
        @url = "/api/v1/courses/#{@course.id}/mastery_paths/rules/#{@rule.id}"
        @other_assignment = @course.assignments.create!
        @base_params = {
          controller: "conditional_release/rules",
          action: "update",
          format: "json",
          course_id: @course.id.to_s,
          id: @rule.id.to_s,
          trigger_assignment_id: @other_assignment.id
        }
      end

      it "requires management rights" do
        student_in_course(course: @course)
        @user = @student
        api_call(:put, @url, @base_params, {}, {}, { expected_status: 401 })
      end

      it "fails for deleted rule" do
        @rule.destroy
        api_call(:put, @url, @base_params, {}, {}, { expected_status: 404 })
      end

      it "updates the trigger_assignment" do
        json = api_call(:put, @url, @base_params, {}, {}, { expected_status: 200 })
        expect(json["trigger_assignment_id"]).to eq @other_assignment.id
        expect(@rule.reload.trigger_assignment).to eq @other_assignment
      end

      it "does not allow invalid rule" do
        api_call(:put, @url, @base_params.merge(trigger_assignment_id: "doh"), {}, {}, { expected_status: 400 })
        expect(@rule.reload.trigger_assignment).to eq @assignment
      end

      it "updates with scoring ranges" do
        rule = create(:rule_with_scoring_ranges,
                      course: @course,
                      scoring_range_count: 2,
                      assignment_count: 3)
        range = rule.scoring_ranges[0]
        range.upper_bound = 99
        rule_params = rule.as_json(include: :scoring_ranges, include_root: false)
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/mastery_paths/rules/#{rule.id}",
                 @base_params.with_indifferent_access.merge(rule_params),
                 {},
                 {},
                 { expected_status: 200 })
        rule.reload
        range.reload
        expect(rule.scoring_ranges.count).to eq(2) # didn't add ranges
        expect(rule.scoring_ranges.include?(range)).to be true
        expect(range.upper_bound).to eq(99)
        expect(range.assignment_set_associations.count).to eq(3) # didn't delete assignments when not specified
      end

      it "updates removes scoring ranges" do
        rule = create(:rule_with_scoring_ranges,
                      course: @course,
                      scoring_range_count: 2)
        rule_params = rule.as_json(include: :scoring_ranges, include_root: false)
        rule_params["scoring_ranges"].shift

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/mastery_paths/rules/#{rule.id}",
                 @base_params.with_indifferent_access.merge(rule_params),
                 {},
                 {},
                 { expected_status: 200 })
        rule.reload
        expect(rule.scoring_ranges.count).to be(1)
      end

      it "updates with assignments in order" do
        rule = create(:rule_with_scoring_ranges,
                      course: @course,
                      scoring_range_count: 2,
                      assignment_set_count: 2,
                      assignment_count: 1)
        rule_params = rule.as_json(include: { scoring_ranges: { include: { assignment_sets: { include: :assignment_set_associations } } } }, include_root: false)

        changed_assignment = @course.assignments.create!
        rule_params["scoring_ranges"][1]["assignment_sets"][0]["assignment_set_associations"][0]["assignment_id"] = changed_assignment.id
        # replace one assignment with another
        deleted_assignment_id = rule_params["scoring_ranges"][0]["assignment_sets"][0]["assignment_set_associations"][0]["assignment_id"]

        new_assignment = @course.assignments.create!
        rule_params["scoring_ranges"][0]["assignment_sets"][0]["assignment_set_associations"] = [{ assignment_id: new_assignment.id }]

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/mastery_paths/rules/#{rule.id}",
                 @base_params.with_indifferent_access.merge(rule_params),
                 {},
                 {},
                 { expected_status: 200 })

        rule.reload
        changed_assoc = rule.assignment_set_associations.where(assignment_id: changed_assignment.id).take
        expect(changed_assoc).not_to be_nil
        new_assoc = rule.assignment_set_associations.where(assignment_id: new_assignment.id).take
        expect(new_assoc).not_to be_nil
        deleted_assoc = rule.assignment_set_associations.where(assignment_id: deleted_assignment_id).take
        expect(deleted_assoc).to be_nil
        expect(rule.assignment_set_associations.count).to be 4

        verify_positions_for rule
      end

      it "updates with assignments in rearranged order" do
        rule = create(:rule_with_scoring_ranges,
                      course: @course,
                      scoring_range_count: 1,
                      assignment_set_count: 1,
                      assignment_count: 3)
        rule_params = rule.as_json(include_root: false, include: { scoring_ranges: { include: { assignment_sets: { include: :assignment_set_associations } } } })

        assignments = rule_params["scoring_ranges"][0]["assignment_sets"][0]["assignment_set_associations"]
        # Rearrange them
        assignments[0], assignments[1], assignments[2] = assignments[2], assignments[0], assignments[1]

        api_call(:put,
                 "/api/v1/courses/#{@course.id}/mastery_paths/rules/#{rule.id}",
                 @base_params.with_indifferent_access.merge(rule_params),
                 {},
                 {},
                 { expected_status: 200 })

        # Refresh the Rule and make sure no assignments were added
        rule.reload
        expect(rule.assignment_set_associations.count).to be 3
        # Check that the rules have been sorted to match the order received
        expect(rule.assignment_set_associations.pluck(:id)).to eq(assignments.pluck("id"))
        # And that their positions are correctly updated
        verify_positions_for rule
      end
    end

    describe "DELETE destroy" do
      before :once do
        @rule = create(:rule, course: @course)
        @url = "/api/v1/courses/#{@course.id}/mastery_paths/rules/#{@rule.id}"
        @base_params = {
          controller: "conditional_release/rules",
          action: "destroy",
          format: "json",
          course_id: @course.id.to_s,
          id: @rule.id.to_s
        }
      end

      it "requires management rights" do
        student_in_course(course: @course)
        @user = @student
        api_call(:delete, @url, @base_params, {}, {}, { expected_status: 401 })
      end

      it "deletes a rule" do
        api_call(:delete, @url, @base_params, {}, {}, { expected_status: 200 })
        expect(@rule.reload.deleted_at).to be_present
        expect(Rule.active.where(id: @rule.id).exists?).to be false
      end

      it "fails for non-existent rule" do
        @rule.destroy
        api_call(:delete, @url, @base_params, {}, {}, { expected_status: 404 })
      end
    end
  end
end
