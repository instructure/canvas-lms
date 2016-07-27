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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

include Api::V1::Collaboration

describe Api::V1::Collaboration do
  before(:once) do
    @current_user  = user_with_pseudonym(:active_all => true)
    @collaboration = ExternalToolCollaboration.new(:title => 'Test collaboration',
                                       :description => 'Let us collaborate',
                                       :type => 'ExternalToolCollaboration',
                                       :url => 'https://google.com',
                                       :user => @current_user)
    @collaboration.data = {updateUrl: 'https://google.com'}
    @collaboration.save!
  end

  it 'should properly serialize' do
    json = collaboration_json(@collaboration, @current_user, nil)

    expect(json['id']).to eq @collaboration.id
    expect(json['collaboration_type']).to eq @collaboration.collaboration_type
    expect(json['document_id']).to eq @collaboration.document_id
    expect(json['user_id']).to eq @collaboration.user_id
    expect(json['context_id']).to eq @collaboration.context_id
    expect(json['context_type']).to eq @collaboration.context_type
    expect(json['url']).to eq @collaboration.url
    expect(json['created_at']).to eq @collaboration.created_at
    expect(json['updated_at']).to eq @collaboration.updated_at
    expect(json['title']).to eq @collaboration.title
    expect(json['description']).to eq @collaboration.description
    expect(json['type']).to eq @collaboration.type

    expect(json['data']).to eq nil
    expect(json['deleted_at']).to eq nil
  end

  it 'should include the owning users name' do
    json = collaboration_json(@collaboration, @current_user, nil)

    expect(json['user_name']).to eq @current_user.name
  end

  it 'should include the update_url' do
    json = collaboration_json(@collaboration, @current_user, nil)

    expect(json['update_url']).to eq @collaboration.update_url
  end
end
