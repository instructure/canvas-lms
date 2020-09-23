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
require_relative '../../spec_helper'

describe Csp::Domain do
  describe '::domains_for_tool' do
    describe 'when the tool has a domain' do
      let(:tool) { double('ContextExternalTool',
                          domain: 'puppyhoff.me',
                          url: 'http://mac.puppyhoff.me/launch') }

      it 'returns that domain and a wildcard for its subdomains' do
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          'puppyhoff.me', '*.puppyhoff.me'
        ]
      end
    end

    describe 'when the tool has a domain property that is actually a URL' do
      let(:tool) { double('ContextExternalTool',
                          domain: 'http://puppyhoff.me',
                          url: 'http://mac.puppyhoff.me/launch') }

      it 'extracts a domain from the domain property' do
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          'puppyhoff.me', '*.puppyhoff.me'
        ]
      end
    end

    describe 'when the tool has a url property but no domain' do
      let(:tool) { double('ContextExternalTool',
                          domain: nil,
                          url: 'http://mac.puppyhoff.me/launch') }

      it 'extracts a domain from the URL' do
        expect(Csp::Domain.domains_for_tool(tool)).to eq [
          'mac.puppyhoff.me', '*.mac.puppyhoff.me'
        ]
      end
    end
  end
end
