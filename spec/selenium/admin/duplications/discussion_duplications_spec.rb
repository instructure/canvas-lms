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

require_relative '../../common'
require_relative '../../discussions/discussion_helpers'

describe "duplicate discussion" do
  include_context "in-process server selenium tests"
  include_context "discussions_page_shared_context"

  context 'discussion created by teacher' do
    before :each do
      course_with_teacher(active_all: true, name: 'teacher1')
      @discussion_topic = DiscussionHelpers.create_discussion_topic(
        @course,
        @teacher,
        'Discussion 1 Title',
        'Discussion 1 message',
        nil
      )
    end

    context 'duplicating' do
      before :each do
        user_session(@teacher)
        get discussions_topic_page
        f('.discussion-actions').click
      end

      it "has duplication option for discussions", priority: "2", test_id: 3353071 do
        expect(f('.al-options')).to contain_css('.icon-copy-course.duplicate-discussion.ui-corner-all')
      end

      it "duplicates a discussion", priority: "2", test_id: 3355802 do
        f('.icon-copy-course.duplicate-discussion.ui-corner-all').click
        expect(f('.open.discussion-list')).to contain_link('Discussion 1 Title Copy')
      end

      it "creates an unpublished duplicate", priority: "2", test_id: 3355803 do
        f('.icon-copy-course.duplicate-discussion.ui-corner-all').click
        expect(f('.open.discussion-list')).to contain_css('.icon-unpublish')
      end
    end
  end
end
