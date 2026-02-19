# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Api::V1::AllocationRule do
  subject { test_class.new }

  let(:test_class) do
    Class.new do
      include Api::V1::AllocationRule

      def session
        {}
      end
    end
  end

  before :once do
    course_with_teacher(active_all: true)
    @student1 = student_in_course(active_all: true).user
    @student2 = student_in_course(active_all: true).user
    @assignment = @course.assignments.create!(
      title: "Test Assignment",
      peer_reviews: true
    )
  end

  describe "#allocation_rule_json" do
    it "returns the expected attributes" do
      allocation_rule = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student1,
        assessee: @student2,
        must_review: true,
        review_permitted: true,
        applies_to_assessor: true
      )

      json = subject.allocation_rule_json(allocation_rule, @teacher, {})

      expect(json).to include(
        "id" => allocation_rule.id,
        "must_review" => true,
        "review_permitted" => true,
        "applies_to_assessor" => true,
        "assessor_id" => @student1.id,
        "assessee_id" => @student2.id
      )
    end

    it "includes all expected keys and no others" do
      allocation_rule = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student1,
        assessee: @student2,
        must_review: false,
        review_permitted: true,
        applies_to_assessor: false
      )

      json = subject.allocation_rule_json(allocation_rule, @teacher, {})

      expect(json.keys).to contain_exactly("id", "must_review", "review_permitted", "applies_to_assessor", "assessor_id", "assessee_id")
    end

    it "does not include workflow_state, assignment_id, or course_id" do
      allocation_rule = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student1,
        assessee: @student2,
        must_review: true,
        review_permitted: true,
        applies_to_assessor: true
      )

      json = subject.allocation_rule_json(allocation_rule, @teacher, {})

      expect(json).not_to have_key("workflow_state")
      expect(json).not_to have_key("assignment_id")
      expect(json).not_to have_key("course_id")
    end

    it "correctly serializes boolean values" do
      allocation_rule = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student1,
        assessee: @student2,
        must_review: false,
        review_permitted: false,
        applies_to_assessor: false
      )

      json = subject.allocation_rule_json(allocation_rule, @teacher, {})

      expect(json["must_review"]).to be false
      expect(json["review_permitted"]).to be false
      expect(json["applies_to_assessor"]).to be false
    end
  end

  describe "#allocation_rules_json" do
    it "returns an array of allocation rule json objects" do
      rule1 = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student1,
        assessee: @student2,
        must_review: true,
        review_permitted: true,
        applies_to_assessor: true
      )
      rule2 = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student2,
        assessee: @student1,
        must_review: false,
        review_permitted: true,
        applies_to_assessor: false
      )

      json = subject.allocation_rules_json([rule1, rule2], @teacher, {})

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.first["id"]).to eq(rule1.id)
      expect(json.second["id"]).to eq(rule2.id)
    end

    it "returns an empty array when given no rules" do
      json = subject.allocation_rules_json([], @teacher, {})

      expect(json).to eq([])
    end

    it "correctly serializes each rule in the collection" do
      rule1 = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student1,
        assessee: @student2,
        must_review: true,
        review_permitted: true,
        applies_to_assessor: true
      )
      rule2 = AllocationRule.create!(
        assignment: @assignment,
        course: @course,
        assessor: @student2,
        assessee: @student1,
        must_review: false,
        review_permitted: false,
        applies_to_assessor: false
      )

      json = subject.allocation_rules_json([rule1, rule2], @teacher, {})

      expect(json.first["must_review"]).to be true
      expect(json.first["assessor_id"]).to eq(@student1.id)
      expect(json.second["must_review"]).to be false
      expect(json.second["assessor_id"]).to eq(@student2.id)
    end
  end
end
