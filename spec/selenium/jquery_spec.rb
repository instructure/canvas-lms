require File.expand_path(File.dirname(__FILE__) + "/common")

describe "jquery" do
  it_should_behave_like "in-process server selenium tests"


  # jquery keeps breaking attr() ... see http://bugs.jquery.com/ticket/10278
  # should be fixed in 1.7 (or 1.6.5?)
  it "should return the correct value for attr" do
    get('/logout')
    driver.execute_script("$(document.body).append('<input type=\"checkbox\" checked=\"checked\" id=\"checkbox_test\">')")

    checkbox = f('#checkbox_test')
    driver.execute_script("return $('#checkbox_test').attr('checked');").should == 'checked'

    checkbox.click
    driver.execute_script("return $('#checkbox_test').attr('checked');").should be_nil
  end
  
  it "should handle $.attr(disabled, true/false) by toggling class too" do
    get('/logout')
    driver.execute_script("return $('button').attr('disabled', true).hasClass('disabled')").should be_true
  end
  it "should handle $.prop(disabled, true/false) by toggling class too" do
    get('/logout')
    driver.execute_script("return $('button').prop('disabled', true).hasClass('disabled')").should be_true
  end
  it "should handle $.attr(method, post|delete|put|get) by adding a hidden input" do
    get('/logout')
    driver.execute_script("return $('form').attr('method', 'delete').attr('method')").downcase.should  == "post"
    driver.execute_script("return $('form input[name=_method]').val()").should == "delete"
  end
end
