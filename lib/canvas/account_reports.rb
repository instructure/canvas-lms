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
  class AvailableReports
    @reports = {}
    @module_names = {}
    class << self
      attr_reader :reports, :module_names
      private :new
    end
  end

  def self.add_account_reports(account_id, module_name, reports)
    AvailableReports.reports[account_id] = reports
    AvailableReports.module_names[account_id] = module_name
  end

  def self.for_account(id)
    (AvailableReports.reports['default'] || {}).merge(AvailableReports.reports[id] || {})
  end

  def self.generate_report(account_report)
    account_report.update_attribute(:workflow_state, 'running')
    account_report.start_at ||= 2.months.ago
    account_report.end_at ||= Time.now
    begin
      module_name = AvailableReports.module_names[account_report.root_account.id]
      if module_name && Canvas::AccountReports.const_defined?(module_name) &&
              Canvas::AccountReports.const_get(module_name).respond_to?(account_report.report_type)
        Canvas::AccountReports.const_get(module_name).send(account_report.report_type, account_report)
      elsif Canvas::AccountReports.const_defined?('Default') &&
              Canvas::AccountReports.const_get('Default').respond_to?(account_report.report_type)
        Canvas::AccountReports.const_get('Default').send(account_report.report_type, account_report)
      else
        nil
      end
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
        csv.each do |(report_name, contents)|
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
