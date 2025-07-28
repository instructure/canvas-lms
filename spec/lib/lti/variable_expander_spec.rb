# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

# disabled RSpec/EmptyExampleGroup for whole file because it doesn't recognize it_expands:
# rubocop:disable RSpec/EmptyExampleGroup

module Lti
  describe VariableExpander do
    let(:root_account) { Account.create!(lti_guid: "test-lti-guid") }
    let(:account) { Account.new(root_account:, name: "Test Account") }
    let(:course) { Course.new(account:, name: "Computers 4", course_code: "CS 124", sis_source_id: "c-sis-id") }
    let(:group_category) { course.group_categories.new(name: "Category") }
    let(:group) { course.groups.new(name: "Group", group_category:) }
    let(:user) { User.new }
    let(:assignment) { Assignment.new(context: course) }
    let(:collaboration) do
      ExternalToolCollaboration.new(
        title: "my collab",
        user:,
        url: "http://www.example.com"
      )
    end
    let(:substitution_helper) { double.as_null_object }
    let(:right_now) { Time.current }
    let(:tool) do
      shard_mock = double("shard")
      allow(shard_mock).to receive(:settings).and_return({ encription_key: "abc" })
      m = double("tool")
      allow(m).to receive_messages(id: 1,
                                   context: root_account,
                                   include_email?: true,
                                   include_name?: true,
                                   public?: true,
                                   shard: shard_mock,
                                   opaque_identifier_for: "6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f",
                                   use_1_3?: false,
                                   launch_url: "http://example.com/launch")
      allow(m).to receive(:extension_setting).with(nil, :prefer_sis_email).and_return(nil)
      allow(m).to receive(:extension_setting).with(:tool_configuration, :prefer_sis_email).and_return(nil)
      m
    end
    let(:available_canvas_resources) do
      [
        { id: "1", name: "item 1" },
        { id: "2", name: "item 2" }
      ]
    end

    let(:controller) do
      request_mock = double("request")
      allow(request_mock).to receive_messages(url: "https://localhost", host_with_port: "https://localhost", host: "/my/url", scheme: "https", parameters: {
        com_instructure_course_accept_canvas_resource_types: ["page", "module"],
        com_instructure_course_canvas_resource_type: "page",
        com_instructure_course_canvas_resource_id: "112233",
        com_instructure_course_allow_canvas_resource_selection: "true",
        com_instructure_course_available_canvas_resources: available_canvas_resources
      }.with_indifferent_access)
      view_context_mock = double("view_context")
      m = double("controller")
      allow(m).to receive(:css_url_for).with(:common).and_return("/path/to/common.scss")
      allow(view_context_mock).to receive(:stylesheet_path)
        .and_return(URI.parse(request_mock.url).merge(m.css_url_for(:common)).to_s)
      allow(m).to receive_messages(request: request_mock,
                                   logged_in_user: user,
                                   named_context_url: "url",
                                   active_brand_config: double(to_json: '{"ic-brand-primary-darkened-5":"#0087D7"}'),
                                   polymorphic_url: "url",
                                   view_context: view_context_mock)
      allow(m).to receive(:active_brand_config_url).with("json").and_return("http://example.com/brand_config.json")
      allow(m).to receive(:active_brand_config_url).with("js").and_return("http://example.com/brand_config.js")
      m
    end
    let(:attachment) { attachment_model }
    let(:submission) { submission_model }
    let(:resource_link_id) { SecureRandom.uuid }
    let(:originality_report) do
      OriginalityReport.create!(attachment:,
                                submission:,
                                link_id: resource_link_id)
    end
    let(:editor_contents) { "<p>This is the contents of the editor</p>" }
    let(:editor_selection) { "is the contents" }
    let(:differentiation_tag) do
      course.save!
      user.save!

      # Enable differentiation tags feature flag and setting on course account
      course.account.enable_feature!(:assign_to_differentiation_tags)
      course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      course.account.save!

      # Create a non-collaborative group category (differentiation tag category)
      tag_category = course.group_categories.create!(name: "Test Category", non_collaborative: true)
      # Create a group (differentiation tag) in that category
      tag = course.groups.create!(name: "Test Tag", group_category: tag_category, non_collaborative: true)
      # Add the user to the group and ensure the membership is accepted
      membership = tag.add_user(user)
      membership&.update!(workflow_state: "accepted")
      tag
    end
    let(:external_tool_assignment) do
      course.save!
      user.save!
      assignment = course.assignments.create!(
        name: "External Tool Assignment",
        submission_types: "external_tool",
        points_possible: 100
      )
      assignment
    end
    let(:variable_expander) do
      VariableExpander.new(
        root_account,
        account,
        controller,
        variable_expander_opts
      )
    end
    let(:variable_expander_with_originality_report) do
      # Creating originality report is slow, only do it in specs that need it
      VariableExpander.new(
        root_account,
        account,
        controller,
        variable_expander_opts.merge(originality_report:)
      )
    end
    let(:variable_expander_opts) do
      {
        current_user: user,
        tool:,
        editor_contents:,
        editor_selection:
      }
    end

    before do
      root_account.disable_feature!(:refactor_custom_variables)
      # Enable the differentiation tags feature
      course.account.enable_feature!(:assign_to_differentiation_tags)
      root_account.settings = { allow_assign_to_differentiation_tags: { value: true } }
      course.account.save!
    end

    def self.it_expands(expansion, val = nil, &blk)
      it "expands #{expansion}" do
        val ||= blk
        val = instance_eval(&val) if val.respond_to?(:call)
        expect(expand!(expansion)).to eq val
      end
    end

    def self.it_leaves_unexpanded(expansion)
      it "leaves #{expansion} unexpanded" do
        expect_unexpanded!(expansion)
      end
    end

    describe ".deregister_expansion" do
      subject { described_class.expansions }

      let(:expansion) { "com.Instructure.Foo.Bar" }

      before do
        described_class.register_expansion(expansion, ["a"], -> { "test" })
        described_class.deregister_expansion(expansion)
      end

      it "removes the requested expansion" do
        expect(subject).not_to include(:"$#{expansion}")
      end
    end

    it "clears the lti_helper instance variable when you set the current_user" do
      expect(variable_expander.lti_helper).not_to be_nil
      variable_expander.current_user = nil
      expect(variable_expander.instance_variable_get(:@current_user)).to be_nil
    end

    it "expands registered variables" do
      VariableExpander.register_expansion("test_expan", ["a"], -> { @context })
      expanded = variable_expander.expand_variables!({ some_name: "$test_expan" })
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq account
    end

    it "expands substring variables" do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion("test_expan", ["a"], -> { @context.id })
      expanded = variable_expander.expand_variables!({ some_name: "my variable is buried in here ${test_expan} can you find it?" })
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq "my variable is buried in here 42 can you find it?"
    end

    it "handles multiple substring variables" do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion("test_expan", ["a"], -> { @context.id })
      VariableExpander.register_expansion("variable1", ["a"], -> { 1 })
      VariableExpander.register_expansion("other_variable", ["a"], -> { 2 })
      expanded = variable_expander.expand_variables!(
        { some_name: "my variables ${variable1} is buried ${other_variable} in here ${test_expan} can you find them?" }
      )
      expect(expanded[:some_name]).to eq "my variables 1 is buried 2 in here 42 can you find them?"
    end

    it "does not expand a substring variable if it is not valid" do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion("test_expan", ["a"], -> { @context.id })
      expanded = variable_expander.expand_variables!({ some_name: "my variable is buried in here ${tests_expan} can you find it?" })
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq "my variable is buried in here ${tests_expan} can you find it?"
    end

    it "echoes registered variable if blacklisted" do
      VariableExpander.register_expansion("test_expan", ["a"], -> { @context })
      VariableExpander.register_expansion("variable1", ["a"], -> { 1 })
      variable_expander.variable_blacklist = ["test_expan"]
      expanded1 = variable_expander.expand_variables!({ some_name: "$test_expan" })
      expanded2 = variable_expander.expand_variables!({ some_name: "$variable1" })
      expect(expanded1.count).to eq 1
      expect(expanded1[:some_name]).to eq "$test_expan"
      expect(expanded2.count).to eq 1
      expect(expanded2[:some_name]).to eq 1
    end

    it "echoes substring variable if blacklisted" do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion("test_expan", ["a"], -> { @context.id })
      VariableExpander.register_expansion("variable1", ["a"], -> { 1 })
      variable_expander.variable_blacklist = ["test_expan"]
      expanded1 = variable_expander.expand_variables!({ some_name: "my variable is buried in here ${test_expan} can you find it?" })
      expanded2 = variable_expander.expand_variables!({ some_name: "my variable is buried in here ${variable1} can you find it?" })
      expect(expanded1.count).to eq 1
      expect(expanded1[:some_name]).to eq "my variable is buried in here $test_expan can you find it?"
      expect(expanded2.count).to eq 1
      expect(expanded2[:some_name]).to eq "my variable is buried in here 1 can you find it?"
    end

    it "echoes multiple substring variables if blacklisted" do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion("test_expan", ["a"], -> { @context.id })
      VariableExpander.register_expansion("variable1", ["a"], -> { 1 })
      VariableExpander.register_expansion("other_variable", ["a"], -> { 2 })
      variable_expander.variable_blacklist = ["test_expan", "variable1"]
      expanded = variable_expander.expand_variables!(
        { some_name: "my variables ${variable1} is buried ${other_variable} in here ${test_expan} can you find them?" }
      )
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq "my variables $variable1 is buried 2 in here $test_expan can you find them?"
    end

    context "launch_url" do
      subject { variable_expander.instance_variable_get(:@launch_url) }

      context "when no options are provided" do
        let(:launch_url) { "default" }

        before do
          allow(tool).to receive(:launch_url).with(extension_type: nil).and_return(launch_url)
        end

        it { is_expected.to eq launch_url }
      end

      context "when placement is provided" do
        let(:launch_url) { "placement" }
        let(:placement) { "test" }

        let(:variable_expander_opts) do
          super().merge({ placement: })
        end

        before do
          allow(tool).to receive(:launch_url).with(extension_type: anything).and_return(launch_url)
        end

        it "passes placement to tool's url method" do
          subject
          expect(tool).to have_received(:launch_url).with(extension_type: placement)
        end

        it { is_expected.to eq launch_url }
      end

      context "when launch_url is provided" do
        let(:launch_url) { "launch" }
        let(:variable_expander_opts) do
          super().merge({ launch_url: })
        end

        before do
          allow(tool).to receive(:launch_url)
        end

        it "uses it as launch_url without asking the tool" do
          subject
          expect(tool).not_to have_received(:launch_url)
        end

        it { is_expected.to eq launch_url }
      end
    end

    describe "#self.expansion_keys" do
      let(:expected_keys) do
        VariableExpander.expansions.keys.map { |c| c.to_s[1..] }
      end

      it "includes all expansion keys" do
        expect(VariableExpander.expansion_keys).to eq expected_keys
      end
    end

    describe "#self.default_name_expansions" do
      let(:expected_keys) do
        VariableExpander.expansions.values.select { |v| v.default_name.present? }.map(&:name)
      end

      it "includes all expansion keys that have default names" do
        expect(VariableExpander.default_name_expansions).to eq expected_keys
      end
    end

    describe "#enabled_capability_params" do
      let(:enabled_capability) do
        %w[TestCapability.Foo
           ToolConsumerInstance.guid
           CourseSection.sourcedId
           Membership.role
           Person.email.primary
           Person.name.given
           Person.name.family
           Person.name.full
           Person.name.display
           Person.sourcedId
           User.id
           User.image
           Message.documentTarget
           Message.locale
           Context.id]
      end

      it "does not use expansions that do not have default names" do
        VariableExpander.register_expansion("TestCapability.Foo", ["a"], -> { "test" })
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        VariableExpander.deregister_expansion("TestCapability.Foo")
        expect(expanded.keys).not_to include "TestCapability.Foo"
      end

      it "does use expansion that have default names" do
        VariableExpander.register_expansion("TestCapability.Foo", ["a"], -> { "test" }, default_name: "test_capability_foo")
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        VariableExpander.deregister_expansion("TestCapability.Foo")
        expect(expanded.values).to include("test")
      end

      it "does use the default name as the key" do
        VariableExpander.register_expansion("TestCapability.Foo", ["a"], -> { "test" }, default_name: "test_capability_foo")
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        VariableExpander.deregister_expansion("TestCapability.Foo")
        expect(expanded["test_capability_foo"]).to eq "test"
      end

      it "includes ToolConsumerInstance.guid when in enabled capability" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded["tool_consumer_instance_guid"]).to eq "test-lti-guid"
      end

      it "includes CourseSection.sourcedId when in enabled capability" do
        variable_expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:)
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "lis_course_section_sourcedid"
      end

      it "includes Membership.role when in enabled capability" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "roles"
      end

      it "includes Person.email.primary when in enabled capability" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "lis_person_contact_email_primary"
      end

      it "includes Person.sourcedId when in enabled capability" do
        allow(SisPseudonym).to receive(:for).with(user, anything, anything).and_return(double(sis_user_id: 12))
        expanded = variable_expander.enabled_capability_params(["Person.sourcedId"])
        expect(expanded.keys).to include "lis_person_sourcedid"
      end

      it "includes User.id when in enabled capability" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "user_id"
      end

      it "includes User.image when in enabled capability" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "user_image"
      end

      it "includes Message.documentTarget" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "launch_presentation_document_target"
      end

      it "includes Message.locale" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "launch_presentation_locale"
      end

      it "includes Context.id" do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include "context_id"
      end

      context "privacy level include_name" do
        it "includes Person.name.given when in enabled capability" do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include "lis_person_name_given"
        end

        it "includes Person.name.family when in enabled capability" do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include "lis_person_name_family"
        end

        it "includes Person.name.full when in enabled capability" do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include "lis_person_name_full"
        end

        it "includes Person.name.display when in enabled capability" do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include "person_name_display"
        end
      end
    end

    context "lti1" do
      it "handles expansion" do
        VariableExpander.register_expansion("test_expan", ["a"], -> { @context })
        expanded = variable_expander.expand_variables!({ "some_name" => "$test_expan" })
        expect(expanded.count).to eq 1
        expect(expanded["some_name"]).to eq account
      end

      it "expands substring variables" do
        allow(account).to receive(:id).and_return(42)
        VariableExpander.register_expansion("test_expan", ["a"], -> { @context.id })
        expanded = variable_expander.expand_variables!({ "some_name" => "my variable is buried in here ${test_expan} can you find it?" })
        expect(expanded.count).to eq 1
        expect(expanded["some_name"]).to eq "my variable is buried in here 42 can you find it?"
      end
    end

    describe "#variable expansions" do
      def expand!(subst_name, expander: nil)
        exp_hash = { test: subst_name }
        (expander || variable_expander).expand_variables!(exp_hash)[:test]
      end

      def expect_unexpanded!(subst_name, expander: nil)
        expect(expand!(subst_name, expander:)).to eq(subst_name)
      end

      it "expands $Canvas.user.sisSourceId as sis_id for enrollment" do
        user.save!
        course.save!
        course.offer!
        managed_pseudonym(user, account: root_account, username: "login_id", sis_user_id: "sis id!")
        login = managed_pseudonym(user, account: root_account, username: "login_id2", sis_user_id: "sis id2!")
        course.enroll_user(user, "StudentEnrollment", sis_pseudonym_id: login.id, enrollment_state: "active")

        exp_hash = { test: "$Canvas.user.sisSourceId" }
        variable_expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:)
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq "sis id2!"
      end

      context "$com.instructure.Assignment.anonymous_grading" do
        let(:exp_hash) { { test: "$com.instructure.Assignment.anonymous_grading" } }

        it "is true if the assignment has anonymous grading on" do
          assignment.anonymous_grading = true
          variable_expander = VariableExpander.new(
            root_account,
            account,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to be true
        end

        it "is false if the assignment does not have anonymous grading on" do
          variable_expander = VariableExpander.new(
            root_account,
            account,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to be false
        end
      end

      describe "with 'com.instructure.Context.globalId'" do
        let(:exp_hash) { { test: "$com.instructure.Context.globalId" } }

        context "when the launch context is present" do
          let(:course) { course_model }
          let(:variable_expander_opts) { super().merge(context: course) }

          it "yields the global ID of the context" do
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq course.global_id
          end
        end
      end

      describe "with 'com.instructure.Context.uuid'" do
        let(:subst_name) { "$com.instructure.Context.uuid" }

        context "when the launch context is present" do
          let(:course) { course_model }
          let(:variable_expander_opts) { super().merge(context: course) }

          it "yields the UUID of the context" do
            expect(expand!(subst_name)).to eq(course.uuid)
          end
        end

        context "when the launch context does not respond to 'uuid'" do
          let(:variable_expander_opts) { super().merge(context: assignment_model) }

          it "does not do the expansion" do
            expect_unexpanded! subst_name
          end
        end

        context "when the launch context is nil" do
          let(:variable_expander_opts) { super().merge(context: nil) }

          it "does not do the expansion" do
            expect_unexpanded! subst_name
          end
        end
      end

      context "$com.instructure.Assignment.restrict_quantitative_data" do
        let(:subst_name) { "$com.instructure.Assignment.restrict_quantitative_data" }

        it "is `false` if restrict_quantitative_data is falsy for current user" do
          course.save!
          managed_pseudonym(user, account: root_account, username: "login_id", sis_user_id: "sis id!")
          login = managed_pseudonym(user, account: root_account, username: "login_id2", sis_user_id: "sis id2!")
          course.enroll_user(user, "StudentEnrollment", sis_pseudonym_id: login.id, enrollment_state: "active")
          my_assignment = course.assignments.create!(title: "my assignment", description: "desc")

          expander = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment: my_assignment
          )

          expect(expand!(subst_name, expander:)).to eq "false"
        end

        it "is the variable's default name if assignment is nil" do
          course.save!
          managed_pseudonym(user, account: root_account, username: "login_id", sis_user_id: "sis id!")
          login = managed_pseudonym(user, account: root_account, username: "login_id2", sis_user_id: "sis id2!")
          course.enroll_user(user, "StudentEnrollment", sis_pseudonym_id: login.id, enrollment_state: "active")
          my_assignment = nil

          expander = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment: my_assignment
          )

          expect_unexpanded!(subst_name, expander:)
        end

        it "is `true` if restrict_quantitative_data is truthy for current user" do
          # truthy feature flag
          Account.default.enable_feature! :restrict_quantitative_data

          # truthy setting
          Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
          Account.default.save!
          course.save!
          managed_pseudonym(user, account: root_account, username: "login_id", sis_user_id: "sis id!")
          login = managed_pseudonym(user, account: root_account, username: "login_id2", sis_user_id: "sis id2!")
          course.enroll_user(user, "StudentEnrollment", sis_pseudonym_id: login.id, enrollment_state: "active")
          my_assignment = course.assignments.create!(title: "my assignment", description: "desc")

          expander = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment: my_assignment
          )

          expect(expand!(subst_name, expander:)).to eq "true"
        end
      end

      context "$com.instructure.Course.gradingScheme" do
        let(:subst_name) { "$com.instructure.Course.gradingScheme" }

        it "is the grading scheme for the course" do
          course.save!
          grading_standard = course.grading_standards.create!(title: "my grading scheme", data: { "A" => 90, "B" => 80, "C" => 70, "D" => 60, "F" => 0 })
          course.grading_standard_enabled = true
          course.grading_standard_id = grading_standard.id
          course.save!

          expander = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user
          )

          expect(expand!(subst_name, expander:)).to eq(
            "[{\"name\":\"A\",\"value\":90},{\"name\":\"B\",\"value\":80},{\"name\":\"C\",\"value\":70},{\"name\":\"D\",\"value\":60},{\"name\":\"F\",\"value\":0}]"
          )
        end

        it "provides the default grading standard if no specific one is set" do
          course.save!

          expander = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user
          )

          expect(expand!(subst_name, expander:)).to eq(
            "[{\"name\":\"A\",\"value\":0.94},{\"name\":\"A-\",\"value\":0.9},{\"name\":\"B+\",\"value\":0.87},{\"name\":\"B\",\"value\":0.84},{\"name\":\"B-\",\"value\":0.8},{\"name\":\"C+\",\"value\":0.77},{\"name\":\"C\",\"value\":0.74},{\"name\":\"C-\",\"value\":0.7},{\"name\":\"D+\",\"value\":0.67},{\"name\":\"D\",\"value\":0.64},{\"name\":\"D-\",\"value\":0.61},{\"name\":\"F\",\"value\":0.0}]"
          )
        end
      end

      context "com.instructure.Account.usage_metrics_enabled" do
        let(:subst_name) { "$com.instructure.Account.usage_metrics_enabled" }

        context "when flag is disabled" do
          before do
            root_account.disable_feature! :send_usage_metrics
          end

          it "expands to false" do
            expect(expand!(subst_name)).to be(false)
          end
        end

        context "when flag is enabled and account allows it" do
          before do
            root_account.settings[:enable_usage_metrics] = true
            root_account.enable_feature! :send_usage_metrics
          end

          it "expands to true" do
            expect(expand!(subst_name)).to be(true)
          end
        end
      end

      it "has a substitution for com.instructure.Assignment.lti.id" do
        expander = variable_expander_with_originality_report
        expect(expand!("$com.instructure.Assignment.lti.id", expander:)).to \
          eq(originality_report.submission.assignment.lti_context_id)
      end

      it "has a substitution for com.instructure.Assignment.lti.id when there is no tool setting" do
        # the account does not have an `id` hence the mock below.
        # creating the account with Account.create! creates an ID bu t breaks other tests.
        allow(course).to receive(:horizon_course?).and_return(false)
        assignment.update(context: course)
        expander = VariableExpander.new(root_account,
                                        account,
                                        controller,
                                        current_user: user,
                                        tool:,
                                        assignment:)
        assignment.update(context: course)
        expect(expand!("$com.instructure.Assignment.lti.id", expander:)).to \
          eq(assignment.lti_context_id)
      end

      it "has a substitution for com.instructure.PostMessageToken" do
        uuid_pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        expander = VariableExpander.new(root_account,
                                        account,
                                        controller,
                                        current_user: user,
                                        tool:,
                                        launch: Lti::Launch.new)
        expanded = expand!("$com.instructure.PostMessageToken", expander:)
        expect(expanded =~ uuid_pattern).to eq(0)
      end

      it "has a substitution for com.instructure.PostMessageToken when token is provided" do
        pm_token_override = SecureRandom.uuid
        expander = VariableExpander.new(root_account,
                                        account,
                                        controller,
                                        current_user: user,
                                        tool:,
                                        post_message_token: pm_token_override)
        expect(expand!("$com.instructure.PostMessageToken", expander:)).to eq pm_token_override
      end

      it "has a substitution for com.instructure.Assignment.lti.id when secure params are present" do
        lti_assignment_id = SecureRandom.uuid
        secure_params = Canvas::Security.create_jwt(lti_assignment_id:)
        expander = VariableExpander.new(root_account,
                                        account,
                                        controller,
                                        current_user: user,
                                        tool:,
                                        secure_params:)
        expect(expand!("$com.instructure.Assignment.lti.id", expander:)).to \
          eq lti_assignment_id
      end

      it "has substitution for com.instructure.Editor.contents" do
        expect(expand!("$com.instructure.Editor.contents")).to eq editor_contents
      end

      it "has substitution for com.instructure.Editor.selection" do
        expect(expand!("$com.instructure.Editor.selection")).to eq editor_selection
      end

      it "has a substitution for Context.title" do
        expect(expand!("$Context.title")).to eq variable_expander.context.name
      end

      it "has substitution for vnd.Canvas.OriginalityReport.url" do
        expander = variable_expander_with_originality_report
        expect(expand!("$vnd.Canvas.OriginalityReport.url", expander:)).to \
          eq "api/lti/assignments/{assignment_id}/submissions/{submission_id}/originality_report"
      end

      context "com.instructure.Assignment.allowedFileExtensions" do
        let(:allowed_extensions) { "docx,txt,pdf" }
        let(:course) { course_model }
        let(:assignment) { assignment_model(context: course) }
        let(:expansion) { "$com.instructure.Assignment.allowedFileExtensions" }
        let(:variable_expander_opts) { super().merge(context: course, assignment:) }

        it "expands when an assignment with online_upload submission type and extensions is present" do
          assignment.update!(allowed_extensions:, submission_types: "online_upload")
          expect(expand!(expansion)).to eq allowed_extensions
        end

        it "doesn't expand if online_uploads is not a submission_type" do
          assignment.update!(submission_types: "online_text_entry,online_url")
          expect_unexpanded! expansion
        end

        it "expands to an empty string if there are no limits on file types" do
          assignment.update!(submission_types: "online_upload,online_text_entry")
          expect(expand!(expansion)).to eq ""
        end

        context "no assignment present" do
          let(:variable_expander_opts) { super().merge(context: course) }

          it "doesn't expand" do
            expect_unexpanded! expansion
          end
        end
      end

      it "has substitution for com.instructure.OriginalityReport.id" do
        expander = variable_expander_with_originality_report
        expect(expand!("$com.instructure.OriginalityReport.id", expander:)).to eq originality_report.id
      end

      it "has substitution for com.instructure.Submission.id" do
        expander = variable_expander_with_originality_report
        expect(expand!("$com.instructure.Submission.id", expander:)).to \
          eq originality_report.submission.id
      end

      it "has substitution for com.instructure.File.id" do
        expander = variable_expander_with_originality_report
        expect(expand!("$com.instructure.File.id", expander:)).to \
          eq originality_report.attachment.id
      end

      it "has substitution for vnd.Canvas.submission.url" do
        expect(expand!("$vnd.Canvas.submission.url")).to \
          eq "api/lti/assignments/{assignment_id}/submissions/{submission_id}"
      end

      it "has substitution for vnd.Canvas.submission.history.url" do
        expect(expand!("$vnd.Canvas.submission.history.url")).to \
          eq "api/lti/assignments/{assignment_id}/submissions/{submission_id}/history"
      end

      it "has substitution for Message.documentTarget" do
        expect(expand!("$Message.documentTarget")).to \
          eq ::IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME
      end

      it "has substitution for Message.locale" do
        expect(expand!("$Message.locale")).to eq I18n.locale
      end

      it "has substitution for $Canvas.api.domain" do
        allow(HostUrl).to receive(:context_host).and_return("localhost")
        expect(expand!("$Canvas.api.domain")).to eq "localhost"
      end

      it "does not expand $Canvas.api.domain when the request is unset" do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        expect_unexpanded! "$Canvas.api.domain"
      end

      it "has substitution for $com.instructure.brandConfigJSON.url" do
        expect(expand!("$com.instructure.brandConfigJSON.url")).to \
          eq "http://example.com/brand_config.json"
      end

      it "does not expand $com.instructure.brandConfigJSON.url when the controller is unset" do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        expect_unexpanded! "$com.instructure.brandConfigJSON.url"
      end

      it "has substitution for $com.instructure.brandConfigJSON" do
        expect(expand!("$com.instructure.brandConfigJSON")).to \
          eq '{"ic-brand-primary-darkened-5":"#0087D7"}'
      end

      it "does not expand $com.instructure.brandConfigJSON when the controller is unset" do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        expect_unexpanded! "$com.instructure.brandConfigJSON"
      end

      it "has substitution for $com.instructure.brandConfigJS.url" do
        expect(expand!("$com.instructure.brandConfigJS.url")).to \
          eq "http://example.com/brand_config.js"
      end

      it "does not expand $com.instructure.brandConfigJS.url when the controller is unset" do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        expect_unexpanded! "$com.instructure.brandConfigJS.url"
      end

      it "has substitution for $Canvas.css.common" do
        expect(expand!("$Canvas.css.common")).to \
          eq "https://localhost/path/to/common.scss"
      end

      it "does not expand $Canvas.css.common when the controller is unset" do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        expect_unexpanded! "$Canvas.css.common"
      end

      it "has substitution for $Canvas.api.baseUrl" do
        allow(HostUrl).to receive(:context_host).and_return("localhost")
        expect(expand!("$Canvas.api.baseUrl")).to eq "https://localhost"
      end

      it "does not expand $Canvas.api.baseUrl when the request is unset" do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        expect_unexpanded! "$Canvas.api.baseUrl"
      end

      it "has substitution for $Canvas.account.id" do
        allow(account).to receive(:id).and_return(12_345)
        expect(expand!("$Canvas.account.id")).to eq 12_345
      end

      it "has substitution for $Canvas.account.name" do
        account.name = "Some Account"
        expect(expand!("$Canvas.account.name")).to eq "Some Account"
      end

      it "has substitution for $Canvas.account.sisSourceId" do
        account.sis_source_id = "abc23"
        expect(expand!("$Canvas.account.sisSourceId")).to eq "abc23"
      end

      it "has substitution for $Canvas.rootAccount.id" do
        allow(root_account).to receive(:id).and_return(54_321)
        expect(expand!("$Canvas.rootAccount.id")).to eq 54_321
      end

      it "has substitution for $Canvas.rootAccount.sisSourceId" do
        root_account.sis_source_id = "cd45"
        expect(expand!("$Canvas.rootAccount.sisSourceId")).to eq "cd45"
      end

      it "has substitution for $Canvas.root_account.id" do
        allow(root_account).to receive(:id).and_return(54_321)
        expect(expand!("$Canvas.root_account.id")).to eq 54_321
      end

      it "has substitution for $Canvas.root_account.uuid" do
        allow(root_account).to receive(:uuid).and_return("123-123-123-123")
        expect(expand!("$vnd.Canvas.root_account.uuid")).to eq "123-123-123-123"
      end

      it "has substitution for $Canvas.root_account.sisSourceId" do
        root_account.sis_source_id = "cd45"
        expect(expand!("$Canvas.root_account.sisSourceId")).to eq "cd45"
      end

      it "has substitution for $Canvas.root_account.global_id" do
        allow(root_account).to receive(:global_id).and_return(10_054_321)
        expect(expand!("$Canvas.root_account.global_id")).to eq 10_054_321
      end

      context "when the new_quizzes_separators feature flag is enabled for decimal separators" do
        before do
          allow(Account.site_admin).to receive(:feature_enabled?).with(:new_quizzes_separators).and_return(true)
          allow(Account.site_admin).to receive(:feature_enabled?).with(:disallow_null_custom_variables).and_return(true)
        end

        it "has substitution for $Canvas.account.decimal_separator when sub account has setting" do
          account_settings = { decimal_separator: { value: "period" } }
          root_settings = { decimal_separator: { value: "comma" } }
          allow(account).to receive(:settings).and_return(account_settings)
          allow(root_account).to receive(:settings).and_return(root_settings)
          allow(variable_expander.lti_helper).to receive_messages(account:, course:)
          expect(expand!("$Canvas.account.decimal_separator")).to eq "period"
        end

        it "has substitution for $Canvas.account.decimal_separator with fallback to root account setting" do
          account_settings = {}
          root_settings = { decimal_separator: { value: "comma" } }
          allow(account).to receive(:settings).and_return(account_settings)
          allow(root_account).to receive(:settings).and_return(root_settings)
          allow(variable_expander.lti_helper).to receive_messages(account:, course:)
          expect(expand!("$Canvas.account.decimal_separator")).to eq "comma"
        end
      end

      context "when the new_quizzes_separators feature flag is disabled for decimal separators" do
        before do
          allow(Account.site_admin).to receive(:feature_enabled?).with(:new_quizzes_separators).and_return(false)
          allow(Account.site_admin).to receive(:feature_enabled?).with(:disallow_null_custom_variables).and_return(true)
        end

        it "does not expand $Canvas.account.decimal_separator" do
          account_settings = { decimal_separator: { value: "period" } }
          root_settings = { decimal_separator: { value: "comma" } }
          allow(account).to receive(:settings).and_return(account_settings)
          allow(root_account).to receive(:settings).and_return(root_settings)
          allow(variable_expander.lti_helper).to receive_messages(account:, course:)
          expect_unexpanded!("$Canvas.account.decimal_separator")
        end
      end

      context "when the new_quizzes_separators feature flag is enabled for thousand separators" do
        before do
          allow(Account.site_admin).to receive(:feature_enabled?).with(:new_quizzes_separators).and_return(true)
          allow(Account.site_admin).to receive(:feature_enabled?).with(:disallow_null_custom_variables).and_return(true)
        end

        it "has substitution for $Canvas.account.thousand_separator when sub account has setting" do
          account_settings = { thousand_separator: { value: "period" } }
          root_settings = { thousand_separator: { value: "comma" } }
          allow(account).to receive(:settings).and_return(account_settings)
          allow(root_account).to receive(:settings).and_return(root_settings)
          allow(variable_expander.lti_helper).to receive_messages(account:, course:)
          expect(expand!("$Canvas.account.thousand_separator")).to eq "period"
        end

        it "has substitution for $Canvas.account.thousand_separator with fallback to root account setting" do
          account_settings = {}
          root_settings = { thousand_separator: { value: "comma" } }
          allow(account).to receive(:settings).and_return(account_settings)
          allow(root_account).to receive(:settings).and_return(root_settings)
          allow(variable_expander.lti_helper).to receive_messages(account:, course:)
          expect(expand!("$Canvas.account.thousand_separator")).to eq "comma"
        end
      end

      context "when the new_quizzes_separators feature flag is disabled for thousand separators" do
        before do
          allow(Account.site_admin).to receive(:feature_enabled?).with(:new_quizzes_separators).and_return(false)
          allow(Account.site_admin).to receive(:feature_enabled?).with(:disallow_null_custom_variables).and_return(true)
        end

        it "does not expand $Canvas.account.thousand_separator" do
          account_settings = { thousand_separator: { value: "period" } }
          root_settings = { thousand_separator: { value: "comma" } }
          allow(account).to receive(:settings).and_return(account_settings)
          allow(root_account).to receive(:settings).and_return(root_settings)
          allow(variable_expander.lti_helper).to receive_messages(account:, course:)
          expect_unexpanded!("$Canvas.account.thousand_separator")
        end
      end

      it "has substitution for $Canvas.shard.id" do
        expect(expand!("$Canvas.shard.id")).to eq Shard.current.id
      end

      it "has substitution for $com.instructure.Course.accept_canvas_resource_types" do
        expect(expand!("$com.instructure.Course.accept_canvas_resource_types")).to eq "page,module"
      end

      it "has substitution for $com.instructure.Course.canvas_resource_type" do
        expect(expand!("$com.instructure.Course.canvas_resource_type")).to eq "page"
      end

      it "has substitution for $com.instructure.Course.canvas_resource_id" do
        expect(expand!("$com.instructure.Course.canvas_resource_id")).to eq "112233"
      end

      it "has substitution for $com.instructure.Course.allow_canvas_resource_selection" do
        expect(expand!("$com.instructure.Course.allow_canvas_resource_selection")).to eq "true"
      end

      it "has substitution for $com.instructure.Course.available_canvas_resources" do
        expect(
          JSON.parse(expand!("$com.instructure.Course.available_canvas_resources"))
        ).to eq(
          [{ "id" => "1", "name" => "item 1" }, { "id" => "2", "name" => "item 2" }]
        )
      end

      # tests for only the variables that were being returned as a raw boolean
      context "custom_variables_booleans_as_strings feature flag" do
        context "when the ff is disabled and the output is a boolean it should be returned as a boolean" do
          before do
            Account.site_admin.enable_feature! :disallow_null_custom_variables
            Account.site_admin.disable_feature! :custom_variables_booleans_as_strings
          end

          let(:tool) do
            course.context_external_tools.create!(domain: "example.com",
                                                  consumer_key: "12345",
                                                  shared_secret: "secret",
                                                  privacy_level: "anonymous",
                                                  name: "tool",
                                                  use_1_3: true)
          end

          it "has a substitution for Canvas.user.isRootAccountAdmin" do
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.user.isRootAccountAdmin", expander:)).to be false
          end

          it "has a substitution for com.instructure.Assignment.anonymous_grading" do
            assignment.anonymous_grading = true
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$com.instructure.Assignment.anonymous_grading", expander:)).to be true
          end

          it "has a substitution for Canvas.assignment.lockdownEnabled" do
            allow(assignment).to receive(:settings).and_return({
                                                                 "lockdown_browser" => {
                                                                   "require_lockdown_browser" => true
                                                                 }
                                                               })
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.lockdownEnabled", expander:)).to be true
          end

          it "has a substitution for Canvas.assignment.hideInGradebook" do
            allow(assignment).to receive(:hideInGradebook).and_return(false)
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.hideInGradebook", expander:)).to be false
          end

          it "has a substitution for com.instructure.User.student_view" do
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$com.instructure.User.student_view", expander:)).to be false
          end

          it "has a substitution for Canvas.course.aiQuizGeneration" do
            course.save!
            course.enable_feature!(:new_quizzes_ai_quiz_generation)
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.course.aiQuizGeneration", expander:)).to be true
          end

          it "has a substitution for Canvas.course.sectionRestricted" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:section_restricted).and_return(true)
            course.save!
            course.enable_feature!(:new_quizzes_ai_quiz_generation)
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.course.sectionRestricted", expander:)).to be true
          end

          it "has a substitution for Canvas.assignment.published" do
            allow(assignment).to receive(:workflow_state).and_return("published")
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.published", expander:)).to be true
          end

          it "has a substitution for Canvas.assignment.omitFromFinalGrade" do
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.omitFromFinalGrade", expander:)).to be false
          end
        end

        context "when the ff is enabled and the output is a boolean it should be returned as a string" do
          before do
            Account.site_admin.enable_feature! :disallow_null_custom_variables
            Account.site_admin.enable_feature! :custom_variables_booleans_as_strings
          end

          let(:tool) do
            course.context_external_tools.create!(domain: "example.com",
                                                  consumer_key: "12345",
                                                  shared_secret: "secret",
                                                  privacy_level: "anonymous",
                                                  name: "tool",
                                                  use_1_3: true)
          end

          it "has a substitution for Canvas.user.isRootAccountAdmin" do
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.user.isRootAccountAdmin", expander:)).to eq "false"
          end

          it "has a substitution for com.instructure.Assignment.anonymous_grading" do
            assignment.anonymous_grading = true
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$com.instructure.Assignment.anonymous_grading", expander:)).to eq "true"
          end

          it "has a substitution for Canvas.assignment.lockdownEnabled" do
            allow(assignment).to receive(:settings).and_return({
                                                                 "lockdown_browser" => {
                                                                   "require_lockdown_browser" => true
                                                                 }
                                                               })
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.lockdownEnabled", expander:)).to eq "true"
          end

          it "has a substitution for Canvas.assignment.hideInGradebook" do
            allow(assignment).to receive(:hideInGradebook).and_return(false)
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.hideInGradebook", expander:)).to eq "false"
          end

          it "has a substitution for com.instructure.User.student_view" do
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$com.instructure.User.student_view", expander:)).to eq "false"
          end

          it "has a substitution for Canvas.course.aiQuizGeneration" do
            course.save!
            course.enable_feature!(:new_quizzes_ai_quiz_generation)
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.course.aiQuizGeneration", expander:)).to eq "true"
          end

          it "has a substitution for Canvas.course.sectionRestricted" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:section_restricted).and_return(true)
            course.save!
            course.enable_feature!(:new_quizzes_ai_quiz_generation)
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.course.sectionRestricted", expander:)).to eq "true"
          end

          it "has a substitution for Canvas.assignment.published" do
            allow(assignment).to receive(:workflow_state).and_return("published")
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.published", expander:)).to eq "true"
          end

          it "has a substitution for Canvas.assignment.omitFromFinalGrade" do
            course.save!
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:)
            expect(expand!("$Canvas.assignment.omitFromFinalGrade", expander:)).to eq "false"
          end
        end
      end

      context "Canvas.course.aiQuizGeneration expansion" do
        let(:subst_name) { "$Canvas.course.aiQuizGeneration" }

        it "returns true when the feature flag is enabled for the course" do
          course.save!
          course.enable_feature!(:new_quizzes_ai_quiz_generation)

          expander = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:
          )

          expect(expand!(subst_name, expander:)).to be(true)
        end

        it "returns false when the feature flag is not enabled for the course" do
          course.save!

          expander = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:
          )

          expect(expand!(subst_name, expander:)).to be(false)
        end
      end

      context "modules resources expansion" do
        let(:available_canvas_resources) { [{ "course_id" => course.id, "type" => "module" }] }

        it "has special substitution to get all course modules for $com.instructure.Course.available_canvas_resources" do
          course.save!
          m1 = course.context_modules.create!(name: "mod1")
          m2 = course.context_modules.create!(name: "mod2")
          expect(
            JSON.parse(expand!("$com.instructure.Course.available_canvas_resources"))
          ).to eq(
            [{ "id" => m1.id, "name" => m1.name }, { "id" => m2.id, "name" => m2.name }]
          )
        end
      end

      context "assignment groups resources expansion" do
        let(:available_canvas_resources) { [{ "course_id" => course.id, "type" => "assignment_group" }] }

        it "has special substitution to get all course modules for $com.instructure.Course.available_canvas_resources" do
          course.save!
          m1 = course.assignment_groups.create!(name: "mod1")
          m2 = course.assignment_groups.create!(name: "mod2")
          expect(
            JSON.parse(expand!("$com.instructure.Course.available_canvas_resources"))
          ).to eq(
            [{ "id" => m1.id, "name" => m1.name }, { "id" => m2.id, "name" => m2.name }]
          )
        end
      end

      context "context is a group" do
        let(:variable_expander) { VariableExpander.new(root_account, group, controller, current_user: user, tool:) }

        it "has substitution for $ToolProxyBinding.memberships.url when context is a group" do
          allow(group).to receive(:id).and_return("1")
          allow(controller).to receive(:polymorphic_url).and_return("/api/lti/groups/#{group.id}/membership_service")
          expect(expand!("$ToolProxyBinding.memberships.url")).to eq \
            "/api/lti/groups/1/membership_service"
        end

        it "does not substitute $ToolProxyBinding.memberships.url when the controller is unset" do
          variable_expander.instance_variable_set(:@controller, nil)
          variable_expander.instance_variable_set(:@request, nil)
          expect_unexpanded! "$ToolProxyBinding.memberships.url"
        end

        it "does not substitute $Context.sourcedId when the context is not a course" do
          expect_unexpanded! "$Context.sourcedId"
        end
      end

      context "when launching from a group assignment" do
        let(:group) { group_category.groups.create!(name: "test", context: assignment_course) }
        let(:group_category) { GroupCategory.create!(name: "test", context: assignment_course) }
        let(:new_assignment) { assignment_model(course: assignment_course) }
        let(:assignment_course) do
          c = course_model(account:)
          c.save!
          c
        end
        let(:variable_expander_opts) { { current_user: user, tool:, assignment: new_assignment } }

        before do
          group.update!(users: [user])
          new_assignment.update!(group_category:)
        end

        describe "com.instructure.Group.id" do
          let(:expansion) { "$com.instructure.Group.id" }

          context "when assignment is blank" do
            let(:variable_expander_opts) { { current_user: user, tool: } }

            it "safely remains unexpanded" do
              expect_unexpanded! expansion
            end
          end

          context "when user is blank" do
            let(:variable_expander_opts) { { tool:, assignment: new_assignment } }

            it "safely remains unexpanded" do
              expect_unexpanded! expansion
            end
          end

          it "has a substitution for com.instructure.Group.id" do
            expect(expand!(expansion)).to eq group.id
          end
        end

        describe "com.instructure.Group.name" do
          let(:expansion) { "$com.instructure.Group.name" }

          context "when assignment is blank" do
            let(:variable_expander_opts) { { current_user: user, tool: } }

            it "it safely remains unexpanded" do
              expect_unexpanded! expansion
            end
          end

          context "when user is blank" do
            let(:variable_expander_opts) { { tool:, assignment: new_assignment } }

            it "it safely remains unexpanded" do
              expect_unexpanded! expansion
            end
          end

          it "has a substitution for com.instructure.Group.name" do
            expect(expand!(expansion)).to eq group.name
          end
        end
      end

      context "context is a course" do
        let(:variable_expander) do
          VariableExpander.new(root_account, course, controller, current_user: user, tool:)
        end

        # See also specs for: context is a #{tested_context_type}
        it "has substitution for $Context.sourcedId" do
          allow(course).to receive(:sis_source_id).and_return("123")
          expect(expand!("$Context.sourcedId")).to eq "123"
        end
      end

      ["course", "group with a course context"].each do |tested_context_type|
        context "context is a #{tested_context_type}" do
          let(:tested_context) { (tested_context_type == "course") ? course : group }
          let(:variable_expander) do
            VariableExpander.new(root_account, tested_context, controller, current_user: user, tool:)
          end

          # Simple substitutions of course properties:
          it_expands "$Canvas.course.name", "Computers 4"
          it_expands("$com.instructure.contextLabel") { course.course_code }
          it_expands "$CourseSection.sourcedId", "c-sis-id"
          it_expands "$Canvas.course.sisSourceId", "c-sis-id"
          it_expands "$CourseOffering.sourcedId", "c-sis-id"

          it_expands "$Canvas.course.id" do
            allow(course).to receive(:id).and_return(123)
            123
          end

          it_expands "$ToolProxyBinding.memberships.url" do
            allow(course).to receive(:id).and_return("1")
            allow(controller).to receive(:polymorphic_url).and_return("/api/lti/courses/#{course.id}/membership_service")
            "/api/lti/courses/1/membership_service"
          end

          it "has substitution for $Context.id.history" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:recursively_fetch_previous_lti_context_ids).and_return("xyz,abc")
            expect(expand!("$Context.id.history")).to eq "xyz,abc"
          end

          it "has substitution for $vnd.instructure.Course.uuid" do
            allow(course).to receive(:uuid).and_return("Ioe3sJPt0KZp9Pw6xAvcHuLCl0z4TvPKP0iIOLbo")
            expect(expand!("$vnd.instructure.Course.uuid")).to eq "Ioe3sJPt0KZp9Pw6xAvcHuLCl0z4TvPKP0iIOLbo"
          end

          it "has substitution for $Canvas.course.workflowState" do
            course.workflow_state = "available"
            expect(expand!("$Canvas.course.workflowState")).to eq "available"
          end

          it "has substitution for $Canvas.course.hideDistributionGraphs" do
            course.hide_distribution_graphs = true
            expect(expand!("$Canvas.course.hideDistributionGraphs")).to be true
          end

          it "has substitution for $Canvas.course.gradePassbackSetting" do
            course.grade_passback_setting = "nightly sync"
            expect(expand!("$Canvas.course.gradePassbackSetting")).to eq "nightly sync"
          end

          it "has substitution for $com.instructure.Course.integrationId" do
            course.integration_id = "integration1"
            expect(expand!("$com.instructure.Course.integrationId")).to eq "integration1"
          end

          it "has substitution for $Canvas.enrollment.enrollmentState" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:enrollment_state).and_return("active")
            expect(expand!("$Canvas.enrollment.enrollmentState")).to eq "active"
          end

          it "has substitution for $Canvas.membership.roles" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:current_canvas_roles).and_return("teacher,student")
            expect(expand!("$Canvas.membership.roles")).to eq "teacher,student"
          end

          it "has substitution for $com.Instructure.membership.roles for 1.1 tools" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:current_canvas_roles_lis_v2).with("lis2").and_return(
              "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student"
            )
            expect(expand!("$com.Instructure.membership.roles")).to eq \
              "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student"
          end

          it "has substitution for $com.Instructure.membership.roles for 1.3 tools" do
            allow(tool).to receive(:use_1_3?).and_return(true)
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:current_canvas_roles_lis_v2).with("lti1_3").and_return(
              "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student"
            )
            expect(expand!("$com.Instructure.membership.roles")).to eq \
              "http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student"
          end

          it "has substitution for $Canvas.membership.concludedRoles" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:concluded_lis_roles).and_return("learner")
            expect(expand!("$Canvas.membership.concludedRoles")).to eq "learner"
          end

          it "has substitution for $Canvas.course.previousContextIds" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:previous_lti_context_ids).and_return("abc,xyz")
            expect(expand!("$Canvas.course.previousContextIds")).to eq "abc,xyz"
          end

          it "has substitution for $Canvas.course.previousContextIds.recursive" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:recursively_fetch_previous_lti_context_ids).and_return("abc,xyz")
            expect(expand!("$Canvas.course.previousContextIds.recursive")).to eq "abc,xyz"
          end

          it "has substitution for $Canvas.course.previousCourseIds" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:previous_course_ids).and_return("1,2")
            expect(expand!("$Canvas.course.previousCourseIds")).to eq "1,2"
          end

          context "when the course has multiple sections" do
            # User.new leads to empty/null columns, which causes yet more AR
            # complaints. The user_factory takes care of this.
            let(:user) { user_factory }

            before do
              # AR complains if you don't save the course to the database first.
              course.save!
              enrolled_section = add_section("section one", { course: })
              add_section("section two", { course: })
              create_enrollment(course, user, { section: enrolled_section })
            end

            it "has a substitution for com.instructure.User.sectionNames" do
              expect(JSON.parse(expand!("$com.instructure.User.sectionNames"))).to match_array ["section one"]
            end

            it "works with a user enrolled in both sections" do
              create_enrollment(course, user, { section: course.course_sections.find_by(name: "section two") })
              expect(JSON.parse(expand!("$com.instructure.User.sectionNames"))).to \
                match_array ["section one", "section two"]
            end

            it "orders the names by section id" do
              add_section("section three", { course: })
              s1 = course.course_sections.find_by(name: "section one")
              s2 = course.course_sections.find_by(name: "section two")
              s3 = course.course_sections.find_by(name: "section three")
              create_enrollment(course, user, { section: s3 }) # Create the enrollment "out of order" based on section id
              create_enrollment(course, user, { section: s2 })
              exp_hash = { test: "$com.instructure.User.sectionNames" }
              variable_expander.expand_variables!(exp_hash)
              expect(s1.id).to be < s2.id
              expect(s2.id).to be < s3.id
              expect(JSON.parse(exp_hash[:test])).to eq ["section one", "section two", "section three"]
            end
          end

          context "when a user has multiple enrollments in one course" do
            let(:user) { user_factory }
            let(:section) { add_section("section one", { course: }) }

            before do
              course.save!
              create_enrollment(course, user, { section:, enrollment_type: "StudentEnrollment" })
              create_enrollment(course, user, { section:, enrollment_type: "TaEnrollment" })
            end

            it "does not list duplicate sections" do
              expect(JSON.parse(expand!("$com.instructure.User.sectionNames"))).to match_array ["section one"]
            end
          end

          context "when the course has groups" do
            before do
              # AR complains if you don't save the course to the database before
              # adding the group (triggered in let(:group) when making a expander
              course.save!
            end

            let(:course_with_groups) do
              variable_expander.lti_helper.course.tap(&:save!)
            end

            let!(:group_one) { group }
            let!(:group_two) { course_with_groups.groups.create!(name: "Group Two") }

            describe "$com.instructure.Course.groupIds" do
              it "has substitution" do
                expected_ids = [group_one, group_two].map { |g| g.id.to_s }
                expanded = expand!("$com.instructure.Course.groupIds")
                expect(expanded.split(",")).to match_array expected_ids
              end

              it "does not include groups outside of the course" do
                second_course = variable_expander.lti_helper.course.dup
                second_course.update!(sis_source_id: SecureRandom.uuid)
                second_course.groups.create!(name: "Group Three")
                expected_ids = [group_two, group_one].map { |g| g.id.to_s }
                expanded = expand!("$com.instructure.Course.groupIds")
                expect(expanded.split(",")).to match_array expected_ids
              end

              it "only includes active group ids" do
                group_one.update!(workflow_state: "deleted")
                expect(expand!("$com.instructure.Course.groupIds")).to eq group_two.id.to_s
              end

              it "guards against the course being nil" do
                VariableExpander.new(root_account, nil, controller, current_user: user)
                expect do
                  expand!("$com.instructure.Course.groupIds")
                end.not_to raise_exception
              end
            end
          end

          describe "$com.instructure.User.student_view" do
            subject { expand!("$com.instructure.User.student_view") }

            context "user is not logged in" do
              let(:user) { nil }

              it { is_expected.to eq "$com.instructure.User.student_view" }
            end

            context "user is generated by student view" do
              before { allow_any_instance_of(User).to receive(:fake_student?).and_return(true) }

              it { is_expected.to be true }
            end

            context "user is not from student view" do
              before { allow_any_instance_of(User).to receive(:fake_student?).and_return(nil) }

              it { is_expected.to be false }
            end
          end

          describe "$com.instructure.instui_nav" do
            subject { expand!("$com.instructure.instui_nav") }

            context "internal tool" do
              before { allow(tool).to receive(:internal_service?).with(any_args).and_return(true) }

              context "release flag instui_nav is true" do
                before { root_account.enable_feature!(:instui_nav) }

                it { is_expected.to be true }
              end

              context "release flag instui_nav is false" do
                before { root_account.disable_feature!(:instui_nav) }

                it { is_expected.to be false }
              end
            end

            context "not internal tool" do
              before { allow(tool).to receive(:internal_service?).with(any_args).and_return(false) }

              context "release flag instui_nav is true" do
                before { root_account.enable_feature!(:instui_nav) }

                it { is_expected.to eq "$com.instructure.instui_nav" }
              end

              context "release flag instui_nav is false" do
                before { root_account.disable_feature!(:instui_nav) }

                it { is_expected.to eq "$com.instructure.instui_nav" }
              end
            end
          end

          describe "$com.instructure.RCS.app_host" do
            subject { expand!("$com.instructure.RCS.app_host") }

            let(:app_host) { "rich-content-iad.inscloudgate.net" }

            context "when the RCS in configured" do
              before do
                allow(DynamicSettings).to receive(:find)
                                      .with(any_args)
                  .and_call_original

                allow(DynamicSettings).to receive(:find)
                                      .with("rich-content-service", default_ttl: 5.minutes)
                  .and_return(DynamicSettings::FallbackProxy.new({ "app-host" => app_host }))
              end

              it { is_expected.to eq app_host }
            end
          end

          describe "$com.instructure.RCS.service_jwt" do
            subject do
              allow(controller).to receive(:rce_js_env_base).with(any_args).and_return(JWT: "service-jwt")
              expand!("$com.instructure.RCS.service_jwt")
            end

            context "when tool is an internal service" do
              before do
                allow(tool).to receive(:internal_service?).with(any_args).and_return(true)
              end

              it { is_expected.to eq("service-jwt") }

              context "when controller is not set" do
                let(:variable_expander) { VariableExpander.new(root_account, course, nil, tool:) }

                it { is_expected.to eq("") }
              end
            end

            context "when tool is NOT an internal service" do
              before { allow(tool).to receive(:internal_service?).with(any_args).and_return(false) }

              it { is_expected.to eq("$com.instructure.RCS.service_jwt") }
            end
          end

          describe "$com.instructure.User.observees" do
            subject { expand!("$com.instructure.User.observees") }
            before do
              # AR complains if you don't save the course to the database first
              # before using the Course-based group
              course.save!
            end

            let(:context) do
              c = variable_expander.context
              c.save!
              c
            end
            let(:student) { user_factory }
            let(:observer) { user_factory }

            before do
              course.enroll_student(student)
              variable_expander.current_user = observer
            end

            context "when the current user is observing users in the course" do
              before do
                observer_enrollment = course.enroll_user(observer, "ObserverEnrollment")
                observer_enrollment.update!(associated_user_id: student.id)
              end

              it "produces a comma-separated string of user UUIDs" do
                expect(subject.split(",")).to match_array [
                  Lti::V1p1::Asset.opaque_identifier_for(student)
                ]
              end

              context "the tool in use is a LTI 1.3 tool" do
                before do
                  allow(tool).to receive(:use_1_3?).and_return(true)
                end

                it "returns the users' lti id instead of lti 1.1 user_id" do
                  expect(subject.split(",")).to match_array [
                    student.lti_id
                  ]
                end
              end
            end

            context "when the current user is not observing users in the course" do
              it { is_expected.to eq "" }
            end
          end
        end

        describe "$com.instructure.Observee.sisIds (context is a #{tested_context_type})" do
          subject { expand!("$com.instructure.Observee.sisIds") }

          let(:student_a) { user_factory }
          let(:student_b) { user_factory }
          let(:student_c) { user_factory }
          let(:observer) { user_factory }
          let(:tested_context) { (tested_context_type == "course") ? course : group }
          let(:variable_expander) { VariableExpander.new(root_account, tested_context, controller, current_user: observer, tool:) }

          before do
            course.save!
            tested_context.save!
            managed_pseudonym(student_a, account: root_account, sis_user_id: "SIS_A")
            managed_pseudonym(student_b, account: root_account, sis_user_id: "SIS_B")

            course.enroll_student(student_a)
            course.enroll_student(student_b)
            course.enroll_student(student_c)

            variable_expander.current_user = observer
          end

          context "when the current user is observing students in the course context" do
            before do
              student_a_enrollment = course.enroll_user(observer, "ObserverEnrollment")
              student_a_enrollment.update!(associated_user_id: student_a.id)

              student_b_enrollment = course.enroll_user(observer, "ObserverEnrollment")
              student_b_enrollment.update!(associated_user_id: student_b.id)

              student_c_enrollment = course.enroll_user(observer, "ObserverEnrollment")
              student_c_enrollment.update!(associated_user_id: student_c.id)
            end

            it "return an array of all student that has a SIS IDs" do
              id_set = subject.split(",").to_set
              expect(Set["SIS_A", "SIS_B"]).to eq(id_set)
            end
          end

          context "when the current user is not observing students in the course context" do
            it "return a empty array of student SIS IDs" do
              expect(subject).to be_empty
            end
          end
        end
      end

      context "context is a course and there is a user" do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, current_user: user, tool:) }
        let(:user) { user_factory }

        it "has substitution for $Canvas.xapi.url" do
          allow(Lti::XapiService).to receive(:create_token).and_return("abcd")
          allow(controller).to receive(:lti_xapi_url).and_return("/xapi/abcd")
          expect(expand!("$Canvas.xapi.url")).to eq "/xapi/abcd"
        end

        it "returns the opaque identifiers for the active groups the user is a part of" do
          course.save!
          user.save!

          g1 = course.groups.new
          g2 = course.groups.new

          user.groups << g1
          user.groups << g2

          g1.save!
          g2.save!

          exp_hash = { test: "$Canvas.group.contextIds" }
          variable_expander.expand_variables!(exp_hash)

          g1.reload
          g2.reload

          ids = exp_hash[:test].split(",")
          expect(ids.size).to eq 2
          expect(ids.include?(g1.lti_context_id)).to be true
          expect(ids.include?(g2.lti_context_id)).to be true
        end
      end

      ["course", "group with a course context"].each do |tested_context_type|
        context "context is a #{tested_context_type} and there is a user" do
          let(:tested_context) { (tested_context_type == "course") ? course : group }
          let(:variable_expander) { VariableExpander.new(root_account, tested_context, controller, current_user: user, tool:) }
          let(:user) { user_factory }

          it "has substitution for com.instructure.User.sectionNames" do
            course.save!
            first_section = add_section("Section 1, M-T", { course: })
            second_section = add_section("Section 2, W-Th", { course: })
            create_enrollment(course, user, { section: first_section })
            create_enrollment(course, user, { section: second_section })
            expanded = expand!("$com.instructure.User.sectionNames")
            expect(JSON.parse(expanded)).to match_array ["Section 1, M-T", "Section 2, W-Th"]
          end

          it "has substitution for $Canvas.course.sectionIds" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:section_ids).and_return("5,6")
            expect(expand!("$Canvas.course.sectionIds")).to eq "5,6"
          end

          it "has substitution for $Canvas.course.sectionRestricted" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:section_restricted).and_return(true)
            expect(expand!("$Canvas.course.sectionRestricted")).to be true
          end

          it "has substitution for $Canvas.course.sectionSisSourceIds" do
            allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
            allow(substitution_helper).to receive(:section_sis_ids).and_return("5a,6b")
            expect(expand!("$Canvas.course.sectionSisSourceIds")).to eq "5a,6b"
          end

          it "has substitution for $Canvas.course.startAt" do
            course.start_at = "2015-04-21 17:01:36"
            course.save!
            expect(expand!("$Canvas.course.startAt")).to eq "2015-04-21 17:01:36"
          end

          it "has a functioning guard for $Canvas.term.startAt when term.start_at is not set" do
            expect(course.enrollment_term&.start_at).to be_falsey
            expect_unexpanded!("$Canvas.term.startAt")
          end

          it "has substitution for $Canvas.term.startAt when term.start_at is set" do
            course.enrollment_term = EnrollmentTerm.new(start_at: "2015-05-21 17:01:36")
            expect(expand!("$Canvas.term.startAt")).to eq "2015-05-21 17:01:36"
          end

          it "has substitution for $Canvas.course.endAt" do
            course.conclude_at = "2019-04-21 17:01:36"
            course.save!
            expect(expand!("$Canvas.course.endAt")).to eq "2019-04-21 17:01:36"
          end

          it "has a functioning guard for $Canvas.term.endAt when term.start_at is not set" do
            expect(course.enrollment_term&.end_at).to be_falsey
            expect_unexpanded!("$Canvas.term.endAt")
          end

          it "has substitution for $Canvas.term.endAt when term.start_at is set" do
            course.enrollment_term = EnrollmentTerm.new(end_at: "2015-05-21 17:01:36")
            expect(expand!("$Canvas.term.endAt")).to eq "2015-05-21 17:01:36"
          end

          it "has a functioning guard for $Canvas.term.name when term.name is not set" do
            expect(course.enrollment_term&.name).to be_falsey
            expect_unexpanded!("$Canvas.term.name")
          end

          it "has substitution for $Canvas.term.name when term.name is set" do
            course.enrollment_term = EnrollmentTerm.new(name: "W1 2017")
            expect(expand!("$Canvas.term.name")).to eq "W1 2017"
          end

          it "has a functioning guard for $Canvas.term.id when there is no term or term ID" do
            # This may not be possible, but regardless it's good not to crash
            expect(course.enrollment_term).to be_nil
            expect_unexpanded!("$Canvas.term.id")
            course.enrollment_term = EnrollmentTerm.new
            expect_unexpanded!("$Canvas.term.id")
          end

          it "has substitution for $Canvas.term.id when there is a term" do
            term = EnrollmentTerm.create!(root_account:)
            course.enrollment_term = term
            expect(expand!("$Canvas.term.id")).to eq term.id
          end

          it "has substitution for $Canvas.externalTool.global_id" do
            course.save!
            tool = course.context_external_tools.create!(domain: "example.com", consumer_key: "12345", shared_secret: "secret", privacy_level: "anonymous", name: "tool")
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:)
            expect(expand!("$Canvas.externalTool.global_id", expander:)).to eq tool.global_id
          end

          it "does not substitute $Canvas.externalTool.global_id when the controller is unset" do
            variable_expander.instance_variable_set(:@controller, nil)
            variable_expander.instance_variable_set(:@request, nil)
            expect_unexpanded! "$Canvas.externalTool.global_id"
          end

          it "has substitution for $Canvas.externalTool.url" do
            course.save!
            tool = course.context_external_tools.create!(domain: "example.com", consumer_key: "12345", shared_secret: "secret", privacy_level: "anonymous", name: "tool")
            expect(controller).to receive(:named_context_url).with(course,
                                                                   :api_v1_context_external_tools_update_url,
                                                                   tool.id,
                                                                   include_host: true).and_return("url")
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:)
            expect(expand!("$Canvas.externalTool.url", expander:)).to eq "url"
          end

          it "does not substitute $Canvas.externalTool.url when the controller is unset" do
            variable_expander.instance_variable_set(:@controller, nil)
            variable_expander.instance_variable_set(:@request, nil)
            expect_unexpanded! "$Canvas.externalTool.url"
          end
        end
      end

      context "has substitutions for ResourceLink variables" do
        let(:course) { course_factory }

        let(:developer_key) { DeveloperKey.create! }

        let(:tool) do
          ContextExternalTool.create!(
            context: course,
            tool_id: 1234,
            name: "test tool",
            consumer_key: "key",
            shared_secret: "secret",
            url: "https://www.tool.com/launch",
            developer_key:,
            lti_version: "1.3"
          )
        end

        let(:right_now) { Time.zone.now }

        context "when the assignment has external_tool as a submission_type" do
          let(:resource_link_uuid) do
            SecureRandom.uuid
          end
          let(:assignment) do
            opts = {
              course:,
              external_tool_tag_attributes: {
                url: tool.url,
                content_type: "ContextExternalTool",
                content_id: tool.id
              },
              title: "Activity XYZ",
              description: "This is a super fun activity",
              submission_types: "external_tool",
              points_possible: 8.5,
              workflow_state: "published",
              unlock_at: right_now,
              due_at: right_now,
              lock_at: right_now
            }
            assignment = assignment_model opts

            line_item = assignment.line_items.first
            line_item.resource_link = Lti::ResourceLink.new(
              resource_link_uuid:,
              context_external_tool_id: tool.id,
              workflow_state: "active",
              root_account_id: course.root_account.id,
              context_id: course.id,
              context_type: "Course",
              custom: {},
              lookup_uuid: SecureRandom.uuid
            )
            line_item.update!(
              {
                resource_id: "abc",
                tag: "def"
              }
            )

            assignment
          end

          let(:variable_expander) do
            VariableExpander.new(
              root_account,
              course,
              controller,
              assignment:
            )
          end

          it_expands("$ResourceLink.id") { resource_link_uuid }
          it_expands "$ResourceLink.description", "This is a super fun activity"
          it_expands "$ResourceLink.title", "Activity XYZ"
          it_expands("$ResourceLink.available.startDateTime") { right_now.iso8601(3) }
          it_expands("$ResourceLink.available.endDateTime") { right_now.iso8601(3) }
          it_expands("$ResourceLink.submission.endDateTime") { right_now.iso8601(3) }
        end

        context "when there is no assignment" do
          let(:assignment) { nil }

          let(:resource_link_uuid) do
            SecureRandom.uuid
          end

          let(:resource_link) do
            Lti::ResourceLink.new(
              resource_link_uuid:,
              context_external_tool_id: tool.id,
              workflow_state: "active",
              root_account_id: course.root_account.id,
              context_id: course.id,
              context_type: "Course",
              custom: {},
              lookup_uuid: SecureRandom.uuid
            )
          end

          let(:content_tag) do
            double("content_tag")
          end

          let(:variable_expander) do
            VariableExpander.new(
              root_account,
              course,
              controller,
              assignment:,
              content_tag:
            )
          end

          it "has substitution for $ResourceLink.id" do
            allow(content_tag).to receive(:associated_asset).and_return(resource_link)
            expect(expand!("$ResourceLink.id")).to eq resource_link_uuid
          end

          it_leaves_unexpanded "$ResourceLink.description"
          it_leaves_unexpanded "$ResourceLink.title"
          it_leaves_unexpanded "$ResourceLink.startDateTime"
          it_leaves_unexpanded "$ResourceLink.endDateTime"
        end

        context "when ResourceLink.title is populated" do
          let(:resource_link_title) { "Tool Title" }

          let(:resource_link) do
            Lti::ResourceLink.new(
              resource_link_uuid: SecureRandom.uuid,
              context_external_tool_id: tool.id,
              workflow_state: "active",
              root_account_id: course.root_account.id,
              context_id: course.id,
              context_type: "Course",
              custom: {},
              lookup_uuid: SecureRandom.uuid,
              title: resource_link_title
            )
          end

          let(:variable_expander) do
            VariableExpander.new(
              root_account,
              course,
              controller,
              resource_link:
            )
          end

          it_expands("$ResourceLink.title") { resource_link_title }
        end
      end

      context "context is a course with an assignment" do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, tool:, collaboration:) }

        it "has substitution for $Canvas.api.collaborationMembers.url" do
          allow(collaboration).to receive(:id).and_return(1)
          allow(controller).to receive(:api_v1_collaboration_members_url).and_return("https://www.example.com/api/v1/collaborations/1/members")
          expect(expand!("$Canvas.api.collaborationMembers.url")).to \
            eq "https://www.example.com/api/v1/collaborations/1/members"
        end
      end

      context "context is a course with an assignment and a user" do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, current_user: user, tool:, assignment:) }

        it "has substitution for $Canvas.assignment.id" do
          allow(assignment).to receive(:id).and_return(2015)
          expect(expand!("$Canvas.assignment.id")).to eq 2015
        end

        it "has substitution for $Canvas.assignment.description" do
          allow(assignment).to receive(:description).and_return("desc")
          expect(expand!("$Canvas.assignment.description")).to eq "desc"
        end

        it "has substitution for $Canvas.assignment.description longer than 1000 characters" do
          str = SecureRandom.urlsafe_base64(1000)
          allow(assignment).to receive(:description).and_return(str)
          expect(expand!("$Canvas.assignment.description")).to eq str[0..984] + "... (truncated)"
        end

        it "has substitution for $Canvas.assignment.title" do
          assignment.title = "Buy as many ducks as you can"
          expect(expand!("$Canvas.assignment.title")).to eq "Buy as many ducks as you can"
        end

        describe "$Canvas.assignment.pointsPossible" do
          it "has substitution for $Canvas.assignment.pointsPossible" do
            allow(assignment).to receive(:points_possible).and_return(10.0)
            expect(expand!("$Canvas.assignment.pointsPossible")).to eq 10
          end

          it "does not round if not whole" do
            allow(assignment).to receive(:points_possible).and_return(9.5)
            expect(expand!("$Canvas.assignment.pointsPossible").to_s).to eq "9.5"
          end

          it "rounds if whole" do
            allow(assignment).to receive(:points_possible).and_return(9.0)
            expect(expand!("$Canvas.assignment.pointsPossible").to_s).to eq "9"
          end
        end

        describe "$LineItem.resultValue.max" do
          it "has substitution for $LineItem.resultValue.max" do
            allow(assignment).to receive(:points_possible).and_return(10.0)
            expect(expand!("$LineItem.resultValue.max")).to eq 10
          end

          it "does not round if not whole" do
            allow(assignment).to receive(:points_possible).and_return(9.5)
            expect(expand!("$LineItem.resultValue.max").to_s).to eq "9.5"
          end

          it "rounds if whole" do
            allow(assignment).to receive(:points_possible).and_return(9.0)
            expect(expand!("$LineItem.resultValue.max").to_s).to eq "9"
          end
        end

        it "has substitution for $Canvas.assignment.unlockAt" do
          allow(assignment).to receive(:unlock_at).and_return(right_now.to_s)
          expect(expand!("$Canvas.assignment.unlockAt")).to eq right_now.to_s
        end

        it "has substitution for $Canvas.assignment.lockAt" do
          allow(assignment).to receive(:lock_at).and_return(right_now.to_s)
          expect(expand!("$Canvas.assignment.lockAt")).to eq right_now.to_s
        end

        it "has substitution for $Canvas.assignment.dueAt" do
          allow(assignment).to receive(:due_at).and_return(right_now.to_s)
          expect(expand!("$Canvas.assignment.dueAt")).to eq right_now.to_s
        end

        it "has substitution for $Canvas.assignment.published" do
          allow(assignment).to receive(:workflow_state).and_return("published")
          expect(expand!("$Canvas.assignment.published")).to be true
        end

        describe "$Canvas.assignment.lockdownEnabled" do
          it "returns true when lockdown is enabled" do
            allow(assignment).to receive(:settings).and_return({
                                                                 "lockdown_browser" => {
                                                                   "require_lockdown_browser" => true
                                                                 }
                                                               })
            expect(expand!("$Canvas.assignment.lockdownEnabled")).to be true
          end

          it "returns false when lockdown is disabled" do
            allow(assignment).to receive(:settings).and_return({
                                                                 "lockdown_browser" => {
                                                                   "require_lockdown_browser" => false
                                                                 }
                                                               })
            expect(expand!("$Canvas.assignment.lockdownEnabled")).to be false
          end

          it "returns false when masquerading" do
            variable_expander = VariableExpander.new(root_account, course, controller, current_user: User.new, tool:, assignment:)
            allow(assignment).to receive(:settings).and_return({
                                                                 "lockdown_browser" => {
                                                                   "require_lockdown_browser" => true
                                                                 }
                                                               })
            exp_hash = { test: "$Canvas.assignment.lockdownEnabled" }
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to be false
          end

          it "returns false as default" do
            allow(assignment).to receive(:settings).and_return({})
            expect(expand!("$Canvas.assignment.lockdownEnabled")).to be false
          end
        end

        it "has substitution for $Canvas.assignment.allowedAttempts" do
          assignment.allowed_attempts = 5
          expect(expand!("$Canvas.assignment.allowedAttempts")).to eq 5
        end

        it "handles a nil assignment.allowedAttempts" do
          assignment.allowed_attempts = nil
          expect(expand!("$Canvas.assignment.allowedAttempts")).to eq "$Canvas.assignment.allowedAttempts"
        end

        describe "$Canvas.assignment.submission.studentAttempts" do
          before do
            user.save
            course.save
            assignment.context = course
            assignment.save
            submission = submission_model(user:, assignment:)
            submission.attempt = 2
            submission.save
          end

          it "does not have a substitution when the user is not a student" do
            allow(course).to receive(:user_is_student?).and_return(false)
            expect_unexpanded! "$Canvas.assignment.submission.studentAttempts"
          end

          it "has substitution when the user is a student" do
            allow(course).to receive(:user_is_student?).and_return(true)
            expect(expand!("$Canvas.assignment.submission.studentAttempts")).to eq 2
          end

          it "has substitution when the user is a student and context is a course-based Group" do
            exp = VariableExpander.new(root_account, group, controller, current_user: user, tool:, assignment:)
            expect(exp.lti_helper.course).to_not be_nil
            expect(exp.lti_helper.course).to receive(:user_is_student?).and_return(true)
            expect(expand!("$Canvas.assignment.submission.studentAttempts", expander: exp)).to eq 2
          end
        end

        context "iso8601" do
          it "has substitution for $Canvas.assignment.unlockAt.iso8601" do
            allow(assignment).to receive(:unlock_at).and_return(right_now)
            expect(expand!("$Canvas.assignment.unlockAt.iso8601")).to eq right_now.utc.iso8601
          end

          it "has substitution for $Canvas.assignment.lockAt.iso8601" do
            allow(assignment).to receive(:lock_at).and_return(right_now)
            expect(expand!("$Canvas.assignment.lockAt.iso8601")).to eq right_now.utc.iso8601
          end

          describe "$Canvas.assignment.dueAt.iso8601" do
            before do
              course.save!
              user.save!
              assignment.update!(course:)
            end

            context "for student" do
              before do
                course.enroll_user(user, "StudentEnrollment")
              end

              it "is expanded" do
                assignment.update!(due_at: right_now)
                expect(expand!("$Canvas.assignment.dueAt.iso8601")).to eq right_now.utc.iso8601
              end

              it "handles a nil due_at" do
                assignment.update!(due_at: nil)
                expect_unexpanded! "$Canvas.assignment.dueAt.iso8601"
              end

              context "with an due_date override" do
                it "is expanded" do
                  assignment.update!(due_at: right_now - 1.day)
                  assignment.submissions[0].update!(cached_due_date: right_now)
                  expect(expand!("$Canvas.assignment.dueAt.iso8601")).to eq right_now.utc.iso8601
                end
              end
            end

            context "for teacher" do
              before do
                course.enroll_user(user, "TeacherEnrollment")
              end

              context "with enrollments" do
                before do
                  course.enroll_user(User.create!, "StudentEnrollment")
                  course.enroll_user(User.create!, "StudentEnrollment")
                end

                it "is expanded" do
                  subm1, subm2 = assignment.submissions.to_a
                  subm1.update! cached_due_date: right_now
                  subm2.update! cached_due_date: right_now - 1.day
                  expect(assignment.due_at).to be_nil
                  expect(expand!("$Canvas.assignment.dueAt.iso8601")).to eq right_now.utc.iso8601
                end

                it "handles a nil due_at" do
                  assignment.update!(due_at: nil)
                  expect_unexpanded! "$Canvas.assignment.dueAt.iso8601"
                end
              end

              context "without enrollments" do
                it "is expanded if there is due date set" do
                  assignment.update!(due_at: right_now)
                  expect(expand!("$Canvas.assignment.dueAt.iso8601")).to eq right_now.utc.iso8601
                end

                it "handles a nil due_at" do
                  assignment.update!(due_at: nil)
                  expect_unexpanded! "$Canvas.assignment.dueAt.iso8601"
                end
              end
            end
          end

          it "has substitution for $Canvas.assignment.allDueAts.iso8601" do
            allow(variable_expander).to receive(:unique_submission_dates).and_return([right_now, nil])
            expect(expand!("$Canvas.assignment.allDueAts.iso8601")).to eq right_now.utc.iso8601 + ","
          end

          it "handles a nil unlock_at" do
            allow(assignment).to receive(:unlock_at).and_return(nil)
            expect_unexpanded! "$Canvas.assignment.unlockAt.iso8601"
          end

          it "handles a nil lock_at" do
            allow(assignment).to receive(:lock_at).and_return(nil)
            expect_unexpanded! "$Canvas.assignment.lockAt.iso8601"
          end
        end

        describe "$Canvas.assignment.earliestEnrollmentDueAt.iso8601" do
          before do
            course.save!
            user.save!
            assignment.update!(course:)
          end

          context "student launch" do
            before do
              course.enroll_user(user, "StudentEnrollment")
            end

            it "expands to the due_at on the assignment (which will be the due date for the student)" do
              expect(assignment).to receive(:due_at).and_return(right_now)
              expect(expand!("$Canvas.assignment.earliestEnrollmentDueAt.iso8601")).to eq right_now.utc.iso8601
            end

            it "expands to an empty string if there is no due date for the student" do
              course.enroll_user(user, "StudentEnrollment")
              expect(expand!("$Canvas.assignment.earliestEnrollmentDueAt.iso8601")).to eq ""
            end

            context "with an due_date override" do
              it "is expanded" do
                assignment.update!(due_at: right_now - 1.day)
                assignment.submissions[0].update!(cached_due_date: right_now)
                expect(expand!("$Canvas.assignment.earliestEnrollmentDueAt.iso8601")).to eq right_now.utc.iso8601
              end
            end
          end

          context "teacher launch" do
            before do
              course.enroll_user(user, "TeacherEnrollment")
              course.enroll_user(User.create!, "StudentEnrollment")
              course.enroll_user(User.create!, "StudentEnrollment")
            end

            it "expands to earliest due date of many sections" do
              subm1, subm2 = assignment.submissions.to_a
              subm1.update! cached_due_date: "2090-01-01T00:00:00Z"
              subm2.update! cached_due_date: "2090-01-02T00:00:00Z"
              expect(expand!("$Canvas.assignment.earliestEnrollmentDueAt.iso8601")).to eq "2090-01-01T00:00:00Z"
            end

            it "expands to an empty string if there are no due dates for any student" do
              expect(expand!("$Canvas.assignment.earliestEnrollmentDueAt.iso8601")).to eq ""
            end
          end
        end
      end

      context "user is not logged in" do
        let(:user) { nil }

        it "has substitution for $vnd.Canvas.Person.email.sis when user is not logged in" do
          expect_unexpanded! "$vnd.Canvas.Person.email.sis"
        end
      end

      context "user is logged in" do
        describe "name" do
          before do
            user.name = "Uncle Jake"
            user.short_name = "Unc J"
            user.sortable_name = "Jake, Uncle"
            user.pronouns = "He/Him"
          end

          it_expands "$Person.name.full", "Uncle Jake"
          it_expands "$Person.name.display", "Unc J"
          it_expands "$Person.name.family", "Jake"
          it_expands "$Person.name.given", "Uncle"
          it_expands "$com.instructure.Person.name_sortable", "Jake, Uncle"
        end

        it "has substitution for $com.instructure.Person.pronouns" do
          user.pronouns = "She/Her"
          user.account.settings[:can_add_pronouns] = true
          user.account.save!

          expect(expand!("$com.instructure.Person.pronouns")).to eq "She/Her"
        end

        it "has substitution for $Person.email.primary" do
          allow(substitution_helper).to receive(:email).and_return("someone@somewhere")
          allow(SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          expect(expand!("$Person.email.primary")).to eq "someone@somewhere"
        end

        it "has substitution for $vnd.Canvas.Person.email.sis when user is added via sis" do
          user.save
          user.email = "someone@somewhere"
          cc1 = user.communication_channels.first
          pseudonym1 = cc1.user.pseudonyms.build(unique_id: cc1.path, account: root_account)
          pseudonym1.sis_communication_channel_id = cc1.id
          pseudonym1.communication_channel_id = cc1.id
          pseudonym1.sis_user_id = "some_sis_id"
          pseudonym1.save

          expect(expand!("$vnd.Canvas.Person.email.sis")).to eq "someone@somewhere"
        end

        it "has substitution for $vnd.Canvas.Person.email.sis when user is NOT added via sis" do
          user.save
          user.email = "someone@somewhere"

          expect_unexpanded! "$vnd.Canvas.Person.email.sis"
        end

        it "has substitution for $Person.address.timezone" do
          expect(expand!("$Person.address.timezone")).to eq "Etc/UTC"
        end

        it "has substitution for $User.image" do
          allow(user).to receive(:avatar_url).and_return("/my/pic")
          expect(expand!("$User.image")).to eq "/my/pic"
        end

        it "has substitution for $Canvas.user.id" do
          allow(user).to receive(:id).and_return(456)
          expect(expand!("$Canvas.user.id")).to eq 456
        end

        it "has substitution for $vnd.instructure.User.uuid" do
          allow(user).to receive(:uuid).and_return("N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3")
          expect(expand!("$vnd.instructure.User.uuid")).to eq \
            "N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3"
        end

        it "has substitution for $vnd.instructure.User.uuid and uses Past uuid" do
          allow(user).to receive(:uuid).and_return("N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3")
          UserPastLtiId.create!(user:, context: account, user_lti_id: "old_lti_id", user_lti_context_id: "old_lti_id", user_uuid: "old_uuid")

          expect(expand!("$vnd.instructure.User.uuid")).to eq "old_uuid"
        end

        it "has substitution for $vnd.instructure.User.current_uuid" do
          allow(user).to receive(:uuid).and_return("N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3")
          expect(expand!("$vnd.instructure.User.current_uuid")).to eq \
            "N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3"
        end

        it "has substitution for $Canvas.user.isRootAccountAdmin" do
          allow(user).to receive(:roles).and_return(["root_admin"])
          expect(expand!("$Canvas.user.isRootAccountAdmin")).to be true
        end

        it "has substitution for $Canvas.user.adminableAccounts" do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:adminable_account_ids_recursive_truncated).and_return("123,456")
          expect(expand!("$Canvas.user.adminableAccounts")).to eq "123,456"
        end

        it "has substitution for $Canvas.xuser.allRoles" do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:all_roles).and_return("Admin,User")
          expect(expand!("$Canvas.xuser.allRoles")).to eq "Admin,User"
        end

        it "has substitution for $Canvas.user.globalId" do
          allow(user).to receive(:global_id).and_return(456)
          expect(expand!("$Canvas.user.globalId")).to eq 456
        end

        it "has substitution for $Membership.role" do
          allow(substitution_helper).to receive(:all_roles).with("lis2").and_return("Admin,User")
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          expect(expand!("$Membership.role")).to eq "Admin,User"
        end

        it "has substitution for $Membership.role in LTI 1.3 mode" do
          allow(tool).to receive(:use_1_3?).and_return(true)
          allow(substitution_helper).to receive(:all_roles).with("lti1_3").and_return("Admin,User")
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          expect(expand!("$Membership.role")).to eq "Admin,User"
        end

        it "has substitution for $User.id" do
          allow(user).to receive(:id).and_return(456)
          expect(expand!("$User.id")).to eq 456
        end

        context "$Canvas.user.prefersHighContrast" do
          it "substitutes as true" do
            allow(user).to receive(:prefers_high_contrast?).and_return(true)
            expect(expand!("$Canvas.user.prefersHighContrast")).to eq "true"
          end

          it "substitutes as false" do
            allow(user).to receive(:prefers_high_contrast?).and_return(false)
            expect(expand!("$Canvas.user.prefersHighContrast")).to eq "false"
          end
        end

        context "pseudonym" do
          let(:pseudonym) { Pseudonym.new }

          before do
            allow(SisPseudonym).to receive(:for).with(user, anything, anything).and_return(pseudonym)
          end

          it_expands("$Canvas.user.sisSourceId") { pseudonym.sis_user_id = "1a2b3c" }
          it_expands("$Person.sourcedId") { pseudonym.sis_user_id = "1a2b3c" }
          it_expands("$Canvas.user.loginId") { pseudonym.unique_id = "username" }
          it_expands("$User.username") { pseudonym.unique_id = "username" }

          context "when in the :user_navigation placement" do
            let(:variable_expander_opts) { super().merge({ placement: :user_navigation }) }

            before do
              pseudonym.sis_user_id = "1a2b3c"
            end

            context "when the context is a User" do
              let(:variable_expander_opts) { super().merge({ context: user }) }

              it_expands "$Context.sourcedId", "1a2b3c"
            end

            context "when the context is not a User" do
              let(:variable_expander_opts) { super().merge({ context: account }) }

              it_leaves_unexpanded "$Context.sourcedId"
            end
          end
        end

        context "attachment" do
          let(:attachment) do
            attachment = attachment_obj_with_context(course)
            attachment.media_object = media_object
            attachment.usage_rights = usage_rights
            attachment
          end
          let(:media_object) do
            mo = MediaObject.new
            mo.media_id = "1234"
            mo.media_type = "video"
            mo.duration = 555
            mo.total_size = 444
            mo.title = "some title"
            mo
          end
          let(:usage_rights) do
            ur = UsageRights.new
            ur.legal_copyright = "legit"
            ur
          end
          let(:variable_expander) { VariableExpander.new(root_account, account, controller, current_user: user, tool:, attachment:) }

          it "has substitution for $Canvas.file.media.id when a media object is present" do
            expect(expand!("$Canvas.file.media.id")).to eq "1234"
          end

          it "has substitution for $Canvas.file.media.id when a media entry is present" do
            attachment.media_object = nil
            attachment.media_entry_id = "4567"
            expect(expand!("$Canvas.file.media.id")).to eq "4567"
          end

          it_expands "$Canvas.file.media.type", "video"
          it_expands "$Canvas.file.media.duration", 555
          it_expands "$Canvas.file.media.size", 444
          it_expands "$Canvas.file.media.title", "some title"

          it "uses user_entered_title for $Canvas.file.media.title if present" do
            media_object.user_entered_title = "user title"
            expect(expand!("$Canvas.file.media.title")).to eq "user title"
          end

          it_expands "$Canvas.file.usageRights.name", "Private (Copyrighted)"
          it_expands "$Canvas.file.usageRights.url", "http://en.wikipedia.org/wiki/Copyright"
          it_expands "$Canvas.file.usageRights.copyrightText", "legit"
        end

        describe "masquerading user substitutions" do
          before do
            masqueradee = User.new
            allow(masqueradee).to receive(:id).and_return(7878)
            allow(user).to receive(:id).and_return(42)
            variable_expander.instance_variable_set(:@current_user, masqueradee)
          end

          it_expands "$Canvas.masqueradingUser.id", 42

          it "does not expand $Canvas.masqueradingUser.id when the controller is unset" do
            variable_expander.instance_variable_set(:@controller, nil)
            variable_expander.instance_variable_set(:@request, nil)
            expect_unexpanded! "$Canvas.masqueradingUser.id"
          end

          it "has substitution for $Canvas.masqueradingUser.userId" do
            expect(expand!("$Canvas.masqueradingUser.userId")).to eq "6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f"
          end

          context "when the tool is LTI 1.3" do
            before { allow(tool).to receive(:use_1_3?).and_return(true) }

            it "returns the user's lti id instead of lti 1.1 user_id" do
              user.lti_id = "fake_lti_id"
              expanded = expand!("$Canvas.masqueradingUser.userId")
              expect(expanded).to eq user.lti_id
            end
          end
        end

        it "has substitution for Canvas.module.id" do
          content_tag = double("content_tag")
          allow(content_tag).to receive(:context_module_id).and_return("foo")
          variable_expander.instance_variable_set(:@content_tag, content_tag)
          expect(expand!("$Canvas.module.id")).to eq "foo"
        end

        it "has substitution for Canvas.moduleItem.id" do
          content_tag = double("content_tag")
          allow(content_tag).to receive(:id).and_return(7878)
          variable_expander.instance_variable_set(:@content_tag, content_tag)
          expect(expand!("$Canvas.moduleItem.id")).to eq 7878
        end

        it "has substitution for ToolConsumerProfile.url" do
          expander = VariableExpander.new(root_account, account, controller, current_user: user, tool: ToolProxy.new)
          expect(expand!("$ToolConsumerProfile.url", expander:)).to eq "url"
        end

        it "has substitution for $com.instructure.user.lti_1_1_id.history" do
          course.save!
          user.lti_context_id = "current_context_id"
          UserPastLtiId.create!(user:, context: account, user_lti_id: "old_lti_id", user_lti_context_id: "old_context_id", user_uuid: "old_uuid")
          UserPastLtiId.create!(user:, context: course, user_lti_id: "old_lti_id", user_lti_context_id: "old_context_id", user_uuid: "old_uuid")
          UserPastLtiId.create!(user: User.new, context: account, user_lti_id: "old_lti_id2", user_lti_context_id: "", user_uuid: "old_uuid2")
          expect(expand!("$com.instructure.user.lti_1_1_id.history")).to eq "old_context_id,current_context_id"
        end
      end

      context "refactor_custom_variables FF is on" do
        before do
          root_account.enable_feature!(:refactor_custom_variables)
        end

        it "has substitution for $Canvas.api.domain" do
          allow(root_account).to receive(:environment_specific_domain).and_return("localhost")
          expect(expand!("$Canvas.api.domain")).to eq "localhost"
        end

        context "context is a course with an assignment" do
          let(:variable_expander) { VariableExpander.new(root_account, course, nil, tool:, collaboration:) }

          it "has substitution for $Canvas.api.collaborationMembers.url" do
            allow(collaboration).to receive(:id).and_return(1)
            allow(tool.context).to receive(:environment_specific_domain).and_return("localhost")
            allow(Rails.application.routes.url_helpers).to receive(:api_v1_collaboration_members_url)
              .and_return("https://www.example.com/api/v1/collaborations/1/members")
            expect(expand!("$Canvas.api.collaborationMembers.url")).to \
              eq "https://www.example.com/api/v1/collaborations/1/members"
          end

          it "has substitution for $ToolProxyBinding.memberships.url even if the controller is unset" do
            course.save!
            allow(root_account).to receive(:environment_specific_domain).and_return("localhost")
            variable_expander.instance_variable_set(:@controller, nil)
            variable_expander.instance_variable_set(:@request, nil)
            expect(expand!("$ToolProxyBinding.memberships.url")).to eq \
              "http://localhost/api/lti/courses/#{course.id}/membership_service"
          end

          it "has substitution for $Canvas.externalTool.url even if the controller is unset" do
            course.save!
            allow(root_account).to receive(:environment_specific_domain).and_return("localhost")
            tool = course.context_external_tools.create!(domain: "example.com", consumer_key: "12345", shared_secret: "secret", privacy_level: "anonymous", name: "tool")
            expander = VariableExpander.new(root_account, course, controller, current_user: user, tool:)
            expander.instance_variable_set(:@controller, nil)
            expander.instance_variable_set(:@request, nil)
            expect(expand!("$Canvas.externalTool.url", expander:)).to eq "http://localhost/api/v1/courses/#{course.id}/external_tools/#{tool.id}"
          end

          it "has substitution for $Canvas.xapi.url even if no controller" do
            course.save!
            allow(Lti::AnalyticsService).to receive(:create_token).and_return("--token--")
            variable_expander.instance_variable_set(:@controller, nil)
            variable_expander.instance_variable_set(:@request, nil)
            variable_expander.instance_variable_set(:@current_user, user)
            allow(root_account).to receive(:environment_specific_domain).and_return("localhost")
            expect(expand!("$Canvas.xapi.url")).to eq "http://localhost/api/lti/v1/xapi/--token--"
          end

          it "has substitution for $Caliper.url even if no controller" do
            course.save!
            allow(Lti::AnalyticsService).to receive(:create_token).and_return("--token--")
            variable_expander.instance_variable_set(:@controller, nil)
            variable_expander.instance_variable_set(:@request, nil)
            variable_expander.instance_variable_set(:@current_user, user)
            allow(root_account).to receive(:environment_specific_domain).and_return("localhost")
            expect(expand!("$Caliper.url")).to eq "http://localhost/api/lti/v1/caliper/--token--"
          end
        end
      end

      it "has substitution for $Canvas.membership.permissions" do
        course_with_student(active_all: true)
        subst = "$Canvas.membership.permissions<moderate_forum,read_forum,create_forum>"
        expander = VariableExpander.new(@course.root_account, @course, controller, current_user: @student, tool:)

        expect(expand!(subst, expander:)).to eq "read_forum,create_forum"
      end

      it "has substitution for $Canvas.membership.permissions (checking Group#grants_right?) when context is a group-based course" do
        course_with_student(active_all: true)
        subst = "$Canvas.membership.permissions<read>"
        expander = VariableExpander.new(@course.root_account, Group.new(course: @course), controller, current_user: @teacher, tool:)

        expect(expand!(subst, expander:)).to eq "read"
      end

      it "substitutes $Canvas.membership.permissions inside substring" do
        course_with_student(active_all: true)
        subst = "string stuff: ${Canvas.membership.permissions<moderate_forum,create_forum,read_forum>}"
        expander = VariableExpander.new(@course.root_account, @course, controller, current_user: @student, tool:)

        expect(expand!(subst, expander:)).to eq "string stuff: create_forum,read_forum"
      end

      context "com.instructure.Tag.id" do
        let(:subst_name) { "$com.instructure.Tag.id" }

        it "has the expansion registered" do
          expect(VariableExpander.expansions).to have_key(:"$com.instructure.Tag.id")
        end

        it "returns the differentiation tag id when student has a tag assigned" do
          # Ensure models are persisted before reloading
          user.save! if user.new_record?
          differentiation_tag.save! if differentiation_tag.new_record?

          # Reload models to ensure database state is visible
          user.reload
          differentiation_tag.reload

          # Create assignment override for the differentiation tag
          external_tool_assignment.assignment_overrides.create!(
            set: differentiation_tag,
            title: differentiation_tag.name
          )

          # Create variable expander with assignment context
          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment: external_tool_assignment
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          expect(expanded).to eq differentiation_tag.id
        end

        it "returns placeholder when student has no tag assigned" do
          # Create course, user, and assignment without tag assignment
          course.save!
          user.save!

          assignment = course.assignments.create!(
            name: "Assignment without tag",
            submission_types: "external_tool",
            points_possible: 100
          )

          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          expect(expanded).to eq "$com.instructure.Tag.id"
        end

        it "returns placeholder when there is no assignment" do
          variable_expander_without_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:
          )

          expanded = expand!(subst_name, expander: variable_expander_without_assignment)
          expect(expanded).to eq "$com.instructure.Tag.id"
        end

        it "returns the correct tag when student has multiple tags assigned)" do
          course.save!
          user.save!

          # Enable differentiation tags feature flag and setting on course account
          course.account.enable_feature!(:assign_to_differentiation_tags)
          course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          course.account.save!

          # Create two differentiation tag categories and tags (use group_categories, not differentiation_tag_categories)
          tag_category_a = course.group_categories.create!(name: "Category A", non_collaborative: true)
          tag_category_b = course.group_categories.create!(name: "Category B", non_collaborative: true)

          tag_a = tag_category_a.groups.create!(
            name: "Tag A",
            context: course,
            non_collaborative: true
          )
          tag_b = tag_category_b.groups.create!(
            name: "Tag B",
            context: course,
            non_collaborative: true
          )

          # Add user to both tags
          tag_a.add_user(user)
          tag_b.add_user(user)

          # Create assignment assigned ONLY to Tag B
          assignment = course.assignments.create!(
            name: "Assignment for Tag B",
            submission_types: "external_tool",
            points_possible: 100
          )

          # Create assignment override for Tag B only
          assignment.assignment_overrides.create!(
            set: tag_b,
            title: tag_b.name
          )

          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          # Should return Tag B's ID (not Tag A's ID) because the assignment is assigned to Tag B
          expect(expanded).to eq tag_b.id
        end

        it "returns placeholder when student has multiple tags but none are assigned to the assignment" do
          course.save!
          user.save!

          # Enable differentiation tags feature flag and setting
          course.account.enable_feature!(:assign_to_differentiation_tags)
          course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          course.account.save!

          # Create two differentiation tag categories and tags (use group_categories, not differentiation_tag_categories)
          tag_category_a = course.group_categories.create!(name: "Category A", non_collaborative: true)
          tag_category_b = course.group_categories.create!(name: "Category B", non_collaborative: true)

          tag_a = tag_category_a.groups.create!(
            name: "Tag A",
            context: course,
            non_collaborative: true
          )
          tag_b = tag_category_b.groups.create!(
            name: "Tag B",
            context: course,
            non_collaborative: true
          )

          # Add user to both tags
          tag_a.add_user(user)
          tag_b.add_user(user)

          # Create assignment but don't assign it to any specific tag (no overrides)
          assignment = course.assignments.create!(
            name: "Assignment for everyone",
            submission_types: "external_tool",
            points_possible: 100
          )

          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          # Should return placeholder since no tag is specifically assigned to this assignment
          expect(expanded).to eq "$com.instructure.Tag.id"
        end
      end

      context "com.instructure.Tag.name" do
        let(:subst_name) { "$com.instructure.Tag.name" }

        it "has the expansion registered" do
          expect(VariableExpander.expansions).to have_key(:"$com.instructure.Tag.name")
        end

        it "returns the differentiation tag name when student has a tag assigned" do
          # Ensure models are persisted before reloading
          user.save! if user.new_record?
          differentiation_tag.save! if differentiation_tag.new_record?

          # Reload models to ensure database state is visible
          user.reload
          differentiation_tag.reload

          # Create assignment override for the differentiation tag
          external_tool_assignment.assignment_overrides.create!(
            set: differentiation_tag,
            title: differentiation_tag.name
          )

          # Create variable expander with assignment context
          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment: external_tool_assignment
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          expect(expanded).to eq differentiation_tag.name
        end

        it "returns placeholder when student has no tag assigned" do
          # Create course, user, and assignment without tag assignment
          course.save!
          user.save!

          assignment = course.assignments.create!(
            name: "Assignment without tag",
            submission_types: "external_tool",
            points_possible: 100
          )

          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          expect(expanded).to eq "$com.instructure.Tag.name"
        end

        it "returns placeholder when there is no assignment" do
          variable_expander_without_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:
          )

          expanded = expand!(subst_name, expander: variable_expander_without_assignment)
          expect(expanded).to eq "$com.instructure.Tag.name"
        end

        it "returns the correct tag name when student has multiple tags assigned (bug fix scenario)" do
          course.save!
          user.save!

          # Enable differentiation tags feature flag and setting
          course.account.enable_feature!(:assign_to_differentiation_tags)
          course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          course.account.save!

          # Create two differentiation tag categories and tags (use group_categories, not differentiation_tag_categories)
          tag_category_a = course.group_categories.create!(name: "Category A", non_collaborative: true)
          tag_category_b = course.group_categories.create!(name: "Category B", non_collaborative: true)

          tag_a = tag_category_a.groups.create!(
            name: "Tag A",
            context: course,
            non_collaborative: true
          )
          tag_b = tag_category_b.groups.create!(
            name: "Tag B",
            context: course,
            non_collaborative: true
          )

          # Add user to both tags
          tag_a.add_user(user)
          tag_b.add_user(user)

          # Create assignment assigned ONLY to Tag B
          assignment = course.assignments.create!(
            name: "Assignment for Tag B",
            submission_types: "external_tool",
            points_possible: 100
          )

          # Create assignment override for Tag B only
          assignment.assignment_overrides.create!(
            set: tag_b,
            title: tag_b.name
          )

          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          # Should return Tag B's name (not Tag A's name) because the assignment is assigned to Tag B
          expect(expanded).to eq "Tag B"
        end

        it "returns placeholder when student has multiple tags but none are assigned to the assignment" do
          course.save!
          user.save!

          # Enable differentiation tags feature flag and setting
          course.account.enable_feature!(:assign_to_differentiation_tags)
          course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          course.account.save!

          # Create two differentiation tag categories and tags (use group_categories, not differentiation_tag_categories)
          tag_category_a = course.group_categories.create!(name: "Category A", non_collaborative: true)
          tag_category_b = course.group_categories.create!(name: "Category B", non_collaborative: true)

          tag_a = tag_category_a.groups.create!(
            name: "Tag A",
            context: course,
            non_collaborative: true
          )
          tag_b = tag_category_b.groups.create!(
            name: "Tag B",
            context: course,
            non_collaborative: true
          )

          # Add user to both tags
          tag_a.add_user(user)
          tag_b.add_user(user)

          # Create assignment but don't assign it to any specific tag (no overrides)
          assignment = course.assignments.create!(
            name: "Assignment for everyone",
            submission_types: "external_tool",
            points_possible: 100
          )

          variable_expander_with_assignment = VariableExpander.new(
            root_account,
            course,
            controller,
            current_user: user,
            tool:,
            assignment:
          )

          expanded = expand!(subst_name, expander: variable_expander_with_assignment)
          # Should return placeholder since no tag is specifically assigned to this assignment
          expect(expanded).to eq "$com.instructure.Tag.name"
        end
      end
    end
  end
end

# rubocop:enable RSpec/EmptyExampleGroup
