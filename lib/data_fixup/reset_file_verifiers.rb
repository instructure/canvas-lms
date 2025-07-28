# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup::ResetFileVerifiers
  # Run this to reset all file verifier tokens on all not deleted attachments for a given account.
  # A CSV file will be created with the former and new UUIDs in the case that a rollback is needed.
  def self.run
    base_file_name = "#{Shard.current.id}_former_uuids_#{Time.now.to_i}"
    file_name = "#{base_file_name}.csv"
    error_file_name = "#{base_file_name}_errors.csv"
    csv = CSV.open(file_name, "w")
    error_csv = nil
    csv << %w[attachment_id former_uuid new_uuid]
    Attachment.not_deleted.find_each(strategy: :pluck_ids) do |attachment|
      attachment_id = attachment.id
      former_uuid = attachment.uuid
      begin
        attachment.reset_uuid!
        new_uuid = attachment.uuid
        csv << [attachment_id, former_uuid, new_uuid]
      rescue => e
        error_csv = CSV.open(error_file_name, "a")
        error_csv << [Shard.current.id, "attachment_id", e.message]
        error_csv.close
      end
    end
    csv.close
    # Save output to attachments
    Attachment.create!(filename: file_name, uploaded_data: File.open(csv.path), context: Account.site_admin, content_type: "text/csv") if File.exist?(csv.path)
    Attachment.create!(filename: error_file_name, uploaded_data: File.open(error_csv.path), context: Account.site_admin, content_type: "text/csv") if error_csv && File.exist?(error_csv.path)
    # Clean up
    FileUtils.rm_f(csv.path)
    FileUtils.rm_f(error_csv.path) if error_csv
  end
end
