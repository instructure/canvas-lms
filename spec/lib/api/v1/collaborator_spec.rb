#
# Copyright (C) 2016 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Api::V1::Collaborator do
  include Api::V1::Collaborator

  describe '.collaborator_json' do
    let(:user) { user_model }
    let(:group) { group_model }
    let(:collaboration) { collaboration_model }

    context 'group collaborator' do
      let(:collaborator) { Collaborator.create(collaboration: collaboration, group: group) }

      it 'serializes' do
        json = collaborator_json(collaborator, user, nil)
        expect(json['id']).to eq collaborator.id
        expect(json['type']).to eq 'group'
        expect(json['name']).to eq group.name
        expect(json['collaborator_id']).to eq group.id
      end

      it 'includes collaborator_lti_id' do
        json = collaborator_json(collaborator, user, nil, include: ['collaborator_lti_id'])
        group.reload
        expect(json['collaborator_lti_id']).not_to be_nil
        expect(json['collaborator_lti_id']).to eq group.lti_context_id
      end

      it 'includes avatar_image_url' do
        json = collaborator_json(collaborator, user, nil, include: ['avatar_image_url'])
        expect(json['avatar_image_url']).to be_nil
      end
    end

    context 'user collaborator' do
      let(:collaborator) { Collaborator.create(collaboration: collaboration, user: user) }

      it 'serializes' do
        json = collaborator_json(collaborator, user, nil)
        expect(json['id']).to eq collaborator.id
        expect(json['type']).to eq 'user'
        expect(json['name']).to eq user.sortable_name
        expect(json['collaborator_id']).to eq user.id
      end

      it 'includes collaborator_lti_id' do
        json = collaborator_json(collaborator, user, nil, include: ['collaborator_lti_id'])
        user.reload
        expect(json['collaborator_lti_id']).not_to be_nil
        expect(json['collaborator_lti_id']).to eq user.lti_context_id
      end

      it 'includes avatar_image_url' do
        user.avatar_image_url = 'https://www.example.com/awesome-avatar.png'
        json = collaborator_json(collaborator, user, nil, include: ['avatar_image_url'])
        expect(json['avatar_image_url']).not_to be_nil
        expect(json['avatar_image_url']).to eq user.avatar_image_url
      end
    end
  end
end
