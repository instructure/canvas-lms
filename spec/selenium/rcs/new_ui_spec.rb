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

require_relative '../common'
require_relative '../helpers/files_common'

describe 'new ui' do
  include_context "in-process server selenium tests"
  include FilesCommon

  context 'as teacher' do

    before(:each) do
      course_with_teacher_logged_in
      enable_all_rcs @course.account
      stub_rcs_config
    end

    it 'should not break tiny mce css', priority: "2", test_id: 244891 do
      skip_if_chrome('Chrome does not get these values properly')
      get "/courses/#{@course.id}/discussion_topics/new?is_announcement=true"
      mce_icons = f('.mce-ico')
      expect(mce_icons.css_value('font-family')).to eq('tinymce,Arial')
      expect(mce_icons.css_value('font-style')).to eq('normal')
      expect(mce_icons.css_value('font-weight')).to eq('400')
      expect(mce_icons.css_value('font-size')).to eq('16px')
      expect(mce_icons.css_value('vertical-align')).to eq('text-top')
      expect(mce_icons.css_value('display')).to eq('inline-block')
      expect(mce_icons.css_value('background-size')).to eq('cover')
      expect(mce_icons.css_value('width')).to eq('16px')
      expect(mce_icons.css_value('height')).to eq('16px')
    end

    it 'should not break equation editor css', priority: "2", test_id: 273600 do
      get "/courses/#{@course.id}/assignments/new"
      wait_for_tiny(f('#assignment_description'))
      f('div#mceu_20.mce-widget.mce-btn').click
      wait_for_ajaximations
      expect(f('.mathquill-toolbar-panes, .mathquill-tab-bar')).to be_displayed
    end
  end
end
