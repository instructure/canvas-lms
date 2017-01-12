require File.expand_path(File.dirname(__FILE__) + "/common")

describe "jquery" do
  include_context "in-process server selenium tests"


  # jquery keeps breaking attr() ... see http://bugs.jquery.com/ticket/10278
  # should be fixed in 1.7 (or 1.6.5?)
  it "should return the correct value for attr" do
    get('/login')
    driver.execute_script("$(document.body).append('<input type=\"checkbox\" checked=\"checked\" id=\"checkbox_test\">')")

    checkbox = f('#checkbox_test')
    expect(driver.execute_script("return $('#checkbox_test').attr('checked');")).to eq 'checked'

    checkbox.click
    expect(driver.execute_script("return $('#checkbox_test').attr('checked');")).to be_nil
  end

  it "should handle $.attr(method, post|delete|put|get) by adding a hidden input" do
    get('/login')
    expect(driver.execute_script("return $('form').attr('method', 'delete').attr('method')").downcase).to  eq "post"
    expect(driver.execute_script("return $('form input[name=_method]').val()")).to eq "delete"
  end
end
