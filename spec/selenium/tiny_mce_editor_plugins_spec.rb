#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Tiny MCE editor plugins" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon

  it "should load all folders for the image plugin.", priority: "1", test_id: 420486 do
    course_with_teacher_logged_in
    @root_folder = Folder.root_folders(@course).first
    11.times { |i| @root_folder.sub_folders.create!(:name => "sf #{i}", :context => @course) }

    get "/courses/#{@course.id}/pages/front-page/edit"
    wait_for_ajaximations

    f("div[aria-label='Embed Image'] button").click
    wait_for_ajaximations

    fj('.imageSourceTabs a:contains(Canvas)').click
    wait_for_ajaximations

    f('.insertUpdateImageTabpane .treeLabel').click
    wait_for_ajaximations

    driver.execute_script("$('.treeContents .subtrees li').last().get(0).scrollIntoView()")
    wait_for_ajaximations

    expect{ff('.treeContents .subtrees li').length}.to become 11
    close_visible_dialog
  end
end
