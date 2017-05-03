require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::ContentItemParameterHelper do
  include ExternalToolsSpecHelper
  let(:course) { course_model }
  let(:user) { course_with_student(course: course).user }
  let(:placement) {'resource_selection'}
  let(:tool) { new_valid_tool(course) }
  let(:launch_url) { 'http://www.test.com/launch' }

  let(:opts) do
    {
      current_user: user,
      current_pseudonym: user.pseudonyms.first,
      domain_root_account: course.root_account,
      controller: double(request: {body: 'body content'})
    }
  end

  before do
    tool.custom_fields = {context_id: '$Context.id'}
    tool.save!
  end

  let(:subject) do
    Lti::ContentItemParameterHelper.new(
      tool: tool,
      placement: placement,
      context: course,
      collaboration: nil,
      opts: opts
    )
  end

  describe 'expanded_variables' do
    it 'expands custom fields' do
      expected_params = {
        'custom_context_id' => Lti::Asset.opaque_identifier_for(course)
      }

      expect(subject.expanded_variables).to include expected_params
    end

    it 'includes supported parameters' do
      expected_params = {
        'context_label' => course.course_code
      }

      expect(subject.expanded_variables).to include expected_params
    end
  end
end
