require File.expand_path(File.dirname(__FILE__) + '/common')

describe "Navigating to wiki pages" do
  it_should_behave_like "in-process server selenium tests"

  describe "Navigation" do
    before do
      course_with_teacher_logged_in
    end

    it "navigates to the wiki pages edit page from the show page" do
      wikiPage = @course.wiki.wiki_pages.create!(:title => "Foo")
      edit_url = course_edit_named_page_url(@course, wikiPage)
      get course_named_page_path(@course, wikiPage)
      f(".edit-wiki").click
      wait_for_dom_ready do
        check_domready.should be_true
        driver.current_url.should == edit_url
      end
    end
  end
end
