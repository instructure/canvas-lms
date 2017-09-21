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
      links = [{ type: 'custom', id: 'report_a_problem', text: 'bob', available_to: ['user'] }]
      translated = Account::HelpLinks.map_default_links(links)
      expect(translated).to eq([{ type: 'custom', id: 'report_a_problem', text: 'bob', available_to: ['user'] }])
    end

    it 'leaves customized text on default links alone' do
      links = [{ type: 'default', id: 'report_a_problem', text: 'bob', subtext: 'bob bob', url: '#bob', available_to: ['user'] }]
      translated = Account::HelpLinks.map_default_links(links)
      expect(translated.first[:text]).to eq 'bob'
      expect(translated.first[:subtext]).to eq 'bob bob'
      expect(translated.first[:url]).to eq '#bob'
    end

    it 'infers text for default links that have not been customized' do
      links = [{ type: 'default', id: 'instructor_question', available_to: ['user'] }]
      translated = Account::HelpLinks.map_default_links(links)
      expect(translated.first[:text].call).to eq 'Ask Your Instructor a Question'
      expect(translated.first[:subtext].call).to eq 'Questions are submitted to your instructor'
      expect(translated.first[:url]).to eq '#teacher_feedback'
    end

    it 'does not choke on links with nil id' do
      links = [{ type: 'default', text: 'bob', available_to: ['user'] }]
      translated = Account::HelpLinks.map_default_links(links)
      expect(translated.first).to eq({ type: 'default', text: 'bob', available_to: ['user'] })
    end
  end
end
