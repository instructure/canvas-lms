# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe Lti::ExternalToolTab do
  subject { described_class.new(context, nil, [tool]) }

  let(:context) do
    account = Account.new
    allow(account).to receive(:id).and_return(1)
    account
  end

  let(:course_navigation) do
    {
      text: "Course Placement",
      url: "http://example.com/ims/lti",
      default: false,
      visibility: "admins"
    }
  end

  let(:account_navigation) do
    {
      text: "Account Placement",
      url: "http://example.com/ims/lti",
      default: "disabled",
      visibility: "members"
    }
  end

  let(:user_navigation) do
    {
      text: "User Placement",
      url: "http://example.com/ims/lti",
    }
  end

  let!(:tool) do
    tool = ContextExternalTool.new(
      url: "http://example.com/ims/lti",
      consumer_key: "asdf",
      shared_secret: "hjkl",
      name: "external tool",
      course_navigation:,
      account_navigation:,
      user_navigation:
    )
    allow(tool).to receive(:id).and_return(2)
    tool
  end

  it "sets the tab id to the tools asset_string" do
    expect(subject.tabs.first[:id]).to eq tool.asset_string
  end

  context "sharding" do
    specs_require_sharding

    it "sets the tab id to the tools asset_string relative to the context's shard" do
      course = @shard1.activate { course_model(account: account_model) }
      tool = external_tool_model(context: course)
      tabs = @shard2.activate do
        described_class.new(course, nil, [tool]).tabs
      end
      expect(tabs.first[:id]).to eq(@shard1.activate { tool.asset_string })
    end
  end

  it "sets the css_class" do
    expect(subject.tabs.first[:css_class]).to eq tool.asset_string
  end

  it "sets the external value to true" do
    expect(subject.tabs.first[:external]).to be true
  end

  it "sets the args to the context_id and tool_id" do
    expect(subject.tabs.first[:args]).to eq [context.id, tool.id]
  end

  it "sets the target if windowTarget is set on the tool" do
    tool[:settings][:windowTarget] = "_blank"
    subject = described_class.new(context, nil, [tool])
    expect(subject.tabs.first[:target]).to eq "_blank"
  end

  it "doesn't set the target if windowTarget is not set on the tool" do
    expect(subject.tabs.first.keys).not_to include :target
  end

  it "doesn't set the target if the windowTarget is not `_blank`" do
    tool[:settings][:windowTarget] = "foo"
    subject = described_class.new(context, nil, [tool])
    expect(subject.tabs.first.keys).not_to include :target
  end

  it "adds {dispaly: 'borderless'} if the windowTarget is present" do
    tool[:settings][:windowTarget] = "_blank"
    subject = described_class.new(context, nil, [tool])
    expect(subject.tabs.first[:args]).to include({ display: "borderless" })
  end

  it "sorts by tool id" do
    tool2 = ContextExternalTool.new(
      url: "http://example.com/ims/lti",
      consumer_key: "asdf",
      shared_secret: "hjkl",
      name: "Tool2",
      course_navigation:,
      account_navigation:
    )
    allow(tool2).to receive(:id).and_return(9)
    subject = described_class.new(context, nil, [tool2, tool])
    expect(subject.tabs.pluck(:id)).to eq [tool.asset_string, tool2.asset_string]
  end

  describe "#tool_id_for_tab" do
    it "returns nil when given nil" do
      expect(described_class.tool_id_for_tab(nil)).to be_nil
    end

    it "returns nil when given a hash that is not a tab" do
      expect(described_class.tool_id_for_tab({ abc: 123 })).to be_nil
    end

    it "returns nil when given a tab that is not a tool tab" do
      expect(
        described_class.tool_id_for_tab(
          { label: "foo", href: "http://google.com", id: "something", args: [tool.id, tool.id] }
        )
      ).to be_nil
    end

    it "returns the id of the tool in the tab when given a tool tab" do
      tool = external_tool_model
      tab = described_class.new(course_model, nil, [tool]).tabs.first
      expect(described_class.tool_id_for_tab(tab)).to eq(tool.id)
    end
  end

  describe "#tool_for_tab" do
    it "returns nil when given a tool tab with an invalid id" do
      tool = external_tool_model
      tab = described_class.new(course_model, nil, [tool]).tabs.first
      tab[:args][1] = ContextExternalTool.last.id + 999
      expect(described_class.tool_for_tab(tab)).to be_nil
    end

    it "returns the tool when given a tool tab with a valid tool" do
      tool = external_tool_model
      tab = described_class.new(course_model, nil, [tool]).tabs.first
      expect(described_class.tool_for_tab(tab)).to eq(tool)
    end
  end

  describe "course_navigation" do
    subject { described_class.new(context, :course_navigation, [tool]) }

    let(:context) do
      course = Course.new
      allow(course).to receive(:id).and_return(3)
      course
    end

    it "sets the label based on placement" do
      expect(subject.tabs.first[:label]).to eq course_navigation[:text]
    end

    it "sets the visibility" do
      expect(subject.tabs.first[:visibility]).to eq course_navigation[:visibility]
    end

    it "sets the href" do
      expect(subject.tabs.first[:href]).to eq :course_external_tool_path
    end

    it "sets hidden" do
      expect(subject.tabs.first[:hidden]).to eq course_navigation[:default]
    end

    it "sets the target if windowTarget is set on the tool" do
      tool[:settings][:course_navigation][:windowTarget] = "_blank"
      subject = described_class.new(context, :course_navigation, [tool])
      expect(subject.tabs.first[:target]).to eq "_blank"
    end
  end

  describe "account_navigation" do
    subject { described_class.new(context, :account_navigation, [tool]) }

    it "sets the label based on placement" do
      expect(subject.tabs.first[:label]).to eq account_navigation[:text]
    end

    it "sets the visibility" do
      expect(subject.tabs.first[:visibility]).to eq account_navigation[:visibility]
    end

    it "sets the href" do
      expect(subject.tabs.first[:href]).to eq :account_external_tool_path
    end

    it "sets hidden" do
      expect(subject.tabs.first[:hidden]).to be true
    end

    it "sets the target if windowTarget is set on the tool" do
      tool[:settings][:account_navigation][:windowTarget] = "_blank"
      subject = described_class.new(context, :account_navigation, [tool])
      expect(subject.tabs.first[:target]).to eq "_blank"
    end
  end

  describe "user_navigation" do
    subject { described_class.new(context, :user_navigation, [tool]) }

    let(:context) do
      user = User.new
      allow(user).to receive(:id).and_return(4)
      user
    end

    it "sets the label based on placement" do
      expect(subject.tabs.first[:label]).to eq user_navigation[:text]
    end

    it "sets the href" do
      expect(subject.tabs.first[:href]).to eq :user_external_tool_path
    end

    it "sets the target if windowTarget is set on the tool" do
      tool[:settings][:user_navigation][:windowTarget] = "_blank"
      subject = described_class.new(context, :user_navigation, [tool])
      expect(subject.tabs.first[:target]).to eq "_blank"
    end
  end
end
