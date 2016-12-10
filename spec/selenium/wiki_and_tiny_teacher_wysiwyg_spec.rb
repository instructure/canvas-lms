require_relative 'helpers/wiki_and_tiny_common'

describe "Wiki pages and Tiny WYSIWYG editor features" do
  include_context "in-process server selenium tests"
  include WikiAndTinyCommon

  equation_button_selector = "div[aria-label='Insert Math Equation'] button"

  context "WYSIWYG generic as a teacher" do

    before(:each) do
      course_with_teacher_logged_in
    end

    def wysiwyg_state_setup(text = "1\n2\n3", val: false, html: false)
      get "/courses/#{@course.id}/pages/front-page/edit"
      wait_for_tiny(f("form.edit-form .edit-content"))

      if val == true
        add_text_to_tiny(text)
        validate_link(text)
      else
        if html
          add_html_to_tiny(text)
        else
          add_text_to_tiny_no_val(text)
        end
        select_all_wiki
      end
    end

    it "should type a web address link, save it, "\
    "and validate auto link plugin worked correctly", priority: "1", test_id: 312410 do
      text = "http://www.google.com/"
      wysiwyg_state_setup(text, val: true)
      save_wiki
      validate_link(text)
    end

    it "should remove web address link previously embedded, save it and persist", priority: "1", test_id: 312637 do
      text = "http://www.google.com/"
      wysiwyg_state_setup(text, val: true)

      select_all_wiki
      f('.mce-i-unlink').click
      save_wiki

      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('a')
      end
    end

    it "should switch views and handle html code" do
      wysiwyg_state_setup

      in_frame wiki_page_body_ifr_id do
        expect(ff("#tinymce p").length).to eq 3
      end
    end

    it "should add bullet lists", priority: "1", test_id: 307623 do
      wysiwyg_state_setup

      f(".mce-i-bullist").click
      in_frame wiki_page_body_ifr_id do
        ff('#tinymce li').length == 3
      end
    end

    it "should remove bullet lists", priority: "1", test_id: 535894 do
      text = "<ul><li>1</li><li>2</li><li>3</li></ul>"
      wysiwyg_state_setup(text, html: true)

      f(".mce-i-bullist").click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('li')
      end
    end

    it "should add numbered lists", priority: "1", test_id: 307625 do
      wysiwyg_state_setup

      f('.mce-i-numlist').click
      in_frame wiki_page_body_ifr_id do
        ff('#tinymce li').length == 3
      end
    end

    it "should remove numbered lists", priority: "1", test_id: 537619 do
      text = "<ol><li>1</li><li>2</li><li>3</li></ol>"
      wysiwyg_state_setup(text, html: true)

      f('.mce-i-numlist').click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('li')
      end
    end

    it "should change font color for all selected text", priority: "1", test_id: 285357 do
      wysiwyg_state_setup

      # order-dependent ID of the forecolor button
      f("#mceu_3 .mce-caret").click
      f(".mce-colorbutton-grid div[title='Red']").click
      validate_wiki_style_attrib("color", "rgb(255, 0, 0)", "p span")
    end

    it "should remove font color for all selected text", priority: "1", test_id: 469876 do
      text = "<p><span style=\"color: rgb(255, 0, 0);\">1</span></p>"
      wysiwyg_state_setup(text, html: true)

      # order-dependent ID of the forecolor button
      f("#mceu_3 .mce-caret").click
      f(".mce-colorbutton-grid div[title='No color']").click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('span')
      end
    end

    it "should change background font color", priority: "1", test_id: 298747 do
      wysiwyg_state_setup

      # order-dependent ID of the backcolor button
      f("#mceu_4 .mce-caret").click
      f(".mce-colorbutton-grid div[title='Red']").click
      validate_wiki_style_attrib("background-color", "rgb(255, 0, 0)", "p span")
    end

    it "should remove background font color", priority: "1", test_id: 474035 do
      text = "<p><span style=\"background-color: rgb(255, 0, 0);\">1</span></p>"
      wysiwyg_state_setup(text, html: true)

      # order-dependent ID of the backcolor button
      f("#mceu_4 .mce-caret").click
      f(".mce-colorbutton-grid div[title='No color']").click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('span')
      end
    end

    it "should change font size", priority: "1", test_id: 401375 do
      wysiwyg_state_setup

      # I'm so, so sorry...
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Font Sizes')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'36pt')]]").click
      validate_wiki_style_attrib("font-size", "36pt", "p span")
    end

    it "should change and remove all custom formatting on selected text", priority: "1", test_id: 298748 do
      wysiwyg_state_setup
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Font Sizes')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'36pt')]]").click
      validate_wiki_style_attrib("font-size", "36pt", "p span")
      f(".mce-i-removeformat").click
      validate_wiki_style_attrib_empty("p")
    end

    it 'should insert image using embed image widget', priority: "2", test_id: 397971 do
      wiki_page_tools_file_tree_setup
      fj('.mce-ico.mce-i-image').click
      wait_for_ajaximations
      widget = fj('.ui-dialog.ui-widget.ui-widget-content.ui-corner-all.ui-draggable.ui-dialog-buttons')
      widget.find_element(:link_text, 'Canvas').click
      wait_for_ajaximations
      widget.find_element(:link_text, 'Course files').click
      wait_for_ajaximations
      widget.find_element(:link_text, 'email.png').click
      fj('.btn-primary.ui-button.ui-widget.ui-state-default.ui-corner-all.ui-button-text-only').click
      wait_for_ajaximations
      fj('.btn.btn-primary.submit').click
      wait_for_ajaximations
      main = fj('#main')
      expect(main.find_element(:tag_name, 'img')).to have_attribute('height', '16')
      expect(main.find_element(:tag_name, 'img')).to have_attribute('width', '16')
      expect(main.find_element(:tag_name, 'img')).to have_attribute('alt', 'email.png')
    end

    it "should indent and remove indentation for embedded images" do
      wiki_page_tools_file_tree_setup

      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations

      @image_list.find_element(:css, '.img_link').click

      select_all_wiki
      f('.mce-i-indent').click
      validate_wiki_style_attrib("padding-left", "30px", "p")
      f('.mce-i-outdent').click
      validate_wiki_style_attrib_empty("p")
    end

    it "should indent and remove indentation for text" do
      wysiwyg_state_setup(text = "test")

      f('.mce-i-indent').click
      validate_wiki_style_attrib("padding-left", "30px", "p")
      f('.mce-i-outdent').click
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the left", priority: "1", test_id: 303702 do
      wysiwyg_state_setup(text = "left")
      f(".mce-i-align#{text}").click
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove left align from text", priority: "1", test_id: 526906 do
      text = "<p style=\"text-align: left;\">1</p>"
      wysiwyg_state_setup(text, html: true)

      f(".mce-i-alignleft").click
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the center", priority: "1", test_id: 303698 do
      wysiwyg_state_setup(text = "center")
      f(".mce-i-align#{text}").click
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove center align from text", priority: "1", test_id: 529217 do
      text = "<p style=\"text-align: center;\">1</p>"
      wysiwyg_state_setup(text, html: true)

      f(".mce-i-aligncenter").click
      validate_wiki_style_attrib_empty("p")
    end

    it "should align text to the right", priority: "1", test_id: 303704 do
      wysiwyg_state_setup(text = "right")
      f(".mce-i-align#{text}").click
      validate_wiki_style_attrib("text-align", text, "p")
    end

    it "should remove right align from text", priority: "1", test_id: 530886 do
      text = "<p style=\"text-align: right;\">1</p>"
      wysiwyg_state_setup(text, html: true)

      f(".mce-i-alignright").click
      validate_wiki_style_attrib_empty("p")
    end

    ["right", "center", "left"].each do |setting|
      it "should align images to the #{setting}" do
        wiki_page_tools_file_tree_setup

        f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
        wait_for_ajaximations

        @image_list.find_element(:css, '.img_link').click

        wait_for_ajaximations

        in_frame wiki_page_body_ifr_id do
          f("#tinymce img").click
        end

        f(".mce-i-align#{setting}").click

        if setting == 'center'
          in_frame wiki_page_body_ifr_id do
            expect(f("#tinymce img").attribute('style')).to eq "display: block; margin-left: auto; margin-right: auto;"
          end
        else
          validate_wiki_style_attrib("float", setting, "img")
        end
      end
    end

    it "should make text superscript in rce", priority: "1", test_id: 306263 do
      wysiwyg_state_setup

      f('.mce-i-superscript').click

      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce sup')).to be_displayed
      end
    end

    it "should remove superscript from text in rce", priority: "1", test_id: 532084 do
      skip_if_chrome('fragile in chrome')
      text = "<p><sup>This is my text</sup></p>"
      wysiwyg_state_setup(text, html: true)
      shift_click_button('.mce-i-superscript')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('sup')
      end
    end

    it "should make text subscript in rce", priority: "1", test_id: 306264 do
      wysiwyg_state_setup

      f('.mce-i-subscript').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce sub')).to be_displayed
      end
    end

    it "should remove subscript from text in rce", priority: "1", test_id: 532799 do
      skip_if_chrome('fragile in chrome')
      text = "<p><sub>This is my text</sub></p>"
      wysiwyg_state_setup(text, html: true)

      shift_click_button('.mce-i-subscript')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('sub')
      end
    end

    it "should add and remove links" do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)

      get "/courses/#{@course.id}/pages/front-page/edit"
      wait_for_tiny(f("form.edit-form .edit-content"))

      f('#new_page_link').click
      expect(f('#new_page_name')).to be_displayed
      f('#new_page_name').send_keys(title)
      submit_form("#new_page_drop_down")

      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p a').attribute('href')).to include title
      end

      select_all_wiki
      f('.mce-i-unlink').click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('p a')
      end
    end

    it "should be able to add links to new wiki pages with special characters in title" do
      title = "this/is a weird-a%% page titlé?"

      get "/courses/#{@course.id}/pages/front-page/edit"
      wait_for_tiny(f("form.edit-form .edit-content"))

      f('#new_page_link').click
      expect(f('#new_page_name')).to be_displayed
      f('#new_page_name').send_keys(title)
      submit_form("#new_page_drop_down")

      in_frame wiki_page_body_ifr_id do
        link = f('#tinymce p a')
        expect(link.text).to eq title
      end

      expect_new_page_load { f('form.edit-form button.submit').click }

      expect_new_page_load{ f('.user_content a').click }

      # should bring up the creation page for the new page

      new_title = driver.execute_script("return $('#title')[0].value")
      expect(new_title).to eq title
    end

    it "should change paragraph type to preformatted" do
      text = "<p>This is a sample paragraph</p><p>This is a test</p><p>I E O U A</p>"
      wysiwyg_state_setup(text, html: true)
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Paragraph')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Preformatted')]]").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce pre').length).to eq 3
      end
    end

    it "should change paragraph type to Header 2", priority: "1", test_id: 417581 do
      text = "<p>This is a sample paragraph</p><p>This is a test</p><p>I E O U A</p>"
      wysiwyg_state_setup(text, html: true)
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Paragraph')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Header 2')]]").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce h2').length).to eq 3
      end
    end

    it "should create a table", priority: "1", test_id: 307627 do
      wysiwyg_state_setup
      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Insert table')]]").click
      driver.find_element(:xpath, "//td/a[@data-mce-x='3' and @data-mce-y='3']").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce tr').length).to eq 4
        expect(ff('#tinymce td').length).to eq 16
      end
    end

    it "should edit a table", priority: "1", test_id: 588944 do
      wysiwyg_state_setup
      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Insert table')]]").click
      driver.find_element(:xpath, "//td/a[@data-mce-x='3' and @data-mce-y='3']").click

      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Row')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Insert row after')]]").click

      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Table properties')]]").click
      driver.find_element(:xpath, "//div[text()[contains(.,'Advanced')]]").click
      ff('.mce-placeholder')[1].send_keys("green")
      f('.mce-primary').click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce tr').length).to eq 5
        expect(ff('#tinymce td').length).to eq 20
      end
      validate_wiki_style_attrib("background-color", "green", "table")
    end

    it "should delete a table", priority: "1", test_id: 588945 do
      table = "<table><tbody><tr><td></td><td></td></tr><tr><td></td><td></td></tr></tbody></table>"
      wysiwyg_state_setup(table, html: true)
      f('.mce-i-table').click
      driver.find_element(:xpath, "//span[text()[contains(.,'Delete table')]]").click
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('table')
      end
    end

    it "should add bold text to the rce", priority: "1", test_id: 285128 do
      wysiwyg_state_setup
      f('.mce-i-bold').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce strong')).to be_displayed
      end
    end

    it "should remove bold from text in rce", priority: "1", test_id: 417603 do
      skip_if_chrome('fragile in chrome')
      text = "<p><strong>This is my text</strong></p>"
      wysiwyg_state_setup(text, html: true)
      shift_click_button('.mce-i-bold')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('strong')
      end
    end

    it "should add italic text to the rce", priority: "1", test_id: 285129 do
      wysiwyg_state_setup
      f('.mce-i-italic').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce em')).to be_displayed
      end
    end

    it "should remove italic from text in rce", priority: "1", test_id: 417607 do
      skip_if_chrome('fragile in chrome')
      text = "<p><em>This is my text</em></p>"
      wysiwyg_state_setup(text, html: true)
      shift_click_button('.mce-i-italic')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('em')
      end
    end

    it "should underline text in the rce", priority: "1", test_id: 285356 do
      wysiwyg_state_setup
      f('.mce-i-underline').click
      validate_wiki_style_attrib("text-decoration", "underline", "p span")
    end

    it "should remove underline from text in the rce", priority: "1", test_id: 460408 do
      text = "<p><u>This is my text</u></p>"
      wysiwyg_state_setup(text, html: true)
      shift_click_button('.mce-i-underline')
      in_frame wiki_page_body_ifr_id do
        expect(f("#tinymce")).not_to contain_css('u')
      end
    end

    it "should change text to right-to-left in the rce", priority: "1", test_id: 401335 do
      wysiwyg_state_setup(text = "rtl")
      f(".mce-i-#{text}").click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p').attribute('dir')).to eq text
      end
    end

    it "should remove right-to-left from text in the rce", priority: "1", test_id: 547797 do
      text = "<p dir=\"rtl\">This is my text</p>"
      wysiwyg_state_setup(text, html: true)
      shift_click_button('.mce-i-rtl')
      validate_wiki_style_attrib_empty("p")
    end

    it "should change text to left-to-right in the rce", priority: "1", test_id: 547548 do
      wysiwyg_state_setup(text = "ltr")
      f(".mce-i-#{text}").click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p').attribute('dir')).to eq text
      end
    end

    it "should remove left-to-right from text in the rce", priority: "1", test_id: 550312 do
      text = "<p dir=\"ltr\">This is my text</p>"
      wysiwyg_state_setup(text, html: true)
      shift_click_button('.mce-i-ltr')
      validate_wiki_style_attrib_empty("p")
    end

    it "should not scroll to the top of the page after using an equation button" do
      get "/courses/#{@course.id}/pages/front-page/edit"
      scroll_page_to_bottom

      f(equation_button_selector).click
      wait_for_ajaximations

      misc_tab = f('.mathquill-tab-bar > li:last-child a')
      misc_tab.click
      f('#Misc_tab li:nth-child(35) a').click
      scroll_location = driver.execute_script("return window.scrollY")
      expect(scroll_location).not_to be 0
    end

    it "should add an equation to the rce by using the equation editor", priority: "2", test_id: 397972 do
      skip('this test depends on codecogs.com.  needs to be rewritten: CNVS-33123')
      equation_text = '\\text{yay math stuff:}\\:\\frac{d}{dx}\\sqrt{x}=\\frac{d}{dx}x^{\\frac{1}{2}}=\\frac{1}{2}x^{-\\frac{1}{2}}=\\frac{1}{2\\sqrt{x}}\\text{that. is. so. cool.}'

      get "/courses/#{@course.id}/pages/front-page/edit"
      f(equation_button_selector).click
      wait_for_ajaximations
      expect(f('.mathquill-editor')).to be_displayed
      textarea = f('.mathquill-editor .textarea textarea')
      3.times do
        textarea.send_keys(:backspace)
      end

      # "paste" some text
      driver.execute_script "$('.mathquill-editor .textarea textarea').val('\\\\text{yay math stuff:}\\\\:\\\\frac{d}{dx}\\\\sqrt{x}=').trigger('paste')"
      # make sure it renders correctly (inclding the medium space)
      expect(f('.mathquill-editor').text).to include "yay math stuff: \nd\n\dx\n"

      # type and click a bit
      textarea.send_keys "d/dx"
      textarea.send_keys :arrow_right
      textarea.send_keys "x^1/2"
      textarea.send_keys :arrow_right
      textarea.send_keys :arrow_right
      textarea.send_keys "="
      textarea.send_keys "1/2"
      textarea.send_keys :arrow_right
      textarea.send_keys "x^-1/2"
      textarea.send_keys :arrow_right
      textarea.send_keys :arrow_right
      textarea.send_keys "=1/2"
      textarea.send_keys "\\sqrt"
      textarea.send_keys :space
      textarea.send_keys "x"
      textarea.send_keys :arrow_right
      textarea.send_keys :arrow_right
      textarea.send_keys "\\text that. is. so. cool."
      f('.ui-dialog-buttonset .btn-primary').click
      wait_for_ajax_requests
      in_frame wiki_page_body_ifr_id do
        img = f('.equation_image')
        keep_trying_until { expect(img.attribute('title')).to eq equation_text }

        # currently there's an issue where the equation is double-escaped in the
        # src, though it's correct after the redirect to codecogs. here we just
        # want to confirm we redirect correctly. so when that bug is fixed, this
        # spec should still pass.
        src = f('.equation_image').attribute('src')
        response = Net::HTTP.get_response(URI.parse(src))
        expect(response.code).to eq "302"
        expect(response.header['location']).to include URI.encode(equation_text, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end
    end

    it "should add an equation to the rce by using the equation editor in advanced view" do
      skip('this test depends on codecogs.com.  needs to be rewritten: CNVS-33123')
      equation_text = '\\text{yay math stuff:}\\:\\frac{d}{dx}\\sqrt{x}=\\frac{d}{dx}x^{\\frac{1}{2}}= \\frac{1}{2}x^{-\\frac{1}{2}}=\\frac{1}{2\\sqrt{x}}\\text{that. is. so. cool.}'

      get "/courses/#{@course.id}/pages/front-page/edit"
      f(equation_button_selector).click
      wait_for_ajaximations
      expect(f('.mathquill-editor')).to be_displayed
      f('a.math-toggle-link').click
      wait_for_ajaximations
      expect(f('#mathjax-editor')).to be_displayed
      textarea = f('#mathjax-editor')
      3.times do
        textarea.send_keys(:backspace)
      end

      # "paste" some latex
      driver.execute_script "$('#mathjax-editor').val('\\\\text{yay math stuff:}\\\\:\\\\frac{d}{dx}\\\\sqrt{x}=').trigger('paste')"


      textarea.send_keys "\\frac{d}{dx}x^{\\frac{1}{2}}"
      f('#mathjax-view .mathquill-toolbar a[title="="]').click
      textarea.send_keys "\\frac{1}{2}x^{-\\frac{1}{2}}=\\frac{1}{2\\sqrt{x}}\\text{that. is. so. cool.}"

      f('.ui-dialog-buttonset .btn-primary').click
      wait_for_ajax_requests
      in_frame wiki_page_body_ifr_id do
        img = f('.equation_image')
        keep_trying_until { expect(img.attribute('title')).to eq equation_text }

        # currently there's an issue where the equation is double-escaped in the
        # src, though it's correct after the redirect to codecogs. here we just
        # want to confirm we redirect correctly. so when that bug is fixed, this
        # spec should still pass.
        src = f('.equation_image').attribute('src')
        response = Net::HTTP.get_response(URI.parse(src))
        expect(response.code).to eq "302"
        expect(response.header['location']).to include URI.encode(equation_text, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end
    end

    it 'should not throw page error with invalid LaTex on assignments', priority: "2", test_id: 237012 do
      skip('this test depends on codecogs.com.  needs to be rewritten: CNVS-33123')
      Assignment.new.tap do |a|
        a.id = 1
        a.title = 'test assignment'
        # invalid LaTex characters in alt tag %, ^, &, _, -, ., ?
        a.description = '<p><img class="equation_image" title="\sqrt[2]{3}%^&_-?."
      src="/equation_images/%255Csqrt%255B2%255D%257B3%257D"
      alt="\sqrt[2]{3}%^&_-?."/%^&_-?.></p>'
        a.context_id = "#{@course.id}"
        a.context_type = 'Course'
        a.save!
      end
      get "/courses/#{@course.id}/assignments"
      expect(error_displayed?).to be_falsey
      get "/courses/#{@course.id}/assignments/1"
      expect(error_displayed?).to be_falsey
    end

    it 'should not throw page error with invalid LaTex on discussions', priority: "2", test_id: 237013 do
      skip('this test depends on codecogs.com.  needs to be rewritten: CNVS-33123')
      DiscussionTopic.new.tap do |d|
        d.id = 1
        d.title = 'test discussion'
        # invalid LaTex characters in alt tag %, ^, &, _, -, ., ?
        d.message = '<p><img class="equation_image" title="\sqrt[2]{3}%^&_-?."
      src="/equation_images/%255Csqrt%255B2%255D%257B3%257D"
      alt="\sqrt[2]{3}%^&_-?."/%^&_-?.></p>'
        d.context_id = "#{@course.id}"
        d.context_type = 'Course'
        d.save!
      end
      get "/courses/#{@course.id}/discussion_topics"
      expect(error_displayed?).to be_falsey
      get "/courses/#{@course.id}/discussion_topics/1"
      expect(error_displayed?).to be_falsey
    end

    it "should display record video dialog" do
      stub_kaltura

      get "/courses/#{@course.id}/pages/front-page/edit"

      f("div[aria-label='Record/Upload Media'] button").click
      expect(f('#record_media_tab')).to be_displayed
      f('#media_comment_dialog a[href="#upload_media_tab"]').click
      expect(f('#media_comment_dialog #audio_upload')).to be_displayed
      close_visible_dialog
      expect(f('#media_comment_dialog')).not_to be_displayed
    end
  end
end
