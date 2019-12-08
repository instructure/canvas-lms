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
require_relative '../shared_components/copy_to_tray_page'
require_relative '../shared_components/commons_fav_tray'

describe 'course wiki pages' do
  include_context 'in-process server selenium tests'
  include CourseWikiIndexPage
  include CopyToTrayPage
	include CommonsFavoriteTray

  let(:select_course_on_copy_tray) {
    course_search_dropdown.click
    course_dropdown_item(@course2.name).click
  }

  context 'with direct share FF ON' do
    before(:each) do
      course_with_teacher_logged_in
      @course.save!
      @module1 = @course.context_modules.create!(:name => "module 1")
      @wiki_page1 = @course.wiki_pages.create!(:title => "Here is the first wiki")
      @module1.add_item(:id => @wiki_page1.id, :type => 'wiki_page')
      # a second course
      @course2 = Course.create!(:name => "Second Course2")
      @course2.enroll_teacher(@teacher, :enrollment_state => 'active')
      @module2 = @course2.context_modules.create!(:name => "module 2")
      # enable direct share
      Account.default.enable_feature!(:direct_share)
      user_session(@teacher)
      visit_course_wiki_index_page(@course.id)
    end

    it 'shows direct share options' do
      manage_wiki_page_item_button(@wiki_page1.title).click
      
      expect(wiki_page_item_settings_menu.text).to include('Send to...')
      expect(wiki_page_item_settings_menu.text).to include('Copy to...')
    end

    context 'copy to' do
      before(:each) do
        manage_wiki_page_item_button(@wiki_page1.title).click
        copy_to_menu_item.click
        select_course_on_copy_tray
      end

      it 'copy tray lists modules in destination course' do
        module_search_dropdown.click
				wait_for_animations

        expect(module_dropdown_list.text).to include 'module 2'
      end
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

	context 'with commons fav FF ON' do
		before(:each) do
			@tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
			@tool.wiki_index_menu = {:url => "http://www.example.com", :text => "Commons Fav"}
			@tool.save!
			Account.default.enable_feature!(:commons_favorites)
			course_with_teacher_logged_in
      @course.save!
			user_session(@teacher)
			visit_course_wiki_index_page(@course.id)
		end

		it "should be able to launch index menu tool via the tray" do
			page_index_menu_link.click
			wait_for_ajaximations
			page_index_menu_item_link("Commons Fav").click
			wait_for_ajaximations

			expect(commons_fav_tray.text).to include 'Commons Fav'
			expect(tray_iframe['src']).to include "/courses/#{@course.id}/external_tools/#{@tool.id}"

			placement_query_params = Rack::Utils.parse_nested_query(URI.parse(tray_iframe['src']).query)
    	expect(placement_query_params["launch_type"]).to eq "wiki_index_menu"
    	expect(placement_query_params["com_instructure_course_allow_canvas_resource_selection"]).to eq "false"
    	expect(placement_query_params["com_instructure_course_canvas_resource_type"]).to eq "page"
    	expect(placement_query_params["com_instructure_course_accept_canvas_resource_types"]).to eq ["page"]
		end
	end
end