require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Tiny MCE editor functions" do
  include_context "in-process server selenium tests"

  context "as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
    end

    it "should bold text on wiki description", priority: "1", test_id: 285128 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"
      wait_for_ajaximations

      f("div[aria-label='Bold'] button").send_keys :shift # no content but gives the bold button focus
      f("div[aria-label='Bold'] button").click
      type_in_tiny('textarea.body', "this should be typed in as bold")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 55 characters
      expect(p.body[0..54]).to eq "<p><strong>this should be typed in as bold</strong></p>"
    end

    it "should unbold text on wiki description", priority: "1", test_id: 417603 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><strong>this should get unbolded</strong></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"
      wait_for_ajaximations

      select_all_wiki
      f("div[aria-label='Bold'] button").send_keys :shift # no content but gives the bold button focus
      f("div[aria-label='Bold'] button").click
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 31 characters
      expect(p.body[0..30]).to eq "<p>this should get unbolded</p>"
    end

    it "should italicize text on wiki description", priority: "1", test_id: 285129 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"
      wait_for_ajaximations

      f("div[aria-label='Italic'] button").send_keys :shift # no content but gives the italic button focus
      f("div[aria-label='Italic'] button").click
      type_in_tiny('textarea.body', "this should be typed in italics")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 50 characters
      expect(p.body[0..46]).to eq "<p><em>this should be typed in italics</em></p>"
    end

    it "should unbold text on wiki description", priority: "1", test_id: 417603 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><em>this should get unitalicized</em></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"
      wait_for_ajaximations

      select_all_wiki
      f("div[aria-label='Italic'] button").send_keys :shift # no content but gives the italic button focus
      f("div[aria-label='Italic'] button").click
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 31 characters
      expect(p.body[0..34]).to eq "<p>this should get unitalicized</p>"
    end
  end
end