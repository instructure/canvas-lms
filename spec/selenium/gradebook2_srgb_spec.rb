require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "screenreader gradebook" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do
    before(:each) do
      gradebook_data_setup
    end

    it "should switch to srgb", priority: "1", test_id: 209987 do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder").click
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      refresh_page
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      f(".span12 a").click
      expect(f("#change_gradebook_version_link_holder")).to be_displayed
    end

    it "Should show sections in drop-down", priority: "1", test_id: 209989 do
      sections=[]
      2.times do |i|
        sections << @course.course_sections.create!(:name => "other section #{i}")
      end

      get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"

      ui_options = Selenium::WebDriver::Support::Select.new(f("#section_select")).options().map { |option| option.text}
      sections.each do |section|
        expect(ui_options.include? section[:name]).to be_truthy
      end
    end

    it "should focus on accessible elements when setting default grades", priority: "1", test_id: 209991 do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder").click
      refresh_page
      Selenium::WebDriver::Support::Select.new(f("#assignment_select"))
                                          .select_by(:text, 'second assignment')

      # When the modal opens the close button should have focus
      f("#set_default_grade").click
      focused_classes = driver.execute_script('return document.activeElement.classList')
      expect(focused_classes).to include("ui-dialog-titlebar-close")

      # When the modal closes
      # by setting a grade the "set default grade" button should have focus
      f(".button_type_submit").click
      driver.switch_to.alert.accept
      check_element_has_focus(f "#set_default_grade")

      # by the close button the "set default grade" button should have focus
      f("#set_default_grade").click
      fj('.ui-icon-closethick:visible').click
      check_element_has_focus(f "#set_default_grade")
    end

    describe "Download Submissions Button" do
      let!(:change_first_assignment_to_media_recording) do
        @first_assignment.submission_types = "media_recording"
        @first_assignment.save
      end

      let!(:get_screenreader_gradebook) do
        get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
      end

      let(:assignment_selector) do
        Selenium::WebDriver::Support::Select.new(f("#assignment_select"))
      end

      # The Download Submission button should be displayed for online_upload,
      # online_text_entry, online_url, and online_quiz assignments. It should
      # not be displayed for any other types.
      it "is displayed for online assignments" do
        assignment_selector.select_by(:text, 'second assignment')

        expect(f("#submissions_download_button")).to be_present
      end

      it "is not displayed for assignments which are not submitted online" do
        assignment_selector.select_by(:text, @first_assignment.name)

        expect(f("#submissions_download_button")).to_not be_present
      end
    end
  end
end


