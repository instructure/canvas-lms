#
# Copyright (C) 2020 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CanvasOutcomesHelper do
  before do
    course_with_teacher_logged_in(:active_all => true)
  end

  subject { Object.new.extend CanvasOutcomesHelper }

  let(:account) { @course.account }

  def create_page(attrs)
    page = @course.wiki_pages.create!(attrs)
    page.publish! if page.unpublished?
    page
  end

  describe '#set_outcomes_alignment_js_env' do
    it 'raises error on invalid artifact type' do
      expect { subject.set_outcomes_alignment_js_env(account, account, {}) }.to raise_error('Unsupported artifact type: Account')
    end

    it 'sets js_env values' do
      wiki_page = create_page title: "title text", body: "body text"
      expect(subject).to receive(:extract_domain_jwt).and_return ['domain', 'jwt']
      expect(subject).to receive(:get_host_and_protocol_from_request).and_return ['host', 'https']
      expect(subject).to receive(:js_env).with({
        canvas_outcomes: {
          artifact_type: 'canvas.page',
          artifact_id: wiki_page.id,
          context_uuid: account.uuid,
          host: 'https://domain',
          jwt: 'jwt',
          extra_key: 'extra_value'
        }
      })
      subject.set_outcomes_alignment_js_env(wiki_page, account, extra_key: 'extra_value')
    end
  end

  describe '#extract_domain_jwt' do
    it 'returns nil domain and jwt with no provision settings' do
      expect(subject.extract_domain_jwt(account, '')).to eq [nil, nil]
    end

    it 'returns nil domain and jwt with no outcomes provision settings' do
      account.settings[:provision] = {}
      account.save!
      expect(subject.extract_domain_jwt(account, '')).to eq [nil, nil]
    end

    it 'returns domain and jwt with outcomes provision settings' do
      settings = { consumer_key: 'key', jwt_secret: 'secret', domain: 'domain' }
      account.settings[:provision] = { 'outcomes' => settings }
      account.save!
      expect(JWT).to receive(:encode).and_return 'encoded'
      expect(subject.extract_domain_jwt(account, '')).to eq ['domain', 'encoded']
    end
  end
end
