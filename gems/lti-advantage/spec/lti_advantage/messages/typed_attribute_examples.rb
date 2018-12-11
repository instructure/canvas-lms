#
# Copyright (C) 2017 - present Instructure, Inc.
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

RSpec.shared_context 'typed_attribute_examples' do
  shared_examples_for 'validations for a JWT LTI message' do
    it 'verifies that "aud" is an array' do
      message.aud = 'invalid-claim'
      message.validate
      expect(message.errors.messages[:aud]).to match_array [
        'aud must be an instance of Array'
      ]
    end

    it 'verifies that "extensions" is a Hash' do
      message.extensions = 'invalid-claim'
      message.validate
      expect(message.errors.messages[:extensions]).to match_array [
        'extensions must be an instance of Hash'
      ]
    end

    it 'verifies that "roles" is an array' do
      message.roles = 'invalid-claim'
      message.validate
      expect(message.errors.messages[:roles]).to match_array [
        'roles must be an instance of Array'
      ]
    end

    it 'verifies that "role_scope_mentor" is an array' do
      message.role_scope_mentor = 'invalid-claim'
      message.validate
      expect(message.errors.messages[:role_scope_mentor]).to match_array [
        'role_scope_mentor must be an instance of Array'
      ]
    end

    it 'verifies that "context" is a Context' do
      message.context = 'foo'
      message.validate
      expect(message.errors.messages[:context]).to match_array [
        'context must be an instance of LtiAdvantage::Claims::Context'
      ]
    end

    it 'verifies that "launch_presentation" is a LaunchPresentation' do
      message.launch_presentation = 'foo'
      message.validate
      expect(message.errors.messages[:launch_presentation]).to match_array [
        'launch_presentation must be an instance of LtiAdvantage::Claims::LaunchPresentation'
      ]
    end

    it 'verifies that "lis" is an Lis' do
      message.lis = 'foo'
      message.validate
      expect(message.errors.messages[:lis]).to match_array [
        'lis must be an instance of LtiAdvantage::Claims::Lis'
      ]
    end

    it 'verifies that "tool_platform" is an Platform' do
      message.tool_platform = 'foo'
      message.validate
      expect(message.errors.messages[:tool_platform]).to match_array [
        'tool_platform must be an instance of LtiAdvantage::Claims::Platform'
      ]
    end
  end
end