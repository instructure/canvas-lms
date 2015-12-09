require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Tiny MCE editor functions" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon

  context "as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
    end

    it "should bold text on wiki description", priority: "1", test_id: 285128 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Bold')
      type_in_tiny('textarea.body', "this should be typed in as bold")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..54]).to eq "<p><strong>this should be typed in as bold</strong></p>"
    end

    it "should unbold text on wiki description", priority: "1", test_id: 417603 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><strong>this should get unbolded</strong></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Bold')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..30]).to eq "<p>this should get unbolded</p>"
    end

    it "should italicize text on wiki description", priority: "1", test_id: 285129 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Italic')
      type_in_tiny('textarea.body', "this should be typed in italics")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..46]).to eq "<p><em>this should be typed in italics</em></p>"
    end

    it "should unitalicize text on wiki description", priority: "1", test_id: 417603 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><em>this should get unitalicized</em></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Italic')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..34]).to eq "<p>this should get unitalicized</p>"
    end

    it "should underline text on wiki description", priority: "1", test_id: 285356 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Underline')
      type_in_tiny('textarea.body', "this should be typed with underline")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..92]).to eq "<p><span style=\"text-decoration: underline;\">this should be typed with underline</span></p>"
    end

    it "should remove underline from text on wiki description", priority: "1", test_id: 460408 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><span style=\"text-decoration: underline;\">the underline should be removed</span></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Underline')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..37]).to eq "<p>the underline should be removed</p>"
    end

    it "should change text color on wiki description", priority: "1", test_id: 285357 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_dropdown('color', '#800080')
      type_in_tiny('textarea.body', "this should be typed in purple")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..75]).to eq "<p><span style=\"color: #800080;\">this should be typed in purple</span></p>"
    end

    it "should remove text color on wiki description", priority: "1", test_id: 469876 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><span style=\"color: #800080;\">the purple should be changed to black</span></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_dropdown('color', 'transparent')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..43]).to eq "<p>the purple should be changed to black</p>"
    end

    it "should change background color on wiki description", priority: "1", test_id: 298747 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_dropdown('bgcolor', '#33CCCC')
      type_in_tiny('textarea.body', "the background should be turquoise")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..90]).to eq "<p><span style=\"background-color: #33cccc;\">the background should be turquoise</span></p>"
    end

    it "should remove background color on wiki description", priority: "1", test_id: 474035 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><span style=\"background-color: #33cccc;\">the turquoise should be removed</span></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_dropdown('bgcolor', 'transparent')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..37]).to eq "<p>the turquoise should be removed</p>"
    end

    it "should clear formatting on wiki description", priority: "1", test_id: 298748 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><span style=\"text-decoration: underline; color: #800080; background-color: #33cccc;\">underline and purple and turquoise should be removed</span></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Clear formatting')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..58]).to eq "<p>underline and purple and turquoise should be removed</p>"
    end

    it "should align text left on wiki description", priority: "1", test_id: 303702 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Align left')
      type_in_tiny('textarea.body', "this should be aligned left")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..61]).to eq "<p style=\"text-align: left;\">this should be aligned left</p>"
    end

    it "should remove left alignment from text on wiki description", priority: "1", test_id: 526906 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p style=\"text-align: left;\">left alignment should be removed</p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Align left')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..38]).to eq "<p>left alignment should be removed</p>"
    end

    it "should align text center on wiki description", priority: "1", test_id: 303698 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Align center')
      type_in_tiny('textarea.body', "this should be aligned center")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..66]).to eq "<p style=\"text-align: center;\">this should be aligned center</p>"
    end

    it "should remove center alignment from text on wiki description", priority: "1", test_id: 529217 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p style=\"text-align: center;\">center alignment should be removed</p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Align center')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..40]).to eq "<p>center alignment should be removed</p>"
    end

    it "should align text right on wiki description", priority: "1", test_id: 303704 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Align right')
      type_in_tiny('textarea.body', "this should be aligned right")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..64]).to eq "<p style=\"text-align: right;\">this should be aligned right</p>"
    end

    it "should remove right alignment from text on wiki description", priority: "1", test_id: 530886 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p style=\"text-align: right;\">right alignment should be removed</p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Align right')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..39]).to eq "<p>right alignment should be removed</p>"
    end

    it "should make text superscript on wiki description", priority: "1", test_id: 306263 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Superscript')
      type_in_tiny('textarea.body', "this should be in superscript")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..46]).to eq "<p><sup>this should be in superscript</sup></p>"
    end

    it "should remove superscript from text on wiki description", priority: "1", test_id: 532084 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><sup>this should have superscript removed</sup></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Superscript')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..42]).to eq "<p>this should have superscript removed</p>"
    end

    it "should make text subscript on wiki description", priority: "1", test_id: 306264 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Subscript')
      type_in_tiny('textarea.body', "this should be in subscript")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..44]).to eq "<p><sub>this should be in subscript</sub></p>"
    end

    it "should remove subscript from text on wiki description", priority: "1", test_id: 532799 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><sub>this should have subscript removed</sub></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Subscript')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..40]).to eq "<p>this should have subscript removed</p>"
    end

    it "should make an unordered list on wiki description", priority: "1", test_id: 307623 do
      p = create_wiki_page("test_page", false, "public")
      num_list_items = 4
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Bullet list')
      type_tiny_list(num_list_items)
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      comparison = create_formatted_list(num_list_items, "unordered")
      expect(p.body[0..comparison.length]).to eq comparison
    end

    it "should remove text from an unordered list on wiki description", priority: "1", test_id: 535894 do
      p = create_wiki_page("test_page", false, "public")
      num_list_items = 4
      p.body = create_formatted_list(num_list_items,"unordered")
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Bullet list')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      comparison = create_unformatted_list(num_list_items)
      expect(p.body[0..comparison.length]).to eq comparison
    end

    it "should make a numbered list on wiki description", priority: "1", test_id: 307625 do
      p = create_wiki_page("test_page", false, "public")
      num_list_items = 4
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Numbered list')
      type_tiny_list(num_list_items)
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      comparison = create_formatted_list(num_list_items, "ordered")
      expect(p.body[0..comparison.length]).to eq comparison
    end

    it "should remove text from a numbered list on wiki description", priority: "1", test_id: 537619 do
      p = create_wiki_page("test_page", false, "public")
      num_list_items = 4
      p.body = create_formatted_list(num_list_items,"ordered")
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Numbered list')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      comparison = create_unformatted_list(num_list_items)
      expect(p.body[0..comparison.length]).to eq comparison
    end

    it "should add a link to text on wiki description", priority: "1", test_id: 312410 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p>this text should link to instructure homepage</p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Link to URL')
      f("#instructure_link_prompt_form_input").send_keys("http://www.instructure.com")
      submit_form(f("#instructure_link_prompt_form"))
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..136]).to eq "<p><a id=\"\" class=\"\" title=\"\" href=\"http://www.instructure.com\" target=\"\">this text should link to instructure homepage</a></p>"
    end

    it "should remove a link from text on wiki description", priority: "1", test_id: 312637 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p><a id=\"\" class=\"\" title=\"\" href=\"http://www.instructure.com\" target=\"\">this text "\
          "should no longer be linked</a></p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      select_all_wiki
      click_tiny_button('Remove link')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..42]).to eq "<p>this text should no longer be linked</p>"
    end

    it "should make text run right-to-left on wiki description", priority: "1", test_id: 401335 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Right to left')
      type_in_tiny('textarea.body', "this should run right to left")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..47]).to eq "<p dir=\"rtl\">this should run right to left</p>"
    end

    it "should remove right-to-left from text on wiki description", priority: "1", test_id: 547797 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p dir=\"rtl\">this should have right to left removed</p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Right to left')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..44]).to eq "<p>this should have right to left removed</p>"
    end

    it "should make text run left-to-right on wiki description", priority: "1", test_id: 547548 do
      p = create_wiki_page("test_page", false, "public")
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Left to right')
      type_in_tiny('textarea.body', "this should run left to right")
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..47]).to eq "<p dir=\"ltr\">this should run left to right</p>"
    end

    it "should remove left-to-right from text on wiki description", priority: "1", test_id: 550312 do
      p = create_wiki_page("test_page", false, "public")
      p.body = "<p dir=\"ltr\">this should have left to right removed</p>"
      p.save!
      get "/courses/#{@course.id}/pages/#{p.title}/edit"

      click_tiny_button('Left to right')
      f("form.edit-form button.submit").click
      wait_for_ajaximations

      p.reload
      expect(p.body[0..44]).to eq "<p>this should have left to right removed</p>"
    end
  end
end