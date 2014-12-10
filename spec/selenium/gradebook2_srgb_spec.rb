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
  end
end


