#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require 'zip'
require 'action_controller_test_process'

module Canvas::AccountReports

  REPORTS = {}

  # account id is ignored; use PluginSetting to enable a subset of reports
  def self.add_account_reports(account_id, module_name, reports)
    reports.each do |report_type, details|
      details = {:title => details} if details.is_a? String
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
    account_report.start_at ||= Time.now
    begin
      REPORTS[account_report.report_type][:proc].call(account_report)
    rescue => e
      account_report.logger.error e
      @er = ErrorReport.log_exception(nil, e, :user => account_report.user)
      self.message_recipient(account_report, "Generating the report, #{account_report.report_type.to_s.titleize}, failed.  Please report the following error code to your system administrator: ErrorReport:#{@er.id}")
    end
  end

  def self.generate_file_name(account_report, ext)
    "#{account_report.report_type}_#{Time.now.strftime('%d_%b_%Y')}_#{account_report.id}_.#{ext}"
  end

  def self.generate_file(account_report, ext = 'csv')
    temp = Tempfile.open(generate_file_name(account_report, ext))
    filepath = temp.path
    temp.close!
    filepath
  end

  def self.report_attachment(account_report, csv=nil)
    attachment = nil
    if csv.is_a? Hash
      filename = generate_file_name(account_report, "zip")
      temp = Tempfile.open(filename)
      filepath = temp.path
      temp.close!

      Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
        csv.each do |report_name, contents|
          zipfile.add(report_name + ".csv", contents)
        end
        zipfile.close
        zipfile
      end
      filetype = 'application/zip'
    elsif csv
      ext = csv !~ /\n/ && File.extname(csv)
      case ext
        when ".csv"
          filename = File.basename(csv);
          filepath = csv
          filetype = 'text/csv'
        when ".zip"
          filetype = 'application/zip'
        when ".txt"
          filename = File.basename(csv);
          filepath = csv
          filetype = 'text/rtf'
        else
          filename = generate_file_name(account_report, "csv")
          f = Tempfile.open(filename)
          f << csv
          f.close
          filepath = f.path
          filetype = 'text/csv'
      end
    end
    if filename
      attachment = account_report.account.attachments.create!(
        :uploaded_data => Rack::Test::UploadedFile.new(filepath, filetype, true),
        :display_name => filename,
        :user => account_report.user
      )
    end
    attachment.uploaded_data = Rack::Test::UploadedFile.new(filepath, filetype, true)
    attachment.save
    attachment
  end

  def self.message_recipient(account_report, message, csv=nil)
    notification = Notification.by_name("Report Generated")
    notification = Notification.by_name("Report Generation Failed") if !csv
    attachment = report_attachment(account_report, csv) if csv
    account_report.message = message
    account_report.parameters ||= {}
    account_report.parameters["extra_text"] = (I18n.t('account_reports.default.error_text',
      "Failed, please report the following error code to your system administrator: ErrorReport:%{error};",
      :error => @er.id)) if !csv
    account_report.attachment = attachment
    account_report.workflow_state = csv ? 'complete' : 'error'
    account_report.update_attribute(:progress, 100)
    account_report.end_at ||= Time.now
    account_report.save
    notification.create_message(account_report, [account_report.user])
    message
  end

end
