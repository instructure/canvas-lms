# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + "/common")

describe "jquery ui" do
  include_examples "in-process server selenium tests"

  def active
    driver.switch_to.active_element
  end
  def shift_tab
    driver.action.key_down(:shift)
      .send_keys(:tab)
      .key_up(:shift)
      .perform
  end
  def create_simple_modal
    driver.execute_script(<<-JS)
      return $('<div><select /><input /></div>')
        .dialog()
        .find('select')
        .focus()
    JS
  end

  before (:each) do
    course_with_teacher_logged_in
    get "/"
  end
  
  it "should make dialogs modal by default" do
    expect(driver.execute_script(<<-JS)).to eq true
      return $('<div />').dialog().dialog('option', 'modal');
    JS
    expect(f(".ui-widget-overlay")).to be_displayed
    
    # make sure that hiding then showing the same dialog again, it still looks modal
    expect(driver.execute_script(<<-JS)).to eq true
      return $('<div />')
        .dialog()
        .dialog('close')
        .dialog('open')
        .dialog('option', 'modal');
    JS
    expect(f(".ui-widget-overlay")).to be_displayed
  end

  it "should capture tabbing" do
    create_simple_modal
    expect(active.tag_name).to eq 'select'
    active.send_keys(:tab)
    expect(active.tag_name).to eq 'input'
    active.send_keys(:tab)
    expect(active.tag_name).to eq 'a'
    active.send_keys(:tab)
    expect(active.tag_name).to eq 'select'
  end

  it "should capture shift-tabbing" do
    create_simple_modal
    expect(active.tag_name).to eq 'select'
    shift_tab
    expect(active.tag_name).to eq 'a'
    shift_tab
    expect(active.tag_name).to eq 'input'
    shift_tab
    expect(active.tag_name).to eq 'select'
  end
  
  context "calendar widget" do
    it "should let you replace content by selecting and typing instead of appending" do
      get "/courses/#{@course.id}/assignments"
      
      f(".add_assignment").click
      wait_for_ajaximations
      f(".ui-datepicker-trigger").click
      wait_for_ajaximations
      f(".ui-datepicker-time-hour").send_keys("12")
      f(".ui-datepicker-time-minute").send_keys("00")
      f(".ui-datepicker-ok").click
      
      f(".ui-datepicker-trigger").click
      wait_for_ajaximations
      
      driver.execute_script("$('#ui-datepicker-time-hour').select();")
      f("#ui-datepicker-time-hour").send_keys('5')
      expect(f("#ui-datepicker-time-hour")).to have_attribute('value', '5')
    end
  end
  
  context "dialog titles" do

    # jquery ui doesn't escape dialog titles by default (even when inferred from
    # title attributes!). our modified ui.dialog does (and hopefully jquery.ui
    # will too in 1.9). to pass in an html title that you don't want escaped,
    # wrap it in a jquery object.
    # 
    # see http://bugs.jqueryui.com/ticket/6016
    it "should html-escape inferred dialog titles" do
      title = "<b>this</b> is the title"
      expect(driver.execute_script(<<-JS)).to eq title
        return $('<div id="jqueryui_test" title="#{title}">hello</div>')
          .dialog()
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS
    end

    it "should use a non-breaking space for empty titles" do
      expect(driver.execute_script(<<-JS)).to eq "\302\240"
        return $('<div id="jqueryui_test">hello</div>')
          .dialog()
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS

      expect(driver.execute_script(<<-JS)).to eq "\302\240"
        return $('#jqueryui_test')
          .dialog()
          .dialog('option', 'title', 'foo')
          .dialog('option', 'title', '')
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS
    end

    it "should html-escape explicit string dialog titles" do
      title = "<b>this</b> is the title"
      expect(driver.execute_script(<<-JS)).to eq title
        return $('<div id="jqueryui_test">hello again</div>')
          .dialog({title: #{title.inspect}})
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS

      new_title = "and now <i>this</i> is the title"
      expect(driver.execute_script(<<-JS)).to eq new_title
        return $('#jqueryui_test')
          .dialog()
          .dialog('option', 'title', #{new_title.inspect})
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS
    end

    it "should accept jquery object dialog titles" do
      title = "<i>i want formatting <b>for realz</b></i>"
      expect(driver.execute_script(<<-JS)).to eq title
        return $('<div id="jqueryui_test">here we go</div>')
          .dialog({title: $(#{title.inspect})})
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .html();
      JS

      new_title = "<i>i <b>still</b> want formatting</i>"
      expect(driver.execute_script(<<-JS)).to eq new_title
        return $('#jqueryui_test')
          .dialog()
          .dialog('option', 'title', $(#{new_title.inspect}))
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .html();
      JS
    end
  end

  context 'admin-links' do
    before do
      driver.execute_script(<<-JS)
        $('<div class="al-selenium">\
            <a class="al-trigger btn" role="button" aria-haspopup="true" aria-owns="toolbar-1" href="#">\
              <i class="icon-settings"></i>\
              <i class="icon-mini-arrow-down"></i>\
              <span class="screenreader-only">Settings</span>\
            </a>\
            <ul id="toolbar-1" class="al-options" role="menu" tabindex="0" aria-hidden="true" aria-expanded="false" aria-activedescendant="toolbar-2">\
              <li role="presentation">\
                <a href="#" class="icon-edit" id="toolbar-2" tabindex="-1" role="menuitem">Edit</a>\
              </li>\
            </ul>\
          </div>').appendTo($('body')).find('.al-trigger').focus();
      JS
    end

    def options
      fj('.al-selenium .al-options:visible')
    end

    it "should open every time when pressing return" do
      expect(options).to be_nil
      active.send_keys(:return)
      expect(options).not_to be_nil
      f('.al-selenium .al-trigger').click
      expect(options).to be_nil
      active.send_keys(:return)
      expect(options).not_to be_nil
    end
  end
end
