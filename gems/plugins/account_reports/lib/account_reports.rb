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

require "account_reports/engine"
require "zip"

module AccountReports
  class << self
    attr_writer :handle_error
  end

  # This hash is modified below and should not be frozen.
  REPORTS = {} # rubocop:disable Style/MutableConstant

  Report = Struct.new(:type, :title, :description_partial, :parameters_partial, :parameters, :module, :proc, :parallel_proc) do
    def module_name
      if self[:module].include?("::")
        self[:module]
      else
        "AccountReports::#{self[:module]}"
      end
    end

    def module_class
      module_name.constantize
    end

    def proc
      unless self[:proc]
        self.proc = module_class.method(type)
      end
      self[:proc]
    end

    def parameters
      self.parameters = :account_report_parameters if self[:parameters].nil?

      begin
        case (p = self[:parameters])
        when Proc
          self.parameters = instance_exec(&p)
        when Symbol
          self.parameters = module_class.send(p)
        else
          p
        end
      rescue => e
        Rails.logger.error(e)
        self.parameters = {}
      end
    end

    def parallel_proc
      unless instance_variable_defined?(:@parallel_proc)
        @parallel_proc = self[:parallel_proc] ||
                         (module_class.public_methods.include?(:"parallel_#{type}") &&
                         module_class.method(:"parallel_#{type}"))
      end
      @parallel_proc
    end

    def title
      title = self[:title]
      title = title.call if title.respond_to?(:call)
      title
    end
  end

  def self.configure_account_report(module_name, reports)
    reports.each do |report_type, details|
      details[:module] ||= module_name
      report = Report.new(report_type,
                          details[:title],
                          details[:description_partial],
                          details[:parameters_partial],
                          details[:parameters],
                          details[:module],
                          details[:proc],
                          details[:parallel_proc])
      REPORTS[report_type] = report
    end
  end

  def self.available_reports
    settings = Canvas::Plugin.find(:account_reports).settings
    return REPORTS.dup unless settings

    enabled_reports = settings.select { |_report, enabled| enabled }.map(&:first)
    REPORTS.select { |report, _details| enabled_reports.include?(report) }
  end

  def self.generate_report(account_report, attempt: 1)
    account_report.capture_job_id
    account_report.update(workflow_state: "running", start_at: Time.zone.now)
    begin
      I18n.with_locale(account_report.parameters["locale"]) do
        REPORTS[account_report.report_type].proc.call(account_report)
      end
    rescue => e
      if retry_exception?(e) && attempt < Setting.get("account_report_attempts", "3").to_i
        account_report.run_report(attempt: attempt + 1) # this will queue a new job
        return
      end
      error_report_id = report_on_exception(e, { user: account_report.user })
      title = account_report.report_type.to_s.titleize
      error_message = "Generating the report, #{title}, failed."
      error_message += if error_report_id
                         " Please report the following error code to your system administrator: ErrorReport:#{error_report_id}"
                       else
                         " Unable to create error_report_id for #{e}"
                       end
      finalize_report(account_report, error_message)
      @er = nil
    end
  end

  def self.retry_exception?(exception)
    exception.is_a?(PG::ConnectionBad)
  end

  def self.report_on_exception(exception, context, level: :error)
    if @handle_error.respond_to?(:call)
      capture_outputs = @handle_error.call(exception, context, level)
      # return the error_report id
      capture_outputs[:error_report]
    else
      Rails.logger.error(exception)
      nil
    end
  end

  def self.generate_file_name(account_report)
    "#{account_report.report_type}_#{Time.zone.now.strftime("%d_%b_%Y")}_#{account_report.id}"
  end

  def self.generate_file(account_report, ext = "csv")
    temp = Tempfile.open([generate_file_name(account_report), ".#{ext}"])
    filepath = temp.path
    temp.close!
    filepath
  end

  def self.report_attachment(account_report, csv = nil)
    attachment = nil
    if csv.is_a? Hash
      filename = generate_file_name(account_report)
      temp = Tempfile.open([filename, ".zip"])
      filepath = temp.path
      filename += ".zip"
      temp.close!

      Zip::File.open(filepath, Zip::File::CREATE) do |zipfile|
        csv.each do |report_name, contents|
          zipfile.add(report_name + ".csv", contents)
        end
        zipfile.close
        zipfile
      end
      filetype = "application/zip"
    elsif csv
      ext = !csv.include?("\n") && File.extname(csv)
      case ext
      when ".csv"
        filename = File.basename(csv)
        filepath = csv
        filetype = "text/csv"
      when ".zip"
        filetype = "application/zip"
      when ".txt"
        filename = File.basename(csv)
        filepath = csv
        filetype = "text/rtf"
      else
        filename = generate_file_name(account_report)
        f = Tempfile.open([filename, ".csv"])
        f << csv
        f.close
        filepath = f.path
        filetype = "text/csv"
      end
    end
    if filename
      data = Canvas::UploadedFile.new(filepath, filetype)
      # have to branch here because calling the uploaded_data= method on attachment
      # (done in the Attachments::Storage method) triggers an attachment_fu save
      # callback which is handled differently than creating the attachment using
      # the create! uploaded_data method, and assigns a different filename
      # which report_attachment tests for :/

      if InstFS.enabled?
        attachment = account_report.account.attachments.new
        begin
          retries ||= 0
          Attachments::Storage.store_for_attachment(attachment, data)
        rescue Timeout::Error
          retries += 1
          sleep 3 * retries
          retry if retries < 3
          raise
        end
        attachment.display_name = filename
        attachment.filename = filename
        attachment.user = account_report.user
        attachment.save!
      else
        attachment = account_report.account.attachments.create!(
          uploaded_data: data,
          display_name: filename,
          filename:,
          user: account_report.user
        )
      end
    end
    account_report.attachment = attachment
  end

  def self.failed_report(account_report)
    fail_text = if @er
                  I18n.t("Failed, please report the following error code to your system administrator: ErrorReport:%{error};",
                         error: @er.id.to_s)
                else
                  I18n.t("Failed, the report failed to generate a file. Please try again.")
                end
    account_report.parameters["extra_text"] = fail_text
  end

  def self.finalize_report(account_report, message, csv = nil)
    report_attachment(account_report, csv)
    account_report.message = message
    failed_report(account_report) unless csv
    if account_report.workflow_state == "aborted"
      account_report.parameters["extra_text"] = I18n.t("Report has been aborted")
    else
      account_report.workflow_state = csv ? "complete" : "error"
    end
    account_report.update_attribute(:progress, 100)
    account_report.end_at ||= Time.zone.now
    account_report.save!
    message_recipient(account_report)
  end

  def self.message_recipient(account_report)
    return account_report if account_report.parameters["skip_message"]

    notification = account_report.attachment ? NotificationFinder.new.by_name("Report Generated") : NotificationFinder.new.by_name("Report Generation Failed")
    notification&.create_message(account_report, [account_report.user])
  end
end
