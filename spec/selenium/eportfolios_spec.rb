require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/eportfolios_common')

describe "eportfolios" do
  include_context "in-process server selenium tests"
  include EportfoliosCommon

  before(:each) do
    course_with_student_logged_in
  end

  it "should create an eportfolio", priority: "1", test_id: 220018 do
    create_eportfolio
  end

  it "should create an eportfolio that is public", priority: "2", test_id: 114348 do
    create_eportfolio(true)
  end

  context "eportfolio created with user" do
    before(:each) do
      eportfolio_model({:user => @user, :name => "student content"})
    end

    it "should start the download of ePortfolio contents", priority: "1", test_id: 115980 do
      get "/eportfolios/#{@eportfolio.id}"
      f(".download_eportfolio_link").click
      expect(f("#export_progress")).to be_displayed
    end

    it "should display the eportfolio wizard", priority: "1", test_id: 220019 do
      get "/eportfolios/#{@eportfolio.id}"
      f(".wizard_popup_link").click
      wait_for_animations
      expect(f("#wizard_box")).to be_displayed
    end

    it "should display and hide eportfolio wizard", priority: "2", test_id: 220020 do
      get "/eportfolios/#{@eportfolio.id}"
      f(".wizard_popup_link").click
      wait_for_animations
      expect(f("#wizard_box")).to be_displayed
      f(".close_wizard_link").click
      wait_for_animations
      expect(f("#wizard_box")).not_to be_displayed
    end

    it "should add a new page", priority: "1", test_id: 115979 do
      page_title = 'I made this page.'
      get "/eportfolios/#{@eportfolio.id}"
      add_eportfolio_page(page_title)
      expect(f("#page_list")).to include_text(page_title)
      get "/eportfolios/#{@eportfolio.id}/category/I_made_this_page"
      wait_for_ajaximations
      expect(pages.last).to include_text(page_title)
      expect(f('#content h2')).to include_text(page_title)
    end

    it "should delete a page", priority: "1", test_id: 3011032 do
      get "/eportfolios/#{@eportfolio.id}"
      # add a few pages
      add_eportfolio_page("page #1")

      # delete page using the settings menu
      page = pages.last
      delete_eportfolio_page(page)

      # The last remaining page should not include the "Delete" action.
      organize_pages
      expect(pages.length).to eq 1
      last_page = pages.last
      last_page.find_element(:css, '.page_settings_menu').click
      expect(last_page).not_to contain_jqcss('.remove_page_link:visible')
    end

    it "should reorder a page", priority: "1", test_id: 3011033 do
      get "/eportfolios/#{@eportfolio.id}"

      # add 3 pages
      (1..3).each do |s|
        add_eportfolio_page("page #{s}")
      end

      # move "page 1" to the bottom
      organize_pages
      page = pages[1]
      move_page_to_bottom(page)
      expect(pages.last.text).to eq page.text
    end


    it "should add a section", priority: "1", test_id: 3011034 do
      get "/eportfolios/#{@eportfolio.id}"
      add_eportfolio_section("test section name")
      expect(sections.last).to include_text("test section name")
    end

    it "should delete a section", priority: "1", test_id: 3011035 do
      get "/eportfolios/#{@eportfolio.id}"

      # add a section
      add_eportfolio_section("section #1")

      # delete section using the settings menu
      section = sections.last
      delete_eportfolio_section(section)

      # The last remaining section should not include the "Delete" action.
      organize_sections
      expect(sections.length).to eq 1
      last_section = sections.last
      last_section.find_element(:css, '.section_settings_menu').click
      expect(last_section).not_to contain_jqcss('.remove_section_link:visible')
    end

    it "should reorder a section", priority: "1", test_id: 3011036 do
      get "/eportfolios/#{@eportfolio.id}"

      # add a 3 sections
      (1..3).each do |s|
        add_eportfolio_section("section #{s}")
      end

      # move "section 1" to the bottom
      organize_sections
      section = sections[1]
      move_section_to_bottom(section)
      expect(sections.last.text).to eq section.text
    end

    it "should edit ePortfolio settings", priority: "2", test_id: 220021 do
      get "/eportfolios/#{@eportfolio.id}"
      f('#section_list_manage .portfolio_settings_link').click
      replace_content f('#edit_eportfolio_form #eportfolio_name'), "new ePortfolio name1"
      f('#edit_eportfolio_form #eportfolio_public').click
      submit_dialog_form('#edit_eportfolio_form')
      wait_for_ajax_requests
      @eportfolio.reload
      expect(@eportfolio.name).to include("new ePortfolio name1")
    end

    it "should have a working flickr search dialog" do
      get "/eportfolios/#{@eportfolio.id}"
      f("#page_list a.page_url").click
      expect(f("#page_list a.page_url")).to be_displayed
      f("#page_sidebar .edit_content_link").click
      expect(f('.add_content_link.add_rich_content_link')).to be_displayed
      f('.add_content_link.add_rich_content_link').click
      expect(f('.mce-container')).to be_displayed
      f("div[aria-label='Embed Image'] button").click
      expect(f('a[href="#tabFlickr"]')).to be_displayed
      f('a[href="#tabFlickr"]').click
      expect(f('form.FindFlickrImageView')).to be_displayed
    end

    it "should not have new section option when adding submission" do
      @assignment = @course.assignments.create!(
        :title => "hardest assignment ever",
        :submission_types => "online_url,online_upload"
      )
      @submission = @assignment.submit_homework(@student)
      @submission.submission_type = "online_url"
      @submission.save!
      get "/eportfolios/#{@eportfolio.id}"
      f(".submission").click
      expect(f("#add_submission_form")).to be_displayed
      expect(ff('#category_select option').map(&:text)).not_to include("New Section")
    end


    it "should delete the ePortfolio", priority: "2", test_id: 114350 do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      f(".delete_eportfolio_link").click
      wait_for_ajaximations
      expect(f("#delete_eportfolio_form")).to be_displayed
      submit_form("#delete_eportfolio_form")
      f("#wrapper .eportfolios").click
      expect(f("#content")).not_to contain_css("#portfolio_#{@eportfolio.id}")
      expect(f("#whats_an_eportfolio .add_eportfolio_link")).to be_displayed
      expect(Eportfolio.first.workflow_state).to eq 'deleted'
    end

    it "should click on all wizard options and validate the text" do
      get "/eportfolios/#{@eportfolio.id}"
      f('.wizard_popup_link').click
      wait_for_ajaximations
      options_text = {
        '.information_step' => "ePortfolios are a place to demonstrate your work.",
        '.portfolio_step' => "Sections are listed along the left side of the window",
        '.section_step' => "Sections have multiple pages",
        '.adding_submissions' => "You may have noticed at the bottom of this page is a list of recent submissions",
        '.edit_step' => "To change the settings for your ePortfolio",
        '.publish_step' => "Ready to get started?"
      }
      options_text.each do |option, text|
        f(option).click
        expect(f('.wizard_details .details')).to include_text text
      end
    end

    it "should be viewable with a shared link" do
      destroy_session
      get "/eportfolios/#{@eportfolio.id}?verifier=#{@eportfolio.uuid}"
      expect(f('#content h2').text).to eq "page"
    end
  end
end

describe "eportfolios file upload" do
  include_context "in-process server selenium tests"

  before do
    @password = "asdfasdf"
    @student = user_with_pseudonym :active_user => true,
                                   :username => "student@example.com",
                                   :password => @password
    @student.save!
    @course = course_factory :active_course => true
    @course.enroll_student(@student).accept!
    @course.reload
    eportfolio_model({:user => @user, :name => "student content"})
  end

  it "should upload a file" do
    create_session(@student.pseudonym)
    get "/eportfolios/#{@eportfolio.id}"
    _filename, fullpath, _data = get_file("testfile5.zip")
    expect_new_page_load { f(".icon-arrow-right").click }
    f("#right-side .edit_content_link").click
    wait_for_ajaximations
    f('.add_file_link').click
    wait_for_animations
    fj(".file_upload:visible").send_keys(fullpath)
    wait_for_ajaximations
    f(".upload_file_button").click
    submit_form(".form_content")
    download = fj("a.eportfolio_download:visible")
    expect(download).to be_displayed
    expect(download).to have_attribute("href", /files/)
    # cannot test downloading the file, will check in the future
    # check_file(download)
  end
end
