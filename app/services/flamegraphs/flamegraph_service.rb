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

class Flamegraphs::FlamegraphService < ApplicationService
  class NoBlockError < StandardError; end
  class NonSiteAdminError < StandardError; end

  SAMPLING_INTERVAL_MICROSECONDS = 1_000

  def initialize(user:, source_name:, custom_name: nil, &block)
    super()
    raise NoBlockError, "Must provide a block!" unless block_given?

    @user = user
    @source_name = source_name
    @custom_name = custom_name
    @block = block
  end

  def call
    raise NonSiteAdminError, "Must be a siteadmin user!" unless Account.site_admin.grants_right?(@user, :update)

    report = create_report
    save_flamegraph_to_attachment(report)
  end

  private

  def create_report
    Tempfile.create do |file|
      StackProf.run(
        mode: :wall,
        raw: true,
        ignore_gc: true,
        out: file,
        interval: SAMPLING_INTERVAL_MICROSECONDS,
        &@block
      )
      StackProf::Report.from_file(file)
    end
  end

  def save_flamegraph_to_attachment(report)
    StringIO.open do |file|
      create_d3_flamegraph_file(report, file)
      create_attachment(file)
    end
  end

  def create_d3_flamegraph_file(report, file)
    report.print_d3_flamegraph(file)
    file.rewind
  end

  def create_attachment(file)
    @user.flamegraphs_folder.attachments.create!(
      context: @user,
      root_account: Account.site_admin,
      content_type: "text/html",
      uploaded_data: file,
      display_name: title,
      filename: "#{title}.html"
    )
  end

  def title
    @title ||= ["flamegraph", @custom_name.presence, @source_name, Time.now.iso8601].compact.join("-")
  end
end
