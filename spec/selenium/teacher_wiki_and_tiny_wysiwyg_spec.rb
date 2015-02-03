require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor features" do
  include_examples "in-process server selenium tests"

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
      f('.mce_unlink').click
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

      f('.mce_bullist').click
      in_frame wiki_page_body_ifr_id do
        ff('#tinymce li').length == 3
      end

      f('.mce_bullist').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce li')).to be_nil
      end
    end

    it "should add and remove numbered lists" do
      wysiwyg_state_setup

      f('.mce_numlist').click
      in_frame wiki_page_body_ifr_id do
        ff('#tinymce li').length == 3
      end

      f('.mce_numlist').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce li')).to be_nil
      end
    end

    it "should change font color for all selected text" do
      wysiwyg_state_setup

      f("##{wiki_page_editor_id}_forecolor_open").click
      fba("##{wiki_page_editor_id}_forecolor_menu", "title", "Red")
      validate_wiki_style_attrib("color", "rgb(255, 0, 0)", "p span")
    end

    it "should change background font color" do
      wysiwyg_state_setup

      f("##{wiki_page_editor_id}_backcolor_open").click
      fba("##{wiki_page_editor_id}_backcolor_menu", "title", "Red")
      validate_wiki_style_attrib("background-color", "rgb(255, 0, 0)", "p span")
    end

    it "should change font size" do
      wysiwyg_state_setup
      f("##{wiki_page_editor_id}_fontsizeselect_open").click
      #f('#menu_#{wiki_page_editor_id}_#{wiki_page_editor_id}_fontsizeselect_menu_tbl [style="font-size:small"]').click

      fba("#menu_#{wiki_page_editor_id}_#{wiki_page_editor_id}_fontsizeselect_menu_tbl", "style", "font-size:xx-large")
      validate_wiki_style_attrib("font-size", "xx-large", "p span")
    end

    it "should change and remove all custom formatting on selected text" do
      wysiwyg_state_setup
      f("##{wiki_page_editor_id}_fontsizeselect_open").click
      fba("#menu_#{wiki_page_editor_id}_#{wiki_page_editor_id}_fontsizeselect_menu_tbl", "style", "font-size:xx-large")
      validate_wiki_style_attrib("font-size", "xx-large", "p span")
      f("##{wiki_page_editor_id}_removeformat").click
      validate_wiki_style_attrib_empty("p")
    end

    it "should indent and remove indentation for embedded images" do
      wiki_page_tools_file_tree_setup

      f('#editor_tabs .ui-tabs-nav li:nth-child(3) a').click
      wait_for_ajaximations
      keep_trying_until { @image_list.find_elements(:css, '.img') }

      @image_list.find_element(:css, '.img_link').click

      select_all_wiki
      f('.mce_indent').click
      validate_wiki_style_attrib("padding-left", "30px", "p")
      f('.mce_outdent').click
      validate_wiki_style_attrib_empty("p")
    end

    it "should indent and remove indentation for text" do
      wysiwyg_state_setup(text = "test")

      f('.mce_indent').click
      validate_wiki_style_attrib("padding-left", "30px", "p")
      f('.mce_outdent').click
      validate_wiki_style_attrib_empty("p")
    end

    ["right", "center", "left"].each do |setting|
      it "should align text to the #{setting}" do
        wysiwyg_state_setup(text = "test")
        f(".mce_justify#{setting}").click
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
        f(".mce_justify#{setting}").click

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
      f('.mce_unlink').click
      in_frame wiki_page_body_ifr_id do
        expect(f('#tinymce p a')).to be_nil
      end
    end

    it "should change paragraph type" do
      text = "<p>This is a sample paragraph</p><p>This is a test</p><p>I E O U A</p>"
      wysiwyg_state_setup(text)
      f("##{wiki_page_editor_id}_formatselect_open").click
      f("#menu_#{wiki_page_editor_id}_#{wiki_page_editor_id}_formatselect_menu .mce_pre").click
      in_frame wiki_page_body_ifr_id do
        expect(ff('#tinymce pre').length).to eq 3
    end
  end

  it "should add bold and italic text to the rce" do
    get "/courses/#{@course.id}/pages/front-page/edit"

    wait_for_tiny(keep_trying_until { f("form.edit-form .edit-content") })
    f('.mceIcon.mce_bold').click
    f('.mceIcon.mce_italic').click
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

  it "should add an equation to the rce by using the equation editor" do
    equation_text = '\\text{yay math stuff:}\\:\\frac{d}{dx}\\sqrt{x}=\\frac{d}{dx}x^{\\frac{1}{2}}=\\frac{1}{2}x^{-\\frac{1}{2}}=\\frac{1}{2\\sqrt{x}}\\text{that. is. so. cool.}'

    get "/courses/#{@course.id}/pages/front-page/edit"
    f("##{wiki_page_editor_id}_instructure_equation").click
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
    f("##{wiki_page_editor_id}_instructure_equation").click
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

    f('.mce_instructure_record').click
    keep_trying_until { expect(f('#record_media_tab')).to be_displayed }
    f('#media_comment_dialog a[href="#upload_media_tab"]').click
    expect(f('#media_comment_dialog #audio_upload')).to be_displayed
    close_visible_dialog
    expect(f('#media_comment_dialog')).not_to be_displayed
  end

  it "should handle table borders correctly" do
    get "/courses/#{@course.id}/pages/front-page/edit"

    def check_table(attributes = {})
      # clear out whatever is in the editor
      driver.execute_script("$('##{wiki_page_body_ifr_id}')[0].contentDocument.body.innerHTML =''")

      # this is the only way I know to actually trigger the insert table dialog to open
      # listening to the click events on the button in the menu did not work
      driver.execute_script("$('##{wiki_page_editor_id}').editorBox('execute', 'mceInsertTable')")

      # the iframe will be created with an id of mce_<some number>_ifr
      table_iframe_id = keep_trying_until { ff('iframe').map { |f| f['id'] }.detect { |w| w =~ /mce_\d+_ifr/ } }
      expect(table_iframe_id).not_to be_nil
      in_frame(table_iframe_id) do
        attributes.each do |attribute, value|
          tab_to_show = attribute == :bordercolor ? 'advanced' : 'general'
          keep_trying_until do
            driver.execute_script "mcTabs.displayTab('#{tab_to_show}_tab', '#{tab_to_show}_panel')"
            set_value(f("##{attribute}"), value)
            true
          end
        end
        f('#insert').click
      end
      in_frame wiki_page_body_ifr_id do
        table = f('#tinymce table')
        attributes.each do |attribute, value|
          (expect(table[attribute]).to eq value.to_s) if (value && (attribute != :bordercolor))
        end
        [:width, :color].each do |part|
          [:top, :right, :bottom, :left].each do |side|
            expected_value = attributes[{:width => :border, :color => :bordercolor}[part]] || {:width => 1, :color => 'rgba(136, 136, 136, 1)'}[part]
            if expected_value.is_a?(Numeric)
              expected_value = 1 if expected_value == 0
              expected_value = "#{expected_value}px"
            end
            expect(table.style("border-#{side}-#{part}")).to eq expected_value
          end
        end
      end
      # TODO: test how it looks after page is saved.
      #submit_form('#new_wiki_page')

    end

    # check with default settings
    check_table()

    check_table(
        :align => 'center',
        :cellpadding => 5,
        :cellspacing => 6,
        :border => 7,
        :bordercolor => 'rgba(255, 0, 0, 1)'
    )
    check_table(
        :align => 'center',
        :cellpadding => 0,
        :cellspacing => 0,
        :border => 0
    )
  end
end
end
