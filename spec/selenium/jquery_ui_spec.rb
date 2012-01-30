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
    driver.find_element(:css, ".ui-widget-overlay").should be_displayed
    
    # make sure that hiding then showing the same dialog again, it still looks modal
    driver.execute_script(<<-JS).should == true
      return $('<div />')
        .dialog()
        .dialog('close')
        .dialog('open')
        .dialog('option', 'modal');
    JS
    driver.find_element(:css, ".ui-widget-overlay").should be_displayed
  end
  
  context "calendar widget" do
    it "should let you replace content by selecting and typing instead of appending" do
      get "/courses/#{@course.id}/assignments"
      
      driver.find_element(:css, "a.add_assignment_link").click
      wait_for_animations
      driver.find_element(:css, ".ui-datepicker-trigger").click
      wait_for_animations
      driver.find_element(:css, ".ui-datepicker-time-hour").send_keys("12")
      driver.find_element(:css, ".ui-datepicker-time-minute").send_keys("00")
      driver.find_element(:css, ".ui-datepicker-ok").click
      
      driver.find_element(:css, ".ui-datepicker-trigger").click
      wait_for_animations
      
      driver.execute_script("$('#ui-datepicker-time-hour').select();")
      driver.find_element(:id, "ui-datepicker-time-hour").send_keys('5')
      driver.find_element(:id, "ui-datepicker-time-hour").attribute('value').should == "5"
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
          .dialog('option', 'title', #{new_title.inspect})
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .text();
      JS
    end

    it "should accept jquery object dialog titles" do
      skip_if_ie("expected: <i>i want formatting <b>for realz</b></i>,got: <I>i want formatting <B>for realz</B></I> (using ==)")
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
          .dialog('option', 'title', $(#{new_title.inspect}))
          .parent('.ui-dialog')
          .find('.ui-dialog-title')
          .html();
      JS
    end
  end
end
