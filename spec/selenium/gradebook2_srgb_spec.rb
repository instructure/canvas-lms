require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "screenreader gradebook" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do
    before(:each) do
      gradebook_data_setup
    end

    it "should switch to srgb" do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder .ellipsible").click
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      refresh_page
      expect(f("#not_right_side")).to include_text("Gradebook: Individual View")
      f(".span12 a").click
      expect(f("#change_gradebook_version_link_holder .ellipsible")).to be_displayed
    end

    it "Should show sections in drop-down" do
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

    it "should focus on accessible elements when setting default grades" do
      get "/courses/#{@course.id}/gradebook"
      f("#change_gradebook_version_link_holder .ellipsible").click
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
  end
end


