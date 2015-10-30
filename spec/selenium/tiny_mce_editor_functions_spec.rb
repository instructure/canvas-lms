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

      click_tiny_button('Bold')
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
      click_tiny_button('Bold')
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

      click_tiny_button('Italic')
      type_in_tiny('textarea.body', "this should be typed in italics")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 50 characters
      expect(p.body[0..46]).to eq "<p><em>this should be typed in italics</em></p>"
    end

    it "should unitalicize text on wiki description", priority: "1", test_id: 417603 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><em>this should get unitalicized</em></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"
      wait_for_ajaximations

      select_all_wiki
      click_tiny_button('Italic')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 35 characters
      expect(p.body[0..34]).to eq "<p>this should get unitalicized</p>"
    end

    it "should underline text on wiki description", priority: "1", test_id: 285356 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"
      wait_for_ajaximations

      click_tiny_button('Underline')
      type_in_tiny('textarea.body', "this should be typed with underline")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 93 characters
      expect(p.body[0..92]).to eq "<p><span style=\"text-decoration: underline;\">this should be typed with underline</span></p>"
    end

    it "should remove underline from text on wiki description", priority: "1", test_id: 460408 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><span style=\"text-decoration: underline;\">the underline should be removed</span></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"
      wait_for_ajaximations

      select_all_wiki
      click_tiny_button('Underline')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      # To avoid fragility of extra formatting characters being added, I just want the first 38 characters
      expect(p.body[0..37]).to eq "<p>the underline should be removed</p>"
    end
  end
end