require "json"
require "selenium-webdriver"
require "rspec"
include RSpec::Expectations

describe "UntitledTestCase" do

  before(:each) do
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "https://www.katalon.com/"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 30
    @verification_errors = []
  end
  
  after(:each) do
    @driver.quit
    @verification_errors.should == []
  end
  
  it "test_untitled_test_case" do
    @driver.get "http://localhost:3000/login/canvas"
    @driver.find_element(:name, "pseudonym_session[unique_id]").clear
    @driver.find_element(:name, "pseudonym_session[unique_id]").send_keys "canvas-admin@example.com"
    @driver.find_element(:name, "pseudonym_session[password]").clear
    @driver.find_element(:name, "pseudonym_session[password]").send_keys "qwertyou812"
    @driver.find_element(:id, "login_form").submit
    @driver.find_element(:id, "global_nav_accounts_link").click
    !60.times{ break if (element_present?(:link, "admin") rescue false); sleep 1 }
    @driver.find_element(:link, "admin").click
    @driver.find_element(:xpath, "(.//*[normalize-space(text()) and normalize-space(.)='Admin Tools'])[1]/following::a[1]").click
    @driver.find_element(:id, "tab-features-link").click
    @driver.find_element(:xpath, "(.//*[normalize-space(text()) and normalize-space(.)='Enable feature: Show default Inbox])[1]/following::div[2]").click
    @driver.navigate.refresh
    @driver.find_element(:id, "global_nav_conversations_link").click
  end
  
  def element_present?(how, what)
    ${receiver}.find_element(how, what)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end
  
  def alert_present?()
    ${receiver}.switch_to.alert
    true
  rescue Selenium::WebDriver::Error::NoAlertPresentError
    false
  end
  
  def verify(&blk)
    yield
  rescue ExpectationNotMetError => ex
    @verification_errors << ex
  end
  
  def close_alert_and_get_its_text(how, what)
    alert = ${receiver}.switch_to().alert()
    alert_text = alert.text
    if (@accept_next_alert) then
      alert.accept()
    else
      alert.dismiss()
    end
    alert_text
  ensure
    @accept_next_alert = true
  end
end
