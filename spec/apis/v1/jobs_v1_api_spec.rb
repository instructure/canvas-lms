# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

require_relative "../api_spec_helper"

describe "Jobs V1 API", type: :request do
  before :once do
    @site_admin_user = site_admin_user(active_all: true)
    @regular_admin_user = account_admin_user(account: Account.default, active_all: true)

    @jobs = []
    3.times do |i|
      job = Delayed::Job.new(tag: "TestTag#{i}", strand: "TestStrand#{i}")
      job.save!
      @jobs << job
    end
  end

  def call_index(session_user, params = {})
    api_call_as_user(
      session_user,
      :get,
      "/api/v1/jobs",
      { controller: "jobs", action: "index", format: "json" }.merge(params),
      {},
      {},
      { expected_status: params[:expected_status] || 200 }
    )
  end

  def call_show(session_user, id, params = {})
    api_call_as_user(
      session_user,
      :get,
      "/api/v1/jobs/#{id}",
      { controller: "jobs", action: "show", id: id.to_s, format: "json" }.merge(params),
      {},
      {},
      { expected_status: params[:expected_status] || 200 }
    )
  end

  def call_batch_update(session_user, params = {})
    params[:update_action] ||= "hold"
    api_call_as_user(
      session_user,
      :post,
      "/api/v1/jobs/batch_update",
      { controller: "jobs", action: "batch_update", format: "json" }.merge(params),
      { update_action: params[:update_action], job_ids: params[:job_ids] || [] },
      {},
      { expected_status: params[:expected_status] || 200 }
    )
  end

  describe "GET /api/v1/jobs (index)" do
    it "allows site admin with :view_jobs permission" do
      call_index(@site_admin_user, { only: "jobs" })
    end

    it "doesn't allow non-site-admins" do
      call_index(@regular_admin_user, { only: "jobs", expected_status: 403 })
    end
  end

  describe "GET /api/v1/jobs/:id (show)" do
    let_once(:job_id) { @jobs.first.id }

    it "allows site admin with :view_jobs permission" do
      call_show(@site_admin_user, job_id)
    end

    it "doesn't allow non-site-admins" do
      call_show(@regular_admin_user, job_id, { expected_status: 403 })
    end
  end

  describe "PUT /api/v1/jobs/batch_update" do
    let_once(:job_ids) { @jobs.map(&:id) }
    it "allows site admin with :manage_jobs permission" do
      call_batch_update(@site_admin_user, { job_ids: })
    end

    it "doesn't allow non-site-admins" do
      call_batch_update(@regular_admin_user, { job_ids:, expected_status: 403 })
    end
  end
end
