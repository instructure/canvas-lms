# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative 'pages/discussions_index_page'

describe 'discussions' do
    include_context 'in-process server selenium tests'

    context 'with direct share FF ON' do
        before(:each) do
            course_with_teacher_logged_in
            @course.save!
            @discussion1 = @course.discussion_topics.create!(
                title: 'First Discussion',
                message: 'What is this discussion about?',
                user: @teacher,
                pinned: false
            )
            Account.default.enable_feature!(:direct_share)
            user_session(@teacher)
            DiscussionsIndex.visit(@course)
        end
        
        it 'shows direct share options' do
            DiscussionsIndex.discussion_menu(@discussion1.title).click

            expect(DiscussionsIndex.manage_discussions_menu.text).to include('Send To...')
            expect(DiscussionsIndex.manage_discussions_menu.text).to include('Copy To...')
        end
    end

    context 'with direct share FF OFF' do
        before(:each) do
            course_with_teacher_logged_in
            @course.save!
            @discussion1 = @course.discussion_topics.create!(
                title: 'First Discussion',
                message: 'What is this discussion about?',
                user: @teacher,
                pinned: false
            )
            Account.default.disable_feature!(:direct_share)
            user_session(@teacher)
            DiscussionsIndex.visit(@course)
        end
        
        it 'hides direct share options' do
            DiscussionsIndex.discussion_menu(@discussion1.title).click
            
            expect(DiscussionsIndex.manage_discussions_menu.text).not_to include('Send To...')
            expect(DiscussionsIndex.manage_discussions_menu.text).not_to include('Copy To...')
        end
    end
end