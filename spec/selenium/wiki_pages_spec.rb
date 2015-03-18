require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Navigating to wiki pages" do
  include_examples "in-process server selenium tests"

  describe "Navigation" do
    before do
      account_model
      course_with_teacher_logged_in :account => @account
    end

    it "navigates to the wiki pages edit page from the show page" do
      wikiPage = @course.wiki.wiki_pages.create!(:title => "Foo")
      edit_url = edit_course_wiki_page_url(@course, wikiPage)
      get course_wiki_page_path(@course, wikiPage)

      f(".edit-wiki").click

      keep_trying_until { expect(driver.current_url).to eq edit_url }
    end
  end

  describe "Accessibility" do

    def check_header_focus(attribute)
      f("[data-sort-field='#{attribute}']").click()
      wait_for_ajaximations
      check_element_has_focus(f("[data-sort-field='#{attribute}']"))
    end

    before :each do
      account_model
      course_with_teacher_logged_in :account => @account
      @course.wiki.wiki_pages.create!(:title => "Foo")
      @course.wiki.wiki_pages.create!(:title => "Bar")
      @course.wiki.wiki_pages.create!(:title => "Baz")
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

    describe "Publish Cloud" do
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

    describe "Delete Page" do

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
  end


  describe "Permissions" do
    before do
      course_with_teacher
    end

    it "displays public content to unregistered users" do
      Canvas::Plugin.register(:kaltura, nil, :settings => {'partner_id' => 1, 'subpartner_id' => 2, 'kaltura_sis' => '1'})

      @course.is_public = true
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
end
