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

require "spec_helper"

describe DataFixup::CreateQuizLtiNavigationPlacements do
  context "when there are no Quiz LTI tools" do
    it "does not create context_external_tool_placements" do
      expect(ContextExternalToolPlacement.count).to eq 0

      DataFixup::CreateQuizLtiNavigationPlacements.run

      expect(ContextExternalToolPlacement.count).to eq 0
    end
  end

  context "when there are Quiz LTI tools" do
    let_once(:root_account) { Account.default }
    let_once(:developer_key) { DeveloperKey.create! }

    before(:once) do
      # create 2 Quiz LTI tools on 2 different accounts
      2.times do
        ContextExternalTool.create!(
          context: account_model(root_account:, parent_account: root_account),
          consumer_key: "key",
          shared_secret: "secret",
          name: "Quizzes 2",
          tool_id: "Quizzes 2",
          url: "http://www.tool.com/launch",
          developer_key:,
          root_account:
        )
      end
    end

    let_once(:some_tool) do
      ContextExternalTool.create!(
        context: account_model(root_account:, parent_account: root_account),
        consumer_key: "key",
        shared_secret: "secret",
        name: "Some tool",
        tool_id: "Some tool",
        url: "http://www.tool.com/launch",
        developer_key:,
        root_account:
      )
    end

    it "creates an account level placement associated for each Quiz LTI tool" do
      expect(ContextExternalToolPlacement.count).to eq 0

      DataFixup::CreateQuizLtiNavigationPlacements.run

      ContextExternalTool.quiz_lti.where.not(workflow_state: "deleted").each do |quiz_tool|
        placements = quiz_tool.context_external_tool_placements

        expect(placements.count).to eq 2
        expect(placements.find_by(placement_type: "account_navigation", context_external_tool_id: quiz_tool.id)).to_not be_nil
        expect(placements.find_by(placement_type: "course_navigation", context_external_tool_id: quiz_tool.id)).to_not be_nil
      end
    end

    it "does not create navigation placements for deleted Quiz LTI tools" do
      ContextExternalTool.quiz_lti.last.update!(workflow_state: "deleted")

      expect(ContextExternalToolPlacement.count).to eq 0

      DataFixup::CreateQuizLtiNavigationPlacements.run

      ContextExternalTool.quiz_lti.where(workflow_state: "deleted").each do |quiz_tool|
        expect(quiz_tool.context_external_tool_placements.count).to eq 0
      end

      ContextExternalTool.quiz_lti.where.not(workflow_state: "deleted").each do |quiz_tool|
        expect(quiz_tool.context_external_tool_placements.count).to eq 2
      end
    end

    it "does not create navigation placements if the placements where already created" do
      expect(ContextExternalToolPlacement.count).to eq 0

      DataFixup::CreateQuizLtiNavigationPlacements.run

      expect(ContextExternalToolPlacement.count).to eq 4

      expect do
        DataFixup::CreateQuizLtiNavigationPlacements.run
      end.to not_change { ContextExternalToolPlacement.count }
    end

    it "does not create navigation placements for tools that are not Quiz LTI" do
      some_tool = ContextExternalTool.find_by(tool_id: "Some tool")

      expect(some_tool.quiz_lti?).to be false
      expect do
        DataFixup::CreateQuizLtiNavigationPlacements.run
        some_tool.reload
      end.to not_change { some_tool.context_external_tool_placements.count }
    end

    it "does not create navigation placements for Quiz LTI tools where context_type is not Account" do
      quiz_tool = ContextExternalTool.quiz_lti.last
      quiz_tool.context = course_model
      quiz_tool.save

      expect do
        DataFixup::CreateQuizLtiNavigationPlacements.run
        quiz_tool.reload
      end.to not_change { quiz_tool.context_external_tool_placements.count }
    end
  end
end
