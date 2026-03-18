# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe Services::NewQuizzes::Routes::LaunchHelper do
  let(:course) { course_model }
  let(:account) { Account.default }
  let(:user) { user_model }
  let(:tool) do
    course.context_external_tools.create!(
      name: "New Quizzes",
      url: "http://example.com/launch",
      consumer_key: "key",
      shared_secret: "secret",
      tool_id: "Quizzes 2"
    )
  end
  let(:assignment) do
    assignment = assignment_model(context: course, submission_types: "external_tool")
    assignment.external_tool_tag = ContentTag.create!(
      context: assignment,
      content: tool,
      url: tool.url,
      content_type: "ContextExternalTool"
    )
    assignment.save!
    assignment
  end
  # rubocop:disable RSpec/VerifiedDoubles
  let(:controller) { double("ApplicationController", request: instance_double(ActionDispatch::Request), set_return_url: nil, lti_grade_passback_api_url: nil, blti_legacy_grade_passback_api_url: nil, lti_turnitin_outcomes_placement_url: nil, params: {}) }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:request) { controller.request }
  let(:pseudonym) { Pseudonym.create!(user:, account:, unique_id: "test@example.com") }

  describe ".default_launch_data" do
    let(:basename) { "/courses/#{course.id}/assignments/#{assignment.id}" }

    context "when assignment has a quiz_lti tool" do
      it "returns signed launch data with basename" do
        result = described_class.default_launch_data(
          tool:,
          assignment:,
          context: course,
          user:,
          controller:,
          request:,
          basename:,
          current_pseudonym: pseudonym,
          domain_root_account: account
        )

        expect(result).to be_a(Hash)
        expect(result[:basename]).to eq(basename)
      end

      it "creates a variable expander with correct parameters" do
        expect(Lti::VariableExpander).to receive(:new).with(
          account,
          course,
          controller,
          hash_including(
            current_user: user,
            current_pseudonym: pseudonym,
            assignment:,
            tool:
          )
        ).and_call_original

        described_class.default_launch_data(
          tool:,
          assignment:,
          context: course,
          user:,
          controller:,
          request:,
          basename:,
          current_pseudonym: pseudonym,
          domain_root_account: account
        )
      end

      it "calls LaunchDataBuilder with correct parameters" do
        expect(NewQuizzes::LaunchDataBuilder).to receive(:new).with(
          hash_including(
            context: course,
            assignment:,
            tool:,
            tag: assignment.external_tool_tag,
            current_user: user,
            controller:,
            request:,
            placement: nil
          )
        ).and_call_original

        described_class.default_launch_data(
          tool:,
          assignment:,
          context: course,
          user:,
          controller:,
          request:,
          basename:
        )
      end

      it "uses context.root_account when domain_root_account is not provided" do
        expect(Lti::VariableExpander).to receive(:new).with(
          course.root_account,
          anything,
          anything,
          anything
        ).and_call_original

        described_class.default_launch_data(
          tool:,
          assignment:,
          context: course,
          user:,
          controller:,
          request:,
          basename:
        )
      end
    end
  end

  describe ".build_speedgrader_launch_data" do
    let(:basename) { "/courses/#{course.id}/gradebook/speed_grader" }

    it "returns signed launch data with basename and grade_by_question_enabled" do
      result = described_class.build_speedgrader_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:,
        current_pseudonym: pseudonym,
        domain_root_account: account
      )

      expect(result).to be_a(Hash)
      expect(result[:basename]).to eq(basename)
      expect(result).to have_key(:grade_by_question_enabled)
    end

    it "defaults grade_by_question_enabled to false" do
      result = described_class.build_speedgrader_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:
      )

      expect(result[:grade_by_question_enabled]).to be false
    end

    it "returns true for grade_by_question_enabled when user preference is set" do
      user.preferences[:enable_speedgrader_grade_by_question] = true
      user.save!

      result = described_class.build_speedgrader_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:
      )

      expect(result[:grade_by_question_enabled]).to be true
    end

    it "calls LaunchDataBuilder with correct parameters" do
      expect(NewQuizzes::LaunchDataBuilder).to receive(:new).with(
        hash_including(
          context: course,
          assignment:,
          tool:,
          tag: assignment.external_tool_tag,
          current_user: user,
          controller:,
          request:,
          placement: nil
        )
      ).and_call_original

      described_class.build_speedgrader_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:
      )
    end
  end

  describe ".item_bank_launch_data" do
    let(:placement) { "course_navigation" }
    let(:basename) { "/courses/#{course.id}" }

    before do
      allow(tool).to receive(:quiz_lti?).and_return(true)
    end

    it "returns signed launch data with basename" do
      result = described_class.item_bank_launch_data(
        tool:,
        context: course,
        user:,
        controller:,
        request:,
        basename:,
        placement:,
        current_pseudonym: pseudonym,
        domain_root_account: account
      )

      expect(result).to be_a(Hash)
      expect(result[:basename]).to eq(basename)
    end

    it "creates a variable expander without assignment" do
      expect(Lti::VariableExpander).to receive(:new).with(
        account,
        course,
        controller,
        hash_including(
          current_user: user,
          current_pseudonym: pseudonym,
          tool:
        )
      ).and_call_original

      described_class.item_bank_launch_data(
        tool:,
        context: course,
        user:,
        controller:,
        request:,
        basename:,
        placement:,
        current_pseudonym: pseudonym,
        domain_root_account: account
      )
    end

    it "calls LaunchDataBuilder with placement" do
      expect(NewQuizzes::LaunchDataBuilder).to receive(:new).with(
        hash_including(
          context: course,
          assignment: nil,
          tool:,
          tag: nil,
          current_user: user,
          controller:,
          request:,
          placement:
        )
      ).and_call_original

      described_class.item_bank_launch_data(
        tool:,
        context: course,
        user:,
        controller:,
        request:,
        basename:,
        placement:
      )
    end

    it "uses context.root_account when domain_root_account is not provided" do
      expect(Lti::VariableExpander).to receive(:new).with(
        course.root_account,
        anything,
        anything,
        anything
      ).and_call_original

      described_class.item_bank_launch_data(
        tool:,
        context: course,
        user:,
        controller:,
        request:,
        basename:,
        placement:
      )
    end

    context "with account context" do
      let(:account_tool) do
        account.context_external_tools.create!(
          name: "New Quizzes",
          url: "http://example.com/launch",
          consumer_key: "key",
          shared_secret: "secret",
          tool_id: "Quizzes 2"
        )
      end
      let(:basename) { "/accounts/#{account.id}" }
      let(:placement) { "account_navigation" }

      it "returns signed launch data for account context" do
        result = described_class.item_bank_launch_data(
          tool: account_tool,
          context: account,
          user:,
          controller:,
          request:,
          basename:,
          placement:,
          domain_root_account: account
        )

        expect(result).to be_a(Hash)
        expect(result[:basename]).to eq(basename)
      end
    end
  end

  describe "integration with NewQuizzes::LaunchDataBuilder" do
    let(:basename) { "/courses/#{course.id}/assignments/#{assignment.id}" }
    let(:mock_signed_data) do
      {
        launch_url: "http://example.com/launch",
        signature: "abc123",
        other_data: "value"
      }
    end

    before do
      allow(described_class).to receive(:find_tool).and_return(tool)
      allow(tool).to receive(:quiz_lti?).and_return(true)

      mock_builder = instance_double(NewQuizzes::LaunchDataBuilder)
      allow(NewQuizzes::LaunchDataBuilder).to receive(:new).and_return(mock_builder)
      allow(mock_builder).to receive(:build_with_signature).and_return(mock_signed_data)
    end

    it "adds basename to the signed data returned by LaunchDataBuilder" do
      result = described_class.default_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:
      )

      expect(result).to eq(mock_signed_data.merge(basename:))
    end

    it "preserves all data from LaunchDataBuilder" do
      result = described_class.default_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:
      )

      expect(result[:launch_url]).to eq("http://example.com/launch")
      expect(result[:signature]).to eq("abc123")
      expect(result[:other_data]).to eq("value")
    end
  end

  describe "parameter compaction" do
    let(:basename) { "/courses/#{course.id}/assignments/#{assignment.id}" }

    before do
      allow(described_class).to receive(:find_tool).and_return(tool)
      allow(tool).to receive(:quiz_lti?).and_return(true)
    end

    it "does not pass nil values to VariableExpander" do
      expect(Lti::VariableExpander).to receive(:new).with(
        anything,
        anything,
        anything,
        hash_not_including(current_pseudonym: nil)
      ).and_call_original

      described_class.default_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:,
        current_pseudonym: nil
      )
    end

    it "passes current_pseudonym when provided" do
      expect(Lti::VariableExpander).to receive(:new).with(
        anything,
        anything,
        anything,
        hash_including(current_pseudonym: pseudonym)
      ).and_call_original

      described_class.default_launch_data(
        tool:,
        assignment:,
        context: course,
        user:,
        controller:,
        request:,
        basename:,
        current_pseudonym: pseudonym
      )
    end
  end
end
