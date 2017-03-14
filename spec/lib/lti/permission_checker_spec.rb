require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper.rb')


describe Lti::PermissionChecker do
  include_context 'lti2_spec_helper'

  describe ".authorized_lti2_action?" do

    it "is true if the tool is authorized for the context" do
      expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: account)).to eq true
    end

    it "is false if the tool isn't installed in the context" do
      expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: Account.create!)).to eq false
    end

    context "assignment" do
      before :each do
        AssignmentConfigurationToolLookup.any_instance.stubs(:create_subscription).returns true
      end

      let(:assignment) do
        a = course.assignments.new(:title => "some assignment")
        a.workflow_state = "published"
        a.tool_settings_tool = message_handler
        a.save
        a
      end

      it "is false if the context is an assignment and the tool isn't associated" do
        assignment.tool_settings_tool = []
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)).to eq false
      end

      it "is true if the tool is authorized for an assignment context" do
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)).to eq true
      end
    end
  end

end
