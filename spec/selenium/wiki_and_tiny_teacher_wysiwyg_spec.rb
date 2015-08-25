require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor features" do
  include_context "in-process server selenium tests"

  equation_button_selector = "div[aria-label='Insert Math Equation'] button"

  context "WYSIWYG generic as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    def wysiwyg_state_setup(text = "<p>1</p><p>2</p><p>3</p>", val = false)
      get "/courses/#{@course.id}/pages/front-page/edit"
      wait_for_tiny(keep_trying_until { f("form.edit-form .edit-content") })

      if val == true
        add_text_to_tiny(text)
        validate_link(text)
      else
        add_text_to_tiny_no_val(text)
        select_all_wiki
      end
    end

    it "should type a web address link, save it, and validate auto link plugin worked correctly" do
      text = "http://www.google.com/"
      wysiwyg_state_setup(text, val = true)
      save_wiki
      validate_link(text)
    end

    it "should remove web address link previously embedded, save it and persist" do
      text = "http://www.google.com/"
      wysiwyg_state_setup(text, val = true)

      select_all_wiki
      f('.mce-i-unlink').click
      save_wiki

      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce a')).to be_nil
      end
    end

    it "should switch views and handle html code" do
      wysiwyg_state_setup

      in_frame wiki_page_body_ifr_id do
        expect(ff("#tinymce p").length).to eq 3
      end
    end

    it "should add and remove bullet lists" do
      wysiwyg_state_setup
      bullist_selector = ".mce-i-bullist"

      f(bullist_selector).click
      in_frame wiki_page_body_ifr_id do
        ff('#tinymce li').length == 3
      end

      f(bullist_selector).click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce li')).to be_nil
      end
    end

    it "should add and remove numbered lists" do
      wysiwyg_state_setup
      numlist_selector = '.mce-i-numlist'

      f(numlist_selector).click
      in_frame wiki_page_body_ifr_id do
        ff('#tinymce li').length == 3
      end

      f(numlist_selector).click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce li')).to be_nil
      end
    end

    it "should change font color for all selected text" do
      wysiwyg_state_setup

      # order-dependent ID of the forecolor button
      f("#mceu_3 .mce-caret").click
      f(".mce-colorbutton-grid div[title='Red']").click
      validate_wiki_style_attrib("color", "rgb(255, 0, 0)", "p span")
    end

    it "should change background font color" do
      wysiwyg_state_setup

      # order-dependent ID of the backcolor button
      f("#mceu_4 .mce-caret").click
      f(".mce-colorbutton-grid div[title='Red']").click
      validate_wiki_style_attrib("background-color", "rgb(255, 0, 0)", "p span")
    end

    it "should change font size" do
      wysiwyg_state_setup

      # I'm so, so sorry...
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Font Sizes')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'36pt')]]").click
      validate_wiki_style_attrib("font-size", "36pt", "p span")
    end

    it "should change and remove all custom formatting on selected text" do
      wysiwyg_state_setup
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Font Sizes')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'36pt')]]").click
      validate_wiki_style_attrib("font-size", "36pt", "p span")
      f(".mce-i-removeformat").click
      validate_wiki_style_attrib_empty("p")
    end

    it "should indent and remove indentation for embedded images" do
      wiki_page_tools_file_tree_setup

      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, '.img') }

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

    ["right", "center", "left"].each do |setting|
      it "should align text to the #{setting}" do
        wysiwyg_state_setup(text = "test")
        f(".mce-i-align#{setting}").click
        validate_wiki_style_attrib("text-align", setting, "p")
      end
    end

    ["right", "center", "left"].each do |setting|
      it "should align images to the #{setting}" do
        wiki_page_tools_file_tree_setup

        f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
        wait_for_ajaximations
        keep_trying_until { @image_list.find_elements(:css, '.img') }

        @image_list.find_element(:css, '.img_link').click
        select_all_wiki
        f(".mce-i-align#{setting}").click

        validate_wiki_style_attrib("text-align", setting, "p")
      end
    end

    it "should add and remove links" do
      title = "test_page"
      unpublished = false
      edit_roles = "public"

      create_wiki_page(title, unpublished, edit_roles)

      get "/courses/#{@course.id}/pages/front-page/edit"
      wait_for_tiny(keep_trying_until { f("form.edit-form .edit-content") })

      f('#new_page_link').click
      keep_trying_until { expect(f('#new_page_name')).to be_displayed }
      f('#new_page_name').send_keys(title)
      submit_form("#new_page_drop_down")

      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p a').attribute('href')).to include_text title
      end

      select_all_wiki
      f('.mce-i-unlink').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p a')).to be_nil
      end
    end

    it "should change paragraph type" do
      text = "<p>This is a sample paragraph</p><p>This is a test</p><p>I E O U A</p>"
      wysiwyg_state_setup(text)
      driver.find_element(:xpath, "//button/span[text()[contains(.,'Paragraph')]]").click
      driver.find_element(:xpath, "//span[text()[contains(.,'Preformatted')]]").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce pre').length).to eq 3
      end
    end

  it "should add bold and italic text to the rce" do
    get "/courses/#{@course.id}/pages/front-page/edit"

    wait_for_tiny(keep_trying_until { f("form.edit-form .edit-content") })
    f('.mce-i-bold').click
    f('.mce-i-italic').click
    first_text = 'This is my text.'

    type_in_tiny("##{wiki_page_editor_id}", first_text)
    in_frame wiki_page_body_ifr_id do
      expect(f('#tinymce')).to include_text(first_text)
    end
    #make sure each view uses the proper format
    fj('a.switch_views:visible').click
    expect(driver.execute_script("return $('##{wiki_page_editor_id}').val()")).to include '<em><strong>'
    fj('a.switch_views:visible').click
    in_frame wiki_page_body_ifr_id do
      expect(f('#tinymce')).not_to include_text('<p>')
    end

    f('form.edit-form button.submit').click
    wait_for_ajax_requests

    expect(driver.page_source).to match(/<em><strong>This is my text\./)
  end

  it "should add an equation to the rce by using equation buttons" do
    skip "check_image broken"
    get "/courses/#{@course.id}/pages/front-page/edit"

    f("##{wiki_page_editor_id}_instructure_equation").click
    wait_for_ajaximations
    expect(f('.mathquill-editor')).to be_displayed
    misc_tab = f('.mathquill-tab-bar > li:last-child a')
    misc_tab.click
    f('#Misc_tab li:nth-child(35) a').click
    basic_tab = f('.mathquill-tab-bar > li:first-child a')
    basic_tab.click
    f('#Basic_tab li:nth-child(27) a').click
    f('.ui-dialog-buttonset .btn-primary').click
    keep_trying_until do
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce img.equation_image')).to be_displayed
      end
    end

    f('form.edit-form button.submit').click
    wait_for_ajax_requests

    check_image(f('#wiki_page_show img'))
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

  it "should add an equation to the rce by using the equation editor" do
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
      keep_trying_until { expect(f('.equation_image').attribute('title')).to eq equation_text }

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

  it "should add an equation to the rce by using equation buttons in advanced view" do
    skip('broken')
    get "/courses/#{@course.id}/pages/front-page/edit"

    f("##{wiki_page_editor_id}_instructure_equation").click
    wait_for_ajaximations
    expect(f('.mathquill-editor')).to be_displayed
    f('a.math-toggle-link').click
    wait_for_ajaximations
    expect(f('#mathjax-editor')).to be_displayed
    misc_tab = f('#mathjax-view .mathquill-tab-bar > li:last-child a')
    misc_tab.click
    f('#misc_tab li:nth-child(35) a').click
    basic_tab = f('#mathjax-view .mathquill-tab-bar > li:first-child a')
    basic_tab.click
    f('#basic_tab li:nth-child(27) a').click
    f('.ui-dialog-buttonset .btn-primary').click
    keep_trying_until do
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce img.equation_image')).to be_displayed
      end
    end

    f('form.edit-form button.submit').click
    wait_for_ajax_requests

    check_image(f('#wiki_page_show img'))
  end

  it "should add an equation to the rce by using the equation editor in advanced view" do
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
      keep_trying_until { expect(f('.equation_image').attribute('title')).to eq equation_text }

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

  it "should display record video dialog" do
    stub_kaltura
    #pending("failing because it is dependant on an external kaltura system")

    get "/courses/#{@course.id}/pages/front-page/edit"

    f("div[aria-label='Record/Upload Media'] button").click
    keep_trying_until { expect(f('#record_media_tab')).to be_displayed }
    f('#media_comment_dialog a[href="#upload_media_tab"]').click
    expect(f('#media_comment_dialog #audio_upload')).to be_displayed
    close_visible_dialog
    expect(f('#media_comment_dialog')).not_to be_displayed
  end

end
end
