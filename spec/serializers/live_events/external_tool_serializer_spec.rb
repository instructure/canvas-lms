# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'spec_helper'

RSpec.describe LiveEvents::ExternalToolSerializer do
  let(:serializer) { LiveEvents::ExternalToolSerializer.new(tool) }

  describe '#as_json' do
    subject { serializer.as_json }

    let(:tool) { external_tool_model(context: course, opts: tool_options) }
    let(:course) { course_model }
    let(:tool_options) { { domain: 'test.com' } }

    it 'includes the url' do
      expect(subject[:url]).to eq tool.url
    end

    it 'includes the domain' do
      expect(subject[:domain]).to eq tool_options[:domain]
    end

    context 'when a tool attribute is nil' do
      let(:tool_options) { {} }

      it 'does not include nil attributes' do
        expect(subject[:domain]).to be_nil
      end
    end
  end
end
