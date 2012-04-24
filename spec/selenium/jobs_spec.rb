require File.expand_path(File.dirname(__FILE__) + '/common')

describe "jobs ui" do
  it_should_behave_like "in-process server selenium tests"

  def put_on_hold (count=2)
    f("#select-all-jobs").click
    f("#hold-jobs").click
    driver.switch_to.alert.should be_present
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql count
    ff("#jobs-grid .r2").count.should eql count
    ff("#jobs-grid .r2")[count-1].text.should eql "hold"
  end

  def first_jobs_cell_displayed?
    ffj('#jobs-grid .slick-cell').count > 0
  end

  before(:each) do
    site_admin_logged_in
    2.times { "present".send_later :reverse }
    "future".send_at Time.now + 30.days, :capitalize
    "failure".send_at Time.now, :downcase
    job= Delayed::Job.find_by_tag("String#downcase")
    job.fail!
  end

  describe "actions" do

    it "should only action the individual job when it has been searched for" do
      j = Delayed::Job.first(:order => :id)
      get "/jobs?id=#{j.id}"
      wait_for_ajax_requests
      keep_trying_until { first_jobs_cell_displayed? }
      f("#hold-jobs").click
      wait_for_ajax_requests
      j.reload.locked_by.should == 'on hold'
      Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql 1
    end

    context "go to the jobs page" do
      before do
        get "/jobs"
        wait_for_ajax_requests
        keep_trying_until { first_jobs_cell_displayed? }
      end

      it "should check all popular tags" do
        f("#tags-flavor option[value='all']").click
        wait_for_ajax_requests
        keep_trying_until do
          f("#tags-grid div[row='0'] .r0").text.should eql "String#reverse"
          f("#tags-grid div[row='0'] .r1").text.should eql "2"
          f("#tags-grid div[row='1'] .r0").text.should eql "String#capitalize"
          f("#tags-grid div[row='1'] .r1").text.should eql "1"
        end
      end

      it "should check current popular tags" do
        f("#tags-flavor option[value='current']").click
        wait_for_ajax_requests
        keep_trying_until do
          f("#tags-grid div[row='0'] .r0").text.should eql "String#reverse"
          f("#tags-grid div[row='0'] .r1").text.should eql "2"
        end
      end

      it "should check future popular tags" do
        f("#tags-flavor option[value='future']").click
        wait_for_ajax_requests
        keep_trying_until do
          f("#tags-grid div[row='0'] .r0").text.should eql "String#capitalize"
          f("#tags-grid div[row='0'] .r1").text.should eql "1"
        end
      end

      it "should check failed popular tags" do
        f("#tags-flavor option[value='failed']").click
        wait_for_ajax_requests
        keep_trying_until do
          f("#tags-grid .r0").text.should eql "String#downcase"
          f("#tags-grid .r1").text.should eql "1"
        end
      end

      it "should not action if no rows are selected" do
        f("#hold-jobs").click
        driver.switch_to.alert.should be_present
        driver.switch_to.alert.accept
        Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql 0
      end

      it "should confirm that all current rows were selected" do
        f("#jobs-flavor option[value='current']").click
        wait_for_ajax_requests
        put_on_hold
      end

      it "should confirm that all rows were selected" do
        f("#jobs-flavor option[value='all']").click
        wait_for_ajax_requests
        put_on_hold 3
      end

      it "should confirm to put jobs on hold and unhold" do
        put_on_hold
        f("#select-all-jobs").click
        f("#un-hold-jobs").click
        driver.switch_to.alert.should be_present
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        f("#jobs-grid .even .r2").text.should eql "0/ 15"
        f("#jobs-grid .odd .r2").text.should eql "0/ 15"
        Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql 0
      end

      it "should confirm that future jobs were selected" do
        f("#jobs-flavor option[value='future']").click
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.find_by_tag("String#capitalize")
        f("#jobs-grid .l0").text.should eql job.id.to_s
      end

      it "should confirm that all jobs were selected" do
        f("#jobs-flavor option[value='all']").click
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.find_by_tag("String#capitalize")
        f("#jobs-grid .l0").text.should eql job.id.to_s
      end

      it "should confirm that failed jobs were selected" do
        f("#jobs-flavor option[value='failed']").click
        f("#jobs-refresh").click
        wait_for_ajax_requests
        ff("#jobs-grid .slick-row").count.should eql 1
        f("#jobs-grid .r1").text.should include_text "#{:downcase}"
      end

      it "should confirm that clicking on delete button should delete all jobs" do
        f("#jobs-flavor option[value='all']").click
        wait_for_ajax_requests
        f("#select-all-jobs").click
        f("#jobs-grid .odd").should be_displayed
        f("#jobs-grid .even").should be_displayed
        f("#jobs-total").text.should eql "3"
        f("#delete-jobs").click
        driver.switch_to.alert.should be_present
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
      keep_trying_until { first_jobs_cell_displayed? }
      ffj('#running-grid .slick-row').size.should eql 1
      first_cell = f('#running-grid .slick-cell.l0.r0')
      first_cell.text.should eql 'my test worker'
    end
  end
end
