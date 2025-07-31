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

# A service for generating reports for site administrators.
# This service requires a block to be provided that will generate the content of the report.
# It also requires the user to be a site administrator.
#
# The service will create a report file and save it to the subclasses specified attachment folder.
# If an error occurs during report generation, it will save an error report instead.
#
# This is an abstract class and should be subclassed to implement the specific report generation logic.
# See FlamegraphService or NPlusOneDetectionService for examples of subclasses.
# You should implement the following methods in subclasses:
# - `create_report_file`: Generates a report file using the provided block.
# - `attachment_folder`: Returns the folder where the report will be saved.
# - `report_type`: Returns the type of report being generated.
# - `content_type`: Returns the MIME type of the report file. If you don't override this method,
# it defaults to "text/plain".
class SiteAdminReportingService < ApplicationService
  class NoBlockError < StandardError; end
  class NonSiteAdminError < StandardError; end

  MAX_BACKTRACE_LINES = 1_000

  attr_reader :user,
              :source_name,
              :custom_name,
              :block

  def initialize(user:, source_name:, custom_name: nil, &block)
    super()
    raise NoBlockError, "Must provide a block!" unless block_given?

    @user = user
    @source_name = source_name
    @custom_name = custom_name
    @block = block
  end

  def call
    raise NonSiteAdminError, "Must be a siteadmin user!" unless Account.site_admin.grants_right?(user, :update)

    begin
      Tempfile.create do |file|
        create_report(file)
        file.rewind
        create_attachment(file)
      end
    rescue => e
      save_error_to_attachment(e)
    end
  end

  private

  # Creates a report. To be implemented in subclasses. The block attribute should
  # be used to generate the content of the report.
  # @param file [File] The file to write the report content to.
  # Do not close this file, as it will be closed by the caller.
  def create_report(_file)
    raise "Abstract method, please implement in subclass"
  end

  # Returns the folder where the report will be saved.
  # @return [Folder] The folder where the report will be saved.
  def attachment_folder
    raise "Abstract method, please implement in subclass"
  end

  # Returns the type of report being generated.
  # @return [String] The type of report.
  def report_type
    raise "Abstract method, please implement in subclass"
  end

  # Returns the type of the file being generated using the typical
  # MIME type format.
  # @return [String] The MIME type of the report file. Defaults to "text/plain".
  def content_type
    "text/plain"
  end

  # Save a file to one of the user's attachment folders.
  # @param file [File] A file containing the report or an error message.
  # @param is_error [Boolean] Whether the file is an error report.
  def create_attachment(file, is_error: false)
    display_name = title(is_error:)
    attachment_folder.attachments.create!(
      context: user,
      root_account: Account.site_admin,
      content_type:,
      uploaded_data: file,
      filename: "#{display_name}.#{MIME::Types[content_type]&.first&.preferred_extension || "txt"}",
      display_name:
    )
  end

  def title(is_error:)
    common_title = [custom_name.presence, source_name, Time.now.iso8601].compact.join("-")

    if is_error
      "#{report_type}-error-#{common_title}"
    else
      "#{report_type}-#{common_title}"
    end
  end

  def save_error_to_attachment(error)
    StringIO.open do |file|
      create_error_html_file(error, file)
      create_attachment(file, is_error: true)
    end
  end

  def create_error_html_file(error, file)
    html = error_html(error)
    file.print(html)
    file.rewind
  end

  def error_html(error)
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>Error Generating #{report_type.titleize}</title>
        </head>
        <body>
          <h1>Error Generating #{report_type.titleize}</h1>
          <h2>#{error.detailed_message}</h2>
          <pre><code>#{backtrace_sample(error)}</code></pre>
        </body>
      </html>
    HTML
  end

  def backtrace_sample(error)
    error.backtrace.first(MAX_BACKTRACE_LINES).join("\n")
  end
end
