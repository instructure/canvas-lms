#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require 'zip/zip'

module Canvas::AccountReports
  REPORTS = {}

  # account id is ignored; use PluginSetting to enable a subset of reports
  def self.add_account_reports(account_id, module_name, reports)
    reports.each do |report_type, details|
      details = { :title => details } if details.is_a? String
      details[:module] ||= module_name
      details[:proc] ||= "Canvas::AccountReports::#{module_name}".constantize.method(report_type)
      REPORTS[report_type] = details
    end
  end

  # again, id is ignored; use PluginSetting to enable a subset of reports
  def self.for_account(id)
    settings = Canvas::Plugin.find(:account_reports).settings
    return REPORTS.dup unless settings
    enabled_reports = settings.select { |report, enabled| enabled }.map(&:first)
    Hash[*REPORTS.select { |report, details| enabled_reports.include?(report) }.flatten]
  end

  def self.generate_report(account_report)
    account_report.update_attribute(:workflow_state, 'running')
    account_report.start_at ||= 2.months.ago
    account_report.end_at ||= Time.now
    begin
      REPORTS[account_report.report_type][:proc].call(account_report)
    rescue => e
      account_report.logger.error e
      er = ErrorReport.log_exception(:default, e, :user => account_report.user)
      self.message_recipient(account_report, "Generating the report, #{account_report.report_type.to_s.titleize}, failed.  Please report the following error code to your system administrator: ErrorReport:#{er.id}")
    end
  end

  def self.message_recipient(account_report, message, csv=nil)
    user = account_report.user
    account = account_report.account
    notification = Notification.by_name("Report Generated")
    notification = Notification.by_name("Report Generation Failed") if !csv
    attachment = nil
    if csv.is_a? Hash
      filename = "#{account_report.report_type}_#{Time.now.strftime('%d_%b_%Y')}_#{account_report.id}_.zip"
      temp = Tempfile.open(filename)
      filepath = temp.path
      temp.close
      FileUtils::rm temp.path

      Zip::ZipFile.open(filepath, Zip::ZipFile::CREATE) do |zipfile|
        csv.each do |report_name, contents|
          zipfile.get_output_stream(report_name + ".csv") { |f| f << contents }
        end
        zipfile
      end
      filetype = 'application/zip'
    elsif csv
      require 'action_controller'
      require 'action_controller/test_process.rb'
      filename = "#{account_report.report_type}_#{Time.now.strftime('%d_%b_%Y')}_#{account_report.id}_.csv"
      f = Tempfile.open(filename)
      f << csv
      f.close
      filepath = f.path
      filetype = 'text/csv'
    end
    if filename
      attachment = account.attachments.create!(
              :uploaded_data => ActionController::TestUploadedFile.new(filepath, filetype, true),
              :display_name => filename,
              :user => user
      )
    end
    account_report.message = message
    account_report.attachment = attachment
    account_report.workflow_state = csv ? 'complete' : 'error'
    account_report.update_attribute(:progress, 100)
    account_report.save
    notification.create_message(account_report, [user])
    message
  end

end
