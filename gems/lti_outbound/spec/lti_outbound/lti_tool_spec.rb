#
# Copyright (C) 2014 Instructure, Inc.
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

require 'spec_helper'

describe LtiOutbound::LTITool do
  it_behaves_like 'it has a proc attribute setter and getter for', :consumer_key
  it_behaves_like 'it has a proc attribute setter and getter for', :privacy_level
  it_behaves_like 'it has a proc attribute setter and getter for', :name
  it_behaves_like 'it has a proc attribute setter and getter for', :shared_secret

  describe '#include_name?' do
    it 'returns true IFF the privacy level is public or name only' do
      subject.privacy_level = :something
      expect(subject.include_name?).to eq false
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
      expect(subject.include_name?).to eq true
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY
      expect(subject.include_name?).to eq true
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY
      expect(subject.include_name?).to eq false
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      expect(subject.include_name?).to eq false
    end
  end

  describe '#include_email?' do
    it 'returns true IFF the privacy level is public or email only' do
      subject.privacy_level = :something
      expect(subject.include_email?).to eq false
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
      expect(subject.include_email?).to eq true
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY
      expect(subject.include_email?).to eq false
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY
      expect(subject.include_email?).to eq true
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      expect(subject.include_email?).to eq false
    end
  end

  describe '#public?' do
    it 'returns true IFF the privacy level is public' do
      subject.privacy_level = :something
      expect(subject.public?).to eq false
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
      expect(subject.public?).to eq true
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY
      expect(subject.public?).to eq false
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY
      expect(subject.public?).to eq false
      subject.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      expect(subject.public?).to eq false
    end
  end

  describe '#settings' do
    it 'attribute setter, but returns {} instead of nil' do
      expect(subject.settings).to eq({})
      subject.settings = 10
      expect(subject.settings).to eq 10
    end
  end

  describe '#set_custom_fields' do
    it 'does not change the given input hash if the settings custom fields are empty' do
      hash = {:a => :b}

      subject.settings = {}
      subject.set_custom_fields(hash, nil)
      expect(hash).to eq({:a => :b})

      subject.settings = {:custom_fields => {}}
      subject.set_custom_fields(hash, nil)
      expect(hash).to eq({:a => :b})
    end

    it 'merges fields from the settings custom fields into the given hash prefixing them with custom_' do
      hash = {:a => :b}
      subject.settings = {:custom_fields => {:d => :e}}

      subject.set_custom_fields(hash, nil)
      expect(hash).to eq({:a => :b, 'custom_d' => :e})
    end

    it 'replaces non-word characters from custom field keys' do
      hash = {:a => :b}
      subject.settings = {:custom_fields => {:'%$#@d()' => :e}}

      subject.set_custom_fields(hash, nil)
      expect(hash).to eq({:a => :b, 'custom_____d__' => :e})
    end

    it 'merges fields from the applicable resource type too' do
      hash = {:a => :b}
      subject.settings = {:given_resource_type => {:custom_fields => {:'%$#@d()' => :e}}}

      subject.set_custom_fields(hash, 'given_resource_type')
      expect(hash).to eq({:a => :b, 'custom_____d__' => :e})
    end
  end

  describe '#format_lti_params' do
    it 'ignores the key if the prefix matches' do
      lti_params = {'custom_my_param' => 123}
      expect(subject.format_lti_params('custom', lti_params)).to eq lti_params
    end

    it 'replaces whitespace with "_"' do
      lti_params = {'custom_my param' => 123}
      expect(subject.format_lti_params('custom', lti_params).keys).to eq ['custom_my_param']
    end

    it 'adds the prefix if not present' do
      lti_params = {'my_param' => 123}
      expect(subject.format_lti_params('custom', lti_params)).to eq({'custom_my_param' => 123})
    end

  end

  describe '#selection_width' do
    it 'returns selection width from settings for a resource type' do
      subject.settings = {editor_button: {:selection_width => 100}}
      expect(subject.selection_width('editor_button')).to eq 100
    end

    it 'returns a default value if type is present in setting, but no selection width' do
      subject.settings = {editor_button: {}}
      expect(subject.selection_width('editor_button')).to eq 800
    end

    it 'returns a default value if none set' do
      expect(subject.selection_width('editor_button')).to eq 800
    end
  end

  describe '#selection_height' do
    it 'returns selection height from settings for a resource type' do
      subject.settings = {editor_button: {:selection_height => 100}}
      expect(subject.selection_height('editor_button')).to eq 100
    end

    it 'returns a default value if none set' do
      expect(subject.selection_height('editor_button')).to eq 400
    end
  end
end