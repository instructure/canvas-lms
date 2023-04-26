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

describe DataFixup::SetNavigationPlacementSettingsForQuizLtiTools do
  let_once(:root_account) { Account.default }
  let_once(:developer_key) { DeveloperKey.create! }

  before(:once) do
    # create 2 Quiz LTI tools on 2 different accounts
    2.times do
      ContextExternalTool.create!(
        context: account_model(root_account: root_account, parent_account: root_account),
        consumer_key: "key",
        shared_secret: "secret",
        name: "Quizzes 2",
        tool_id: "Quizzes 2",
        url: "http://www.tool.com/launch",
        developer_key: developer_key,
        root_account: root_account
      )
    end

    ContextExternalTool.create!(
      context: account_model(root_account: root_account, parent_account: root_account),
      consumer_key: "key",
      shared_secret: "secret",
      name: "Some tool",
      tool_id: "Some tool",
      url: "http://www.tool.com/launch",
      developer_key: developer_key,
      root_account: root_account
    )
  end

  it "sets account_navigation settings for each Quiz LTI tool" do
    ContextExternalTool.quiz_lti.each do |quiz_tool|
      expect(quiz_tool.settings[:account_navigation]).to be_nil
    end

    DataFixup::SetNavigationPlacementSettingsForQuizLtiTools.run

    ContextExternalTool.quiz_lti.each do |quiz_tool|
      expect(quiz_tool.settings[:account_navigation]).to_not be_nil
      expect(quiz_tool.extension_setting(:account_navigation, :display_type)).to eq "full_width"
      expect(quiz_tool.extension_setting(:account_navigation, :text)).to eq "Item Banks"
      expect(quiz_tool.extension_setting(:account_navigation, :default)).to eq "enabled"
      expect(quiz_tool.extension_setting(:account_navigation, :custom_fields)).to eq({ "item_banks" => "account" })
    end

    ContextExternalTool.quiz_lti.find_by(workflow_state: "deleted")
  end

  it "sets course_navigation settings for each Quiz LTI tool" do
    ContextExternalTool.quiz_lti.each do |quiz_tool|
      expect(quiz_tool.settings[:course_navigation]).to be_nil
    end

    DataFixup::SetNavigationPlacementSettingsForQuizLtiTools.run

    ContextExternalTool.quiz_lti.each do |quiz_tool|
      expect(quiz_tool.settings[:course_navigation]).to_not be_nil
      expect(quiz_tool.extension_setting(:course_navigation, :display_type)).to eq "full_width"
      expect(quiz_tool.extension_setting(:course_navigation, :text)).to eq "Item Banks"
      expect(quiz_tool.extension_setting(:course_navigation, :default)).to eq "enabled"
      expect(quiz_tool.extension_setting(:course_navigation, :custom_fields)).to eq({ "item_banks" => "course" })
    end
  end

  it "does not set navigation placement settings for deleted Quiz LTI tools" do
    ContextExternalTool.quiz_lti.last.update!(workflow_state: "deleted")

    ContextExternalTool.quiz_lti.each do |quiz_tool|
      expect(quiz_tool.settings[:course_navigation]).to be_nil
    end

    DataFixup::SetNavigationPlacementSettingsForQuizLtiTools.run

    ContextExternalTool.quiz_lti.where.not(workflow_state: "deleted").each do |quiz_tool|
      expect(quiz_tool.settings[:course_navigation]).to_not be_nil
      expect(quiz_tool.settings[:account_navigation]).to_not be_nil
    end

    ContextExternalTool.quiz_lti.where(workflow_state: "deleted").each do |quiz_tool|
      expect(quiz_tool.settings[:course_navigation]).to be_nil
      expect(quiz_tool.settings[:account_navigation]).to be_nil
    end
  end

  it "does not set navigation placement settings for tools that are not Quiz LTI" do
    some_tool = ContextExternalTool.find_by(tool_id: "Some tool")

    expect(some_tool.quiz_lti?).to be false
    expect do
      DataFixup::SetNavigationPlacementSettingsForQuizLtiTools.run
      some_tool.reload
    end.to not_change { some_tool.settings }
  end

  it "does not set navigation placement settings for Quiz LTI tools where context_type is not Account" do
    quiz_tool = ContextExternalTool.quiz_lti.last
    quiz_tool.context = course_model
    quiz_tool.save

    expect do
      DataFixup::SetNavigationPlacementSettingsForQuizLtiTools.run
      quiz_tool.reload
    end.to not_change { quiz_tool.settings }
  end
end
