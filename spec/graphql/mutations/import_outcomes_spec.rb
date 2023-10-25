# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../graphql_spec_helper"

describe Mutations::ImportOutcomes do
  def mutation_str(**attrs)
    target_group_id = attrs[:target_group_id]
    target_context_id = attrs[:target_context_id]
    target_context_type = attrs[:target_context_type]
    source_context_id = attrs[:source_context_id]
    source_context_type = attrs[:source_context_type]
    outcome_id = attrs[:outcome_id]
    group_id = attrs[:group_id]

    optional_fields = []
    optional_fields << "targetGroupId: #{target_group_id}" if target_group_id
    optional_fields << "targetContextId: #{target_context_id}" if target_context_id
    optional_fields << "targetContextType: \"#{target_context_type}\"" if target_context_type
    optional_fields << "sourceContextId: #{source_context_id}" if source_context_id
    optional_fields << "sourceContextType: \"#{source_context_type}\"" if source_context_type
    optional_fields << "outcomeId: #{outcome_id}" if outcome_id
    optional_fields << "groupId: \"#{group_id}\"" if group_id

    <<~GQL
      mutation {
        importOutcomes(input: {
          #{optional_fields.join(",\n")}
        }) {
          errors {
            attribute
            message
          }
          progress {
            id
          }
        }
      }
    GQL
  end

  def execute_query(query, context)
    CanvasSchema.execute(query, context:)
  end

  def exec_graphql(**attrs)
    execute_query(
      mutation_str(
        **attrs.reverse_merge(
          target_group_id: target_group.id,
          source_context_id:,
          source_context_type:
        )
      ),
      ctx
    )
  end

  def exec(**attrs)
    attrs.reverse_merge!(
      target_group_id: target_group.id,
      source_context_id:,
      source_context_type:
    )
    source_context = attrs[:source_context_type].constantize.find_by(id: attrs[:source_context_id]) if attrs[:source_context_type]
    group = LearningOutcomeGroup.find_by(id: attrs[:group_id]) if attrs[:group_id]
    target_group = LearningOutcomeGroup.find_by(id: attrs[:target_group_id])
    outcome_id = attrs[:outcome_id]

    described_class.execute(progress, source_context, group, outcome_id, target_group)
  end

  def find_group(title)
    LearningOutcomeGroup.find_by(title:)
  end

  def get_outcome_id(title, context = Account.default)
    LearningOutcome.find_by(context:, short_description: title).id
  end

  let(:target_context) { @course }
  let(:target_group) do
    @course.root_outcome_group
  end
  let(:source_context_id) { Account.default.id }
  let(:source_context_type) { "Account" }
  let(:ctx) { { domain_root_account: Account.default, current_user: } }
  let(:current_user) { @teacher }
  let(:progress) { @course.progresses.create!(tag: "import_outcomes") }

  before :once do
    Account.default.enable_feature!(:improved_outcomes_management)
    course_with_teacher
  end

  before do
    make_group_structure({
                           title: "Group A",
                           outcomes: 5,
                           groups: [{
                             title: "Group C",
                             outcomes: 3,
                             groups: [{
                               title: "Group D",
                               outcomes: 5
                             },
                                      {
                                        title: "Group E",
                                        outcomes: 5
                                      }]
                           }]
                         },
                         Account.default)

    make_group_structure({
                           title: "Group B",
                           outcomes: 5
                         },
                         Account.default)
  end

  def assert_tree_exists(groups, db_parent_group)
    group_titles = db_parent_group.child_outcome_groups.active.pluck(:title)
    expect(group_titles.sort).to eql(groups.pluck(:title).sort)

    groups.each do |group|
      outcome_titles = group[:outcomes] || []
      title = group[:title]
      childs = group[:groups]

      # root_account_id should match the context of the db_parent_group.context root_account_id
      log_db_root_account_id = LearningOutcomeGroup.find_by(context: db_parent_group.context, title:).root_account_id
      expect(log_db_root_account_id).to eq(db_parent_group.context.resolved_root_account_id)

      db_group = db_parent_group.child_outcome_groups.find_by!(title:)

      db_outcomes = db_group.child_outcome_links.map(&:content)

      expect(outcome_titles.sort).to eql(db_outcomes.map(&:title).sort)

      assert_tree_exists(childs, db_group) if childs
    end
  end

  context "imports outcomes" do
    it "does not generate an error" do
      result = exec_graphql(outcome_id: get_outcome_id(
        "0 Group E outcome"
      ))
      errors = result.dig("data", "importOutcomes", "errors")
      expect(errors).to be_nil
    end
  end

  context "errors" do
    before(:once) do
      @course2 = Course.create!(name: "Second", account: Account.default)
      @course2_group = outcome_group_model(context: @course2)
      @course2_outcome = outcome_model(context: @course2, outcome_group: @course2_group)
      @global_outcome = outcome_model(global: true, title: "Global outcome")
      @outcome_without_group = LearningOutcome.create!(title: "Outcome without group")
    end

    def expect_validation_error(result, attribute, message)
      errors = result.dig("data", "importOutcomes", "errors")
      expect(errors).not_to be_nil
      expect(errors[0]["attribute"]).to eq attribute
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    def expect_error(result, message)
      errors = result["errors"]
      expect(errors).not_to be_nil
      expect(errors[0]["message"]).to match(/#{message}/)
    end

    it "errors when groupId is missing" do
      group_id = find_group("Group B").id
      query = <<~GQL
        mutation {
          importOutcomes(input: {
            groupId: #{group_id}
          }) {
            errors {
              attribute
              message
            }
          }
        }
      GQL
      result = execute_query(query, ctx)
      errors = result["errors"]
      expect(errors).not_to be_nil
      expect(errors.length).to eq 1
      expect(
        errors.select { |e| e["path"] == %w[mutation importOutcomes input targetGroupId] }
      ).not_to be_nil
    end

    it "errors when no such group is found" do
      result = exec_graphql(target_group_id: 9999)
      expect_error(result, "no such target group")
    end

    it "errors when sourceContextType is invalid" do
      result = exec_graphql(source_context_type: "FooContext")
      expect_validation_error(result, "sourceContextType", "invalid value")
    end

    it "errors when no such source context is found" do
      result = exec_graphql(source_context_type: "Account", source_context_id: -1)
      expect_error(result, "no such source context")
    end

    it "errors when sourceContextId is not provided when sourceContextType is provided" do
      result = exec_graphql(source_context_type: "Account", source_context_id: nil)
      expect_validation_error(
        result,
        "sourceContextId",
        "sourceContextId required if sourceContextType provided"
      )
    end

    it "errors when sourceContextType is not provided when sourceContextId is provided" do
      result = exec_graphql(source_context_type: nil, source_context_id: 1)
      expect_validation_error(
        result,
        "sourceContextType",
        "sourceContextType required if sourceContextId provided"
      )
    end

    it "errors when targetContext and targetGroupId is blank" do
      result = exec_graphql(target_context_type: nil, target_context_id: nil, target_group_id: nil)
      expect_error(result, "You must provide targetGroupId or targetContextId and targetContextType")
    end

    it "errors when targetContextId and targetGroupId is blank" do
      result = exec_graphql(target_context_type: nil, target_context_id: 1, target_group_id: nil)
      expect_error(result, "targetContextType required if targetContextId provided")
    end

    it "errors when targetContextType and targetGroupId is blank" do
      result = exec_graphql(target_context_type: "Account", target_context_id: nil, target_group_id: nil)
      expect_error(result, "targetContextId required if targetContextType provided")
    end

    it "errors when no such context is found" do
      result = exec_graphql(target_context_type: "Account", target_context_id: -1, target_group_id: nil)
      expect_error(result, "no such target context")
    end

    it "errors when targetContextType is invalid" do
      result = exec_graphql(target_context_type: "Foo", target_context_id: -1, target_group_id: nil)
      expect_error(result, "Invalid targetContextType")
    end

    it "errors when neither groupId or outcomeId value is provided" do
      result = exec_graphql
      expect_validation_error(result, "message", "Either groupId or outcomeId values are required")
    end

    context "import group" do
      it "errors on invalid group id" do
        result = exec_graphql(group_id: 0)
        expect_error(result, "group not found")
      end

      it "errors when importing group from course to course" do
        result = exec_graphql(
          group_id: @course2_group.id,
          source_context_type: nil,
          source_context_id: nil
        )
        expect_error(result, "invalid context for group")
      end

      it "errors when importing root outcome group" do
        result = exec_graphql(group_id: Account.default.root_outcome_group.id)
        expect_error(result, "cannot import a root group")
      end

      it "errors when source context does not match the group's context" do
        result = exec_graphql(
          group_id: find_group("Group B").id,
          source_context_type: "Course",
          source_context_id: @course2.id
        )
        expect_error(result, "source context does not match group context")
      end
    end

    context "import outcome" do
      it "errors when importing non-existence outcome" do
        result = exec_graphql(outcome_id: 0)
        expect_error(result, "Outcome 0 is not available in context Course##{@course.id}")
      end

      it "errors when importing ineligible outcome" do
        result = exec_graphql(outcome_id: @course2_outcome.id)
        expect_error(result, "Outcome #{@course2_outcome.id} is not available in context Course##{@course.id}")
      end
    end

    context "without permissions" do
      let(:current_user) { nil }

      it "returns error" do
        result = exec_graphql(outcome_id: get_outcome_id(
          "0 Group E outcome"
        ))
        expect_error(result, "not found")
      end
    end
  end

  it "returns a progress" do
    result = exec_graphql(outcome_id: get_outcome_id(
      "0 Group E outcome"
    ))
    expect(result.dig("data", "importOutcomes", "progress", "id")).to be_present
  end

  it "calls process_job with root_outcome_group if target_context provided" do
    expect_any_instance_of(described_class).to receive(:process_job).with(
      hash_including(target_group: @course.root_outcome_group)
    ).and_call_original
    exec_graphql(
      outcome_id: get_outcome_id("0 Group E outcome"),
      target_group_id: nil,
      target_context_type: "Course",
      target_context_id: @course.id
    )
  end

  it "calls process_job with target_group if provided" do
    dummy_group = outcome_group_model(
      title: "Dummy",
      context: @course
    )

    expect_any_instance_of(described_class).to receive(:process_job).with(
      hash_including(target_group: dummy_group)
    ).and_call_original
    exec_graphql(
      outcome_id: get_outcome_id("0 Group E outcome"),
      target_group_id: dummy_group.id
    )
  end

  context "passing outcomeId" do
    it "works when importing outcomes from same group" do
      [
        "0 Group E outcome",
        "1 Group E outcome",
        "2 Group E outcome",
        "3 Group E outcome",
        "4 Group E outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title))
      end

      assert_tree_exists([{
                           title: "Group E",
                           outcomes: [
                             "0 Group E outcome",
                             "1 Group E outcome",
                             "2 Group E outcome",
                             "3 Group E outcome",
                             "4 Group E outcome"
                           ]
                         }],
                         @course.root_outcome_group)
    end

    it "works when importing outcomes to a target_group" do
      target_group = outcome_group_model(
        title: "Group A",
        context: @course
      )

      [
        "0 Group E outcome",
        "1 Group E outcome",
        "2 Group E outcome",
        "3 Group E outcome",
        "4 Group E outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title), target_group_id: target_group.id)
      end

      assert_tree_exists([{
                           title: "Group A",
                           groups: [{
                             title: "Group E",
                             outcomes: [
                               "0 Group E outcome",
                               "1 Group E outcome",
                               "2 Group E outcome",
                               "3 Group E outcome",
                               "4 Group E outcome"
                             ]
                           }]
                         }],
                         @course.root_outcome_group)
    end

    it "works when importing outcomes from different group" do
      [
        "0 Group E outcome", "0 Group C outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title))
      end

      assert_tree_exists([{
                           title: "Group C",
                           outcomes: ["0 Group C outcome"],
                           groups: [{
                             title: "Group E",
                             outcomes: ["0 Group E outcome"]
                           }]
                         }],
                         @course.root_outcome_group)
    end

    it "rebuilds structure when importing a parent group and a group that was imported before" do
      [
        "0 Group D outcome", "0 Group C outcome", "1 Group D outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title))
      end

      assert_tree_exists([{
                           title: "Group C",
                           outcomes: ["0 Group C outcome"],
                           groups: [{
                             title: "Group D",
                             outcomes: ["0 Group D outcome", "1 Group D outcome"]
                           }]
                         }],
                         @course.root_outcome_group)
    end

    it "rebuilds structure when importing a parent group from a group that was imported before" do
      [
        "0 Group D outcome", "0 Group C outcome", "0 Group A outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title))
      end

      assert_tree_exists([{
                           title: "Group A",
                           outcomes: ["0 Group A outcome"],
                           groups: [{
                             title: "Group C",
                             outcomes: ["0 Group C outcome"],
                             groups: [{
                               title: "Group D",
                               outcomes: ["0 Group D outcome"]
                             }]
                           }]
                         }],
                         @course.root_outcome_group)
    end

    it "rebuilds structure when importing a child group from a group that was imported before" do
      [
        "0 Group A outcome", "0 Group D outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title))
      end

      assert_tree_exists([{
                           title: "Group A",
                           outcomes: ["0 Group A outcome"],
                           groups: [{
                             title: "Group C",
                             groups: [{
                               title: "Group D",
                               outcomes: ["0 Group D outcome"]
                             }]
                           }]
                         }],
                         @course.root_outcome_group)
    end

    it "rebuilds structure (reverse order)" do
      [
        "0 Group D outcome", "0 Group A outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title))
      end

      assert_tree_exists([{
                           title: "Group A",
                           outcomes: ["0 Group A outcome"],
                           groups: [{
                             title: "Group C",
                             groups: [{
                               title: "Group D",
                               outcomes: ["0 Group D outcome"]
                             }]
                           }]
                         }],
                         @course.root_outcome_group)
    end

    it "build structure correctly if import outcomes groups from different root parents" do
      [
        "0 Group D outcome", "0 Group B outcome"
      ].each do |title|
        exec(outcome_id: get_outcome_id(title))
      end

      assert_tree_exists([{
                           title: "Group D",
                           outcomes: ["0 Group D outcome"]
                         },
                          {
                            title: "Group B",
                            outcomes: ["0 Group B outcome"]
                          }],
                         @course.root_outcome_group)
    end

    it "Don't mess with outcomes that belongs already to the course" do
      make_group_structure({
                             title: "Group in Course",
                             outcomes: 1
                           },
                           @course)

      exec(outcome_id: get_outcome_id("0 Group D outcome"))

      assert_tree_exists([{
                           title: "Group D",
                           outcomes: ["0 Group D outcome"]
                         },
                          {
                            title: "Group in Course",
                            outcomes: ["0 Group in Course outcome"]
                          }],
                         @course.root_outcome_group)
    end

    it "doesn't reactivate previous destroyed imported groups" do
      exec(outcome_id: get_outcome_id("0 Group E outcome"))
      group = @course.root_outcome_group.child_outcome_groups.find_by(title: "Group E")
      group.destroy
      exec(outcome_id: get_outcome_id("0 Group D outcome"))

      assert_tree_exists([{
                           title: "Group D",
                           outcomes: ["0 Group D outcome"]
                         }],
                         @course.root_outcome_group)
    end

    it "imports outcomes that belongs to root folders" do
      outcome_model(
        title: "Root group outcome",
        outcome_group: Account.default.root_outcome_group,
        context: Account.default
      )

      # force the creation of root outcome group in the course
      @course.root_outcome_group

      # rubocop:disable Layout/MultilineMethodCallIndentation
      # see https://github.com/rubocop/rubocop/issues/12261
      expect do
        exec(outcome_id: get_outcome_id("Root group outcome"))
      end.to not_change(LearningOutcomeGroup, :count)
        .and(change(ContentTag, :count).by(1))
        .and(change do
               @course.root_outcome_group.child_outcome_links.map { |link| link.content.title }
             end.from([]).to(["Root group outcome"]))
      # rubocop:enable Layout/MultilineMethodCallIndentation
    end
  end

  context "passing groupId" do
    it "import all nested outcomes from a group" do
      exec(group_id: find_group("Group C").id)

      assert_tree_exists([{
                           title: "Group C",
                           outcomes: Array.new(3) { |i| "#{i} Group C outcome" },
                           groups: [{
                             title: "Group D",
                             outcomes: Array.new(5) { |i| "#{i} Group D outcome" }
                           },
                                    {
                                      title: "Group E",
                                      outcomes: Array.new(5) { |i| "#{i} Group E outcome" }
                                    }]
                         }],
                         @course.root_outcome_group)
    end

    it "import all nested outcomes to a specific group" do
      make_group_structure({
                             title: "Group F",
                           },
                           @course)

      exec(
        group_id: find_group("Group C").id,
        target_group_id: find_group("Group F").id
      )

      assert_tree_exists([{
                           title: "Group F",
                           groups: [{
                             title: "Group C",
                             outcomes: Array.new(3) { |i| "#{i} Group C outcome" },
                             groups: [{
                               title: "Group D",
                               outcomes: Array.new(5) { |i| "#{i} Group D outcome" }
                             },
                                      {
                                        title: "Group E",
                                        outcomes: Array.new(5) { |i| "#{i} Group E outcome" }
                                      }]
                           }]
                         }],
                         @course.root_outcome_group)
    end

    it "resync new added outcomes and groups" do
      group_e = LearningOutcomeGroup.find_by(title: "Group E")
      groupc_id = find_group("Group C").id

      exec(group_id: groupc_id)

      # add new outcome
      outcome_model(
        title: "5 Group E outcome",
        outcome_group: group_e,
        context: Account.default
      )

      # add new group with outcomes
      make_group_structure({
                             title: "Group F",
                             outcomes: 1
                           },
                           Account.default,
                           group_e)

      exec(group_id: groupc_id)

      assert_tree_exists([{
                           title: "Group C",
                           outcomes: Array.new(3) { |i| "#{i} Group C outcome" },
                           groups: [{
                             title: "Group D",
                             outcomes: Array.new(5) { |i| "#{i} Group D outcome" }
                           },
                                    {
                                      title: "Group E",
                                      outcomes: Array.new(6) { |i| "#{i} Group E outcome" },
                                      groups: [{
                                        title: "Group F",
                                        outcomes: ["0 Group F outcome"],
                                      }]
                                    }]
                         }],
                         @course.root_outcome_group)
    end

    it "build structure correctly if import groups from different parents" do
      exec(group_id: find_group("Group B").id)
      exec(group_id: find_group("Group C").id)

      assert_tree_exists([{
                           title: "Group C",
                           outcomes: Array.new(3) { |i| "#{i} Group C outcome" },
                           groups: [{
                             title: "Group D",
                             outcomes: Array.new(5) { |i| "#{i} Group D outcome" }
                           },
                                    {
                                      title: "Group E",
                                      outcomes: Array.new(5) { |i| "#{i} Group E outcome" }
                                    }]
                         },
                          {
                            title: "Group B",
                            outcomes: Array.new(5) { |i| "#{i} Group B outcome" }
                          }],
                         @course.root_outcome_group)

      expect(LearningOutcomeGroup.find_by(context: @course, title: "Group B").root_account_id).to eq(@course.root_account_id)
      expect(LearningOutcomeGroup.find_by(context: @course, title: "Group B").root_account_id).to eq(@course.root_account_id)
    end

    it "reactivate previous imported deleted group" do
      exec(group_id: find_group("Group C").id)

      groupc = LearningOutcomeGroup.find_by(title: "Group D", context: @course)
      groupd = LearningOutcomeGroup.find_by(title: "Group C", context: @course)
      groupc.destroy
      groupd.destroy

      exec(group_id: find_group("Group C").id)
      groupc.reload
      groupd.reload

      expect(groupc.workflow_state).to eql("active")
      expect(groupd.workflow_state).to eql("active")
      expect(groupc.root_account_id).to eq(@course.resolved_root_account_id)
      expect(groupd.root_account_id).to eq(@course.resolved_root_account_id)
    end
  end

  context "global to account to course" do
    context "single import" do
      before do
        root_group = LearningOutcomeGroup.find_or_create_root(nil, true)
        @root_group = outcome_group_model(
          title: "Root Group A",
          outcome_group_id: root_group.id
        )
        outcome_model(
          title: "0 Root Group A outcome",
          outcome_group: @root_group,
          global: true
        )
        outcome_model(
          title: "1 Root Group A outcome",
          outcome_group: @root_group,
          global: true
        )

        # account level import
        exec(
          outcome_id: get_outcome_id("0 Root Group A outcome", nil),
          source_context_id: nil,
          source_context_type: nil,
          target_group_id: Account.default.root_outcome_group.id
        )
        # course level import
        exec(group_id: Account.default.root_outcome_group.child_outcome_groups.find_by(title: "Root Group A").id)
      end

      it "import Root Group A with 1 outcome to Account" do
        assert_tree_exists([{
                             title: "Group A",
                             outcomes: Array.new(5) { |i| "#{i} Group A outcome" },
                             groups: [{
                               title: "Group C",
                               outcomes: Array.new(3) { |i| "#{i} Group C outcome" },
                               groups: [{
                                 title: "Group D",
                                 outcomes: Array.new(5) { |i| "#{i} Group D outcome" }
                               },
                                        {
                                          title: "Group E",
                                          outcomes: Array.new(5) { |i| "#{i} Group E outcome" }
                                        }]
                             }]
                           },
                            {
                              title: "Group B",
                              outcomes: Array.new(5) { |i| "#{i} Group B outcome" }
                            },
                            {
                              title: "Root Group A",
                              outcomes: ["0 Root Group A outcome"]
                            }],
                           Account.default.root_outcome_group)
      end

      it "import Root Group A with 1 outcome to Course" do
        assert_tree_exists([{
                             title: "Root Group A",
                             outcomes: ["0 Root Group A outcome"]
                           }],
                           @course.root_outcome_group)
      end

      it "handles source_outcome_group_id" do
        account_imported_group = Account.default.root_outcome_group.child_outcome_groups.find_by(title: "Root Group A")
        course_imported_group = @course.root_outcome_group.child_outcome_groups.find_by(title: "Root Group A")

        expect(account_imported_group.source_outcome_group_id).to eql(@root_group.id)
        expect(course_imported_group.source_outcome_group_id).to eql(account_imported_group.id)
      end
    end

    context "multiple imports" do
      before do
        root_group = LearningOutcomeGroup.find_or_create_root(nil, true)
        @root_group = outcome_group_model(
          title: "Root Group",
          outcome_group_id: root_group.id
        )
        group_a = outcome_group_model(
          title: "Root Group A",
          outcome_group_id: @root_group.id
        )
        group_b = outcome_group_model(
          title: "Root Group B",
          outcome_group_id: group_a.id
        )
        group_c = outcome_group_model(
          title: "Root Group C",
          outcome_group_id: group_a.id
        )
        outcome_model(
          title: "0 Root Group B outcome",
          outcome_group: group_b,
          global: true
        )
        outcome_model(
          title: "0 Root Group C outcome",
          outcome_group: group_c,
          global: true
        )

        # account level
        exec(
          group_id: find_group("Root Group B").id,
          source_context_id: nil,
          source_context_type: nil,
          target_group_id: Account.default.root_outcome_group.id
        )

        # account level
        exec(
          group_id: find_group("Root Group C").id,
          source_context_id: nil,
          source_context_type: nil,
          target_group_id: Account.default.root_outcome_group.id
        )
      end

      it "imports correctly" do
        assert_tree_exists([{
                             title: "Group A",
                             outcomes: Array.new(5) { |i| "#{i} Group A outcome" },
                             groups: [{
                               title: "Group C",
                               outcomes: Array.new(3) { |i| "#{i} Group C outcome" },
                               groups: [{
                                 title: "Group D",
                                 outcomes: Array.new(5) { |i| "#{i} Group D outcome" }
                               },
                                        {
                                          title: "Group E",
                                          outcomes: Array.new(5) { |i| "#{i} Group E outcome" }
                                        }]
                             }]
                           },
                            {
                              title: "Group B",
                              outcomes: Array.new(5) { |i| "#{i} Group B outcome" }
                            },
                            {
                              title: "Root Group A",
                              groups: [{
                                title: "Root Group B",
                                outcomes: ["0 Root Group B outcome"],
                              },
                                       {
                                         title: "Root Group C",
                                         outcomes: ["0 Root Group C outcome"],
                                       }]
                            }],
                           Account.default.root_outcome_group)
        # course level
        exec(group_id: LearningOutcomeGroup.find_by(context: Account.default, title: "Root Group B").id)
        exec(group_id: LearningOutcomeGroup.find_by(context: Account.default, title: "Root Group C").id)

        assert_tree_exists([{
                             title: "Root Group A",
                             groups: [{
                               title: "Root Group B",
                               outcomes: ["0 Root Group B outcome"],
                             },
                                      {
                                        title: "Root Group C",
                                        outcomes: ["0 Root Group C outcome"],
                                      }]
                           }],
                           @course.root_outcome_group)
      end
    end
  end
end
