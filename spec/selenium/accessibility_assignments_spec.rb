require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/accessibility/accessibility_common')

describe "accessibility assignments", priority: "2" do
  include_context "in-process server selenium tests"
  before(:each) do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/assignments"
  end


  it "should be accessible" do
    val_image_alt_tags_not_empty
    val_input_alt_tags_present
    #pending('not passing') val_input_alt_tags_not_empty
    val_image_alt_tags_max_length
    val_page_title_present
    val_page_title_not_empty
    val_html_lang_attribute_present
    val_html_lang_attribute_not_empty
    #pending('not passing') val_h1_populated
    #pending('not passing') val_link_name_uniqueness
    #pending('not passing')val_all_tables_have_heading
  end
end

