require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_dependency "lti/capabilities_helper"

# Get a list of valid capabilities
# Validate capabilities array
# return capability params hash

module Lti
  describe CapabilitiesHelper do
    let(:root_account) { Account.new(lti_guid: 'test-lti-guid') }
    let(:account) { Account.new(root_account: root_account) }
    let(:course) { Course.new(account: account) }
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
    let(:substitution_helper) { stub_everything }
    let(:right_now) { DateTime.now }
    let(:tool) do
      m = mock('tool')
      m.stubs(:id).returns(1)
      m.stubs(:context).returns(root_account)
      shard_mock = mock('shard')
      shard_mock.stubs(:settings).returns({encription_key: 'abc'})
      m.stubs(:shard).returns(shard_mock)
      m.stubs(:opaque_identifier_for).returns("6cd2e0d65bd5aef3b5ee56a64bdcd595e447bc8f")
      m
    end
    let(:controller) do
      request_mock = mock('request')
      request_mock.stubs(:url).returns('https://localhost')
      request_mock.stubs(:host).returns('/my/url')
      request_mock.stubs(:scheme).returns('https')
      m = mock('controller')
      m.stubs(:css_url_for).with(:common).returns('/path/to/common.scss')
      m.stubs(:request).returns(request_mock)
      m.stubs(:logged_in_user).returns(user)
      m.stubs(:named_context_url).returns('url')
      m.stubs(:polymorphic_url).returns('url')
      view_context_mock = mock('view_context')
      view_context_mock.stubs(:stylesheet_path)
        .returns(URI.parse(request_mock.url).merge(m.css_url_for(:common)).to_s)
      m.stubs(:view_context).returns(view_context_mock)
      m
    end

    let(:variable_expander) { Lti::VariableExpander.new(root_account, account, controller, current_user: user, tool: tool) }

    let(:invalid_enabled_caps){ %w(InvalidCap.Foo AnotherInvalid.Bar) }
    let(:valid_enabled_caps){ %w(ToolConsumerInstance.guid Membership.role CourseSection.sourcedId) }
    let(:supported_capabilities){
      %w(ToolConsumerInstance.guid
         CourseSection.sourcedId
         Membership.role
         Person.email.primary
         Person.name.given
         Person.name.family
         Person.name.full
         Person.sourcedId
         User.id
         User.image
         Message.documentTarget
         Message.locale
         Context.id
         vnd.Canvas.root_account.uuid)
    }
    describe '#supported_capabilities' do
      it 'returns all supported capabilities asociated with launch params' do
        expect(CapabilitiesHelper.supported_capabilities).to match_array(supported_capabilities)
      end
    end

    describe '#filter_capabilities' do
      it 'removes invalid capabilities' do
        valid_capabilities = CapabilitiesHelper.filter_capabilities(valid_enabled_caps + invalid_enabled_caps)
        expect(valid_capabilities).not_to include(*invalid_enabled_caps)
      end

      it 'does not remove valid capabilities' do
        valid_capabilities = CapabilitiesHelper.filter_capabilities(valid_enabled_caps + invalid_enabled_caps)
        expect(valid_capabilities).to match_array valid_enabled_caps
      end
    end

    describe '#capability_params_hash' do
      let(:valid_keys) { %w(tool_consumer_instance_guid roles lis_course_section_sourcedid) }

      it 'does not include a name (key) for invalid capabilities' do
        params_hash = CapabilitiesHelper.capability_params_hash(invalid_enabled_caps + valid_enabled_caps, variable_expander)
        expect(params_hash.keys).not_to include(*invalid_enabled_caps)
      end

      it 'does include a valid name (key) for valid capabilities' do
        params_hash = CapabilitiesHelper.capability_params_hash(invalid_enabled_caps + valid_enabled_caps, variable_expander)
        expect(params_hash.keys).to include(*valid_keys)
      end

      it 'does include a value for each valid capability' do
        params_hash = CapabilitiesHelper.capability_params_hash(invalid_enabled_caps + valid_enabled_caps, variable_expander)
        expect(params_hash.values.length).to eq valid_keys.length
      end
    end
  end
end
