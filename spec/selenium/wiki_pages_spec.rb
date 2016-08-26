require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

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
    end

    it "should navigate to pages tab with no front page set", priority: "1", test_id: 126843 do
      @course.wiki.wiki_pages.create!(title: 'Page1')
      @course.wiki.wiki_pages.create!(title: 'Page2')
      get "/courses/#{@course.id}"
      f('.pages').click
      expect(driver.current_url).to include("/courses/#{@course.id}/pages")
      expect(driver.current_url).not_to include("/courses/#{@course.id}/wiki")
      get "/courses/#{@course.id}/wiki"
      expect(driver.current_url).to include("/courses/#{@course.id}/pages")
      expect(driver.current_url).not_to include("/courses/#{@course.id}/wiki")
    end

    it "should navigate to front page when set", priority: "1", test_id: 126844 do
      front = @course.wiki.wiki_pages.create!(title: 'Front')
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
      front = @course.wiki.wiki_pages.create!(title: 'Front')
      front.set_as_front_page!
      front.save!
      get "/courses/#{@course.id}/wiki"
      fln('Home').click
      # setting front-page as home page
      fj('.btn.button-sidebar-wide:contains("Choose Home Page")').click
      fj('input[type=radio][value=wiki]').click
      fj('button.btn.btn-primary.button_type_submit.ui-button.ui-widget.ui-state-default.ui-corner-all.ui-button-text-only').click
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
      wikiPage = @course.wiki.wiki_pages.create!(:title => "Foo")
      edit_url = edit_course_wiki_page_url(@course, wikiPage)
      get course_wiki_page_path(@course, wikiPage)

      f(".edit-wiki").click

      keep_trying_until { expect(driver.current_url).to eq edit_url }
    end

    it "should alert a teacher when accessing a non-existant page", priority: "1", test_id: 126842 do
      get "/courses/#{@course.id}/pages/fake"
      expect_flash_message :info
    end

    it "should update the page with changes made in another window", priority: "1", test_id: 126833 do
      @course.wiki.wiki_pages.create!(title: 'Page1')
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
      @course.wiki.wiki_pages.create!(title: 'Garfield and Odie Food Preparation',
        body: '<a href="http://example.com/poc/" target="_blank" id="click_here_now">click_here</a>')
      get "/courses/#{@course.id}/pages/garfield-and-odie-food-preparation"
      expect(f('#click_here_now').attribute("rel")).to eq "noreferrer"
    end
  end

  context "Index Page as a teacher" do
    before do
      account_model
      course_with_teacher_logged_in
    end

    it "should edit page title from pages index", priority: "1", test_id: 126849 do
      @course.wiki.wiki_pages.create!(title: 'B-Team')
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
      @course.wiki.wiki_pages.create!(title: 'deleted')
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
    end

    it "should display a warning alert to a student when accessing a deleted page", priority: "1", test_id: 126839 do
      page = @course.wiki.wiki_pages.create!(title: 'delete_deux')
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

  context "Accessibility" do

    def check_header_focus(attribute)
      f("[data-sort-field='#{attribute}']").click
      wait_for_ajaximations
      check_element_has_focus(f("[data-sort-field='#{attribute}']"))
    end

    before :once do
      account_model
      course_with_teacher :account => @account
      @course.wiki.wiki_pages.create!(:title => "Foo")
      @course.wiki.wiki_pages.create!(:title => "Bar")
      @course.wiki.wiki_pages.create!(:title => "Baz")
    end

    before :each do
      user_session(@user)
    end

    it "returns focus to the header item clicked while sorting" do
      get "/courses/#{@course.id}/pages"

      check_header_focus('title')
      check_header_focus('created_at')
      check_header_focus('updated_at')
    end

    describe "Add Course Button" do
      before :each do
        get "/courses/#{@course.id}/pages"

        driver.execute_script("$('.new_page').focus()")
        @active_element = driver.execute_script('return document.activeElement')
      end

      it "navigates to the add course view when enter is pressed" do
        @active_element.send_keys(:enter)
        wait_for_ajaximations
        check_element_has_focus(f('.edit-header #title'))
      end

      it "navigates to the add course view when spacebar is pressed" do
        @active_element.send_keys(:space)
        wait_for_ajaximations
        check_element_has_focus(f('.edit-header #title'))
      end
    end

    context "Publish Cloud" do

      it "should set focus back to the publish cloud after unpublish" do
        get "/courses/#{@course.id}/pages"
        f('.publish-icon').click
        wait_for_ajaximations
        check_element_has_focus(f('.publish-icon'))
      end

      it "should set focus back to the publish cloud after publish" do
        get "/courses/#{@course.id}/pages"
        f('.publish-icon').click # unpublish it.
        wait_for_ajaximations
        f('.publish-icon').click # publish it.
        check_element_has_focus(f('.publish-icon'))
      end
    end

    context "Delete Page" do

      before do
        get "/courses/#{@course.id}/pages"
      end

      it "returns focus back to the item cog if the item was not deleted" do
        f('.al-trigger').click
        f('.delete-menu-item').click
        f('.ui-dialog-buttonset .btn').click
        wait_for_ajaximations
        check_element_has_focus(f('.al-trigger'))
      end

      it "returns focus back to the item cog if escape was pressed" do
        f('.al-trigger').click
        f('.delete-menu-item').click
        f('.ui-dialog-buttonset .btn').send_keys(:escape)
        wait_for_ajaximations
        check_element_has_focus(f('.al-trigger'))
      end

      it "returns focus back to the item cog if the dialog close was pressed" do
        f('.al-trigger').click
        f('.delete-menu-item').click
        f('.ui-dialog-titlebar-close').click
        wait_for_ajaximations
        check_element_has_focus(f('.al-trigger'))
      end

      it "returns focus to the previous item cog if it was deleted" do
        triggers = ff('.al-trigger')
        triggers.last.click
        ff('.delete-menu-item').last.click
        f('.ui-dialog-buttonset .btn-danger').click
        wait_for_ajaximations
        check_element_has_focus(triggers[-2])
      end

      it "returns focus to the + Page button if there are no previous item cogs" do
        f('.al-trigger').click
        f('.delete-menu-item').click
        f('.ui-dialog-buttonset .btn-danger').click
        wait_for_ajaximations
        check_element_has_focus(f('.new_page'))
      end
    end

    context "Use as Front Page Link" do
      before :each do
        get "/courses/#{@course.id}/pages"
        f('.al-trigger').click
      end

      it "should set focus back to the cog after setting" do
        f('.use-as-front-page-menu-item').click
        wait_for_ajaximations
        check_element_has_focus(f('.al-trigger'))
      end

      it "should set focus to the next focusable item if you press Tab" do
        f('.use-as-front-page-menu-item').send_keys(:tab)
        check_element_has_focus(ff('.wiki-page-link')[1])
      end
    end

    context "Cog menu" do
      before :each do
        get "/courses/#{@course.id}/pages"
        f('.al-trigger').click
        f('.edit-menu-item').click
      end

      it "should set focus back to the cog menu if you cancel the dialog" do
        f('.ui-dialog-buttonset .btn').click
        check_element_has_focus(f('.al-trigger'))
      end

      it "sets focus back to the cog if you press escape" do
        f('.ui-dialog-buttonset .btn').send_keys(:escape)
        check_element_has_focus(f('.al-trigger'))
      end

      it "sets focus back to the cog if you click the dialog close button" do
        f('.ui-dialog-titlebar-close').click
        check_element_has_focus(f('.al-trigger'))
      end

      it "should return focus to the dialog if you cancel, then reopen the dialog" do
        f('.ui-dialog-titlebar-close').click
        check_element_has_focus(f('.al-trigger'))
        f('.al-trigger').click
        f('.edit-menu-item').click
        wait_for_ajaximations
        check_element_has_focus(ff('.page-edit-dialog .edit-control-text').last)
      end

      it "should set focus back to the cog menu if you edit the title and save" do
        f('.ui-dialog-buttonset .btn-primary').click
        wait_for_ajaximations
        check_element_has_focus(f('.al-trigger'))
      end
    end

    context "Revisions Page" do
      before :once do
        account_model
        course_with_teacher :account => @account, :active_all => true
        @timestamps = %w(2015-01-01 2015-01-02 2015-01-03).map { |d| Time.zone.parse(d) }

        Timecop.freeze(@timestamps[0]) do      # rev 1
          @vpage = @course.wiki.wiki_pages.build :title => 'bar'
          @vpage.workflow_state = 'unpublished'
          @vpage.body = 'draft'
          @vpage.save!
        end

        Timecop.freeze(@timestamps[1]) do      # rev 2
          @vpage.workflow_state = 'active'
          @vpage.body = 'published by teacher'
          @vpage.user = @teacher
          @vpage.save!
        end

        Timecop.freeze(@timestamps[2]) do      # rev 3
          @vpage.body = 'revised by teacher'
          @vpage.user = @teacher
          @vpage.save!
        end
        @user = @teacher
      end

      before :each do
        user_session(@user)
        get "/courses/#{@course.id}/pages/#{@vpage.url}/revisions"
      end

      it "should focus the revision buttons" do
        driver.execute_script("$('.close-button').focus();")
        f('.close-button').send_keys(:tab)
        all_revisions = ff('.revision-details')
        all_revisions.each do |revision|
          check_element_has_focus(revision)
          revision.send_keys(:tab)
        end
      end

      it "should validate that revision restored is displayed", priority: "1", test_id: 126832 do
        get "/courses/#{@course.id}/pages/#{@vpage.url}"
        f('.icon-settings').click
        expect(f('.icon-clock')).to be_present
        f('.view_page_history').click
        wait_for_ajaximations
        ff(".revision-details")[1].click
        expect(f('.restore-link')).to be_present
        expect_new_page_load do
          f('.restore-link').click
        end
        f('.close-button').click
        wait_for_ajaximations
        f('.icon-edit').click
        f('.btn-primary').click
        wait_for_ajaximations
        expect(f('div.user_content.clearfix.enhanced > p').text).to include 'published by teacher'
      end

      it "keeps focus on clicked revision button" do
        driver.execute_script("$('button.revision-details')[1].focus();")
        ff('button.revision-details')[1].click
        wait_for_ajaximations
        check_element_has_focus(ff('button.revision-details')[1])
      end
    end

    context "Edit Page" do
      before :each do
        get "/courses/#{@course.id}/pages/bar/edit"
        wait_for_ajaximations
      end

      it "should alert user if navigating away from page with unsaved RCE changes", priority: "1", test_id: 267612 do
        add_text_to_tiny("derp")
        fln('Home').click
        expect(driver.switch_to.alert.text).to be_present
        driver.switch_to.alert.accept
      end

      it "should alert user if navigating away from page with unsaved html changes", priority: "1", test_id: 126838 do
        switch_editor_views(wiki_page_body)
        wiki_page_body.send_keys("derp")
        fln('Home').click
        expect(driver.switch_to.alert.text).to be_present
        driver.switch_to.alert.accept
      end

      it "should not save changes when navigating away and not saving", priority: "1", test_id: 267613 do
        switch_editor_views(wiki_page_body)
        wiki_page_body.send_keys('derp')
        fln('Home').click
        expect(driver.switch_to.alert.text).to be_present
        driver.switch_to.alert.accept
        get "/courses/#{@course.id}/pages/bar/edit"
        expect(f('textarea')).not_to include_text('derp')
      end

      it "should alert user if navigating away from page after title change", priority: "1", test_id: 267832 do
        switch_editor_views(wiki_page_body)
        f('.title').clear()
        f('.title').send_keys("derpy-title")
        fln('Home').click
        expect(driver.switch_to.alert.text).to be_present
        driver.switch_to.alert.accept
      end

      it "should insert a file using RCE in the wiki page", priority: "1", test_id: 126673 do
        file = @course.attachments.create!(display_name: 'some test file', uploaded_data: default_uploaded_data)
        file.context = @course
        file.save!
        get "/courses/#{@course.id}/pages/bar/edit"
        insert_file_from_rce
      end
    end
  end

  context "Show Page" do
    before do
      account_model
      course_with_student_logged_in account: @account
    end

    it "should lock page based on module date", priority: "1", test_id: 126845 do
      locked = @course.wiki.wiki_pages.create! title: 'locked'
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
      foo = @course.wiki.wiki_pages.create! title: 'foo'
      bar = @course.wiki.wiki_pages.create! title: 'bar'
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

      foo = @course.wiki.wiki_pages.create! title: 'foo'
      get "/courses/#{@course.id}/pages/foo"

      expect(f("#content")).not_to contain_css('.view_all_pages')

    end
  end

  context "Permissions" do
    before do
      course_with_teacher
    end

    it "displays public content to unregistered users", priority: "1", test_id: 270035 do
      Canvas::Plugin.register(:kaltura, nil, :settings => {'partner_id' => 1, 'subpartner_id' => 2, 'kaltura_sis' => '1'})

      @course.is_public = true
      @course.workflow_state = 'available'
      @course.save!

      title = "foo"
      wikiPage = @course.wiki.wiki_pages.create!(:title => title, :body => "bar")

      get "/courses/#{@course.id}/pages/#{title}"
      expect(f('#wiki_page_show')).not_to be_nil
    end
  end

  context "menu tools" do
    before do
      course_with_teacher_logged_in
      Account.default.enable_feature!(:lor_for_account)

      @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.wiki_page_menu = {:url => "http://www.example.com", :text => "Export Wiki Page"}
      @tool.save!

      @course.wiki.set_front_page_url!('front-page')
      @wiki_page = @course.wiki.front_page
      @wiki_page.workflow_state = 'active'; @wiki_page.save!
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
      title = "foo"
      public_course.wiki.wiki_pages.create!(:title => title, :body => "bar")

      get "/courses/#{public_course.id}/wiki/#{title}"
      expect(f('.user_content')).not_to be_nil
    end
  end

  context "embed video in a Page" do
    before :each do
      course_with_teacher_logged_in :account => @account, :active_all => true
      @course.wiki.wiki_pages.create!(title: 'Page1')
    end

    it "should embed vimeo video in the page", priority: "1", test_id: 126835 do
      get "/courses/#{@course.id}/pages/Page1/edit"
      element = f("#wiki_page_body")
      switch_editor_views(element)
      html_contents = %q(
        <p>
          <iframe style="width: 640px; height: 480px;"
                  title="Instructure - About Us"
                  src="https://player.vimeo.com/video/58752872"
                  width="300"
                  height="150"
                  allowfullscreen="allowfullscreen"
                  webkitallowfullscreen="webkitallowfullscreen"
                  mozallowfullscreen="mozallowfullscreen">
          </iframe>
        </p>
      )
      element.send_keys(html_contents)
      f(".btn-primary").click
      wait_for_ajaximations
      expect(f("iframe")).to be_present
    end
  end
end
