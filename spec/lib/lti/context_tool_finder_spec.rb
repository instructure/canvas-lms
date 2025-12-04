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
      tools = method_returning_scope.call(@course, only_visible: true, current_user: @user, placements: ["assignment_view"])
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
        lambda do |context, **args|
          # unlike all_tools_for, this is not sorted (for multiple shards sort needs to happen
          # in ruby anyway). When we remove all_tools_for we can remove the order(:name) and
          # tweak the expectations to not expect order.
          described_class.all_tools_scope_union(context, **args).scopes.first.order(:name)
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

    it "returns empty relation if context is nil" do
      expect(described_class.all_tools_for(nil)).to be_empty
    end

    it_behaves_like "a method creating a scope for all tools for a context" do
      let(:method_returning_scope) do
        lambda do |context, **args|
          described_class.all_tools_for(context, **args)
        end
      end
    end

    context "with tools" do
      let(:tool1) { create_tool(@course, "c", domain: "google.com") }
      let(:tool2) { create_tool(@account, "b", domain: "google.com") }
      let(:tool3) { create_tool(@root_account, "c", domain: "google.com") }
      let(:tool4) { create_tool(@course, "a", domain: "google.com") }

      before do
        [tool1, tool2, tool3, tool4] # instantiate
      end

      context "with no order options" do
        subject { described_class.all_tools_for(@course, order_in_scope: false) }

        it "does not order tools" do
          expect(subject.to_sql).not_to include("ORDER BY")
          expect(subject).to include(tool1, tool2, tool3, tool4)
        end
      end

      context "with default order" do
        subject { described_class.all_tools_for(@course) }

        it "orders tools by name then id" do
          expect(subject.to_sql).to include("ORDER BY")
          expect(subject).to eq [tool4, tool2, tool1, tool3]
        end
      end

      context "with only order_by_context" do
        subject { described_class.all_tools_for(@course, order_by_context: true, order_in_scope: false) }

        before do
          tool4.destroy # to avoid ambiguity, only have one course-level tool
        end

        it "orders tools by the context chain" do
          expect(subject.to_sql).to include("ORDER BY")
          # course first, then subaccounts, then root account
          expect(subject).to eq [tool1, tool2, tool3]
        end
      end

      context "with order_by_scope and order_by_context" do
        subject { described_class.all_tools_for(@course, order_by_context: true, order_in_scope: true) }

        it "orders tools by the context chain and then by name" do
          expect(subject.to_sql).to include("ORDER BY")
          expect(subject).to eq [tool4, tool1, tool2, tool3]
        end
      end

      context "with an unavailable context control" do
        let(:registration) do
          lti_registration_with_tool(account: @course.root_account, binding_params: { workflow_state: "on" })
        end

        let!(:registration_tool1) { registration.deployments.first }
        let!(:registration_tool2) { registration.new_external_tool(@root_account) }

        before do
          # unavailable CC in @account for registration_tool1
          Lti::ContextControl.create!(
            account: @account,
            deployment: registration_tool1,
            registration:,
            available: false
          )
        end

        it "does not return an unavailable tool" do
          expect(described_class.all_tools_for(@account, order_by_context: true)).to eq [
            tool2, # @account
            tool3, # @root_account
            registration_tool2 # @root_account, no unavailable context control
          ]
        end

        it "does not return a tool for course that is made unavailable in parent account" do
          expect(described_class.all_tools_for(@course, order_by_context: true)).to eq [
            tool4, # @course
            tool1, # @course
            tool2, # @account
            tool3, # @root_account
            registration_tool2 # @root_account, no unavailable context control
          ]
        end

        it "returns a tool for course that is unavailable in parent account but available in course" do
          Lti::ContextControl.create!(
            course: @course,
            deployment: registration_tool1,
            registration:,
            available: true
          )

          expect(described_class.all_tools_for(@course, order_by_context: true)).to eq [
            tool4, # @course
            tool1, # @course
            tool2, # @account
            tool3, # @root_account
            registration_tool1, # @root_account, context control made available for @course
            registration_tool2  # @root_account, no unavailable context control
          ]
        end

        it "does not affect the tool availability of the lti_registrations_next flag is off" do
          @account.root_account.disable_feature!(:lti_registrations_next)

          expect(described_class.all_tools_for(@account, order_by_context: true)).to eq [
            tool2, # @account
            tool3, # @root_account
            registration_tool1, # @root_account, unavailable context control being ignored b/c of flag
            registration_tool2  # @root_account, no unavailable context control
          ]
        end
      end

      context "with account bindings and context controls" do
        before do
          context_control
          # Manually set the tool's workflow_state to match the account binding's
          # workflow_state. In practice, this will happen in a delayed job when the
          # developer_key_account_binding is created or updated. There are also tests
          # for this in create_registration_service_spec.rb.
          tool.update(workflow_state: binding_workflow_state ? "public" : "disabled")
        end

        let(:registration) do
          lti_registration_with_tool(account: @root_account, binding_params: { workflow_state: binding_workflow_state })
        end

        let(:tool) { registration.deployments.first }

        let(:context_control) do
          Lti::ContextControl.create!(
            course: @course,
            deployment: tool,
            registration:,
            available: context_control_availability
          )
        end

        context "with an 'on' binding" do
          let(:binding_workflow_state) { true }

          context "and an 'on' context control" do
            let(:context_control_availability) { true }

            it "includes the tool" do
              expect(described_class.all_tools_for(@course)).to include(tool)
            end
          end

          context "and an 'off' context control" do
            let(:context_control_availability) { false }

            it "does not include the tool" do
              expect(described_class.all_tools_for(@course)).not_to include(tool)
            end
          end
        end

        context "with an 'off' binding" do
          let(:binding_workflow_state) { false }

          context "and an 'on' context control" do
            let(:context_control_availability) { true }

            it "does not include the tool" do
              expect(described_class.all_tools_for(@course)).not_to include(tool)
            end
          end

          context "and an 'off' context control" do
            let(:context_control_availability) { false }

            it "does not include the tool" do
              expect(described_class.all_tools_for(@course)).not_to include(tool)
            end
          end
        end
      end
    end
  end

  describe ".ordered_by_context_scope_union" do
    subject { described_class.ordered_by_context_scope_union(@course).to_unsorted_array }

    let(:tool1) { create_tool(@course, "c", domain: "google.com") }
    let(:tool2) { create_tool(@account, "b", domain: "google.com") }
    let(:tool3) { create_tool(@root_account, "c", domain: "google.com") }
    let(:tool4) { create_tool(@course, "a", domain: "google.com") }

    before do
      [tool1, tool2, tool3, tool4] # instantiate in cross-shard
    end

    it "orders tools by the context chain" do
      expect(subject).to eq [tool4, tool1, tool2, tool3]
    end
  end

  describe ".ordered_by_context_for" do
    subject { described_class.ordered_by_context_for(@course) }

    let(:tool1) { create_tool(@course, "c", domain: "google.com") }
    let(:tool2) { create_tool(@account, "b", domain: "google.com") }
    let(:tool3) { create_tool(@root_account, "c", domain: "google.com") }
    let(:tool4) { create_tool(@course, "a", domain: "google.com") }

    before do
      [tool1, tool2, tool3, tool4] # instantiate in cross-shard
    end

    it "orders tools by the context chain" do
      expect(subject).to eq [tool4, tool1, tool2, tool3]
    end
  end
end
