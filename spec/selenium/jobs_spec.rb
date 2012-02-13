require File.expand_path(File.dirname(__FILE__) + '/common')

describe "jobs ui" do
  it_should_behave_like "in-process server selenium tests"

  before do
    site_admin_logged_in
    2.times { "ohai".send_later :reverse }
  end

  describe "actions" do
    it "should only action the individual job when it's been searched for" do
      j = Delayed::Job.last(:order => :id)
      get "/jobs?id=#{j.id}"
      driver.find_element(:id, "hold-jobs").click
      wait_for_ajax_requests
      j.reload.locked_by.should == 'on hold'
      Delayed::Job.count(:conditions => { :locked_by => 'on hold' }).should == 1
    end

    it "should not action if no rows are selected" do
      get "/jobs"
      expect_fired_alert { driver.find_element(:id, "hold-jobs").click }
      Delayed::Job.count(:conditions => { :locked_by => 'on hold' }).should == 0
    end

    it "should confirm if all rows are selected" do
      get "/jobs"
      driver.find_element(:id, "select-all-jobs").click
      driver.execute_script(" window.confirm = function() { window.confirmed = true; return true; } ")
      driver.find_element(:id, "hold-jobs").click
      wait_for_ajax_requests
      driver.execute_script("return window.confirmed;").should == true
      Delayed::Job.count(:conditions => { :locked_by => 'on hold' }).should == 2
    end
  end
end
