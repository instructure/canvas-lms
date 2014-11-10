require File.expand_path(File.dirname(__FILE__) + '/common')

describe "error reporting" do
  include_examples "in-process server selenium tests"

  it "should log the same error at most 1 time per 5 seconds" do
    get('/login')
    4.times do
      driver.execute_script("window.onerror('Throwing a test error', ''+document.location, 12)")
    end
    expect(driver.execute_script("return $('body > img[src^=\"'+ INST.errorURL +'\"]').length")).to eq 1
  end
end
