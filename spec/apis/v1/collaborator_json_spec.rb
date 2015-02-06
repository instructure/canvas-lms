#
# Copyright (C) 2012 Instructure, Inc.
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

include Api::V1::Collaborator

describe Api::V1::Collaborator do
  before(:once) do
    @current_user  = user_with_pseudonym(:active_all => true)
    @collaboration = Collaboration.new(:title => 'Test collaboration')
    @collaboration.type = 'EtherPad'
    @collaboration.save!
  end

  context 'a user' do
    it 'should properly serialize' do
      user = user_with_pseudonym
      collaborator = @collaboration.collaborators.create!(:user => user)
      expect(collaborator_json(collaborator, @current_user, nil)).to eq({
        'collaborator_id' => user.id,
        'id'              => collaborator.id,
        'name'            => user.sortable_name,
        'type'            => 'user'
        })
    end
  end

  context 'a group' do
    it 'should properly serialize' do
      group = group_model
      collaborator = @collaboration.collaborators.create!(:group => group)
      expect(collaborator_json(collaborator, @current_user, nil)).to eq({
        'collaborator_id' => group.id,
        'id'              => collaborator.id,
        'name'            => group.name,
        'type'            => 'group'
        })
    end
  end
end

