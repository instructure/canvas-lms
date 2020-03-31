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
  let(:account) { Account.create! }
  let(:subject) { Account::HelpLinks.new(account) }

  before do
    Account.site_admin.enable_feature! :featured_help_links
  end

  describe '.instantiate_links' do
    it 'calls procs' do
      links = [{ text: -> { 'abc' }}]
      expect(subject.instantiate_links(links)).to eq [{ text: 'abc' }]
    end

    it 'reorders featured links to the front' do
      links = [{ id: 'a', is_featured: false }, { id: 'b', is_featured: false }, { id: 'c', is_featured: true }, { id: 'd', is_featured: false }]
      expect(subject.instantiate_links(links).pluck(:id)).to eq ['c', 'a', 'b', 'd']
    end
  end

  describe '.map_default_links' do
    it 'leaves custom links alone' do
      links = [{ type: 'custom', id: 'report_a_problem', text: 'bob', available_to: ['user'] }]
      translated = subject.map_default_links(links)
      expect(translated).to eq([{ type: 'custom', id: 'report_a_problem', text: 'bob', available_to: ['user'] }])
    end

    it 'leaves customized attributes on default links alone' do
      links = [{ type: 'default', id: 'report_a_problem', text: 'bob', subtext: 'bob bob', url: '#bob', available_to: ['user'], is_featured: true }]
      translated = subject.map_default_links(links)
      expect(translated.first[:text]).to eq 'bob'
      expect(translated.first[:subtext]).to eq 'bob bob'
      expect(translated.first[:url]).to eq '#bob'
      expect(translated.first[:is_featured]).to be true
    end

    it 'infers text for default links that have not been customized' do
      links = [{ type: 'default', id: 'instructor_question', available_to: ['user'] }]
      translated = subject.map_default_links(links)
      expect(translated.first[:text].call).to eq 'Ask Your Instructor a Question'
      expect(translated.first[:subtext].call).to eq 'Questions are submitted to your instructor'
      expect(translated.first[:url]).to eq '#teacher_feedback'
    end

    it 'uses default booleans when values have not been set' do
      links = [{ type: 'default', id: :instructor_question }, { type: 'default', id: :search_the_canvas_guides }]
      translated = subject.map_default_links(links)
      expect(translated.first[:is_featured]).to be false
      expect(translated.last[:is_new]).to be false
    end

    it 'does not choke on links with nil id' do
      links = [{ type: 'default', text: 'bob', available_to: ['user'] }]
      translated = subject.map_default_links(links)
      expect(translated.first).to eq({ type: 'default', text: 'bob', available_to: ['user'] })
    end
  end

  describe '.process_links_before_save' do
    it 'coalesces boolean values' do
      links = [{ is_featured: '0', is_new: '1' }, { is_featured: 'true', is_new: '' }]
      processed = subject.process_links_before_save(links)
      expect(processed).to eq [{is_featured: false, is_new: true}, {is_featured: true, is_new: false}]
    end

    it 'removes default values from default links' do
      links = account.help_links.first(3).deep_dup
      updates = [
        { text: 'this is new text', subtext: 'this is new subtext' },
        { url: 'this is a new url' },
        { feature_headline: 'this is a new headline', is_new: true }
      ]
      links.zip(updates).each {|link, update| link.merge!(update)}

      processed = subject.process_links_before_save(links)
      non_trivial_text = processed.map {|link| link.slice(:text, :subtext, :url, :feature_headline, :is_new).compact}
      expect(non_trivial_text).to eq updates
    end
  end

  describe 'self.validate_links' do
    it 'includes error if more than one link is marked featured' do
      links = [{ is_featured: true, is_new: false }, { is_featured: false, is_new: false }, { is_featured: true, is_new: false }]
      expect(described_class.validate_links(links)).to include(/at most one featured/)
    end

    it 'includes error if more than one link is marked new' do
      links = [{ is_featured: true, is_new: false }, { is_featured: false, is_new: true }, { is_featured: false, is_new: true }]
      expect(described_class.validate_links(links)).to include(/at most one new/)
    end

    it 'includes error if a link is marked new and featured' do
      links = [{ is_featured: false, is_new: false }, { is_featured: true, is_new: true }, { is_featured: false, is_new: false }]
      expect(described_class.validate_links(links)).to include(/cannot be featured and new/)
    end
  end

  describe 'with featured_help_links disabled' do
    it 'does not return featured_help_links fields' do
      Account.site_admin.disable_feature! :featured_help_links
      links = account.help_links
      links.each do |link|
        expect(link).not_to have_key(:is_featured)
        expect(link).not_to have_key(:is_new)
        expect(link).not_to have_key(:feature_headline)
      end
    end
  end
end
