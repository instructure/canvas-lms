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
#

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Account::HelpLinks do
  describe '.instantiate_links' do
    it 'calls procs' do
      links = [{ text: -> { 'abc' }}]
      expect(Account::HelpLinks.instantiate_links(links)).to eq [{ text: 'abc' }]
    end
  end

  describe '.map_default_links' do
    it 'leaves custom links alone' do
      links = [{ type: 'custom', id: 'report_a_problem', text: 'bob', available_to: ['user'] },
               { type: 'default', id: 'report_a_problem', text: 'joe', available_to: ['user'] }]
      translated = Account::HelpLinks.map_default_links(links)
      expect(translated.first).to eq({ type: 'custom', id: 'report_a_problem', text: 'bob', available_to: ['user'] })
      expect(translated.last[:text]).to be_a(Proc)
      expect(translated.last[:subtext]).to be_a(Proc)
      expect(translated.last[:available_to]).to eq ['user']
    end

    it 'does not choke on links with nil id' do
      links = [{ type: 'default', text: 'bob', available_to: ['user'] }]
      translated = Account::HelpLinks.map_default_links(links)
      expect(translated.first).to eq({ type: 'default', text: 'bob', available_to: ['user'] })
    end
  end
end
