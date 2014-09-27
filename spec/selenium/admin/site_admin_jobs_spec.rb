require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "site admin jobs ui" do
  include_examples "in-process server selenium tests"

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
      @all_jobs.each { |j| j.reload rescue nil }
      @all_jobs.count { |j| j.locked_by == 'on hold' }.should == count
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
    !ff('#jobs-grid .slick-cell').should_not be_empty
  end

  def load_jobs_page
    get "/jobs"
    wait_for_ajaximations
    keep_trying_until do
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
    track_jobs do
      2.times { "present".send_later :reverse }
      "future".send_at Time.now + 30.days, :capitalize
      job = "failure".send_later_enqueue_args :downcase, no_delay: true
      @failed_job = job.fail!
    end
    @all_jobs = created_jobs.dup
    # tweak these settings to speed up the test run
    Setting.set('running_jobs_refresh_seconds', 1)
    Setting.set('job_tags_refresh_seconds', 1)
  end

  context "search" do

    it "should only action the individual job when it has been searched for" do
      j = Delayed::Job.list_jobs(:current, 1).first
      get "/jobs?flavor=id&q=#{j.id}"
      wait_for_ajax_requests
      keep_trying_until { ffj('#jobs-grid .slick-cell').count > 0 }
      f("#hold-jobs").click
      wait_for_ajax_requests
      j.reload.locked_by.should == 'on hold'
      @all_jobs.count { |j| (j.reload rescue nil).try(:locked_by) == 'on hold' }.should == 1
    end

    it "should load handler via ajax" do
      Delayed::Job.delete_all
      job = "test".send_later_enqueue_args :to_s, no_delay: true
      load_jobs_page
      fj('#jobs-grid .slick-row .l0.r0').click()
      fj('#job-id').text.should == job.id.to_s
      fj('#job-handler-show').click()
      wait_for_ajax_requests
      get_value('#job-handler').should == job.handler
      fj('a.ui-dialog-titlebar-close').click()

      # also for failed job
      filter_jobs(FlavorTags::FAILED)
      wait_for_ajax_requests
      fj('#jobs-grid .slick-row .l0.r0').click()
      fj('#job-id').text.should == @failed_job.id.to_s
      fj('#job-handler-show').click()
      wait_for_ajax_requests
      get_value('#job-handler').should == @failed_job.handler
    end

    context "all jobs" do
      before (:each) do
        load_jobs_page
      end

      it "should confirm that clicking on delete button should delete all future jobs" do
        2.times { "test".send_at 2.hours.from_now, :to_s }
        filter_jobs(FlavorTags::FUTURE)
        validate_all_jobs_selected
        f("#jobs-grid .odd").should be_displayed
        f("#jobs-grid .even").should be_displayed
        f("#jobs-total").text.should == "3"
        num_of_jobs = Delayed::Job.all.count

        keep_trying_until do
          fj("#delete-jobs").click
          driver.switch_to.alert.should_not be_nil
          driver.switch_to.alert.accept
          wait_for_ajaximations
          Delayed::Job.count.should == num_of_jobs - 3
        end

        fj("#jobs-grid .odd").should be_nil # using fj to bypass selenium cache
        fj("#jobs-grid .even").should be_nil #using fj to bypass selenium cache
      end

      it "should check current popular tags" do
        filter_tags(FlavorTags::CURRENT)
        keep_trying_until do
          f("#tags-grid .slick-row:nth-child(1) .r0").text.should == "String#reverse"
          f("#tags-grid .slick-row:nth-child(1) .r1").text.should == "2"
        end
      end

      it "should check all popular tags" do
        filter_tags(FlavorTags::ALL)
        keep_trying_until do
          f("#tags-grid .slick-row:nth-child(1) .r0").text.should == "String#reverse"
          f("#tags-grid .slick-row:nth-child(1) .r1").text.should == "2"
          f("#tags-grid .slick-row:nth-child(2) .r0").text.should == "String#capitalize"
          f("#tags-grid .slick-row:nth-child(2) .r1").text.should == "1"
        end
      end

      it "should not action if no rows are selected" do
        f("#hold-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        @all_jobs.count { |j| (j.reload rescue nil).try(:locked_by) == 'on hold' }.should == 0
      end

      it "should confirm that all current rows were selected and put on hold" do
        filter_jobs(FlavorTags::CURRENT)
        put_on_hold
      end

      it "should confirm to put jobs on hold and unhold" do
        put_on_hold
        validate_all_jobs_selected
        f("#un-hold-jobs").click
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        keep_trying_until do
          f("#jobs-grid .even .r2").text.should == "0/ 15"
          f("#jobs-grid .odd .r2").text.should == "0/ 15"
          @all_jobs.count { |j| (j.reload rescue nil).try(:locked_by) == 'on hold' }.should == 0
        end
      end

      it "should confirm that future jobs were selected" do
        filter_jobs(FlavorTags::FUTURE)
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.where(tag: "String#capitalize").first
        f("#jobs-grid .l0").text.should == job.id.to_s
      end

      it "should confirm that failed jobs were selected" do
        filter_jobs(FlavorTags::FAILED)
        f("#jobs-refresh").click
        wait_for_ajax_requests
        ff("#jobs-grid .slick-row").count.should == 1
        f("#jobs-grid .r1").text.should include_text "String#downcase"
      end

      it "should confirm that clicking on delete button should delete all future jobs" do
        2.times { "test".send_at 2.hours.from_now, :to_s }
        filter_jobs(FlavorTags::FUTURE)
        validate_all_jobs_selected
        f("#jobs-grid .odd").should be_displayed
        f("#jobs-grid .even").should be_displayed
        f("#jobs-total").text.should == "3"
        Delayed::Job.all.count.should == 5
        num_of_jobs = Delayed::Job.all.count

         keep_trying_until do
            f("#delete-jobs").click
            driver.switch_to.alert.should_not be_nil
            driver.switch_to.alert.accept
           true
         end
        wait_for_ajaximations
        Delayed::Job.count.should == num_of_jobs - 3

        fj("#jobs-grid .odd").should be_nil # using fj to bypass selenium cache
        fj("#jobs-grid .even").should be_nil #using fj to bypass selenium cache
      end
    end
  end

  context "running jobs" do
    it "should display running jobs in the workers grid" do
      j = Delayed::Job.order(:id).first
      j.lock_exclusively!('my test worker')
      load_jobs_page
      ffj('#running-grid .slick-row').size.should == 1
      keep_trying_until do
        first_cell = fj('#running-grid .slick-cell.l0.r0')
        first_cell.text.should == 'my test worker'
      end
    end

    it "should sort by runtime by default" do
      @all_jobs[0].lock_exclusively!('my test worker 1')
      Delayed::Job.stubs(:db_time_now).returns(24.hours.ago)
      @all_jobs[1].update_attribute(:run_at, 48.hours.ago)
      @all_jobs[1].lock_exclusively!('my test worker 2')
      Delayed::Job.unstub(:db_time_now)

      load_jobs_page
      ffj('#running-grid .slick-row').size.should == 2
      keep_trying_until do
        first_cell = fj('#running-grid .slick-cell.l0.r0')
        first_cell.text.should == 'my test worker 2'
        last_cell = fj('#running-grid .slick-cell.l6.r6 .super-slow')
        last_cell.should_not be_nil
        true
      end
    end

    it "should sort dynamically" do
      @all_jobs[0].lock_exclusively!('my test worker 1')
      @all_jobs[1].lock_exclusively!('my test worker 2')

      load_jobs_page
      ffj('#running-grid .slick-row').size.should == 2
      # sort ASC
      worker_header = fj("#running-grid .slick-header div[id*='worker'] .slick-column-name")
      worker_header.click
      keep_trying_until do
        first_cell = fj('#running-grid .slick-cell.l0.r0')
        first_cell.text.should == 'my test worker 1'
      end

      # sort DESC
      worker_header.click
      keep_trying_until do
        first_cell = fj('#running-grid .slick-cell.l0.r0')
        first_cell.text.should == 'my test worker 2'
      end
    end
  end
end
