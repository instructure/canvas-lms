require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/eportfolios_common')

describe "add content box" do
  include_examples "in-process server selenium tests"

  before(:each) do
    course_with_student_logged_in
    @assignment = @course.assignments.create(:name => 'new assignment')
    @assignment.submit_homework(@student)
    attachment_model(:context => @student)
    eportfolio_model({:user => @user, :name => "student content"})
    get "/eportfolios/#{@eportfolio.id}"
    expect_new_page_load { f(".icon-arrow-right").click }
    f("#right-side .edit_content_link").click
    wait_for_ajaximations
  end

  it "should click on the How Do I..? button" do
    f(".wizard_popup_link").click
    keep_trying_until { expect(f("#wizard_box .wizard_options_list")).to be_displayed }
  end

  it "should add rich text content" do
    f(".add_rich_content_link").click
    type_in_tiny "textarea", "hello student"
    submit_form(".form_content")
    wait_for_ajax_requests
    entry_verifier ({:section_type => "rich_text", :content => "hello student"})
    expect(f("#page_content .section_content")).to include_text("hello student")
  end

  it "should add a user file" do
    keep_trying_until { expect(f('.add_file_link')).to be_displayed } 
    f('.add_file_link').click
    wait_for_ajaximations
    fj('.file_list:visible .sign:visible').click
    wait_for_ajaximations# my files
    file = fj('li.file .text:visible')
    expect(file).to include_text @attachment.filename
    wait_for_ajaximations
    file.click
    f('.upload_file_button').click
    wait_for_ajaximations
    download = fj('.eportfolio_download:visible')
    expect(download).to be_present
    expect(download).to include_text @attachment.filename
    submit_form('.form_content')
    wait_for_ajaximations
    expect(f('.section.read_only')).to include_text @attachment.filename
    refresh_page
    expect(f('.section.read_only')).to include_text @attachment.filename
  end

  context "adding html content" do
    before(:each) do
      @html_content="<b>student</b>"
      f(".add_html_link").click
      wait_for_ajaximations
      f("#edit_page_section_1").send_keys(@html_content)
    end

    def add_html
      submit_form(".form_content")
      #driver.execute_script("$('.form_content .btn-primary').click()")
      wait_for_ajaximations
      expect(f(".section_content b").text).to eq "student"
      entry_verifier ({:section_type => "html", :content => @html_content})
    end

    def put_comment_in_html
      allow_comments = "#eportfolio_entry_allow_comments"
      f(allow_comments).click
      expect(is_checked(allow_comments)).to be_truthy
      comment_public="#eportfolio_entry_show_comments"
      f(comment_public).click
      expect(is_checked(comment_public)).to be_truthy
      submit_form(".form_content")
      wait_for_ajaximations
      expect(f(".section_content b").text).to eq "student"
      entry_verifier ({:section_type => "html", :content => @html_content})
      refresh_page
      f("#page_comment_message").send_keys("hi student")
      submit_form("#add_page_comment_form")
      wait_for_ajax_requests
      expect(f("#page_comments .message")).to include_text("hi student")
      expect(@eportfolio_entry.page_comments[0].message).to eq "hi student"
    end

    it "should verify that the html is there" do
      add_html
    end

    it "should put comment in html" do
      put_comment_in_html
    end

    it "should delete the html content" do
      add_html
      f("#right-side .edit_content_link").click
      hover_and_click("#page_section_1 .delete_page_section_link")
      try_to_close_modal
      wait_for_ajaximations
      submit_form(".form_content")
      wait_for_ajaximations
      expect(@eportfolio.eportfolio_entries.first.content[0]).to eq "No Content Added Yet"
      expect(f("#edit_page_section_1")).to be_nil
    end

    it "should delete html comment" do
      put_comment_in_html
      PageComment.count>0
      f(".delete_comment_link").click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f("#page_comments .message")).to be_nil
      expect(PageComment.count).to eq 0
    end
  end

  it "should add a course submission" do
    skip('fragile')
    f(".add_submission_link").click
    wait_for_ajaximations
    keep_trying_until { expect(f(".submission_list")).to include_text(@assignment.title) }
    f(".select_submission_button").click
    submit_form(".form_content")
  end
end