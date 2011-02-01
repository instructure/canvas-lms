#
# Copyright (C) 2011 Instructure, Inc.
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
  REPORT_TO_SEND = "counts_progressive_overview"

  after_create :push_to_instructure_if_collection_enabled

  def self.report_value_over_time(report, key)
    items = []
    report['monthly'].each do |month|
      if month[key]
        date = Date
        stamp = ((Time.utc(month['year'], month['month'], 1).to_date >> 1) - 1.day).to_time.to_i
        items << [stamp*1000, month[key]]
      end
    end
    report['weekly'].each do |week|
      if week[key]
        stamp = (week['week'] * 604800) + ((week['year'] - 1970) * 31556926)
        items << [stamp*1000, week[key]]
      end
    end
    items.sort_by(&:first).once_per(&:first)
  end
  
  def self.get_account_detail_over_time(type, id, key)
    report = get_account_details_by_type_and_id(type, id)
    report_value_over_time(report, key)
  end
  
  def self.get_category_detail_over_time(type, category, key)
    count_data = ReportSnapshot.get_last_data_by_type(type)
    category_details = count_data[category] if count_data
    if count_data and category_details
      category_details['generated_at'] = count_data['generated_at']
    end
    report_value_over_time(category_details, key)
  end
  
  def self.get_last_data_by_type(type)
    count_data = nil
    begin
      snap = ReportSnapshot.find_last_by_report_type(type)
      if snap
        count_data = JSON.parse(snap.data)
        count_data['generated_at'] = Time.at(count_data['generated_at'].to_i/1000)
      end
    rescue
      nil
    end
    count_data
  end
  
  def self.get_account_details_by_type_and_id(type, id)
    school_details = nil
    begin
      count_data = ReportSnapshot.get_last_data_by_type(type)
      school_details = count_data['detailed'][id.to_s] if count_data and count_data['detailed']
      if count_data and school_details
        school_details['generated_at'] = count_data['generated_at']
      end
    rescue
      nil
    end
    school_details
  end
  
  def push_to_instructure_if_collection_enabled
    begin
      return if self.report_type != REPORT_TO_SEND
      collection_type = Setting.get("usage_statistics_collection", "opt_out")
      return if collection_type  == "opt_out"
      
      installation_uuid = Setting.get("installation_uuid", "")
      if installation_uuid == ""
        installation_uuid = UUIDSingleton.instance.generate
        Setting.set("installation_uuid", installation_uuid)
      end
  
      require 'lib/ssl_common'
      
      data = {
          "collection_type" => collection_type,
          "installation_uuid" => installation_uuid,
          "report_type" => self.report_type,
          "data" => self.data,
          "rails_env" => RAILS_ENV
        }

      if collection_type == "opt_in"
        data["account_name"] = Account.default.name
        data["admin_email"] = Account.site_admin.users.first.pseudonyms.first.unique_id
      end
      
      SSLCommon.post_form(STATS_COLLECTION_URL, data)
    rescue
    end
  end
end
