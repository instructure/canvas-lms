require File.expand_path(File.dirname(__FILE__) + '/../common')

describe "site admin jobs ui" do
  include_context "in-process server selenium tests"

  module FlavorTags
    ALL = 'All'
    CURRENT = 'Current'
    FUTURE = 'Future'
    FAILED = 'Failed'
  end

  def put_on_hold(count = 2)
    validate_all_jobs_selected
    f("#hold-jobs").click
    expect(driver.switch_to.alert).not_to be_nil
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    keep_trying_until do
      expect(jobs_on_hold.count).to eq count
    end

    status_cells = ff('.r2')
    status_cells.each { |status_cell| expect(status_cell.find_element(:css, 'span')).to have_class('on-hold') }
  end

  def jobs_on_hold
    @all_jobs.select do |job|
      begin
        job.reload
        job.locked_by == 'on hold'
      rescue ActiveRecord::RecordNotFound
        false
      end
    end
  end

  def validate_all_jobs_selected
    f("#select-all-jobs").click
    all_jobs = ff("#jobs-grid .slick-cell")
    all_jobs.each { |job| expect(job).to have_class('selected') }
  end

  def load_jobs_page
    get "/jobs"
    # wait for it
    f('#jobs-grid .slick-cell')
  end

  def filter_jobs(job_flavor_text)
    click_option('#jobs-flavor', job_flavor_text)
    wait_for_ajax_requests
  end

  def filter_tags(tag_flavor_text)
    click_option('#tags-flavor', tag_flavor_text)
    wait_for_ajax_requests
  end

  def future_jobs
    Delayed::Job.list_jobs(:future, nil)
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
      job = Delayed::Job.list_jobs(:current, 1).first
      get "/jobs?flavor=id&q=#{job.id}"
      expect(f('#jobs-grid .slick-cell')).to be
      f("#hold-jobs").click
      wait_for_ajax_requests
      expect(job.reload.locked_by).to eq 'on hold'
      expect(jobs_on_hold.count).to eq 1
    end

    it "should load handler via ajax" do
      Delayed::Job.delete_all
      job = "test".send_later_enqueue_args :to_s, no_delay: true
      load_jobs_page
      ff("#jobs-grid .slick-row .l0.r0").find do |element|
        element.click if element.text == job.id.to_s
      end
      expect(f('#job-id').text).to eq job.id.to_s
      f('#job-handler-show').click
      wait_for_ajax_requests
      expect(get_value('#job-handler')).to eq job.handler
      f('a.ui-dialog-titlebar-close').click

      # also for failed job
      filter_jobs(FlavorTags::FAILED)
      wait_for_ajax_requests
      f('#jobs-grid .slick-row .l0.r0').click
      expect(f('#job-id').text).to eq @failed_job.id.to_s
      f('#job-handler-show').click
      wait_for_ajax_requests
      expect(get_value('#job-handler')).to eq @failed_job.handler
    end

    context "all jobs" do
      before(:each) do
        load_jobs_page
      end

      it "should check current popular tags" do
        filter_tags(FlavorTags::CURRENT)
        expect(f("#tags-grid .slick-row:nth-child(1) .r0")).to include_text "String#reverse"
        expect(f("#tags-grid .slick-row:nth-child(1) .r1")).to include_text "2"
      end

      it "should check all popular tags", priority: "2" do
        filter_tags(FlavorTags::ALL)
        expect(f("#tags-grid")).to include_text("String#reverse\n2")
        expect(f("#tags-grid")).to include_text("String#capitalize\n1")
      end

      it "should not action if no rows are selected" do
        f("#hold-jobs").click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        expect(jobs_on_hold.count).to eq 0
      end

      it "should confirm that all current rows were selected and put on hold", priority: "2" do
        filter_jobs(FlavorTags::CURRENT)
        put_on_hold
      end

      it "should confirm to put jobs on hold and unhold" do
        put_on_hold
        validate_all_jobs_selected
        f("#un-hold-jobs").click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        expect(f("#jobs-grid .even .r2")).to include_text "0/ 15"
        expect(f("#jobs-grid .odd .r2")).to include_text "0/ 15"
        expect(jobs_on_hold.count).to eq 0
      end

      it "should confirm that future jobs were selected" do
        filter_jobs(FlavorTags::FUTURE)
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.where(tag: "String#capitalize").first
        expect(f("#jobs-grid .l0").text).to eq job.id.to_s
      end

      it "should confirm that failed jobs were selected" do
        filter_jobs(FlavorTags::FAILED)
        f("#jobs-refresh").click
        wait_for_ajax_requests
        expect(ff("#jobs-grid .slick-row").count).to eq 1
        expect(f("#jobs-grid .r1")).to include_text "String#downcase"
      end

      it "should confirm that clicking on delete button should delete all future jobs" do
        2.times { "test".send_at 2.hours.from_now, :to_s }
        filter_jobs(FlavorTags::FUTURE)
        validate_all_jobs_selected
        expect(f("#jobs-grid .odd")).to be_displayed
        expect(f("#jobs-grid .even")).to be_displayed
        expect(f("#jobs-total").text).to eq "3"
        expect(future_jobs.count).to eq 3
        num_of_jobs = Delayed::Job.all.count

        delete = f("#delete-jobs")
        keep_trying_until do
          delete.click
          expect(driver.switch_to.alert).not_to be_nil
          driver.switch_to.alert.accept
          true
        end
        wait_for_ajaximations
        expect(Delayed::Job.count).to eq num_of_jobs - 3

        expect(f("#content")).not_to contain_css("#jobs-grid .odd")
        expect(f("#content")).not_to contain_css("#jobs-grid .even")
      end
    end
  end

  context "running jobs" do
    it "should display running jobs in the workers grid" do
      Delayed::Job.get_and_lock_next_available('my test worker')
      load_jobs_page
      expect(ff('#running-grid .slick-row').size).to eq 1
      first_cell = f('#running-grid .slick-cell.l0.r0')
      expect(first_cell).to include_text 'my test worker'
    end

    it "should sort by runtime by default" do
      j1 = Delayed::Job.get_and_lock_next_available('my test worker 1')
      j2 = Delayed::Job.get_and_lock_next_available('my test worker 2')
      j2.update_attribute(:locked_at, 48.hours.ago)

      load_jobs_page
      expect(ff('#running-grid .slick-row').size).to eq 2
      first_cell = f('#running-grid .slick-cell.l0.r0')
      expect(first_cell).to include_text 'my test worker 2'
      last_cell = f('#running-grid .slick-cell.l6.r6 .super-slow')
      expect(last_cell).not_to be_nil
    end

    it "should sort dynamically" do
      Delayed::Job.get_and_lock_next_available('my test worker 1')
      Delayed::Job.get_and_lock_next_available('my test worker 2')

      load_jobs_page
      expect(ff('#running-grid .slick-row').size).to eq 2
      # sort ASC
      worker_header = f("#running-grid .slick-header div[id*='worker'] .slick-column-name")
      worker_header.click
      first_cell = f('#running-grid .slick-cell.l0.r0')
      expect(first_cell).to include_text 'my test worker 1'

      # sort DESC
      worker_header.click
      first_cell = f('#running-grid .slick-cell.l0.r0')
      expect(first_cell).to include_text 'my test worker 2'
    end
  end
end
