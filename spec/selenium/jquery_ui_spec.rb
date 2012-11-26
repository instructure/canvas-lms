# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + "/common")

describe "jquery ui" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
    get "/"
  end
  
  it "should make dialogs modal by default" do
    driver.execute_script(<<-JS).should == true
      return $('<div />').dialog().dialog('option', 'modal');
    JS
    f(".ui-widget-overlay").should be_displayed
    
    # make sure that hiding then showing the same dialog again, it still looks modal
    driver.execute_script(<<-JS).should == true
      return $('<div />')
        .dialog()
        .dialog('close')
        .dialog('open')
        .dialog('option', 'modal');
    JS
    f(".ui-widget-overlay").should be_displayed
  end
  
  context "calendar widget" do
    it "should let you replace content by selecting and typing instead of appending" do
      get "/courses/#{@course.id}/assignments"
      
      f(".add_assignment_link").click
      wait_for_animations
      f(".ui-datepicker-trigger").click
      wait_for_animations
      f(".ui-datepicker-time-hour").send_keys("12")
      f(".ui-datepicker-time-minute").send_keys("00")
      f(".ui-datepicker-ok").click
      
      f(".ui-datepicker-trigger").click
      wait_for_animations
      
      driver.execute_script("$('#ui-datepicker-time-hour').select();")
      f("#ui-datepicker-time-hour").send_keys('5')
      f("#ui-datepicker-time-hour").should have_attribute('value', '5')
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
      driver.execute_script(<<-JS).should == title
        return $('<div id="jqueryui_test" title="#{title}">hello</div>')
          .dialog()
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS
    end

    it "should use a non-breaking space for empty titles" do
      driver.execute_script(<<-JS).should == "\302\240"
        return $('<div id="jqueryui_test">hello</div>')
          .dialog()
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS

      driver.execute_script(<<-JS).should == "\302\240"
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
      driver.execute_script(<<-JS).should == title
        return $('<div id="jqueryui_test">hello again</div>')
          .dialog({title: #{title.inspect}})
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS

      new_title = "and now <i>this</i> is the title"
      driver.execute_script(<<-JS).should == new_title
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
      driver.execute_script(<<-JS).should == title
        return $('<div id="jqueryui_test">here we go</div>')
          .dialog({title: $(#{title.inspect})})
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .html();
      JS

      new_title = "<i>i <b>still</b> want formatting</i>"
      driver.execute_script(<<-JS).should == new_title
        return $('#jqueryui_test')
          .dialog()
          .dialog('option', 'title', $(#{new_title.inspect}))
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .html();
      JS
    end
  end
end
