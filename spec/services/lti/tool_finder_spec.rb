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

require "lti2_spec_helper"

describe Lti::ToolFinder do
  before(:once) do
    @root_account = Account.default
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    course_model(account: @account)
  end

  describe ".find_by" do
    subject { Lti::ToolFinder.find_by(id:, scope:) }

    let(:tool) { external_tool_1_3_model(context: @course) }
    let(:id) { tool.id }
    let(:scope) { nil }

    it "finds the tool by id" do
      expect(subject).to eq tool
    end

    context "when the tool is not found" do
      let(:id) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with scope" do
      let(:scope) { ContextExternalTool.active }

      context "when tool is in scope" do
        it "finds the tool" do
          expect(subject).to eq tool
        end
      end

      context "when tool is not in scope" do
        before do
          tool.destroy
        end

        it "returns nil" do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe ".find" do
    subject { Lti::ToolFinder.find(id, scope:) }

    let(:tool) { external_tool_1_3_model(context: @course) }
    let(:id) { tool.id }
    let(:scope) { nil }

    it "finds the tool by id" do
      expect(subject).to eq tool
    end

    context "when the tool is not found" do
      let(:id) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with scope" do
      let(:scope) { ContextExternalTool.active }

      context "when tool is in scope" do
        it "finds the tool" do
          expect(subject).to eq tool
        end
      end

      context "when tool is not in scope" do
        before do
          tool.destroy
        end

        it "raises an error" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe ".from_context" do
    subject { Lti::ToolFinder.from_context(@course, scope:) }

    let(:scope) { ContextExternalTool.where(consumer_key:) }
    let(:tool) { external_tool_1_3_model(context: @course) }
    let(:consumer_key) { "test" }

    before do
      tool.update!(consumer_key:)
    end

    it "returns the first tool it finds" do
      expect(subject).to eq tool
    end

    context "when there is no matching tool" do
      before do
        tool.update!(consumer_key: "other")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when tool is installed up the context chain" do
      let(:tool) { external_tool_1_3_model(context: @course.account) }

      it "returns the tool" do
        expect(subject).to eq tool
      end
    end
  end

  describe ".from_id!" do
    # moved directly from ContextExternalTool#find_for
    def new_external_tool(context)
      context.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "google.com")
    end

    it "finds the tool if it's attached to the course" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(Lti::ToolFinder.from_id!(tool.id, @course, placement: :course_navigation)).to eq tool
      expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "finds the tool if it's attached to the course's account" do
      tool = new_external_tool @course.account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(Lti::ToolFinder.from_id!(tool.id, @course, placement: :course_navigation)).to eq tool
      expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "finds the tool if it's attached to the course's root account" do
      tool = new_external_tool @course.root_account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(Lti::ToolFinder.from_id!(tool.id, @course, placement: :course_navigation)).to eq tool
      expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find the tool if it's attached to a sub-account" do
      @account = @course.account.sub_accounts.create!(name: "sub-account")
      tool = new_external_tool @account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find the tool if it's attached to another course" do
      @course2 = @course
      @course = course_model
      tool = new_external_tool @course2
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find the tool if it's not enabled for the correct navigation type" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises RecordNotFound if the id is invalid" do
      expect { Lti::ToolFinder.from_id!("horseshoes", @course, placement: :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find a course tool with workflow_state deleted" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.workflow_state = "deleted"
      tool.save!
      expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find an account tool with workflow_state deleted" do
      tool = new_external_tool @account
      tool.account_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.workflow_state = "deleted"
      tool.save!
      expect { Lti::ToolFinder.from_id!(tool.id, @account, placement: :account_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when the workflow state is "disabled"' do
      let(:tool) do
        tool = new_external_tool @account
        tool.account_navigation = { url: "http://www.example.com", text: "Example URL" }
        tool.workflow_state = "disabled"
        tool.save!
        tool
      end

      it "does not find an account tool with workflow_state disabled" do
        expect { Lti::ToolFinder.from_id!(tool.id, @account, placement: :account_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "when the tool is installed in a course" do
        let(:tool) do
          tool = new_external_tool @course
          tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
          tool.workflow_state = "disabled"
          tool.save!
          tool
        end

        it "does not find a course tool with workflow_state disabled" do
          expect { Lti::ToolFinder.from_id!(tool.id, @course, placement: :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "error handling" do
      subject { Lti::ToolFinder.from_id!(id, context) }

      let(:context) { @course }

      context "with invalid id" do
        let(:id) { (ContextExternalTool.last&.id || 0) + 1 }

        it "raises RecordNotFound" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with nil id" do
        let(:id) { nil }

        it "raises RecordNotFound" do
          expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe ".from_id" do
    subject { Lti::ToolFinder.from_id(id, context) }

    let(:context) { @course }

    context "with invalid id" do
      let(:id) { (ContextExternalTool.last&.id || 0) + 1 }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with nil id" do
      let(:id) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with cross-shard query" do
      specs_require_sharding

      let(:cross_shard_account) { @shard2.activate { account_model } }
      let(:cross_shard_course) { @shard2.activate { course_model(account: cross_shard_account) } }
      let(:should_raise) { false }
      let(:context) { cross_shard_course }
      let(:id) { tool.id }

      context "and tool directly in context" do
        let(:tool) { @shard2.activate { external_tool_model(context: cross_shard_course) } }

        before { tool }

        it "finds tool" do
          expect(subject).to eq tool
        end

        context "with context on wrong shard" do
          let(:context) { course_model }

          it "does not find tool" do
            expect(subject).to be_nil
          end
        end
      end

      context "and tool in context chain" do
        let(:tool) { @shard2.activate { external_tool_model(context: cross_shard_account) } }

        before { tool }

        it "finds tool" do
          expect(subject).to eq tool
        end
      end
    end
  end

  describe ".from_assignment" do
    let(:tool) do
      @course.context_external_tools.create(
        name: "a",
        consumer_key: "12345",
        shared_secret: "secret",
        url: "http://example.com/launch"
      )
    end

    it "finds the tool from an assignment" do
      a = @course.assignments.create!(title: "test",
                                      submission_types: "external_tool",
                                      external_tool_tag_attributes: { url: tool.url })
      expect(described_class.from_assignment(a)).to eq tool
    end

    it "returns nil if there is no content tag" do
      a = @course.assignments.create!(title: "test",
                                      submission_types: "external_tool")
      expect(described_class.from_assignment(a)).to be_nil
    end
  end

  describe "from_content_tag" do
    subject { Lti::ToolFinder.from_content_tag(*arguments) }

    let(:arguments) { [content_tag, tool.context] }
    let(:assignment) { assignment_model(course: tool.context) }
    let(:course) { course_model }
    let(:tool) { external_tool_model(context: course) }
    let(:content_tag_opts) { { url: tool.url, content_type: "ContextExternalTool", context: assignment } }
    let(:content_tag) { ContentTag.new(content_tag_opts) }
    let(:developer_key) { lti_developer_key_model(account: tool.context.root_account) }
    let(:lti_1_3_tool) do
      t = tool.dup
      t.lti_registration = developer_key.lti_registration
      t.developer_key_id = developer_key.id
      t.lti_version = "1.3"
      t.save!
      t.context_controls.create!(
        account: tool.context.root_account,
        available: true,
        registration: t.lti_registration
      )
      t
    end

    it { is_expected.to eq tool }

    context "when the tool is linked to the tag by id (LTI 1.1)" do
      let(:content_tag_opts) { super().merge({ content_id: tool.id }) }

      it { is_expected.to eq tool }

      context "and an LTI 1.3 tool has a conflicting URL" do
        let(:arguments) do
          [content_tag, tool.context]
        end

        before { lti_1_3_tool }

        it { is_expected.to be_use_1_3 }
      end
    end

    context "when the tool is linked to a tag by id (LTI 1.3)" do
      let(:content_tag_opts) { super().merge({ content_id: lti_1_3_tool.id }) }
      let(:duplicate_1_3_tool) do
        t = lti_1_3_tool.dup
        t.save!
        t.context_controls.create!(
          account: course.root_account,
          registration: t.lti_registration,
          available: true
        )
        t
      end

      context "with the lti_registrations_next flag off" do
        before do
          course.root_account.disable_feature!(:lti_registrations_next)
        end

        it "finds the tool with an available CC" do
          expect(subject).to eq(lti_1_3_tool)
        end

        it "finds the tool with an unavailable CC" do
          lti_1_3_tool.context_controls.first.update!(available: false)
          expect(subject).to eq(lti_1_3_tool)
        end
      end

      context "and an LTI 1.1 tool has a conflicting URL" do
        before { tool } # initialized already, but included for clarity

        it { is_expected.to eq lti_1_3_tool }

        context "and the LTI 1.3 tool is unavailable" do
          before do
            lti_1_3_tool.context_controls.first.update!(available: false)
          end

          it { is_expected.to eq tool }
        end

        context "and there are multiple matching LTI 1.3 tools" do
          before { duplicate_1_3_tool }

          let(:arguments) { [content_tag, tool.context] }
          let(:content_tag_opts) { super().merge({ content_id: lti_1_3_tool.id }) }

          it { is_expected.to eq lti_1_3_tool }

          context "and the original LTI 1.3 tool is unavailable" do
            before do
              lti_1_3_tool.context_controls.first.update!(available: false)
            end

            it "returns the duplicate tool instead" do
              expect(subject).to eq duplicate_1_3_tool
            end
          end
        end

        context "and the LTI 1.3 tool gets reinstalled" do
          before do
            # "install" a copy of the tool
            duplicate_1_3_tool

            # "uninstall" the original tool
            lti_1_3_tool.destroy!
          end

          it { is_expected.to eq duplicate_1_3_tool }
        end
      end
    end

    context "when there are blank arguments" do
      context "when the content tag argument is blank" do
        let(:arguments) { [nil, tool.context] }

        it { is_expected.to be_nil }
      end
    end

    context "when tag is not linked to an LTI tool" do
      let(:content_tag) { ContentTag.create!(content: assignment, context: tool.context) }
      let(:assignment) { assignment_model(course: tool.context) }

      it { is_expected.to be_nil }
    end

    context "when tag is linked to an LTI 2.0 tool" do
      # introduces message_handler and all required LTI 2 models
      include_context "lti2_spec_helper"

      let(:content_tag) { ContentTag.create!(content: message_handler, context: tool.context) }

      it { is_expected.to be_nil }
    end
  end

  describe "from_url" do
    subject { Lti::ToolFinder.from_url(url, context, preferred_tool_id:, exclude_tool_id:, preferred_client_id:, prefer_1_1:, only_1_3:) }

    let(:url) { "http://www.google.com/is/cool" }
    let(:context) { @course }
    let(:preferred_tool_id) { nil }
    let(:exclude_tool_id) { nil }
    let(:preferred_client_id) { nil }
    let(:prefer_1_1) { false }
    let(:only_1_3) { false }

    let(:tool) { @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret") }

    it "matches on the same domain" do
      tool
      expect(subject).to eql(tool)
    end

    context "when context is a course on a different shard" do
      specs_require_sharding

      before { tool }

      it "matches on the same domain" do
        @shard2.activate do
          expect(subject).to eql(tool)
        end
      end
    end

    it "is case insensitive when matching on the same domain" do
      tool.update!(domain: "Google.com")
      expect(subject).to eql(tool)
    end

    context "with subdomain url" do
      let(:url) { "http://www.google.com/is/cool" }

      it "matches on a subdomain" do
        tool
        expect(subject).to eql(tool)
      end
    end

    it "matches on a domain with a scheme attached" do
      tool.update!(domain: "http://google.com")
      expect(subject).to eql(tool)
    end

    it "does not match on non-matching domains" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool2 = @course.context_external_tools.create!(name: "a", domain: "www.google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://mgoogle.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to be_nil
      @found_tool = Lti::ToolFinder.from_url("http://sgoogle.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to be_nil
    end

    it "does not match on the closest matching domain" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool2 = @course.context_external_tools.create!(name: "a", domain: "www.google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.www.google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool2)
    end

    context "with exact url match" do
      let(:url) { "http://www.google.com/coolness" }

      before do
        tool.update!(url:)
      end

      it "matches" do
        expect(subject).to eql(tool)
      end
    end

    it "matches on url ignoring query parameters" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com/coolness?a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com/coolness?a=1&b=2", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "matches on url even when tool url contains query parameters" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness?a=1&b=2", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com/coolness?b=2&a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com/coolness?c=3&b=2&d=4&a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "does not match on url if the tool url contains query parameters that the search url doesn't" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness?a=1", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com/coolness?a=2", Course.find(@course.id))
      expect(@found_tool).to be_nil
    end

    it "does not match on url before matching on domain" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", consumer_key: "12345", shared_secret: "secret")
      @tool2 = @course.context_external_tools.create!(name: "a", domain: "www.google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com/coolness", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "does not match on domain if domain is nil" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://malicious.domain./hahaha", Course.find(@course.id))
      expect(@found_tool).to be_nil
    end

    it "matches on url or domain for a tool that has both" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      expect(Lti::ToolFinder.from_url("http://google.com/is/cool", Course.find(@course.id))).to eql(@tool)
      expect(Lti::ToolFinder.from_url("http://www.google.com/coolness", Course.find(@course.id))).to eql(@tool)
    end

    it "finds the context's tool matching on url first" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the nearest account's tool matching on url if there are no url-matching context tools" do
      @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool = @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the root account's tool matching on url before matching by domain on the course" do
      @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool = @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the context's tool matching on domain if no url-matching tools are found" do
      @tool = @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the nearest account's tool matching on domain if no url-matching tools are found" do
      @tool = @account.context_external_tools.create!(name: "c", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "e", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the root account's tool matching on domain if no url-matching tools are found" do
      @tool = @root_account.context_external_tools.create!(name: "e", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = Lti::ToolFinder.from_url("http://www.google.com/", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    context "when exclude_tool_id is set" do
      let(:exclude_tool_id) { tool.id }

      it "does not return the excluded tool" do
        expect(subject).to be_nil
      end
    end

    context "preferred_tool_id" do
      it "finds the preferred tool if there are two matching-priority tools" do
        @tool1 = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @tool2 = @course.context_external_tools.create!(name: "b", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool1.id)
        expect(@found_tool).to eql(@tool1)
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool2.id)
        expect(@found_tool).to eql(@tool2)
        @tool1.destroy
        @tool2.destroy

        @tool1 = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool2 = @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool1.id)
        expect(@found_tool).to eql(@tool1)
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool2.id)
        expect(@found_tool).to eql(@tool2)
      end

      it "finds the preferred tool even if there is a higher priority tool configured" do
        @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @preferred = @root_account.context_external_tools.create!(name: "f", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")

        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @preferred.id)
        expect(@found_tool).to eql(@preferred)
      end

      it "does not find the preferred tool if it is deleted" do
        @preferred = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @preferred.destroy
        @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool = @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @preferred.id)
        expect(@found_tool).to eql(@tool)
      end

      it "does not find the preferred tool if it is disabled" do
        @preferred = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @preferred.update!(workflow_state: "disabled")
        @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool = @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @preferred.id)
        expect(@found_tool).to eql(@tool)
      end

      it "does not return preferred tool outside of context chain" do
        preferred = @root_account.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        expect(Lti::ToolFinder.from_url("http://www.google.com", @course, preferred_tool_id: preferred.id)).to eq preferred
      end

      it "does not return preferred tool if url doesn't match" do
        c1 = @course
        preferred = c1.account.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        expect(Lti::ToolFinder.from_url("http://example.com", c1, preferred_tool_id: preferred.id)).to be_nil
      end

      it "finds preferred tool if url doesn't match but url's domain is a subdomain of the tool domain" do
        c1 = @course
        preferred = c1.account.context_external_tools.create!(name: "a", url: "http://www.google.com", domain: "example.com", consumer_key: "12345", shared_secret: "secret")
        # If we didn't favor the preferred tool, we would return this tool because it's in a closer context
        c1.context_external_tools.create!(name: "a", url: "http://www.google.com", domain: "example.com", consumer_key: "12345", shared_secret: "secret")
        expect(Lti::ToolFinder.from_url("http://subdomain.example.com", c1, preferred_tool_id: preferred.id)).to eq(preferred)
      end

      it "returns the preferred tool if the url is nil" do
        c1 = @course
        preferred = c1.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        expect(Lti::ToolFinder.from_url(nil, c1, preferred_tool_id: preferred.id)).to eq preferred
      end

      it "bypasses tool lookup if the url is nil and check_availability is false" do
        c1 = @course
        preferred = c1.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        expect(Lti::ToolFinder).not_to receive(:potential_matching_tools)
        expect(Lti::ToolFinder.from_url(nil, c1, preferred_tool_id: preferred.id)).to eq preferred
      end

      it "does not return preferred tool if it is 1.1 and there is a matching 1.3 tool" do
        registration = lti_developer_key_model(account: @course.root_account).tap do |k|
          lti_tool_configuration_model(developer_key: k, lti_registration: k.lti_registration)
        end.lti_registration
        @tool1_1 = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @tool1_3 = registration.new_external_tool(@course)
        @tool1_3.update!(name: "b", consumer_key: "12345", shared_secret: "secret", url: "http://www.google.com")

        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool1_1.id)
        expect(@found_tool).to eql(@tool1_3)
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool1_3.id)
        expect(@found_tool).to eql(@tool1_3)
        @tool1_1.destroy
        @tool1_3.destroy

        @tool1_1 = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool1_3 = registration.new_external_tool(@course)
        @tool1_3.update!(name: "b", consumer_key: "12345", shared_secret: "secret", domain: "google.com")
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool1_1.id)
        expect(@found_tool).to eql(@tool1_3)
        @found_tool = Lti::ToolFinder.from_url("http://www.google.com", Course.find(@course.id), preferred_tool_id: @tool1_3.id)
        expect(@found_tool).to eql(@tool1_3)
      end
    end

    context "when multiple ContextExternalTools have domain/url conflict" do
      before do
        ContextExternalTool.create!(
          context: @course,
          consumer_key: "key1",
          shared_secret: "secret1",
          name: "test faked tool",
          url: "http://nothing",
          domain: "www.tool.com",
          tool_id: "faked"
        )

        ContextExternalTool.create!(
          context: @course,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool",
          url: "http://www.tool.com/launch",
          tool_id: "real"
        )
      end

      it "picks up url in higher priority" do
        tool = Lti::ToolFinder.from_url("http://www.tool.com/launch?p1=2082", Course.find(@course.id))
        expect(tool.tool_id).to eq("real")
      end

      context "and there is a difference in LTI version" do
        def find_tool(url, **)
          Lti::ToolFinder.from_url(url, context, **)
        end

        before do
          # Creation order is important. Be default Canvas uses
          # creation order as a tie-breaker. Creating the LTI 1.3
          # tool first ensures we are actually exercising the preferred
          # LTI version matching logic.
          lti_1_1_tool
          lti_1_3_tool
        end

        let(:context) { @course }
        let(:domain) { "www.test.com" }
        let(:opts) { { url:, domain: } }
        let(:url) { "https://www.test.com/foo?bar=1" }
        let(:lti_1_1_tool) { external_tool_model(context:, opts:) }
        let(:registration) do
          lti_developer_key_model(account: context.root_account).tap do |k|
            lti_tool_configuration_model(developer_key: k, lti_registration: k.lti_registration)
          end.lti_registration
        end
        let(:lti_1_3_tool) do
          t = registration.new_external_tool(context)
          t.update!(**opts)
          t
        end

        it "prefers LTI 1.3 tools when there is an exact URL match" do
          expect(find_tool(url)).to eq lti_1_3_tool
        end

        it "prefers LTI 1.3 tools when there is an partial URL match" do
          expect(find_tool("#{url}&extra_param=1")).to eq lti_1_3_tool
        end

        it "prefers LTI 1.3 tools when there is an domain match" do
          expect(find_tool("https://www.test.com/another_endpoint")).to eq lti_1_3_tool
        end

        context "when prefer_1_1: true is passed in" do
          it "prefers LTI 1.1 tools when there is an exact URL match" do
            expect(find_tool(url, prefer_1_1: true)).to eq lti_1_1_tool
          end

          it "prefers LTI 1.1 tools when there is an partial URL match" do
            expect(find_tool("#{url}&extra_param=1", prefer_1_1: true)).to eq lti_1_1_tool
          end

          it "prefers LTI 1.1 tools when there is an domain match" do
            expect(find_tool("https://www.test.com/another_endpoint", prefer_1_1: true)).to \
              eq lti_1_1_tool
          end
        end

        context "when the LTI Registrations Next flag is disabled" do
          before do
            context.root_account.disable_feature!(:lti_registrations_next)
          end

          it "still finds the available LTI 1.3 tool" do
            expect(subject).to eql(lti_1_3_tool)
          end

          it "still finds an unavailable LTI 1.3 tool" do
            registration.context_controls.find_by(course: context, deployment: lti_1_3_tool).update!(available: false)

            expect(subject).to eql(lti_1_3_tool)
          end
        end
      end
    end

    context("with a client id") do
      let(:url) { "http://test.com" }
      let(:tool_params) do
        {
          name: "a",
          url:,
          consumer_key: "12345",
          shared_secret: "secret",
        }
      end
      let!(:tool1) { @course.context_external_tools.create!(tool_params) }
      let!(:tool2) do
        @course.context_external_tools.create!(
          tool_params.merge(developer_key: DeveloperKey.create!)
        )
      end

      it "preferred_tool_id has precedence over preferred_client_id" do
        external_tool = Lti::ToolFinder.from_url(
          url, @course, preferred_tool_id: tool1.id, preferred_client_id: tool2.developer_key.id
        )
        expect(external_tool).to eq tool1
      end

      it "finds the tool based on developer key id" do
        external_tool = Lti::ToolFinder.from_url(
          url, @course, preferred_client_id: tool2.developer_key.id
        )
        expect(external_tool).to eq tool2
      end
    end

    context "with duplicate tools" do
      let(:url) { "http://example.com/launch" }
      let(:tool) do
        t = @course.context_external_tools.create!(name: "test", domain: "example.com", url:, consumer_key: "12345", shared_secret: "secret")
        t.global_navigation = {
          url: "http://www.example.com",
          text: "Example URL"
        }
        t.save!
        t
      end
      let(:duplicate) do
        t = tool.dup
        t.save!
        t
      end

      context "when original tool exists" do
        it "finds original tool" do
          tool
          expect(Lti::ToolFinder.from_url(url, @course)).to eq tool
        end
      end

      context "when original tool is gone" do
        before do
          duplicate
          tool.destroy
        end

        it "finds duplicate tool" do
          expect(Lti::ToolFinder.from_url(url, @course)).to eq duplicate
        end
      end

      context "when non-duplicate tool was created later" do
        before do
          duplicate
          tool.update_column :identity_hash, "duplicate"
          # re-calculate the identity hash for the later tool
          duplicate.update!(domain: "fake.com")
          duplicate.update!(domain: "example.com")
        end

        it "finds tool with non-duplicate identity_hash" do
          expect(Lti::ToolFinder.from_url(url, @course)).to eq duplicate
        end
      end

      context "when duplicate is 1.3" do
        before do
          dev_key = lti_developer_key_model(account: @course.root_account)
          duplicate.lti_version = "1.3"
          duplicate.developer_key = dev_key
          duplicate.lti_registration = dev_key.lti_registration
          duplicate.save!
          duplicate.context_controls.create!(course: @course, registration: dev_key.lti_registration, available: true)
          duplicate.update_column :identity_hash, "duplicate"
        end

        it "finds duplicate tool" do
          expect(Lti::ToolFinder.from_url(url, @course)).to eq duplicate
        end
      end
    end

    describe "when only_1_3 is passed in" do
      let(:url) { "http://example.com/launch" }
      let(:tool) do
        @course.context_external_tools.create!(name: "test", domain: "example.com", url:, consumer_key: "12345", shared_secret: "secret")
      end

      context "when the matching tool is 1.1" do
        it "returns nil" do
          expect(Lti::ToolFinder.from_url(url, @course, only_1_3: true)).to be_nil
        end
      end

      context "when the matching tool is 1.3" do
        before do
          dev_key = lti_developer_key_model(account: @course.root_account)
          tool.lti_version = "1.3"
          tool.developer_key = dev_key
          tool.lti_registration = dev_key.lti_registration
          tool.save!
          tool.context_controls.create!(course: @course, registration: dev_key.lti_registration, available: true)
        end

        it "returns the tool" do
          expect(Lti::ToolFinder.from_url(url, @course, only_1_3: true)).to eq tool
        end
      end
    end

    context "with env-specific override urls" do
      subject { Lti::ToolFinder.from_url(given_url, @course) }

      let(:given_url) { "http://example.beta.com/launch?foo=bar" }
      let(:tool) do
        t = @course.context_external_tools.create!(name: "test", domain: "example.com", url: "http://example.com/launch", consumer_key: "12345", shared_secret: "secret")
        t.global_navigation = {
          url: "http://www.example.com",
          text: "Example URL"
        }
        t.save!
        t
      end

      shared_examples_for "matches tool with overrides" do
        context "in production environment" do
          it "does not match" do
            expect(subject).to be_nil
          end
        end

        context "in nonprod environment" do
          before do
            allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")
          end

          it "matches on override" do
            expect(subject).to eq tool
          end
        end
      end

      context "when tool has override domain" do
        before do
          tool.settings[:environments] = {
            domain: "example.beta.com"
          }
          tool.save!
        end

        it_behaves_like "matches tool with overrides"
      end

      context "when tool has override url" do
        before do
          tool.settings[:environments] = {
            launch_url: "http://example.beta.com/launch"
          }
          tool.save!
        end

        it_behaves_like "matches tool with overrides"
      end

      context "when tool has override url with query parameters" do
        before do
          tool.settings[:environments] = {
            launch_url: "http://example.beta.com/launch?foo=bar"
          }
          tool.save!
        end

        it_behaves_like "matches tool with overrides"
      end
    end

    context "when closest matching tool is from a different developer key" do
      let(:url) { "http://test.com" }
      let(:tool_params) do
        {
          name: "a",
          url:,
          consumer_key: "12345",
          shared_secret: "secret",
          developer_key: original_key
        }
      end
      let(:original_key) { DeveloperKey.create! }
      let(:other_key) { DeveloperKey.create! }
      let(:original_tool) { @course.context_external_tools.create!(tool_params) }
      let(:matching_tool) { @course.root_account.context_external_tools.create!(tool_params) }
      let(:closest_tool) { @course.context_external_tools.create!(tool_params.merge(developer_key: other_key)) }

      before do
        original_tool.destroy!
        matching_tool
        closest_tool
      end

      context "and the flag is disabled" do
        before do
          @course.root_account.disable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "returns the closest matching tool" do
          expect(Lti::ToolFinder.from_url(url, @course, preferred_tool_id: original_tool.id)).to eq closest_tool
        end
      end

      context "and the flag is enabled" do
        before do
          @course.root_account.enable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "prefers tool from the same developer key" do
          expect(Lti::ToolFinder.from_url(url, @course, preferred_tool_id: original_tool.id)).to eq matching_tool
        end
      end
    end
  end

  describe "potential_matching_tools" do
    subject do
      Lti::ToolFinder.send(:potential_matching_tools, context: @course, preferred_tool_id:, original_client_id:).to_a
    end

    let(:tool1) { external_tool_model(context: @course, opts: { name: "tool1" }) }
    let(:tool2) { external_tool_model(context: @course, opts: { name: "tool2" }) }
    let(:tool3) { external_tool_model(context: @course, opts: { name: "tool3" }) }
    let(:tools) { [tool1, tool2, tool3] }
    let(:preferred_tool_id) { nil }
    let(:original_client_id) { nil }
    let(:key) { DeveloperKey.create! }

    before do
      # initialize tools
      tools
    end

    context "when preferred_tool_id contains a sql injection" do
      let(:preferred_tool_id) { "123\npsql syntax error" }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when tool is from separate context" do
      let(:other_tool) { external_tool_model(context: Course.create!) }

      it "does not include tools from separate contexts" do
        expect(subject).not_to include(other_tool)
      end
    end

    context "with tools in the context chain" do
      let(:account_tool) { external_tool_model(context: @course.account, opts: { name: "Account Tool" }) }

      before do
        # We can't just soft-delete tools because the finder doesn't actually filter them out and our
        # sorting criteria doesn't currently account for soft-deleted tools, so they might actually
        # end up at the front of the list, depending on how Postgres is feeling that day.
        tool2.destroy_permanently!
        tool3.destroy_permanently!
        account_tool
      end

      it "sorts tool from immediate context to the front" do
        expect(subject.first).to eq tool1
      end

      it "sorts tool from farthest context to the back" do
        expect(subject.last).to eq account_tool
      end
    end

    context "with tools that have subdomains and urls" do
      before do
        tool2.update!(domain: "c.b.a.com")
        tool3.update!(domain: "a.com")
        tool1.update!(url: "https://a.com/launch")
      end

      it "sorts tools with more subdomains to the front" do
        expect(subject.first).to eq tool2
      end

      it "sorts tools with fewer subdomains to the back" do
        expect(subject.second).to eq tool3
      end

      it "sorts tools with url and no domain to the back" do
        expect(subject.last).to eq tool1
      end
    end

    context "with different LTI versions" do
      let(:registration) do
        lti_developer_key_model(account: @course.root_account).tap do |k|
          lti_tool_configuration_model(developer_key: k, lti_registration: k.lti_registration)
        end.lti_registration
      end
      let(:tool3) { registration.new_external_tool(@course) }

      before do
        tool1.destroy_permanently!
      end

      it "sorts 1.3 tools to the front" do
        expect(subject.first).to eq tool3
      end

      it "sorts 1.1 tools to the back" do
        expect(subject.last).to eq tool2
      end

      context "when prefer_1_1 is true" do
        subject do
          Lti::ToolFinder.send(:potential_matching_tools, context: @course, preferred_tool_id:, prefer_1_1: true).to_a
        end

        it "sorts 1.1 tools to the front and 1.3 tools to the back" do
          expect(subject.first).to eq tool2
          expect(subject.last).to eq tool3
        end
      end
    end

    context "with duplicate tools" do
      before do
        tool2.update!(name: "tool1")
        tool3.update!(name: "tool1")
      end

      it "sorts non-duplicate tools to the front" do
        expect(subject.first).to eq tool1
      end

      it "sorts duplicate tools to the back" do
        # The order here is not guaranteed, but we know that the duplicates
        # will be at the end of the list.
        expect(subject[1..]).to match_array([tool2, tool3])
      end
    end

    context "when preferred_tool_id is provided" do
      let(:preferred_tool_id) { tool2.id }

      it "sorts tool with that id to the front" do
        expect(subject.first).to eq tool2
      end
    end

    context "when closest matching tool is from a different developer key" do
      let(:original_client_id) { key.id }

      before do
        # preferred tool is gone
        tool3.delete

        # the tool we actually want is farther up in context chain
        tool1.context = @course.account
        tool1.developer_key = key
        tool1.save!

        # the tool that matches first is from the wrong dev key
        tool2.developer_key = DeveloperKey.create!
        tool2.save!
      end

      context "and flag is enabled" do
        before do
          @course.root_account.enable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "prefers tool from the same developer key" do
          expect(subject.first).to eq tool1
        end
      end

      context "and flag is disabled" do
        before do
          @course.root_account.disable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "prefers tool from closer context" do
          expect(subject.first).to eq tool2
        end
      end
    end

    context "with many tools that mix all ordering conditions" do
      let(:registration) do
        lti_developer_key_model(account: @course.root_account).tap do |k|
          lti_tool_configuration_model(developer_key: k, lti_registration: k.lti_registration)
        end.lti_registration
      end
      let(:tool3) do
        t = registration.new_external_tool(@course)
        t.update!(domain: "c.com")
        t
      end
      let(:tool1) do
        t = registration.new_external_tool(@course)
        t.update!(domain: "a.b.c.com")
        t
      end
      let(:account_tool) do
        t = registration.new_external_tool(@course.account)
        t.update!(domain: "b.c.com")
        t
      end
      let(:lti1tool) do
        t = tool1.dup
        t.developer_key_id = nil
        t.lti_registration_id = nil
        t.lti_version = "1.1"
        t.domain = "b.c.com"
        t.save!
        t
      end
      let(:dupe_tool) do
        t = tool1.dup
        t.save!
        t.context_controls.create!(
          account: @course.root_account,
          registration:,
          available: true
        )
        t
      end
      let(:preferred_tool) do
        t = tool1.dup
        t.name = "preferred"
        t.save!
        t.context_controls.create!(
          account: @course.root_account,
          registration:,
          available: true
        )
        t
      end
      let(:preferred_tool_id) { preferred_tool.id }

      before do
        tool3
        tool2
        tool1
        account_tool
        lti1tool
        preferred_tool
        dupe_tool
      end

      it "sorts tools in order of order clauses" do
        expect(subject.map(&:id)).to eq [
          preferred_tool,
          tool1,
          tool3,
          account_tool,
          dupe_tool,
          lti1tool,
          tool2
        ].map(&:id)
      end
    end
  end

  describe "associated_1_1_tool" do
    specs_require_cache(:redis_cache_store)

    subject { Lti::ToolFinder.associated_1_1_tool(lti_1_3_tool, context, requested_url) }

    let(:context) { @course }
    let(:domain) { "test.com" }
    let(:opts) { { url:, domain: } }
    let(:requested_url) { nil }
    let(:url) { "https://test.com/foo?bar=1" }
    let!(:lti_1_1_tool) { external_tool_model(context:, opts:) }
    let!(:lti_1_3_tool) { external_tool_1_3_model(context:, opts:) }

    it { is_expected.to eq lti_1_1_tool }

    context "when tool is nil" do
      let(:lti_1_3_tool) { nil }

      it { is_expected.to be_nil }
    end

    it "caches the result" do
      expect(subject).to eq lti_1_1_tool

      allow(Lti::ToolFinder).to receive(:potential_matching_tools)
      Lti::ToolFinder.associated_1_1_tool(lti_1_3_tool, context, requested_url)
      expect(Lti::ToolFinder).not_to have_received(:potential_matching_tools)
    end

    it "finds deleted 1.1 tools" do
      lti_1_1_tool.destroy
      expect(subject).to eq(lti_1_1_tool)
    end

    it "finds nil and doesn't error on tools with invalid URL & Domains" do
      lti_1_1_tool.update_column(:url, "http://url path>/invalidurl}")
      lti_1_1_tool.update_column(:domain, "url path>/invalidurl}")

      expect { subject }.not_to raise_error
      expect(subject).to be_nil
    end

    it "finds tools in a higher level context" do
      lti_1_1_tool.update!(context: context.account)
      expect(subject).to eq(lti_1_1_tool)
    end

    it "ignores duplicate tools" do
      lti_1_1_tool.dup.save!
      expect(subject).to eq(lti_1_1_tool)
    end

    context "the request is to a subdomain of the tools' domain" do
      let(:requested_url) { "https://morespecific.test.com/foo?bar=1" }

      it { is_expected.to eq(lti_1_1_tool) }

      context "there's another 1.1 tool with that subdomain" do
        let(:specific_opts) do
          {
            url: "https://morespecific.test.com/foo?bar=1",
            domain: "https://morespecific.test.com"
          }
        end
        let!(:specific_1_1_tool) { external_tool_model(context:, opts: specific_opts) }

        it { is_expected.to eq(specific_1_1_tool) }
      end
    end
  end

  describe "filter_by_unavailable_context_controls" do
    subject { Lti::ToolFinder.send(:filter_by_unavailable_context_controls, scope, root_account) }

    let_once(:root_account) { account_model }
    let_once(:dev_key) do
      lti_developer_key_model(account: root_account).tap do |k|
        lti_tool_configuration_model(account: k.account, developer_key: k, lti_registration: k.lti_registration)
      end
    end
    let_once(:registration) { dev_key.lti_registration }
    let_once(:tool) { registration.new_external_tool(root_account) }
    let_once(:old_tool) { external_tool_model(context: root_account) }

    let(:scope) { ContextExternalTool.all }

    it "allows 1.3 and 1.1 tools if they are available" do
      expect(subject).to include(tool, old_tool)
    end

    context "with multiple 1.3 tools associated with the same registration" do
      let_once(:other_tool) { registration.new_external_tool(root_account) }

      context "one of the tools is unavailable" do
        before(:once) do
          tool.context_controls.first.update!(available: false)
        end

        it "only returns the other tool in the root account" do
          expect(subject).not_to include(tool)
          expect(subject).to include(other_tool)
        end

        it "only returns the other tool in a subaccount" do
          subaccount = account_model(parent_account: root_account)
          expect(Lti::ToolFinder.send(:filter_by_unavailable_context_controls, scope, subaccount)).not_to include(tool)
          expect(Lti::ToolFinder.send(:filter_by_unavailable_context_controls, scope, subaccount)).to include(other_tool)
        end

        it "only returns the other tool in a course" do
          subaccount = account_model(parent_account: root_account)
          course = course_model(account: subaccount)
          expect(Lti::ToolFinder.send(:filter_by_unavailable_context_controls, scope, course)).not_to include(tool)
          expect(Lti::ToolFinder.send(:filter_by_unavailable_context_controls, scope, course)).to include(other_tool)
        end
      end
    end
  end
end
