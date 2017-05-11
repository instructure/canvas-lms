#
# Copyright (C) 2015 - present Instructure, Inc.
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
require 'db/migrate/20151006222126_fix_groups_with_duplicate_wiki_and_uuid'

describe 'FixGroupsWithDuplicateWikiAndUuid' do

  before do
    FixGroupsWithDuplicateWikiAndUuid.new.down
  end

  it "properly resets groups with duplicate data" do
    course_with_student

    @group_category = @course.group_categories.create!(name: 'Hi')
    @group = @group_category.groups.create!(name: 'Hi 1', context: @course)
    @membership = @group.group_memberships.create!(user: @student, workflow_state: 'invited')
    @group.wiki # this creates the wiki

    @new_group_category = @course.group_categories.create!(name: 'Hi Dup')
    @dup_group = @new_group_category.groups.create!(name: 'Hi Dup 1', context: @course)
    @dup_membership = @dup_group.group_memberships.create!(user: @student, workflow_state: 'invited')
    Group.where(id: @dup_group).update_all(wiki_id: @group.wiki_id, uuid: @group.uuid)
    GroupMembership.where(id: @dup_membership).update_all(uuid: @membership.uuid)

    @dup_uuid_only_group = @new_group_category.groups.create!(name: 'Hi Dup 2', context: @course)
    @dup_uuid_only_group.wiki
    Group.where(id: @dup_uuid_only_group).update_all(uuid: @group.uuid)

    @other_group_category = @course.group_categories.create!(name: 'Hi Other')
    @other_group = @other_group_category.groups.create!(name: 'Hi Other 1', context: @course)
    @other_membership = @other_group.group_memberships.create!(user: @student, workflow_state: 'invited')
    @other_group.wiki

    other_group_wiki_id = @other_group.wiki_id
    other_group_uuid = @other_group.uuid
    other_membership_uuid = @other_membership.uuid
    dup_uuid_only_group_wiki_id = @dup_uuid_only_group.wiki_id

    FixGroupsWithDuplicateWikiAndUuid.new.up

    @group.reload
    @dup_group.reload
    @dup_uuid_only_group.reload
    @other_group.reload

    @membership.reload
    @dup_membership.reload
    @other_membership.reload

    expect(@dup_group.wiki_id).not_to eq @group.wiki_id
    expect(@dup_group.uuid).not_to eq @group.uuid
    expect(@dup_uuid_only_group.wiki_id).to eq dup_uuid_only_group_wiki_id
    expect(@dup_uuid_only_group.uuid).not_to eq @group.uuid
    expect(@dup_membership.uuid).not_to eq @membership.uuid

    expect(@other_group.wiki_id).to eq other_group_wiki_id
    expect(@other_group.uuid).to eq other_group_uuid
    expect(@other_membership.uuid).to eq other_membership_uuid
  end

  it "sets a uuid for groups without one" do
    course_model
    @group_category = @course.group_categories.create!(name: 'Hi')
    @group = @group_category.groups.create!(name: 'Hi 1', context: @course)
    Group.where(id: @group).update_all(uuid: nil)

    FixGroupsWithDuplicateWikiAndUuid.new.up

    @group.reload
    expect(@group.uuid).not_to be nil
  end
end
