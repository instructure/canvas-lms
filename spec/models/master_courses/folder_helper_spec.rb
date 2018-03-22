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

require 'spec_helper'

describe MasterCourses::FolderHelper do
  it "should be able to fetch a list of folder ids with restricted files (even recursively via sub-folders)" do
    @copy_from = course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)

    @copy_to = course_factory

    # master course
    master_root = Folder.root_folders(@copy_from).first
    locked_master_att = attachment_model(context: @copy_from, folder: master_root, filename: 'lockedfile.txt')
    locked_master_tag = @template.create_content_tag_for!(locked_master_att, :restrictions => {:content => true})
    unlocked_master_att = attachment_model(context: @copy_from, folder: master_root, filename: 'unlockedfile.txt')
    unlocked_master_tag = @template.create_content_tag_for!(unlocked_master_att)

    # child course
    child_root = Folder.root_folders(@copy_to).first
    locked_parent_folder = child_root.sub_folders.create!(:name => "locked parent", :context => @copy_to)
    locked_child_folder = locked_parent_folder.sub_folders.create!(:name => "locked child", :context => @copy_to)
    unlocked_parent_folder = child_root.sub_folders.create!(:name => "unlocked parent", :context => @copy_to)
    unlocked_child_folder = unlocked_parent_folder.sub_folders.create!(:name => "unlocked child", :context => @copy_to)

    locked_att = attachment_model(context: @copy_to, folder: locked_child_folder,
      filename: 'lockedfile.txt', migration_id: locked_master_tag.migration_id)
    unlocked_att = attachment_model(context: @copy_to, folder: unlocked_child_folder,
      filename: 'unlockedfile.txt', migration_id: unlocked_master_tag.migration_id)

    expect(MasterCourses::FolderHelper.locked_folder_ids_for_course(@copy_to)).
      to match_array([child_root, locked_parent_folder, locked_child_folder].map(&:id))
  end
end
