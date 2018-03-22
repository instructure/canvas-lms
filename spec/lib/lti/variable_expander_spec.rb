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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_dependency "lti/variable_expander"
module Lti
  describe VariableExpander do
    let(:root_account) { Account.new(lti_guid: 'test-lti-guid') }
    let(:account) { Account.new(root_account: root_account, name:'Test Account') }
    let(:course) { Course.new(account: account, course_code: 'CS 124', sis_source_id: '1234') }
    let(:group_category) { course.group_categories.new(name: 'Category') }
    let(:group) { course.groups.new(name: 'Group', group_category: group_category) }
    let(:user) { User.new }
    let(:assignment) { Assignment.new }
    let(:collaboration) do
      ExternalToolCollaboration.new(
        title: "my collab",
        user: user,
        url: 'http://www.example.com'
      )
    end
    let(:substitution_helper) { double.as_null_object }
    let(:right_now) { DateTime.now }
    let(:tool) do
      m = double('tool')
      allow(m).to receive(:id).and_return(1)
      allow(m).to receive(:context).and_return(root_account)
      allow(m).to receive(:extension_setting).with(nil, :prefer_sis_email).and_return(nil)
      allow(m).to receive(:extension_setting).with(:tool_configuration, :prefer_sis_email).and_return(nil)
      allow(m).to receive(:include_email?).and_return(true)
      allow(m).to receive(:include_name?).and_return(true)
      allow(m).to receive(:public?).and_return(true)
      shard_mock = double('shard')
      allow(shard_mock).to receive(:settings).and_return({encription_key: 'abc'})
      allow(m).to receive(:shard).and_return(shard_mock)
      allow(m).to receive(:opaque_identifier_for).and_return("6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f")
      m
    end
    let(:controller) do
      request_mock = double('request')
      allow(request_mock).to receive(:url).and_return('https://localhost')
      allow(request_mock).to receive(:host).and_return('/my/url')
      allow(request_mock).to receive(:scheme).and_return('https')
      m = double('controller')
      allow(m).to receive(:css_url_for).with(:common).and_return('/path/to/common.scss')
      allow(m).to receive(:request).and_return(request_mock)
      allow(m).to receive(:logged_in_user).and_return(user)
      allow(m).to receive(:named_context_url).and_return('url')
      allow(m).to receive(:active_brand_config_url).with('json').and_return('http://example.com/brand_config.json')
      allow(m).to receive(:active_brand_config_url).with('js').and_return('http://example.com/brand_config.js')
      allow(m).to receive(:active_brand_config).and_return(double(to_json: '{"ic-brand-primary-darkened-5":"#0087D7"}'))
      allow(m).to receive(:polymorphic_url).and_return('url')
      view_context_mock = double('view_context')
      allow(view_context_mock).to receive(:stylesheet_path)
        .and_return(URI.parse(request_mock.url).merge(m.css_url_for(:common)).to_s)
      allow(m).to receive(:view_context).and_return(view_context_mock)
      m
    end
    let(:attachment) { attachment_model }
    let(:submission) { submission_model }
    let(:resource_link_id) { SecureRandom.uuid }
    let(:originality_report) do
      OriginalityReport.create!(attachment: attachment,
                                submission: submission,
                                link_id: resource_link_id)
    end
    let(:editor_contents) { '<p>This is the contents of the editor</p>' }
    let(:editor_selection) { 'is the contents' }
    let(:variable_expander) do
      VariableExpander.new(
        root_account,
        account,
        controller,
        current_user: user,
        tool: tool,
        originality_report: originality_report,
        editor_contents: editor_contents,
        editor_selection: editor_selection
      )
    end

    it 'clears the lti_helper instance variable when you set the current_user' do
      expect(variable_expander.lti_helper).not_to be nil
      variable_expander.current_user = nil
      expect(variable_expander.instance_variable_get(:"@current_user")).to be nil
    end

    it 'registers expansions' do
      before_count = VariableExpander.expansions.count
      VariableExpander.register_expansion('abc123', ['a'], -> { @context })
      expansions = VariableExpander.expansions
      expect(expansions.count - before_count).to eq 1
      test_expan = expansions[:"$abc123"]
      expect(test_expan.name).to eq 'abc123'
      expect(test_expan.permission_groups).to eq ['a']
    end

    it 'expands registered variables' do
      VariableExpander.register_expansion('test_expan', ['a'], -> { @context })
      expanded = variable_expander.expand_variables!({some_name: '$test_expan'})
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq account
    end

    it 'expands substring variables' do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion('test_expan', ['a'], -> { @context.id })
      expanded = variable_expander.expand_variables!({some_name: 'my variable is buried in here ${test_expan} can you find it?'})
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq "my variable is buried in here 42 can you find it?"
    end

    it 'handles multiple substring variables' do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion('test_expan', ['a'], -> { @context.id })
      VariableExpander.register_expansion('variable1', ['a'], -> { 1 })
      VariableExpander.register_expansion('other_variable', ['a'], -> { 2 })
      expanded = variable_expander.expand_variables!(
        {some_name: 'my variables ${variable1} is buried ${other_variable} in here ${test_expan} can you find them?'}
      )
      expect(expanded[:some_name]).to eq "my variables 1 is buried 2 in here 42 can you find them?"
    end

    it 'does not expand a substring variable if it is not valid' do
      allow(account).to receive(:id).and_return(42)
      VariableExpander.register_expansion('test_expan', ['a'], -> { @context.id })
      expanded = variable_expander.expand_variables!({some_name: 'my variable is buried in here ${tests_expan} can you find it?'})
      expect(expanded.count).to eq 1
      expect(expanded[:some_name]).to eq "my variable is buried in here ${tests_expan} can you find it?"
    end

    describe '#self.expansion_keys' do
      let(:expected_keys) do
        VariableExpander.expansions.keys.map { |c| c.to_s[1..-1] }
      end

      it 'includes all expansion keys' do
        expect(VariableExpander.expansion_keys).to eq expected_keys
      end
    end

    describe '#self.default_name_expansions' do
      let(:expected_keys) do
        VariableExpander.expansions.values.select { |v| v.default_name.present? }.map(&:name)
      end

      it 'includes all expansion keys that have default names' do
        expect(VariableExpander.default_name_expansions).to eq expected_keys
      end
    end

    describe '#enabled_capability_params' do
      let(:enabled_capability) {
        %w(TestCapability.Foo
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
           Context.id)
      }

      it 'does not use expansions that do not have default names' do
        VariableExpander.register_expansion('TestCapability.Foo', ['a'], -> {'test'})
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).not_to include 'TestCapability.Foo'
      end

      it 'does use expansion that have default names' do
        VariableExpander.register_expansion('TestCapability.Foo', ['a'], -> { 'test' }, default_name: 'test_capability_foo')
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.values).to include('test')
      end

      it 'does use the default name as the key' do
        VariableExpander.register_expansion('TestCapability.Foo', ['a'], -> { 'test' }, default_name: 'test_capability_foo')
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded['test_capability_foo']).to eq 'test'
      end

      it 'includes ToolConsumerInstance.guid when in enabled capability' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded['tool_consumer_instance_guid']).to eq 'test-lti-guid'
      end

      it 'includes CourseSection.sourcedId when in enabled capability' do
        variable_expander = VariableExpander.new(root_account, course, controller, current_user: user, tool: tool)
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'lis_course_section_sourcedid'
      end

      it 'includes Membership.role when in enabled capability' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'roles'
      end

      it 'includes Person.email.primary when in enabled capability' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'lis_person_contact_email_primary'
      end

      it 'includes Person.sourcedId when in enabled capability' do
        allow(SisPseudonym).to receive(:for).with(user, anything, anything).and_return(double(sis_user_id: 12))
        expanded = variable_expander.enabled_capability_params(['Person.sourcedId'])
        expect(expanded.keys).to include 'lis_person_sourcedid'
      end

      it 'includes User.id when in enabled capability' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'user_id'
      end

      it 'includes User.image when in enabled capability' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'user_image'
      end

      it 'includes Message.documentTarget' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'launch_presentation_document_target'
      end

      it 'includes Message.locale' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'launch_presentation_locale'
      end

      it 'includes Context.id' do
        expanded = variable_expander.enabled_capability_params(enabled_capability)
        expect(expanded.keys).to include 'context_id'
      end

      context 'privacy level include_name' do
        it 'includes Person.name.given when in enabled capability' do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include 'lis_person_name_given'
        end

        it 'includes Person.name.family when in enabled capability' do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include 'lis_person_name_family'
        end

        it 'includes Person.name.full when in enabled capability' do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include 'lis_person_name_full'
        end

        it 'includes Person.name.display when in enabled capability' do
          expanded = variable_expander.enabled_capability_params(enabled_capability)
          expect(expanded.keys).to include 'person_name_display'
        end
      end
    end

    context 'lti1' do
      it 'handles expansion' do
        VariableExpander.register_expansion('test_expan', ['a'], -> { @context })
        expanded = variable_expander.expand_variables!({'some_name' => '$test_expan'})
        expect(expanded.count).to eq 1
        expect(expanded['some_name']).to eq account
      end

      it 'expands substring variables' do
        allow(account).to receive(:id).and_return(42)
        VariableExpander.register_expansion('test_expan', ['a'], -> { @context.id })
        expanded = variable_expander.expand_variables!({'some_name' => 'my variable is buried in here ${test_expan} can you find it?'})
        expect(expanded.count).to eq 1
        expect(expanded['some_name']).to eq "my variable is buried in here 42 can you find it?"
      end
    end

    describe "#variable expansions" do
      it 'has a substitution for com.instructure.Assignment.lti.id' do
        exp_hash = {test: '$com.instructure.Assignment.lti.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq originality_report.submission.assignment.lti_context_id
      end

      it 'has a substitution for com.instructure.Assignment.lti.id when there is no tool setting' do
        assignment.update_attributes(context: course)
        variable_expander = VariableExpander.new(root_account,
                                                 account,
                                                 controller,
                                                 current_user: user,
                                                 tool: tool,
                                                 assignment: assignment)
        assignment.update_attributes(context: course)
        exp_hash = {test: '$com.instructure.Assignment.lti.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq assignment.lti_context_id
      end

      it 'has a substitution for com.instructure.PostMessageToken' do
        uuid_pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        variable_expander = VariableExpander.new(root_account,
                                                 account,
                                                 controller,
                                                 current_user: user,
                                                 tool: tool,
                                                 launch: Lti::Launch.new)
        exp_hash = {test: '$com.instructure.PostMessageToken'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test] =~ uuid_pattern).to eq 0
      end

      it 'has a substitution for com.instructure.PostMessageToken when token is provided' do
        pm_token_override = SecureRandom.uuid
        variable_expander = VariableExpander.new(root_account,
                                                 account,
                                                 controller,
                                                 current_user: user,
                                                 tool: tool,
                                                 post_message_token: pm_token_override)
        exp_hash = {test: '$com.instructure.PostMessageToken'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq pm_token_override
      end

      it 'has a substitution for com.instructure.Assignment.lti.id when secure params are present' do
        lti_assignment_id = SecureRandom.uuid
        secure_params = Canvas::Security.create_jwt(lti_assignment_id: lti_assignment_id)
        variable_expander = VariableExpander.new(root_account,
                                                 account,
                                                 controller,
                                                 current_user: user,
                                                 tool: tool,
                                                 secure_params: secure_params)
        exp_hash = {test: '$com.instructure.Assignment.lti.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq lti_assignment_id
      end

      it 'has substitution for com.instructure.Editor.contents' do
        exp_hash = {test: '$com.instructure.Editor.contents'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq editor_contents
      end

      it 'has substitution for com.instructure.Editor.selection' do
        exp_hash = {test: '$com.instructure.Editor.selection'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq editor_selection
      end

      it 'has a substitution for Context.title' do
        exp_hash = {test: '$Context.title'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq variable_expander.context.name
      end

      it 'has substitution for vnd.Canvas.OriginalityReport.url' do
        exp_hash = {test: '$vnd.Canvas.OriginalityReport.url'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'api/lti/assignments/{assignment_id}/submissions/{submission_id}/originality_report'
      end

      it 'has substitution for com.instructure.OriginalityReport.id' do
        exp_hash = {test: '$com.instructure.OriginalityReport.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq originality_report.id
      end

      it 'has substitution for com.instructure.Submission.id' do
        exp_hash = {test: '$com.instructure.Submission.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq originality_report.submission.id
      end

      it 'has substitution for com.instructure.File.id' do
        exp_hash = {test: '$com.instructure.File.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq originality_report.attachment.id
      end

      it 'has substitution for vnd.Canvas.submission.url' do
        exp_hash = {test: '$vnd.Canvas.submission.url'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'api/lti/assignments/{assignment_id}/submissions/{submission_id}'
      end

      it 'has substitution for vnd.Canvas.submission.history.url' do
        exp_hash = {test: '$vnd.Canvas.submission.history.url'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'api/lti/assignments/{assignment_id}/submissions/{submission_id}/history'
      end

      it 'has substitution for Message.documentTarget' do
        exp_hash = {test: '$Message.documentTarget'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME
      end

      it 'has substitution for Message.locale' do
        exp_hash = {test: '$Message.locale'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq I18n.locale
      end

      it 'has substitution for $Canvas.api.domain' do
        exp_hash = {test: '$Canvas.api.domain'}
        allow(HostUrl).to receive(:context_host).and_return('localhost')
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'localhost'
      end

      it 'does not expand $Canvas.api.domain when the request is unset' do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        exp_hash = {test: '$Canvas.api.domain'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '$Canvas.api.domain'
      end

      it 'has substitution for $com.instructure.brandConfigJSON.url' do
        exp_hash = {test: '$com.instructure.brandConfigJSON.url'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'http://example.com/brand_config.json'
      end

      it 'does not expand $com.instructure.brandConfigJSON.url when the controller is unset' do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        exp_hash = {test: '$com.instructure.brandConfigJSON.url'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '$com.instructure.brandConfigJSON.url'
      end

      it 'has substitution for $com.instructure.brandConfigJSON' do
        exp_hash = {test: '$com.instructure.brandConfigJSON'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '{"ic-brand-primary-darkened-5":"#0087D7"}'
      end

      it 'does not expand $com.instructure.brandConfigJSON when the controller is unset' do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        exp_hash = {test: '$com.instructure.brandConfigJSON'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '$com.instructure.brandConfigJSON'
      end

      it 'has substitution for $com.instructure.brandConfigJS.url' do
        exp_hash = {test: '$com.instructure.brandConfigJS.url'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'http://example.com/brand_config.js'
      end

      it 'does not expand $com.instructure.brandConfigJS.url when the controller is unset' do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        exp_hash = {test: '$com.instructure.brandConfigJS.url'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '$com.instructure.brandConfigJS.url'
      end

      it 'has substitution for $Canvas.css.common' do
        exp_hash = {test: '$Canvas.css.common'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'https://localhost/path/to/common.scss'
      end

      it 'does not expand $Canvas.css.common when the controller is unset' do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        exp_hash = {test: '$Canvas.css.common'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '$Canvas.css.common'
      end

      it 'has substitution for $Canvas.api.baseUrl' do
        exp_hash = {test: '$Canvas.api.baseUrl'}
        allow(HostUrl).to receive(:context_host).and_return('localhost')
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'https://localhost'
      end

      it 'does not expand $Canvas.api.baseUrl when the request is unset' do
        variable_expander.instance_variable_set(:@controller, nil)
        variable_expander.instance_variable_set(:@request, nil)
        exp_hash = {test: '$Canvas.api.baseUrl'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '$Canvas.api.baseUrl'
      end

      it 'has substitution for $Canvas.account.id' do
        allow(account).to receive(:id).and_return(12345)
        exp_hash = {test: '$Canvas.account.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 12345
      end

      it 'has substitution for $Canvas.account.name' do
        account.name = 'Some Account'
        exp_hash = {test: '$Canvas.account.name'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'Some Account'
      end

      it 'has substitution for $Canvas.account.sisSourceId' do
        account.sis_source_id = 'abc23'
        exp_hash = {test: '$Canvas.account.sisSourceId'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'abc23'
      end

      it 'has substitution for $Canvas.rootAccount.id' do
        allow(root_account).to receive(:id).and_return(54321)
        exp_hash = {test: '$Canvas.rootAccount.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 54321
      end

      it 'has substitution for $Canvas.rootAccount.sisSourceId' do
        root_account.sis_source_id = 'cd45'
        exp_hash = {test: '$Canvas.rootAccount.sisSourceId'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'cd45'
      end

      it 'has substitution for $Canvas.root_account.id' do
        allow(root_account).to receive(:id).and_return(54321)
        exp_hash = {test: '$Canvas.root_account.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 54321
      end

      it 'has substitution for $Canvas.root_account.uuid' do
        allow(root_account).to receive(:uuid).and_return('123-123-123-123')
        exp_hash = {test: '$vnd.Canvas.root_account.uuid'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq '123-123-123-123'
      end

      it 'has substitution for $Canvas.root_account.sisSourceId' do
        root_account.sis_source_id = 'cd45'
        exp_hash = {test: '$Canvas.root_account.sisSourceId'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 'cd45'
      end

      it 'has substitution for $Canvas.root_account.global_id' do
        allow(root_account).to receive(:global_id).and_return(10054321)
        exp_hash = {test: '$Canvas.root_account.global_id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq 10054321
      end

      it 'has substitution for $Canvas.shard.id' do
        exp_hash = {test: '$Canvas.shard.id'}
        variable_expander.expand_variables!(exp_hash)
        expect(exp_hash[:test]).to eq Shard.current.id
      end

      context 'context is a group' do
        let(:variable_expander) { VariableExpander.new(root_account, group, controller, current_user: user) }

        it 'has substitution for $ToolProxyBinding.memberships.url when context is a group' do
          exp_hash = { test: '$ToolProxyBinding.memberships.url' }
          allow(group).to receive(:id).and_return('1')
          allow(controller).to receive(:polymorphic_url).and_return("/api/lti/groups/#{group.id}/membership_service")
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq "/api/lti/groups/1/membership_service"
        end

        it 'does not substitute $ToolProxyBinding.memberships.url when the controller is unset' do

          variable_expander.instance_variable_set(:@controller, nil)
          variable_expander.instance_variable_set(:@request, nil)
          exp_hash = { test: '$ToolProxyBinding.memberships.url' }
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '$ToolProxyBinding.memberships.url'
        end
      end

      context 'when launching from a group assignment' do
        let(:group) { group_category.groups.create!(name: 'test', context: assignment_course) }
        let(:group_category) { GroupCategory.create!(name: 'test', context: assignment_course) }
        let(:new_assignment) { assignment_model(course: assignment_course) }
        let(:assignment_course) do
          c = course_model(account: account)
          c.save!
          c
        end
        let(:variable_expander) do
          VariableExpander.new(
            root_account,
            account,
            controller,
            current_user: user,
            tool: tool,
            assignment: new_assignment
          )
        end

        before do
          group.update_attributes!(users: [user])
          new_assignment.update_attributes!(group_category: group_category)
        end

        shared_examples 'a safe expansion when assignment is blank' do
          let(:expansion) { raise 'override in spec' }
          let(:variable_expander) do
            VariableExpander.new(
              root_account,
              account,
              controller,
              current_user: user,
              tool: tool
            )
          end

          it 'returns the variable if no Assignment is present' do
            exp_hash = {test: expansion}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq expansion
          end
        end

        shared_examples 'a safe expansion when user is blank' do
          let(:expansion) { raise 'override in spec' }
          let(:variable_expander) do
            VariableExpander.new(
              root_account,
              account,
              controller,
              current_user: user,
              tool: tool
            )
          end

          it 'returns the variable if no User is present' do
            exp_hash = {test: expansion}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq expansion
          end
        end

        describe 'com.instructure.Group.id' do
          let(:expansion_string) { '$com.instructure.Group.id' }

          it_behaves_like 'a safe expansion when assignment is blank' do
            let(:expansion) { expansion_string }
          end

          it_behaves_like 'a safe expansion when user is blank' do
            let(:expansion) { expansion_string }
          end

          it 'has a substitution for com.instructure.Group.id' do
            exp_hash = {test: expansion_string}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq group.id
          end
        end

        describe 'com.instructure.Group.name' do
          let(:expansion_string) { '$com.instructure.Group.name' }

          it_behaves_like 'a safe expansion when assignment is blank' do
            let(:expansion) { expansion_string }
          end

          it_behaves_like 'a safe expansion when user is blank' do
            let(:expansion) { expansion_string }
          end

          it 'has a substitution for com.instructure.Group.name' do
            exp_hash = {test: expansion_string}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq group.name
          end
        end
      end

      context 'context is a course' do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, current_user: user) }

        it 'has substitution for $ToolProxyBinding.memberships.url when context is a course' do
          exp_hash = { test: '$ToolProxyBinding.memberships.url' }
          allow(course).to receive(:id).and_return('1')
          allow(controller).to receive(:polymorphic_url).and_return("/api/lti/courses/#{course.id}/membership_service")
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq "/api/lti/courses/1/membership_service"
        end

        it 'has substitution for $Canvas.course.id' do
          allow(course).to receive(:id).and_return(123)
          exp_hash = {test: '$Canvas.course.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 123
        end

        it 'has substitution for $Context.sourcedId' do
          allow(course).to receive(:sis_source_id).and_return('123')
          exp_hash = {test: '$Context.sourcedId'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '123'
        end

        it 'has substitution for $vnd.instructure.Course.uuid' do
          allow(course).to receive(:uuid).and_return('Ioe3sJPt0KZp9Pw6xAvcHuLCl0z4TvPKP0iIOLbo')
          exp_hash = {test: '$vnd.instructure.Course.uuid'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Ioe3sJPt0KZp9Pw6xAvcHuLCl0z4TvPKP0iIOLbo'
        end

        it 'has substitution for $Canvas.course.name' do
          allow(course).to receive(:name).and_return('Course 101')
          exp_hash = {test: '$Canvas.course.name'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Course 101'
        end

        it 'has substitution for $Canvas.course.workflowState' do
          course.workflow_state = 'available'
          exp_hash = {test: '$Canvas.course.workflowState'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'available'
        end

        it 'has substitution for $CourseSection.sourcedId' do
          course.sis_source_id = 'course1'
          exp_hash = {test: '$CourseSection.sourcedId'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'course1'
        end

        it 'has substitution for $Canvas.course.sisSourceId' do
          course.sis_source_id = 'course1'
          exp_hash = {test: '$Canvas.course.sisSourceId'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'course1'
        end

        it 'has substitution for $Canvas.enrollment.enrollmentState' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:enrollment_state).and_return('active')
          exp_hash = {test: '$Canvas.enrollment.enrollmentState'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'active'
        end

        it 'has substitution for $Canvas.membership.roles' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:current_canvas_roles).and_return('teacher,student')
          exp_hash = {test: '$Canvas.membership.roles'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'teacher,student'
        end

        it 'has substitution for $Canvas.membership.concludedRoles' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:concluded_lis_roles).and_return('learner')
          exp_hash = {test: '$Canvas.membership.concludedRoles'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'learner'
        end

        it 'has substitution for $Canvas.course.previousContextIds' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:previous_lti_context_ids).and_return('abc,xyz')
          exp_hash = {test: '$Canvas.course.previousContextIds'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'abc,xyz'
        end

        it 'has substitution for $Canvas.course.previousContextIds.recursive' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:recursively_fetch_previous_lti_context_ids).and_return('abc,xyz')
          exp_hash = {test: '$Canvas.course.previousContextIds.recursive'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'abc,xyz'
        end

        it 'has substitution for $Canvas.course.previousCourseIds' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:previous_course_ids).and_return('1,2')
          exp_hash = {test: '$Canvas.course.previousCourseIds'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '1,2'
        end

        it 'has a substitution for com.instructure.contextLabel' do
          exp_hash = {test: '$com.instructure.contextLabel'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq course.course_code
        end

        context 'when the course has groups' do
          let(:course_with_groups) do
            course = variable_expander.context
            course.save!
            course
          end

          let!(:group_one) { course_with_groups.groups.create!(name: 'Group One') }
          let!(:group_two) { course_with_groups.groups.create!(name: 'Group Two') }

          describe '$com.instructure.Course.groupIds' do
            it 'has substitution' do
              exp_hash = {test: '$com.instructure.Course.groupIds'}
              variable_expander.expand_variables!(exp_hash)
              expected_ids = [group_one, group_two].map { |g| g.id.to_s }
              expect(exp_hash[:test].split(',')).to match_array expected_ids
            end

            it 'does not include groups outside of the course' do
              second_course = variable_expander.context.dup
              second_course.update!(sis_source_id: SecureRandom.uuid)
              second_course.groups.create!(name: 'Group Three')
              exp_hash = {test: '$com.instructure.Course.groupIds'}
              variable_expander.expand_variables!(exp_hash)
              expected_ids = [group_two, group_one].map { |g| g.id.to_s }
              expect(exp_hash[:test].split(',')).to match_array expected_ids
            end

            it 'only includes active group ids' do
              group_one.update!(workflow_state: 'deleted')
              exp_hash = {test: '$com.instructure.Course.groupIds'}
              variable_expander.expand_variables!(exp_hash)
              expect(exp_hash[:test]).to eq group_two.id.to_s
            end

            it 'guards against the course being nil' do
              no_course_expander = VariableExpander.new(root_account, nil, controller, current_user: user)
              exp_hash = {test: '$com.instructure.Course.groupIds'}
              expect do
                no_course_expander.expand_variables!(exp_hash)
              end.not_to raise_exception
            end
          end
        end
      end

      context 'context is a course and there is a user' do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, current_user: user, tool: tool) }

        it 'has substitution for $Canvas.xapi.url' do
          allow(Lti::XapiService).to receive(:create_token).and_return('abcd')
          allow(controller).to receive(:lti_xapi_url).and_return('/xapi/abcd')
          exp_hash = {test: '$Canvas.xapi.url'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '/xapi/abcd'
        end

        it 'has substitution for $Canvas.course.sectionIds' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:section_ids).and_return('5,6')
          exp_hash = {test: '$Canvas.course.sectionIds'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '5,6'
        end

        it 'has substitution for $Canvas.course.sectionSisSourceIds' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:section_sis_ids).and_return('5a,6b')
          exp_hash = {test: '$Canvas.course.sectionSisSourceIds'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '5a,6b'
        end

        it 'has substitution for $Canvas.course.startAt' do
          course.start_at = '2015-04-21 17:01:36'
          course.save!
          exp_hash = {test: '$Canvas.course.startAt'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '2015-04-21 17:01:36'
        end

        it 'has a functioning guard for $Canvas.term.startAt when term.start_at is not set' do
          term = course.enrollment_term
          exp_hash = {test: '$Canvas.term.startAt'}
          variable_expander.expand_variables!(exp_hash)

          unless term && term.start_at
            expect(exp_hash[:test]).to eq '$Canvas.term.startAt'
          end
        end

        it 'has substitution for $Canvas.term.startAt when term.start_at is set' do
          course.enrollment_term ||= EnrollmentTerm.new
          term = course.enrollment_term

          term.start_at = '2015-05-21 17:01:36'
          term.save
          exp_hash = {test: '$Canvas.term.startAt'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '2015-05-21 17:01:36'
        end

        it 'has a functioning guard for $Canvas.term.name when term.name is not set' do
          term = course.enrollment_term
          exp_hash = {test: '$Canvas.term.name'}
          variable_expander.expand_variables!(exp_hash)

          unless term && term.name
            expect(exp_hash[:test]).to eq '$Canvas.term.name'
          end
        end

        it 'has substitution for $Canvas.term.name when term.name is set' do
          course.enrollment_term ||= EnrollmentTerm.new
          term = course.enrollment_term

          term.name = 'W1 2017'
          term.save
          exp_hash = {test: '$Canvas.term.name'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'W1 2017'
        end

        it 'has substitution for $Canvas.externalTool.url' do
          course.save!
          tool = course.context_external_tools.create!(:domain => 'example.com', :consumer_key => '12345', :shared_secret => 'secret', :privacy_level => 'anonymous', :name => 'tool')
          expect(controller).to receive(:named_context_url).with(course, :api_v1_context_external_tools_update_url,
                                                      tool.id, include_host:true).and_return("url")
          expander = VariableExpander.new(root_account, course, controller, current_user: user, tool: tool)
          exp_hash = {test: '$Canvas.externalTool.url'}
          expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq "url"
        end

        it 'does not substitute $Canvas.externalTool.url when the controller is unset' do

          variable_expander.instance_variable_set(:@controller, nil)
          variable_expander.instance_variable_set(:@request, nil)
          exp_hash = {test: '$Canvas.externalTool.url'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '$Canvas.externalTool.url'
        end

        it 'returns the opaque identifiers for the active groups the user is a part of' do
          course.save!
          user.save!

          g1 = course.groups.new
          g2 = course.groups.new

          user.groups << g1
          user.groups << g2

          g1.save!
          g2.save!

          exp_hash = { test: '$Canvas.group.contextIds' }
          variable_expander.expand_variables!(exp_hash)

          g1.reload
          g2.reload

          ids = exp_hash[:test].split(',')
          expect(ids.size).to eq 2
          expect(ids.include?(g1.lti_context_id)).to be true
          expect(ids.include?(g2.lti_context_id)).to be true
        end
      end

      context 'context is a course with an assignment' do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, collaboration: collaboration) }

        it 'has substitution for $Canvas.api.collaborationMembers.url' do
          allow(collaboration).to receive(:id).and_return(1)
          allow(controller).to receive(:api_v1_collaboration_members_url).and_return('https://www.example.com/api/v1/collaborations/1/members')
          exp_hash = {test: '$Canvas.api.collaborationMembers.url'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'https://www.example.com/api/v1/collaborations/1/members'
        end
      end

      context 'context is a course with an assignment' do
        let(:variable_expander) { VariableExpander.new(root_account, course, controller, current_user: user, assignment: assignment) }

        it 'has substitution for $Canvas.assignment.id' do
          allow(assignment).to receive(:id).and_return(2015)
          exp_hash = {test: '$Canvas.assignment.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 2015
        end

        it 'has substitution for $Canvas.assignment.title' do
          assignment.title = 'Buy as many ducks as you can'
          exp_hash = {test: '$Canvas.assignment.title'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Buy as many ducks as you can'
        end

        describe "$Canvas.assignment.pointsPossible" do
          it 'has substitution for $Canvas.assignment.pointsPossible' do
            allow(assignment).to receive(:points_possible).and_return(10.0)
            exp_hash = {test: '$Canvas.assignment.pointsPossible'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 10
          end

          it 'does not round if not whole' do
            allow(assignment).to receive(:points_possible).and_return(9.5)
            exp_hash = {test: '$Canvas.assignment.pointsPossible'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test].to_s).to eq "9.5"
          end

          it 'rounds if whole' do
            allow(assignment).to receive(:points_possible).and_return(9.0)
            exp_hash = {test: '$Canvas.assignment.pointsPossible'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test].to_s).to eq "9"
          end
        end

        it 'has substitution for $Canvas.assignment.unlockAt' do
          allow(assignment).to receive(:unlock_at).and_return(right_now.to_s)
          exp_hash = {test: '$Canvas.assignment.unlockAt'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq right_now.to_s
        end

        it 'has substitution for $Canvas.assignment.lockAt' do
          allow(assignment).to receive(:lock_at).and_return(right_now.to_s)
          exp_hash = {test: '$Canvas.assignment.lockAt'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq right_now.to_s
        end

        it 'has substitution for $Canvas.assignment.dueAt' do
          allow(assignment).to receive(:due_at).and_return(right_now.to_s)
          exp_hash = {test: '$Canvas.assignment.dueAt'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq right_now.to_s
        end

        it 'has substitution for $Canvas.assignment.published' do
          allow(assignment).to receive(:workflow_state).and_return('published')
          exp_hash = {test: '$Canvas.assignment.published'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq true
        end

        context 'iso8601' do
          it 'has substitution for $Canvas.assignment.unlockAt.iso8601' do
            allow(assignment).to receive(:unlock_at).and_return(right_now)
            exp_hash = {test: '$Canvas.assignment.unlockAt.iso8601'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq right_now.utc.iso8601.to_s
          end

          it 'has substitution for $Canvas.assignment.lockAt.iso8601' do
            allow(assignment).to receive(:lock_at).and_return(right_now)
            exp_hash = {test: '$Canvas.assignment.lockAt.iso8601'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq right_now.utc.iso8601.to_s
          end

          it 'has substitution for $Canvas.assignment.dueAt.iso8601' do
            allow(assignment).to receive(:due_at).and_return(right_now)
            exp_hash = {test: '$Canvas.assignment.dueAt.iso8601'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq right_now.utc.iso8601.to_s
          end

          it 'handles a nil unlock_at' do
            allow(assignment).to receive(:unlock_at).and_return(nil)
            exp_hash = {test: '$Canvas.assignment.unlockAt.iso8601'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq "$Canvas.assignment.unlockAt.iso8601"
          end

          it 'handles a nil lock_at' do
            allow(assignment).to receive(:lock_at).and_return(nil)
            exp_hash = {test: '$Canvas.assignment.lockAt.iso8601'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq "$Canvas.assignment.lockAt.iso8601"
          end

          it 'handles a nil due_at' do
            allow(assignment).to receive(:lock_at).and_return(nil)
            exp_hash = {test: '$Canvas.assignment.dueAt.iso8601'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq "$Canvas.assignment.dueAt.iso8601"
          end

        end


      end

      context 'user is not logged in' do
        let(:user) {}
        it 'has substitution for $vnd.Canvas.Person.email.sis when user is not logged in' do
          exp_hash = {test: '$vnd.Canvas.Person.email.sis'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '$vnd.Canvas.Person.email.sis'
        end
      end

      context 'user is logged in' do

        it 'has substitution for $Person.name.full' do
          user.name = 'Uncle Jake'
          exp_hash = {test: '$Person.name.full'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Uncle Jake'
        end

        it 'has substitution for $Person.name.display' do
          user.name = 'Uncle Jake'
          user.short_name = 'Unc J'
          exp_hash = {test: '$Person.name.display'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Unc J'
        end

        it 'has substitution for $Person.name.family' do
          user.name = 'Uncle Jake'
          exp_hash = {test: '$Person.name.family'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Jake'
        end

        it 'has substitution for $Person.name.given' do
          user.name = 'Uncle Jake'
          exp_hash = {test: '$Person.name.given'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Uncle'
        end

        it 'has substitution for $Person.email.primary' do
          allow(substitution_helper).to receive(:email).and_return('someone@somewhere')
          allow(SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          exp_hash = {test: '$Person.email.primary'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'someone@somewhere'
        end

        it 'has substitution for $vnd.Canvas.Person.email.sis when user is added via sis' do
          user.save
          user.email = 'someone@somewhere'
          cc1 = user.communication_channels.first
          pseudonym1 = cc1.user.pseudonyms.build(:unique_id => cc1.path, :account => Account.default)
          pseudonym1.sis_communication_channel_id=cc1.id
          pseudonym1.communication_channel_id=cc1.id
          pseudonym1.sis_user_id="some_sis_id"
          pseudonym1.save

          exp_hash = {test: '$vnd.Canvas.Person.email.sis'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'someone@somewhere'
        end

        it 'has substitution for $vnd.Canvas.Person.email.sis when user is NOT added via sis' do
          user.save
          user.email = 'someone@somewhere'

          exp_hash = {test: '$vnd.Canvas.Person.email.sis'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '$vnd.Canvas.Person.email.sis'
        end

        it 'has substitution for $Person.address.timezone' do
          exp_hash = {test: '$Person.address.timezone'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Etc/UTC'
        end

        it 'has substitution for $User.image' do
          allow(user).to receive(:avatar_url).and_return('/my/pic')
          exp_hash = {test: '$User.image'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '/my/pic'
        end

        it 'has substitution for $Canvas.user.id' do
          allow(user).to receive(:id).and_return(456)
          exp_hash = {test: '$Canvas.user.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 456
        end

        it 'has substitution for $vnd.instructure.User.uuid' do
          allow(user).to receive(:uuid).and_return('N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3')
          exp_hash = {test: '$vnd.instructure.User.uuid'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'N2ST123dQ9zyhurykTkBfXFa3Vn1RVyaw9Os6vu3'
        end

        it 'has substitution for $Canvas.user.isRootAccountAdmin' do
          allow(user).to receive(:roles).and_return(["root_admin"])
          exp_hash = {test: '$Canvas.user.isRootAccountAdmin'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq true
        end

        it 'has substitution for $Canvas.xuser.allRoles' do
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          allow(substitution_helper).to receive(:all_roles).and_return('Admin,User')
          exp_hash = {test: '$Canvas.xuser.allRoles'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Admin,User'
        end

        it 'has substitution for $Canvas.user.globalId' do
          allow(user).to receive(:global_id).and_return(456)
          exp_hash = {test: '$Canvas.user.globalId'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 456
        end

        it 'has substitution for $Membership.role' do
          allow(substitution_helper).to receive(:all_roles).with('lis2').and_return('Admin,User')
          allow(Lti::SubstitutionsHelper).to receive(:new).and_return(substitution_helper)
          exp_hash = {test: '$Membership.role'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'Admin,User'
        end

        it 'has substitution for $User.id' do
          allow(user).to receive(:id).and_return(456)
          exp_hash = {test: '$User.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 456
        end

        context '$Canvas.user.prefersHighContrast' do
          it 'substitutes as true' do
            allow(user).to receive(:prefers_high_contrast?).and_return(true)
            exp_hash = {test: '$Canvas.user.prefersHighContrast'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'true'
          end

          it 'substitutes as false' do
            allow(user).to receive(:prefers_high_contrast?).and_return(false)
            exp_hash = {test: '$Canvas.user.prefersHighContrast'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'false'
          end
        end

        context 'pseudonym' do
          let(:pseudonym) { Pseudonym.new }

          before :each do
            allow(SisPseudonym).to receive(:for).with(user, anything, anything).and_return(pseudonym)
          end

          it 'has substitution for $Canvas.user.sisSourceId' do
            pseudonym.sis_user_id = '1a2b3c'
            exp_hash = {test: '$Canvas.user.sisSourceId'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '1a2b3c'
          end

          it 'has substitution for $Person.sourcedId' do
            pseudonym.sis_user_id = '1a2b3c'
            exp_hash = {test: '$Person.sourcedId'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '1a2b3c'
          end


          it 'has substitution for $Canvas.user.loginId' do
            pseudonym.unique_id = 'username'
            exp_hash = {test: '$Canvas.user.loginId'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'username'
          end

          it 'has substitution for $User.username' do
            pseudonym.unique_id = 'username'
            exp_hash = {test: '$User.username'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'username'
          end
        end

        context 'attachment' do
          let (:attachment) do
            attachment = attachment_obj_with_context(course)
            attachment.media_object = media_object
            attachment.usage_rights = usage_rights
            attachment
          end
          let(:media_object) do
            mo = MediaObject.new
            mo.media_id = '1234'
            mo.media_type = 'video'
            mo.duration = 555
            mo.total_size = 444
            mo.title = 'some title'
            mo
          end
          let(:usage_rights) do
            ur = UsageRights.new
            ur.legal_copyright = 'legit'
            ur
          end
          let(:variable_expander) { VariableExpander.new(root_account, account, controller, current_user: user, tool: tool, attachment: attachment) }

          it 'has substitution for $Canvas.file.media.id when a media object is present' do
            exp_hash = {test: '$Canvas.file.media.id'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '1234'
          end

          it 'has substitution for $Canvas.file.media.id when a media entry is present' do
            exp_hash = {test: '$Canvas.file.media.id'}
            attachment.media_object = nil
            attachment.media_entry_id = '4567'
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq '4567'
          end

          it 'has substitution for $Canvas.file.media.type' do
            exp_hash = {test: '$Canvas.file.media.type'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'video'
          end

          it 'has substitution for $Canvas.file.media.duration' do
            exp_hash = {test: '$Canvas.file.media.duration'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 555
          end

          it 'has substitution for $Canvas.file.media.size' do
            exp_hash = {test: '$Canvas.file.media.size'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 444
          end

          it 'has substitution for $Canvas.file.media.title' do
            exp_hash = {test: '$Canvas.file.media.title'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'some title'
          end

          it 'uses user_entered_title for $Canvas.file.media.title if present' do
            media_object.user_entered_title = 'user title'
            exp_hash = {test: '$Canvas.file.media.title'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'user title'
          end

          it 'has substitution for $Canvas.file.usageRights.name' do
            exp_hash = {test: '$Canvas.file.usageRights.name'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'Private (Copyrighted)'
          end

          it 'has substitution for $Canvas.file.usageRights.url' do
            exp_hash = {test: '$Canvas.file.usageRights.url'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'http://en.wikipedia.org/wiki/Copyright'
          end

          it 'has substitution for $Canvas.file.usageRights.copyright_text' do
            exp_hash = {test: '$Canvas.file.usageRights.copyrightText'}
            variable_expander.expand_variables!(exp_hash)
            expect(exp_hash[:test]).to eq 'legit'
          end

        end

        it 'has substitution for $Canvas.masqueradingUser.id' do
          masquerading_user = User.new
          allow(masquerading_user).to receive(:id).and_return(7878)
          allow(user).to receive(:id).and_return(42)
          variable_expander.instance_variable_set("@current_user", masquerading_user)
          exp_hash = {test: '$Canvas.masqueradingUser.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 42
        end

        it 'does not expand $Canvas.masqueradingUser.id when the controller is unset' do
          variable_expander.instance_variable_set(:@controller, nil)
          variable_expander.instance_variable_set(:@request, nil)
          exp_hash = {test: '$Canvas.masqueradingUser.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '$Canvas.masqueradingUser.id'
        end

        it 'has substitution for $Canvas.masqueradingUser.userId' do
          masquerading_user = User.new
          allow(masquerading_user).to receive(:id).and_return(7878)
          variable_expander.instance_variable_set("@current_user", masquerading_user)
          exp_hash = {test: '$Canvas.masqueradingUser.userId'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq '6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f'
        end

        it 'has substitution for Canvas.module.id' do
          content_tag = double('content_tag')
          allow(content_tag).to receive(:context_module_id).and_return('foo')
          variable_expander.instance_variable_set('@content_tag', content_tag)
          exp_hash = {test: '$Canvas.module.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'foo'
        end

        it 'has substitution for Canvas.moduleItem.id' do
          content_tag = double('content_tag')
          allow(content_tag).to receive(:id).and_return(7878)
          variable_expander.instance_variable_set('@content_tag', content_tag)
          exp_hash = {test: '$Canvas.moduleItem.id'}
          variable_expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 7878
        end

        it 'has substitution for ToolConsumerProfile.url' do
          expander = VariableExpander.new(root_account, account, controller, current_user: user, tool: ToolProxy.new)
          exp_hash = {test: '$ToolConsumerProfile.url'}
          expander.expand_variables!(exp_hash)
          expect(exp_hash[:test]).to eq 'url'
        end
      end
    end
  end
end
