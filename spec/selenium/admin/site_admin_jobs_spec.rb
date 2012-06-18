require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "jobs ui" do
  it_should_behave_like "in-process server selenium tests"

  module FlavorTags
    ALL = 'All'
    CURRENT = 'Current'
    FUTURE = 'Future'
    FAILED = 'Failed'
  end

  def put_on_hold(count = 2)
    validate_all_jobs_selected
    f("#hold-jobs").click
    driver.switch_to.alert.should_not be_nil
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    keep_trying_until do
      Delayed::Job.all.each { |job| job.reload }
      Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql count
    end

    status_cells = ff('.r2')
    status_cells.each { |status_cell| status_cell.find_element(:css, 'span').should have_class('on-hold') }
  end

  def validate_all_jobs_selected
    f("#select-all-jobs").click
    all_jobs = ff("#jobs-grid .slick-cell")
    all_jobs.each { |job| job.should have_class('selected') }
  end

  def first_jobs_cell_displayed?
    ffj('#jobs-grid .slick-cell').count > 0
  end

  def load_jobs_page
    keep_trying_until do
      get "/jobs"
      wait_for_ajax_requests
      first_jobs_cell_displayed?
    end
  end

  def filter_jobs(job_flavor_text)
    click_option('#jobs-flavor', job_flavor_text)
    wait_for_ajax_requests
  end

  def filter_tags(tag_flavor_text)
    click_option('#tags-flavor', tag_flavor_text)
    wait_for_ajax_requests
  end

  before(:each) do
    site_admin_logged_in
    2.times { "present".send_later :reverse }
    "future".send_at Time.now + 30.days, :capitalize
    "failure".send_at Time.now, :downcase
    job= Delayed::Job.find_by_tag("String#downcase")
    job.fail!
  end

  context "search" do

    it "should only action the individual job when it has been searched for" do
      j = Delayed::Job.first(:order => :id)
      get "/jobs?id=#{j.id}"
      wait_for_ajax_requests
      keep_trying_until { ffj('#jobs-grid .slick-cell').count > 0 }
      f("#hold-jobs").click
      wait_for_ajax_requests
      j.reload.locked_by.should == 'on hold'
      Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql 1
    end

    context "all jobs" do
      before (:each) do
        load_jobs_page
      end

      it "should check all popular tags" do
        filter_tags(FlavorTags::ALL)
        keep_trying_until do
          f("#tags-grid div[row='0'] .r0").text.should eql "String#reverse"
          f("#tags-grid div[row='0'] .r1").text.should eql "2"
          f("#tags-grid div[row='1'] .r0").text.should eql "String#capitalize"
          f("#tags-grid div[row='1'] .r1").text.should eql "1"
        end
      end

      it "should check current popular tags" do
        filter_tags(FlavorTags::CURRENT)
        keep_trying_until do
          f("#tags-grid div[row='0'] .r0").text.should eql "String#reverse"
          f("#tags-grid div[row='0'] .r1").text.should eql "2"
        end
      end

      it "should check future popular tags" do
        filter_tags(FlavorTags::FUTURE)
        keep_trying_until do
          f("#tags-grid div[row='0'] .r0").text.should eql "String#capitalize"
          f("#tags-grid div[row='0'] .r1").text.should eql "1"
        end
      end

      it "should check failed popular tags" do
        filter_tags(FlavorTags::FAILED)
        keep_trying_until do
          f("#tags-grid .r0").text.should eql "String#downcase"
          f("#tags-grid .r1").text.should eql "1"
        end
      end

      it "should not action if no rows are selected" do
        f("#hold-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql 0
      end

      it "should confirm that all current rows were selected and put on hold" do
        pending('intermittent failure')
        filter_jobs(FlavorTags::CURRENT)
        put_on_hold
      end

      it "should confirm that all rows were selected and put on hold" do
        pending('intermittent failure')
        filter_jobs(FlavorTags::ALL)
        put_on_hold 3
      end

      it "should confirm to put jobs on hold and unhold" do
        pending('intermittent failure')
        put_on_hold
        f("#un-hold-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        keep_trying_until do
          f("#jobs-grid .even .r2").text.should eql "0/ 15"
          f("#jobs-grid .odd .r2").text.should eql "0/ 15"
          Delayed::Job.count(:conditions => {:locked_by => 'on hold'}).should eql 0
        end
      end

      it "should confirm that future jobs were selected" do
        filter_jobs(FlavorTags::FUTURE)
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.find_by_tag("String#capitalize")
        f("#jobs-grid .l0").text.should eql job.id.to_s
      end

      it "should confirm that all jobs were selected" do
        filter_jobs(FlavorTags::ALL)
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.find_by_tag("String#capitalize")
        f("#jobs-grid .l0").text.should eql job.id.to_s
      end

      it "should confirm that failed jobs were selected" do
        filter_jobs(FlavorTags::FAILED)
        f("#jobs-refresh").click
        wait_for_ajax_requests
        ff("#jobs-grid .slick-row").count.should eql 1
        f("#jobs-grid .r1").text.should include_text "String#downcase"
      end

      it "should confirm that clicking on delete button should delete all jobs" do
        filter_jobs(FlavorTags::ALL)
        validate_all_jobs_selected
        f("#jobs-grid .odd").should be_displayed
        f("#jobs-grid .even").should be_displayed
        f("#jobs-total").text.should eql "3"
        keep_trying_until do
          f("#delete-jobs").click
          driver.switch_to.alert.should_not be_nil
          driver.switch_to.alert.accept
          true
        end
        wait_for_ajax_requests
        fj("#jobs-grid .odd").should be_nil # using fj to bypass selenium cache
        fj("#jobs-grid .even").should be_nil #using fj to bypass selenium cache
        Delayed::Job.count.should eql 0
      end
    end
  end

  context "running jobs" do
    it "should display running jobs in the workers grid" do
      j = Delayed::Job.first(:order => :id)
      j.lock_exclusively!(100, 'my test worker')
      load_jobs_page
      ffj('#running-grid .slick-row').size.should eql 1
      first_cell = f('#running-grid .slick-cell.l0.r0')
      first_cell.text.should eql 'my test worker'
    end
  end
end
