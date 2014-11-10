require File.expand_path(File.dirname(__FILE__) + '/common')

describe "eportfolios" do
  include_examples "in-process server selenium tests"

  def create_eportfolio(is_public = false)
    get "/dashboard/eportfolios"
    f(".add_eportfolio_link").click
    wait_for_animations
    replace_content f("#eportfolio_name"), "student content"
    f("#eportfolio_public").click if is_public
    expect_new_page_load { f("#eportfolio_submit").click }
    eportfolio = Eportfolio.find_by_name("student content")
    expect(eportfolio).to be_valid
    expect(eportfolio.public).to be_truthy if is_public
    expect(f('#content h2')).to include_text(I18n.t('headers.welcome', "Welcome to Your ePortfolio"))
  end

  def entry_verifier(opts={})
    @eportfolio.eportfolio_entries.count > 0
    entry= @eportfolio.eportfolio_entries.first
    if opts[:section_type]
      expect(entry.content.first[:section_type]).to eq opts[:section_type]
    end

    if opts[:content]
      expect(entry.content.first[:content]).to include_text(opts[:content])
    end
  end

  before (:each) do
    course_with_student_logged_in
  end

  it "should create an eportfolio" do
    create_eportfolio
  end

  it "should create an eportfolio that is public" do
    create_eportfolio(true)
  end

  context "eportfolio created with user" do
    before(:each) do
      eportfolio_model({:user => @user, :name => "student content"})
    end

    it "should start the download of ePortfolio contents" do
      get "/eportfolios/#{@eportfolio.id}"
      f(".download_eportfolio_link").click
      keep_trying_until { expect(f("#export_progress")).to be_displayed }
    end

    it "should display and hide eportfolio wizard" do
      get "/eportfolios/#{@eportfolio.id}"
      f(".wizard_popup_link").click
      wait_for_animations
      expect(f("#wizard_box")).to be_displayed
      f(".close_wizard_link").click
      wait_for_animations
      expect(f("#wizard_box")).not_to be_displayed
    end

    it "should add a section" do
      get "/eportfolios/#{@eportfolio.id}"
      f("#section_list_manage .manage_sections_link").click
      f("#section_list_manage .add_section_link").click
      f("#section_list input").send_keys("test section name", :return)
      wait_for_ajax_requests
      expect(fj("#section_list li:last-child .name").text).to eq "test section name"
    end

    it "should edit ePortfolio settings" do
      get "/eportfolios/#{@eportfolio.id}"
      f('#section_list_manage .portfolio_settings_link').click
      replace_content f('#edit_eportfolio_form #eportfolio_name'), "new ePortfolio name"
      f('#edit_eportfolio_form #eportfolio_public').click
      submit_form('#edit_eportfolio_form')
      wait_for_ajax_requests
      @eportfolio.reload
      expect(@eportfolio.name).to eq "new ePortfolio name"
    end

    it "should have a working flickr search dialog" do
      get "/eportfolios/#{@eportfolio.id}"
      f("#page_list a.page_url").click
      keep_trying_until {
        expect(f("#page_list a.page_url")).to be_displayed
      }
      f("#page_sidebar .edit_content_link").click
      keep_trying_until {
        expect(f('.add_content_link.add_rich_content_link')).to be_displayed
      }
      f('.add_content_link.add_rich_content_link').click
      wait_for_tiny(f('textarea.edit_section'))
      keep_trying_until {
        expect(f('a.mce_instructure_image')).to be_displayed
      }
      f('a.mce_instructure_image').click
      keep_trying_until {
        expect(f('a[href="#tabFlickr"]')).to be_displayed
      }
      f('a[href="#tabFlickr"]').click
      keep_trying_until {
        expect(f('form.FindFlickrImageView')).to be_displayed
      }
    end

    it "should not have new section option when adding submission" do
      @assignment = @course.assignments.create!(:title => "hardest assignment ever", :submission_types => "online_url,online_upload")
      @submission = @assignment.submit_homework(@student)
      @submission.submission_type = "online_url"
      @submission.save!
      get "/eportfolios/#{@eportfolio.id}"
      f(".submission").click
      expect(f("#add_submission_form")).to be_displayed
      expect(ff('#category_select option').map(&:text)).not_to include("New Section")
    end


    it "should delete the ePortfolio" do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      f(".delete_eportfolio_link").click
      submit_form("#delete_eportfolio_form")
      fj("#wrapper-container .eportfolios").click
      keep_trying_until {
        expect(f("#whats_an_eportfolio .add_eportfolio_link")).to be_displayed
        expect(f("#portfolio_#{@eportfolio.id}")).to be_nil
      }
      expect(Eportfolio.first.workflow_state).to eq 'deleted'
    end

    describe "add content box" do
      before(:each) do
        @assignment = @course.assignments.create(:name => 'new assignment')
        @assignment.submit_homework(@student)
        attachment_model(:context => @student)
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

    it "should click on all wizard options and validate the text" do
      get "/eportfolios/#{@eportfolio.id}"
      f('.wizard_popup_link').click
      wait_for_ajaximations
      options_text = {'.information_step' => "ePortfolios are a place to demonstrate your work.",
                      '.portfolio_step' => "Sections are listed along the left side of the window",
                      '.section_step' => "Sections have multiple pages",
                      '.adding_submissions' => "You may have noticed at the bottom of this page is a list of recent submissions",
                      '.edit_step' => "To change the settings for your ePortfolio",
                      '.publish_step' => "Ready to get started?"}
      options_text.each do |option, text|
        f(option).click
        wait_for_animations
        expect(f('.wizard_details .details').text).to include_text text
      end
    end

    it "should be viewable with a shared link" do
      destroy_session false
      get "/eportfolios/#{@eportfolio.id}?verifier=#{@eportfolio.uuid}"
      expect(f('#content h2').text).to eq "page"
    end
  end
end

describe "eportfolios file upload" do
  include_examples "in-process server selenium tests"

  before (:each) do
    @password = "asdfasdf"
    @student = user_with_pseudonym :active_user => true,
                                   :username => "student@example.com",
                                   :password => @password
    @student.save!
    @course = course :active_course => true
    @course.enroll_student(@student).accept!
    @course.reload
    eportfolio_model({:user => @user, :name => "student content"})
  end

  it "should upload a file" do
    create_session(@student.pseudonym, false)
    get "/eportfolios/#{@eportfolio.id}"
    filename, fullpath, data = get_file("testfile5.zip")
    expect_new_page_load { f(".icon-arrow-right").click }
    f("#right-side .edit_content_link").click
    wait_for_ajaximations
    driver.execute_script "$('.add_file_link').click()"
    fj(".file_upload:visible").send_keys(fullpath)
    fj(".upload_file_button").click
    wait_for_ajaximations
    submit_form(".form_content")
    wait_for_ajax_requests
    download = f("a.eportfolio_download")
    expect(download).to be_displayed
    expect(download.attribute('href')).not_to be_nil
    #cannot test downloading the file, will check in the future
    #check_file(download)
  end
end
