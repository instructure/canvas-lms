module LtiAdvantage::Messages
  RSpec.describe ResourceLinkRequest do
    let(:message) { ResourceLinkRequest.new }
    let(:valid_message) do
      ResourceLinkRequest.new(
        aud: ['129aeb8c-a267-4551-bb5f-e6fc308fcecf'],
        azp: '163440e5-1c75-4c28-a07c-43e8a9cd3110',
        sub: '7da708b6-b6cf-483b-b899-11831c685b6f',
        deployment_id: 'ee493d2e-9f2e-4eca-b2a0-122413887caa',
        iat: 1529681618,
        exp: 1529681634,
        iss: 'https://platform.example.edu',
        nonce: '5a234202-6f0e-413d-8793-809db7a95930',
        resource_link: LtiAdvantage::Claims::ResourceLink.new(id: 1),
        roles: ['foo']
      )
    end

    describe 'initializer' do
      it 'defaults "message_type" to "LtiResourceLinkRequest' do
        expect(message.message_type).to eq 'LtiResourceLinkRequest'
      end

      it 'defaults "version" to "1.3.0' do
        expect(message.version).to eq '1.3.0'
      end
    end

    describe 'attributes' do
      it 'initializes the context when it is referenced' do
        message.context.id = 23
        expect(message.context.id).to eq 23
      end

      it 'initializes "resource_link" when it is referenced' do
        message.resource_link.id = 23
        expect(message.resource_link.id).to eq 23
      end

      it 'initalizes "launch_presentation" when it is referenced' do
        message.launch_presentation.width = 100
        expect(message.launch_presentation.width).to eq 100
      end

      it 'initalizes "tool_platform" when it is referenced' do
        message.tool_platform.name = 'foo'
        expect(message.tool_platform.name).to eq 'foo'
      end
    end

    describe 'validations' do
      it 'is not valid if required claims are missing' do
        expect(message).to be_invalid
      end

      it 'is valid if all required claims are present' do
        expect(valid_message).to be_valid
      end

      it 'validates sub claims' do
        message = ResourceLinkRequest.new(
          aud: ['129aeb8c-a267-4551-bb5f-e6fc308fcecf'],
          azp: '163440e5-1c75-4c28-a07c-43e8a9cd3110',
          sub: '7da708b6-b6cf-483b-b899-11831c685b6f',
          deployment_id: 'ee493d2e-9f2e-4eca-b2a0-122413887caa',
          iat: 1529681618,
          exp: 1529681634,
          iss: 'https://platform.example.edu',
          nonce: '5a234202-6f0e-413d-8793-809db7a95930',
          resource_link: LtiAdvantage::Claims::ResourceLink.new(id: 1),
          roles: ['foo'],
          context: LtiAdvantage::Claims::Context.new
        )
        message.validate
        expect(message.errors.messages[:context]).to match_array [
          { id: ["can't be blank"] }
        ]
      end

      it 'verifies that "aud" is an array' do
        message.aud = 'invalid-claim'
        message.validate
        expect(message.errors.messages[:aud]).to match_array [
          'aud must be an intance of Array'
        ]
      end

      it 'verifies that "extensions" is an array' do
        message.extensions = 'invalid-claim'
        message.validate
        expect(message.errors.messages[:extensions]).to match_array [
          'extensions must be an intance of Hash'
        ]
      end

      it 'verifies that "roles" is an array' do
        message.roles = 'invalid-claim'
        message.validate
        expect(message.errors.messages[:roles]).to match_array [
          'roles must be an intance of Array'
        ]
      end

      it 'verifies that "role_scope_mentor" is an array' do
        message.role_scope_mentor = 'invalid-claim'
        message.validate
        expect(message.errors.messages[:role_scope_mentor]).to match_array [
          'role_scope_mentor must be an intance of Array'
        ]
      end

      it 'verifies that "context" is a Context' do
        message.context = 'foo'
        message.validate
        expect(message.errors.messages[:context]).to match_array [
          'context must be an intance of LtiAdvantage::Claims::Context'
        ]
      end

      it 'verifies that "launch_presentation" is a LaunchPresentation' do
        message.launch_presentation = 'foo'
        message.validate
        expect(message.errors.messages[:launch_presentation]).to match_array [
          'launch_presentation must be an intance of LtiAdvantage::Claims::LaunchPresentation'
        ]
      end

      it 'verifies that "lis" is an Lis' do
        message.lis = 'foo'
        message.validate
        expect(message.errors.messages[:lis]).to match_array [
          'lis must be an intance of LtiAdvantage::Claims::Lis'
        ]
      end

      it 'verifies that "tool_platform" is an Platform' do
        message.tool_platform = 'foo'
        message.validate
        expect(message.errors.messages[:tool_platform]).to match_array [
          'tool_platform must be an intance of LtiAdvantage::Claims::Platform'
        ]
      end

      it 'verifies that "resource_link" is an Platform' do
        message.resource_link = 'foo'
        message.validate
        expect(message.errors.messages[:resource_link]).to match_array [
          'resource_link must be an intance of LtiAdvantage::Claims::ResourceLink'
        ]
      end
    end

  end
end
