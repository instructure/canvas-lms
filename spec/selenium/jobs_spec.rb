require File.expand_path(File.dirname(__FILE__) + '/common')

describe "jobs ui" do
  it_should_behave_like "in-process server selenium tests"

  before do
    site_admin_logged_in
    2.times { "ohai".send_later :reverse }
  end

  describe "actions" do
    it "should only action the individual job when it has been searched for" do
      j = Delayed::Job.last(:order => :id)
      get "/jobs?id=#{j.id}"
      f("#hold-jobs").click
      wait_for_ajax_requests
      j.reload.locked_by.should == 'on hold'
      Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should == 1
    end

    it "should not action if no rows are selected" do
      get "/jobs"
      f("#hold-jobs").click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should == 0
    end

    it "should confirm that all rows were selected" do
      get "/jobs"
      f("#select-all-jobs").click
      f("#hold-jobs").click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajax_requests
      Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should == 2
    end
  end

  describe "running jobs" do
    it "should display running jobs in the workers grid" do
      j = Delayed::Job.last(:order => :id)
      j.lock_exclusively!(100, 'my test worker')
      get "/jobs"
      wait_for_ajax_requests
      ff('#running-grid .slick-row').size.should == 1
      row = f('#running-grid .slick-row')
      f('.l0', row).text.should == 'my test worker'
    end
  end
end
