# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Lti::ContextToolFinder do
  before(:once) do
    @root_account = Account.default
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    course_model(account: @account)
  end

  def create_tool(context, name, opts)
    context.context_external_tools.create!(
      { name:, consumer_key: "12345", shared_secret: "secret" }.merge(opts)
    )
  end

  shared_examples_for "a method creating a scope for all tools for a context" do
    it "retrieves all tools in alphabetical order" do
      @tools = [
        create_tool(@root_account, "f", domain: "google.com"),
        create_tool(@root_account, "e", url: "http://www.google.com"),
        create_tool(@account, "d", domain: "google.com"),
        create_tool(@course, "a", url: "http://www.google.com"),
        create_tool(@course, "b", domain: "google.com"),
        create_tool(@account, "c", url: "http://www.google.com"),
      ]
      expect(method_returning_scope.call(@course).to_a).to eql(@tools.sort_by(&:name))
    end

    it "returns all tools that are selectable" do
      @tools = [
        create_tool(@root_account, "f", domain: "google.com"),
        create_tool(@root_account, "e", url: "http://www.google.com", not_selectable: true),
        create_tool(@account, "d", domain: "google.com"),
        create_tool(@course, "a", url: "http://www.google.com", not_selectable: true),
      ]
      tools = method_returning_scope.call(@course, selectable: true)
      expect(tools.count).to eq 2
    end

    it "returns multiple requested placements" do
      tool1 = @course.context_external_tools.create!(name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "Another Tool", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:editor_button] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(name: "Third Tool", consumer_key: "key", shared_secret: "secret")
      tool3.settings[:resource_selection] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool3.save!
      placements = Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS + ["resource_selection"]
      expect(method_returning_scope.call(@course, placements:).to_a).to eql([tool1, tool3].sort_by(&:name))
    end

    it "honors only_visible option" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      @tools = [
        create_tool(@root_account, "f", domain: "google.com"),
        create_tool(@course,
                    "d",
                    domain: "google.com",
                    settings: { assignment_view: { visibility: "admins" } }),
        create_tool(@course,
                    "a",
                    url: "http://www.google.com",
                    settings: { assignment_view: { visibility: "members" } })
      ]

      tools = method_returning_scope.call(@course)
      expect(tools.count).to eq 3
      tools = method_returning_scope.call(@course, only_visible: true, current_user: @user, visibility_placements: ["assignment_view"])
      expect(tools.count).to eq 1
      expect(tools[0].name).to eq "a"
    end
  end

  describe ".all_tools_scope_union" do
    it "returns a ScopeUnion with a scope for the tool" do
      expect(described_class.all_tools_scope_union(@course)).to be_a(Lti::ScopeUnion)
    end

    it_behaves_like "a method creating a scope for all tools for a context" do
      let(:method_returning_scope) do
        lambda do |*args|
          # unlike all_tools_for, this is not sorted (for multiple shards sort needs to happen
          # in ruby anyway). When we remove all_tools_for we can remove the order(:name) and
          # tweak the expectations to not expect order.
          described_class.all_tools_scope_union(*args).scopes.first.order(:name)
        end
      end
    end

    it "applies the base_scope" do
      tools = [
        create_tool(@root_account, "hello", domain: "google.com"),
        create_tool(@account, "bye", domain: "google.com"),
        create_tool(@course, "hello", domain: "google.com"),
        create_tool(course_model, "hello", url: "http://www.google.com"),
      ]
      scope_union = described_class.all_tools_scope_union(
        tools[2].course,
        base_scope: ContextExternalTool.where(name: "hello")
      )
      expect(scope_union.to_unsorted_array).to contain_exactly(tools[0], tools[2])
    end
  end

  describe "all_tools_sorted_array" do
    it "returns all the tools, sorted" do
      create_tool(@root_account, "b", domain: "google.com")
      create_tool(@account, "d", url: "http://www.google.com")
      create_tool(@account, "a", domain: "google.com")
      create_tool(@course, "c", url: "http://www.google.com")
      result = described_class.new(@course).all_tools_sorted_array
      expect(result.map(&:name)).to eq(%w[a b c d])
    end

    context "when exclude_admin_visibility is true" do
      it "doesn't include admin tools of type options[:type]" do
        create_tool(
          @account,
          "1",
          domain: "google.com",
          settings: { assignment_view: { visibility: "admins" } }
        )
        tool2 = create_tool(
          @account,
          "2",
          url: "http://www.google.com",
          settings: { assignment_view: { visibility: "members" } }
        )
        create_tool(
          @account,
          "3",
          url: "http://www.google.com",
          settings: { course_navigation: { visibility: "members" } }
        )

        finder = described_class.new(@course, type: :assignment_view)
        expect(finder.all_tools_sorted_array(exclude_admin_visibility: true)).to eq([tool2])
      end
    end
  end

  describe "all_tools_for" do
    it "returns a scope" do
      expect(described_class.all_tools_for(@course)).to be_a(ActiveRecord::Relation)
    end

    it "returns nil if context is nil" do
      expect(described_class.all_tools_for(nil)).to be_nil
    end

    it_behaves_like "a method creating a scope for all tools for a context" do
      let(:method_returning_scope) do
        lambda do |*args|
          described_class.all_tools_for(*args)
        end
      end
    end
  end
end
