#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../helpers/wiki_and_tiny_common'
require_relative 'pages/rcs_sidebar_page'

describe "Wiki pages and Tiny WYSIWYG editor Files" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon
  include RCSSidebarPage

  context "wiki and tiny files as a teacher" do

    before(:each) do
      stub_rcs_config
      course_with_teacher_logged_in
    end

    after(:each) do
      # wait for all images to be done loading, since they may be thumbnails which hit the rails stack
      keep_trying_until do
        driver.execute_script <<-SCRIPT
          var done = true;
          var images = $('img:visible');
          for(var idx in images) {
            if(images[idx].src && !images[idx].complete) {
              done = false;
              break;
            }
          }
          return done;
        SCRIPT
      end
    end

    describe "keyboard navigation and accessiblity" do
      context "when on the Files tab" do
        before do
          wiki_page_tools_file_tree_setup(true, true)
          click_files_tab
          driver.execute_script('$("#right-side li a").focus()')
        end

        it "sets the first root folder with aria-expanded=true when initialized" do
          root_folder = fj('#right-side button:contains("course files")')
          expect(root_folder).to have_attribute('aria-expanded', "true")
        end

        it "collapses a folder when you press the spacebar" do
          root_folder = fj('#right-side button:contains("course files")')
          root_folder.send_keys :space
          expect(root_folder).to have_attribute('aria-expanded', "false")
        end
      end
    end
  end
end

