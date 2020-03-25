#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative 'common'
require_relative 'helpers/wiki_and_tiny_common'
require_relative 'helpers/public_courses_context'
require_relative 'helpers/files_common'

# We have the funky indenting here because we will remove this once the granular
# permission stuff is released, and I don't want to complicate the git history
# for this file
RSpec.shared_examples "wiki_pages" do
describe "Wiki Pages" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include WikiAndTinyCommon

  context "Navigation" do
    def edit_page(edit_text)
      get "/courses/#{@course.id}/pages/Page1/edit"
      add_text_to_tiny(edit_text)
      expect_new_page_load { fj('button:contains("Save")').click }
    end

    before do
      account_model
      course_with_teacher_logged_in :account => @account
      set_granular_permission
    end

    it "should navigate to pages tab with no front page set", priority: "1", test_id: 126843 do
      @course.wiki_pages.create!(title: 'Page1')
      @course.wiki_pages.create!(title: 'Page2')
      get "/courses/#{@course.id}"
      f('.pages').click
      expect(driver.current_url).to include("/courses/#{@course.id}/pages")
      expect(driver.current_url).not_to include("/courses/#{@course.id}/wiki")
      get "/courses/#{@course.id}/wiki"
      expect(driver.current_url).to include("/courses/#{@course.id}/pages")
      expect(driver.current_url).not_to include("/courses/#{@course.id}/wiki")
    end

    it "should navigate to front page when set", priority: "1", test_id: 126844 do
      front = @course.wiki_pages.create!(title: 'Front')
      front.set_as_front_page!
      front.save!
      get "/courses/#{@course.id}"
      f('.pages').click
      expect(driver.current_url).not_to include("/courses/#{@course.id}/pages")
      expect(driver.current_url).to include("/courses/#{@course.id}/wiki")
      expect(f('span.front-page.label')).to include_text 'Front Page'
      get "/courses/#{@course.id}/pages"
      expect(driver.current_url).to include("/courses/#{@course.id}/pages")
      expect(driver.current_url).not_to include("/courses/#{@course.id}/wiki")
    end

    it "should have correct front page UI elements when set as home page", priority: "1", test_id: 126848 do
      front = @course.wiki_pages.create!(title: 'Front')
      front.set_as_front_page!
      @course.update_attribute :default_view, "wiki"
      get "/courses/#{@course.id}"
      wait_for_ajaximations
      # validations
      expect(f('.al-trigger')).to be_present
      expect(f('.course-title')).to include_text 'Unnamed Course'
      content = f("#content")
      expect(content).not_to contain_css('span.front-page.label')
      expect(content).not_to contain_css('button.btn.btn-published')
      f('.al-trigger').click
      expect(content).not_to contain_css('.icon-trash')
      expect(f('.icon-clock')).to be_present
    end

    it "navigates to the wiki pages edit page from the show page" do
      wiki_page = @course.wiki_pages.create!(:title => "Foo")
      edit_url = edit_course_wiki_page_url(@course, wiki_page)
      get course_wiki_page_path(@course, wiki_page)

      f(".edit-wiki").click

      keep_trying_until { expect(driver.current_url).to eq edit_url }
    end

    it "should alert a teacher when accessing a non-existant page", priority: "1", test_id: 126842 do
      get "/courses/#{@course.id}/pages/fake"
      expect_flash_message :info
    end

    it "should update with changes made in other window", priority: "1", test_id: 126833, custom_timeout: 40.seconds do
      @course.wiki_pages.create!(title: 'Page1')
      edit_page('this is')
      driver.execute_script("window.open()")
      driver.switch_to.window(driver.window_handles.last)
      edit_page('test')
      driver.execute_script("window.close()")
      driver.switch_to.window(driver.window_handles.first)
      get "/courses/#{@course.id}/pages/Page1/edit"
      switch_editor_views(wiki_page_body)
      expect(f('textarea')).to include_text('test')
    end

    it "blocks linked page from redirecting parent page", priority: "2", test_id: 927147 do
      @course.wiki_pages.create!(title: 'Garfield and Odie Food Preparation',
        body: '<a href="http://example.com/poc/" target="_blank" id="click_here_now">click_here</a>')
      get "/courses/#{@course.id}/pages/garfield-and-odie-food-preparation"
      expect(f('#click_here_now').attribute("rel")).to eq "noreferrer noopener"
    end

    it "does not mark valid links as invalid", priority: "2", test_id: 927788 do
      @course.wiki_pages.create!(title: 'Page1', body: 'http://www.instructure.com/')
      get "/courses/#{@course.id}/link_validator"
      fj('button:contains("Start Link Validation")').click
      run_jobs
      expect(f('#link_validator')).to contain_jqcss('div:contains("No broken links found")')
    end
  end

  context "Index Page as a teacher" do
    before do
      account_model
      course_with_teacher_logged_in
      set_granular_permission
    end

    it "should edit page title from pages index", priority: "1", test_id: 126849 do
      @course.wiki_pages.create!(title: 'B-Team')
      get "/courses/#{@course.id}/pages"
      f('.al-trigger').click
      f('.edit-menu-item').click
      expect(f('.edit-control-text').attribute(:value)).to include('B-Team')
      f('.edit-control-text').clear()
      f('.edit-control-text').send_keys('A-Team')
      fj('button:contains("Save")').click
      expect(f('.collectionViewItems')).to include_text('A-Team')
    end

    it "should display a warning alert when accessing a deleted page", priority: "1", test_id: 126840 do
      @course.wiki_pages.create!(title: 'deleted')
      get "/courses/#{@course.id}/pages"
      f('.al-trigger').click
      f('.delete-menu-item').click
      fj('button:contains("Delete")').click
      wait_for_ajaximations
      get "/courses/#{@course.id}/pages/deleted"
      expect_flash_message :info
    end
  end

  context "Index Page as a student" do
    before do
      course_with_student_logged_in
      set_granular_permission
    end

    it "should display a warning alert to a student when accessing a deleted page", priority: "1", test_id: 126839 do
      page = @course.wiki_pages.create!(title: 'delete_deux')
      # sets the workflow_state = deleted to act as a deleted page
      page.workflow_state = 'deleted'
      page.save!
      get "/courses/#{@course.id}/pages/delete_deux"
      expect_flash_message :warning
    end

    it "should display a warning alert when accessing a non-existant page", priority: "1", test_id: 126841 do
      get "/courses/#{@course.id}/pages/non-existant"
      expect_flash_message :warning
    end
  end

  context "Insert RCE File" do
    before do
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
      set_granular_permission
    end

    it "should insert a file using RCE in the wiki page", priority: "1", test_id: 126673 do
      stub_rcs_config
      @course.wiki_pages.create!(:title => "Bar")
      user_session(@user)
      file = @course.attachments.create!(display_name: 'some test file', uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      get "/courses/#{@course.id}/pages/bar/edit"
      insert_file_from_rce
    end
  end

  context "Show Page" do
    before do
      account_model
      course_with_student_logged_in account: @account
      set_granular_permission
    end

    it "should lock page based on module date", priority: "1", test_id: 126845 do
      locked = @course.wiki_pages.create! title: 'locked'
      mod2 = @course.context_modules.create! name: 'mod2', unlock_at: 1.day.from_now
      mod2.add_item id: locked.id, type: 'wiki_page'
      mod2.save!

      get "/courses/#{@course.id}/pages/locked"
      wait_for_ajaximations
      # validation
      lock_explanation = f('.lock_explanation').text
      expect(lock_explanation).to include "This page is locked until"
      expect(lock_explanation).to include 'The following requirements need to be completed before this page will be unlocked:'
    end

    it "should lock page based on module progression", priority: "1", test_id: 126846 do
      foo = @course.wiki_pages.create! title: 'foo'
      bar = @course.wiki_pages.create! title: 'bar'
      mod = @course.context_modules.create! name: 'the_mod', require_sequential_progress: true
      foo_item = mod.add_item id: foo.id, type: 'wiki_page'
      bar_item = mod.add_item id: bar.id, type: 'wiki_page'
      mod.completion_requirements = {foo_item.id => {type: 'must_view'}, bar_item.id => {type: 'must_view'}}
      mod.save!

      get "/courses/#{@course.id}/pages/bar"
      wait_for_ajaximations
      # validation
      lock_explanation = f('.lock_explanation').text
      expect(lock_explanation).to include "This page is part of the module the_mod and hasn't been unlocked yet"
      expect(lock_explanation).to match /foo\s+must view the page/
    end

    it "should not show the show all pages link if the pages tab is disabled" do
      @course.tab_configuration = [ { :id => Course::TAB_PAGES, :hidden => true } ]
      @course.save!

      foo = @course.wiki_pages.create! title: 'foo'
      get "/courses/#{@course.id}/pages/foo"

      expect(f("#content")).not_to contain_css('.view_all_pages')

    end
  end

  context "Permissions" do
    before do
      course_with_teacher
      set_granular_permission
    end

    it "displays public content to unregistered users", priority: "1", test_id: 270035 do
      Canvas::Plugin.register(:kaltura, nil, :settings => {'partner_id' => 1, 'subpartner_id' => 2, 'kaltura_sis' => '1'})

      @course.is_public = true
      @course.workflow_state = 'available'
      @course.save!

      title = "foo"
      wiki_page = @course.wiki_pages.create!(:title => title, :body => "bar")

      get "/courses/#{@course.id}/pages/#{title}"
      expect(f('#wiki_page_show')).not_to be_nil
    end
  end

  context "menu tools" do
    before do
      course_with_teacher_logged_in
      set_granular_permission
      @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.wiki_page_menu = {:url => "http://www.example.com", :text => "Export Wiki Page"}
      @tool.save!

      @course.wiki.set_front_page_url!('front-page')
      @wiki_page = @course.wiki.front_page
      @wiki_page.workflow_state = 'active'
      @wiki_page.save!
    end

    it "should show tool launch links in the gear for items on the index" do
      get "/courses/#{@course.id}/pages"
      wait_for_ajaximations

      gear = f(".collectionViewItems tr .al-trigger")
      gear.click
      link = f(".collectionViewItems tr li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:wiki_page_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=wiki_page_menu&pages[]=#{@wiki_page.id}"
    end

    it "should show tool launch links in the gear for items on the show page" do
      get "/courses/#{@course.id}/pages/#{@wiki_page.url}"
      wait_for_ajaximations

      gear = f("#wiki_page_show .al-trigger")
      gear.click
      link = f("#wiki_page_show .al-options li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:wiki_page_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool) + "?launch_type=wiki_page_menu&pages[]=#{@wiki_page.id}"
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "should display wiki content", priority: "1", test_id: 270035 do
      @coures = public_course
      set_granular_permission
      title = "foo"
      public_course.wiki_pages.create!(:title => title, :body => "bar")

      get "/courses/#{public_course.id}/wiki/#{title}"
      expect(f('.user_content')).not_to be_nil
    end
  end

  context "embed video in a Page" do
    before :each do
      course_with_teacher_logged_in :account => @account, :active_all => true
      set_granular_permission
      @course.wiki_pages.create!(title: 'Page1')
    end

    it "should embed vimeo video in the page", priority: "1", test_id: 126835 do
      get "/courses/#{@course.id}/pages/Page1/edit"
      element = f("#wiki_page_body")
      switch_editor_views(element)
      html_contents = %q(
        <p>
          <iframe style="width: 640px; height: 480px;"
                  title="Instructure - About Us"
                  src="https://player.vimeo.com/video/51408381"
                  width="300"
                  height="150"
                  allowfullscreen="allowfullscreen"
                  webkitallowfullscreen="webkitallowfullscreen"
                  mozallowfullscreen="mozallowfullscreen">
          </iframe>
        </p>
      )
      element.send_keys(html_contents)
      wait_for_new_page_load { f(".btn-primary").click }
      expect(f("iframe")).to be_present
    end
  end

  context "MathML" do
    include_context "public course as a logged out user"

    it "should load mathjax in a page with <math>" do
      skip('Unskip in ADMIN-2684')
      title = "mathML"
      @course = public_course
      set_granular_permission
      public_course.wiki_pages.create!(
        :title => title,
        :body => "<math><mi>&#x3C0;</mi> <msup> <mi>r</mi> <mn>2</mn> </msup></math>"
      )
      get "/courses/#{public_course.id}/wiki/#{title}"
      is_mathjax_loaded = driver.execute_script("return (typeof MathJax == 'object')")
      expect(is_mathjax_loaded).to match(true)
    end

    it "should not load mathjax without <math>" do
      title = "not_mathML"
      @course = public_course
      set_granular_permission
      public_course.wiki_pages.create!(:title => title, :body => "not mathML")
      get "/courses/#{public_course.id}/wiki/#{title}"
      is_mathjax_loaded = driver.execute_script("return (typeof MathJax == 'object')")
      expect(is_mathjax_loaded).not_to match(true)

    end
  end
end
end
# End shared_example block

RSpec.describe 'With granular permission on' do
  it_behaves_like "wiki_pages" do
    let(:set_granular_permission) { @course.root_account.enable_feature!(:granular_permissions_wiki_pages) }
  end
end

RSpec.describe 'With granular permission off' do
  it_behaves_like "wiki_pages" do
    let(:set_granular_permission) { @course.root_account.disable_feature!(:granular_permissions_wiki_pages) }
  end
end
