# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class ReportSnapshot < ActiveRecord::Base
  STATS_COLLECTION_URL = "https://stats.instructure.com/stats_collection"
  REPORT_TO_SEND = "counts_progressive_detailed"

  belongs_to :account

  after_create :push_to_instructure_if_collection_enabled
  before_save :serialize_data

  def self.report_value_over_time(report, key)
    items = []
    now = Time.now.utc.to_i
    report["monthly"].each do |month|
      next unless month[key]

      stamp = ((Time.utc(month["year"], month["month"], 1).to_date >> 1) - 1.day).to_time.to_i
      next if stamp > now

      items << [stamp.to_i * 1000, month[key]]
    end
    report["weekly"].each do |week|
      next unless week[key]

      stamp = (week["week"] * 604_800) + ((week["year"] - 1970) * 31_556_926)
      next if stamp > now

      items << [stamp * 1000, week[key]]
    end
    items.sort_by(&:first).uniq(&:first)
  end

  def report_value_over_time(*args)
    if args.length == 1
      ReportSnapshot.report_value_over_time(data, args.first)
    else
      ReportSnapshot.report_value_over_time(data[args.first], args.last)
    end
  end

  def data
    unless @data
      @data = JSON.parse(read_attribute(:data) || "{}")
      @data["generated_at"] = Time.at(@data["generated_at"].to_i / 1000) if @data["generated_at"]
    end
    @data
  end

  def data=(new_data)
    @data = new_data || {}
  end

  def serialize_data
    return unless @data

    data = @data.dup
    data["generated_at"] = data["generated_at"].to_i * 1000 if data["generated_at"]
    write_attribute(:data, data.to_json)
  end

  scope :detailed, -> { where(report_type: "counts_detailed") }
  scope :progressive, -> { where(report_type: "counts_progressive_detailed") }

  def push_to_instructure_if_collection_enabled
    return if report_type != REPORT_TO_SEND
    return if account != Account.default

    collection_type = Setting.get("usage_statistics_collection", "opt_out")
    return if collection_type == "opt_out"

    data = {
      "collection_type" => collection_type,
      "installation_uuid" => Canvas.installation_uuid,
      "report_type" => report_type,
      "data" => read_attribute(:data),
      "rails_env" => Rails.env
    }

    if collection_type == "opt_in"
      data["account_name"] = Account.default.name
      data["admin_email"] = Account.site_admin.users.first.pseudonyms.first.unique_id
    end

    SSLCommon.post_form(STATS_COLLECTION_URL, data)
  rescue
    nil
  end
end
