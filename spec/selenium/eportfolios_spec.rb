require File.expand_path(File.dirname(__FILE__) + '/common')

describe "eportfolios" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_student_logged_in
  end

  it "should create an eportfolio" do
    get "/dashboard/eportfolios"

    driver.find_element(:css, ".add_eportfolio_link").click
    wait_for_animations
    expect_new_page_load { driver.find_element(:id, "eportfolio_submit").click }
    driver.find_element(:css, '#content h2').should include_text(I18n.t('headers.welcome', "Welcome to Your ePortfolio"))
  end

  it "should display and hide eportfolio wizard" do
    eportfolio_model({:user => @user})
    get "/eportfolios/#{@eportfolio.id}"

    driver.find_element(:css, '.wizard_popup_link').click
    wait_for_animations
    driver.find_element(:id, 'wizard_box').should be_displayed
    driver.find_element(:css, '.close_wizard_link').click
    wait_for_animations
    driver.find_element(:id, 'wizard_box').should_not be_displayed
  end

  it "should add a section" do
    eportfolio_model({:user => @user})
    get "/eportfolios/#{@eportfolio.id}"

    driver.find_element(:css, '#section_list_manage .manage_sections_link').click
    driver.find_element(:css, '#section_list_manage .add_section_link').click
    driver.find_element(:css, '#section_list input').send_keys("test section name")
    driver.execute_script('$("#section_list input").blur();')
    wait_for_ajax_requests
    find_with_jquery('#section_list li:last-child .name').text.should == "test section name"
  end

  it "should edit ePortfolio settings" do
    eportfolio_model({:user => @user})
    get "/eportfolios/#{@eportfolio.id}"

    driver.find_element(:css, '#section_list_manage .portfolio_settings_link').click
    driver.find_element(:css, '#edit_eportfolio_form #eportfolio_name').clear
    driver.find_element(:css, '#edit_eportfolio_form #eportfolio_name').send_keys("new ePortfolio name")
    driver.find_element(:css, '#edit_eportfolio_form #eportfolio_public').click
    driver.find_element(:id, 'edit_eportfolio_form').submit
    wait_for_ajax_requests
    @eportfolio.reload
    @eportfolio.name.should == "new ePortfolio name"
  end

  it "should have a working flickr search dialog" do
    skip_if_ie("Out of memory / stack overflow")
    eportfolio_model({:user => @user})
    get "/eportfolios/#{@eportfolio.id}"

    keep_trying_until {
      driver.find_element(:css, "#page_list a.page_url").click
      driver.find_element(:css, "#page_sidebar .edit_content_link")
    }.click
    driver.find_element(:css, '.add_content_link.add_rich_content_link').click
    wait_for_tiny(driver.find_element(:css, 'textarea.edit_section'))
    driver.find_element(:css, "img[alt='Embed Image']").click
    driver.find_element(:css, ".flickr_search_link").click
    driver.find_element(:id, "instructure_image_search").should_not be_nil
  end

  it "should create rich content for eportfolio" do
    eportfolio_model({:user => @user})
    get "/eportfolios/#{@eportfolio.id}"

    keep_trying_until {
      driver.find_element(:css, "#page_list a.page_url").click
      driver.find_element(:css, "#page_sidebar .edit_content_link")
    }.click
    driver.find_element(:css, '.add_content_link.add_rich_content_link').click

    #send text to tiny
    first_text = 'This is my eportfolio'
    type_in_tiny 'textarea.edit_section', first_text

    driver.find_element(:id, 'edit_page_form').submit
    driver.find_element(:css, '#page_content .section_content').should include_text(first_text)
  end

  it "should add a submission to a new section" do
    pending "BUG 6345 - Eportfolio Error When Adding New Section" do
      eportfolio_model({:user => @user})
      @assignment = @course.assignments.create!(:title => "hardest assignment ever", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@student)
      @submission.submission_type = "online_url"
      @submission.save!

      get "/eportfolios/#{@eportfolio.id}"
      driver.find_element(:css, '.submission').click
      submission_form = driver.find_element(:id, 'add_submission_form')
      submission_form.should be_displayed
      click_option('#add_submission_form #category_select', 'New Category')
      submission_form.submit
      driver.find_element(:css, '.error_text').should_not be_displayed
      EportfolioEntry.count.should == 1
    end
  end
end
