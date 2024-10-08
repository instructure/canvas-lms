# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../common"

describe "site admin jobs ui" do
  include_context "in-process server selenium tests"

  def put_on_hold(count = 2)
    validate_all_jobs_selected
    f("#hold-jobs").click
    expect(driver.switch_to.alert).not_to be_nil
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    keep_trying_until do
      expect(jobs_on_hold.count).to eq count
    end

    status_cells = ff(".f2")
    status_cells.each { |status_cell| expect(status_cell.find_element(:css, "span")).to have_class("on-hold") }
  end

  def jobs_on_hold
    @all_jobs.select do |job|
      job.reload
      job.locked_by == "on hold"
    rescue ActiveRecord::RecordNotFound
      false
    end
  end

  def validate_all_jobs_selected
    f("#select-all-jobs").click
    all_jobs = ff("#jobs-grid .slick-cell")
    all_jobs.each { |job| expect(job).to have_class("selected") }
  end

  def load_jobs_page
    get "/jobs_v1"
    # wait for it
    f("#jobs-grid .slick-cell")
  end

  def filter_jobs(job_flavor_text)
    click_option("#jobs-flavor", job_flavor_text)
    wait_for_ajax_requests
  end

  def filter_tags(tag_flavor_text)
    click_option("#tags-flavor", tag_flavor_text)
    wait_for_ajax_requests
  end

  def future_jobs
    Delayed::Job.list_jobs(:future, nil)
  end

  before do
    site_admin_logged_in
    track_jobs do
      2.times { "present".delay.reverse }
      "future".delay(run_at: 30.days.from_now).capitalize
      job = "failure".delay(ignore_transaction: true).downcase
      @failed_job = job.fail!
    end
    @all_jobs = created_jobs.dup
    # tweak these settings to speed up the test run
    Setting.set("running_jobs_refresh_seconds", 1)
    Setting.set("job_tags_refresh_seconds", 1)
  end

  context "search" do
    it "only actions the individual job when it has been searched for" do
      job = Delayed::Job.list_jobs(:current, 1).first
      get "/jobs_v1?flavor=id&q=#{job.id}"
      expect(f("#jobs-grid .slick-cell")).to be
      f("#hold-jobs").click
      wait_for_ajax_requests
      expect(job.reload.locked_by).to eq "on hold"
      expect(jobs_on_hold.count).to eq 1
    end

    it "loads handler via ajax" do
      Delayed::Job.delete_all
      job = "test".delay(ignore_transaction: true).to_s
      load_jobs_page
      ff("#jobs-grid .slick-row .b0.f0").find do |element|
        element.click if element.text == job.id.to_s
      end
      expect(f("#job-id").text).to eq job.id.to_s
      f("#job-handler-show").click
      wait_for_ajax_requests
      expect(get_value("#job-handler")).to eq job.handler
      f(".ui-dialog-titlebar-close").click

      # also for failed job
      filter_jobs("Failed")
      wait_for_ajax_requests
      f("#jobs-grid .slick-row .b0.f0").click
      expect(f("#job-id").text).to eq @failed_job.id.to_s
      f("#job-handler-show").click
      wait_for_ajax_requests
      expect(get_value("#job-handler")).to eq @failed_job.handler
    end

    context "all jobs" do
      before do
        load_jobs_page
      end

      it "checks current popular tags" do
        filter_tags("Current")
        expect(f("#tags-grid")).to include_text "String#reverse"
        expect(f("#tags-grid")).to include_text "2"
      end

      it "checks all popular tags", priority: "2" do
        filter_tags("All")
        expect(f("#tags-grid")).to include_text("String#reverse\n2")
        expect(f("#tags-grid")).to include_text("String#capitalize\n1")
      end

      it "does not action if no rows are selected" do
        f("#hold-jobs").click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        expect(jobs_on_hold.count).to eq 0
      end

      it "confirms that all current rows were selected and put on hold", priority: "2" do
        filter_jobs("Current")
        put_on_hold
      end

      it "confirms to put jobs on hold and unhold" do
        put_on_hold
        validate_all_jobs_selected
        f("#un-hold-jobs").click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        expect(f("#jobs-grid .even .f2")).to include_text "0/ 1"
        expect(f("#jobs-grid .odd .f2")).to include_text "0/ 1"
        expect(jobs_on_hold.count).to eq 0
      end

      it "confirms that future jobs were selected" do
        filter_jobs("Future")
        f("#jobs-refresh").click
        wait_for_ajax_requests
        job = Delayed::Job.where(tag: "String#capitalize").first
        expect(f("#jobs-grid .b0").text).to eq job.id.to_s
      end

      it "confirms that failed jobs were selected" do
        filter_jobs("Failed")
        f("#jobs-refresh").click
        wait_for_ajax_requests
        expect(ff("#jobs-grid .slick-row").count).to eq 1
        expect(f("#jobs-grid .f1")).to include_text "String#downcase"
      end

      it "confirms that clicking on delete button should delete all future jobs" do
        2.times { "test".delay(run_at: 2.hours.from_now).to_s }
        filter_jobs("Future")
        validate_all_jobs_selected
        expect(f("#jobs-grid .odd")).to be_displayed
        expect(f("#jobs-grid .even")).to be_displayed
        expect(f("#jobs-total").text).to eq "3"
        expect(future_jobs.count).to eq 3
        num_of_jobs = Delayed::Job.count

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
    it "displays running jobs in the workers grid" do
      Delayed::Job.get_and_lock_next_available("my test worker")
      load_jobs_page
      expect(ff("#running-grid .slick-row").size).to eq 1
      first_cell = f("#running-grid .slick-cell.b0.f0")
      expect(first_cell).to include_text "my test worker"
    end

    it "sorts by runtime by default" do
      Delayed::Job.get_and_lock_next_available("my test worker 1")
      j2 = Delayed::Job.get_and_lock_next_available("my test worker 2")
      j2.update_attribute(:locked_at, 48.hours.ago)

      load_jobs_page
      expect(ff("#running-grid .slick-row").size).to eq 2
      first_cell = f("#running-grid .slick-cell.b0.f0")
      expect(first_cell).to include_text "my test worker 2"
      last_cell = f("#running-grid .slick-cell.b7.f7 .super-slow")
      expect(last_cell).not_to be_nil
    end

    it "sorts dynamically" do
      Delayed::Job.get_and_lock_next_available("my test worker 1")
      Delayed::Job.get_and_lock_next_available("my test worker 2")

      load_jobs_page
      expect(ff("#running-grid .slick-row").size).to eq 2
      # sort ASC
      worker_header = f("#running-grid .slick-header div[id*='worker'] .slick-column-name")
      worker_header.click
      first_cell = f("#running-grid .slick-cell.b0.f0")
      expect(first_cell).to include_text "my test worker 1"

      # sort DESC
      worker_header.click
      first_cell = f("#running-grid .slick-cell.b0.f0")
      expect(first_cell).to include_text "my test worker 2"
    end
  end
end
