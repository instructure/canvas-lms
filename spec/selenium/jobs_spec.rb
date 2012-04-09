require File.expand_path(File.dirname(__FILE__) + '/common')

describe "jobs ui" do
  it_should_behave_like "in-process server selenium tests"

  before do
    site_admin_logged_in
    2.times { "ohai".send_later :reverse }
    "hello".send_at Time.now + 40.days, :capitalize
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
    context "go to the jobs page" do
      before do
        get "/jobs"
        wait_for_ajax_requests
      end

      it "should not action if no rows are selected" do
        f("#hold-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should == 0
      end

      it "should confirm that all rows were selected" do
        f("#select-all-jobs").click
        f("#hold-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should == 2
      end

      it "should confirm that all rows were selected" do
        f("#select-all-jobs").click
        f("#hold-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should == 2
      end

      it "should confirm that future jobs were selected" do
        f("#jobs-flavor option[value='future']").click
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.find_by_tag("String#capitalize")
        f("#jobs-grid .l0").text.should eql job.id.to_s
      end

      it "should confirm that failed jobs were selected" do
        f("#jobs-flavor option[value='failed']").click
        f("#jobs-refresh").click
        wait_for_ajax_requests
      end

      it "should confirm that clicking on delete button should delete jobs" do
        f("#jobs-flavor option[value='all']").click
        wait_for_ajax_requests
        f("#select-all-jobs").click
        f("#jobs-grid .odd").should be_displayed
        f("#jobs-grid .even").should be_displayed
        Delayed::Job.count.should eql 3
        f("#delete-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        f("#jobs-grid .odd").should be_nil
        f("#jobs-grid .even").should be_nil
        Delayed::Job.count.should eql 0
      end
    end

  end

  describe "running jobs" do
    it "should display running jobs in the workers grid" do
      j = Delayed::Job.first(:order => :id)
      j.lock_exclusively!(100, 'my test worker')
      get "/jobs"
      wait_for_ajax_requests
      ff('#running-grid .slick-row').size.should == 1
      row = f('#running-grid .slick-row')
      f('.l0', row).text.should == 'my test worker'
    end
  end
end
