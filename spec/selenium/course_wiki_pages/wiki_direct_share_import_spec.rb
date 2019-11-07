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
require_relative 'page_objects/wiki_index_page'

describe 'course wiki pages' do
    include_context 'in-process server selenium tests'
    include CourseWikiIndexPage

    context 'with direct share FF ON' do
        before(:each) do
            course_with_teacher_logged_in
            @course.save!
            @module1 = @course.context_modules.create!
            @wiki_page1 = @course.wiki_pages.create!(:title => "Here is the first wiki")
            @module1.add_item(:id => @wiki_page1.id, :type => 'wiki_page')
            Account.default.enable_feature!(:direct_share)
            user_session(@teacher)
            visit_course_wiki_index_page(@course.id)
        end

        it 'shows direct share options' do
            manage_wiki_page_item_button(@wiki_page1.title).click
            
            expect(wiki_page_item_settings_menu.text).to include('Send to...')
            expect(wiki_page_item_settings_menu.text).to include('Copy to...')
        end
    end

    context 'with direct share FF OFF' do
        before(:each) do
            course_with_teacher_logged_in
            @course.save!
            @module1 = @course.context_modules.create!
            @wiki_page1 = @course.wiki_pages.create!(:title => "Here is the first wiki")
            @module1.add_item(:id => @wiki_page1.id, :type => 'wiki_page')
            Account.default.disable_feature!(:direct_share)
            user_session(@teacher)
            visit_course_wiki_index_page(@course.id)
        end

        it 'hides direct share options' do
            manage_wiki_page_item_button(@wiki_page1.title).click
            
            expect(wiki_page_item_settings_menu.text).not_to include('Send to...')
            expect(wiki_page_item_settings_menu.text).not_to include('Copy to...')
        end
    end
end