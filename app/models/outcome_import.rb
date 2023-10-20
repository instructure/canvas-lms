# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class OutcomeImport < ApplicationRecord
  include Workflow
  belongs_to :context, polymorphic: %i[account course], required: true
  belongs_to :attachment
  belongs_to :user
  has_many :outcome_import_errors

  validates :workflow_state, presence: true

  workflow do
    state :initializing
    state :created do
      event :job_started, transitions_to: :importing do
        context.update!(latest_outcome_import: self)
      end
    end
    state :importing do
      event :job_completed, transitions_to: :succeeded
      event :job_failed, transitions_to: :failed
    end
    state :succeeded
    state :failed
  end

  IMPORT_TYPES = %w[instructure_csv].freeze

  def self.valid_import_type?(type)
    IMPORT_TYPES.include? type
  end

  # If you are going to change any settings on the import before it's processed,
  # do it in the block passed into this method, so that the changes are saved
  # before the import is marked created and eligible for processing.
  def self.create_with_attachment(context, import_type, attachment, user = nil, learning_outcome_group_id = nil)
    import = OutcomeImport.create!(
      context:,
      learning_outcome_group_id:,
      progress: 0,
      workflow_state: :initializing,
      data: { import_type: },
      user:
    )

    att = Attachment.create_data_attachment(import, attachment, "outcome_upload_#{import.global_id}.csv")
    import.attachment = att

    yield import if block_given?
    import.workflow_state = :created
    import.save!

    import
  end

  def as_json(_options = {})
    data = {
      "id" => id,
      "created_at" => created_at,
      "ended_at" => ended_at,
      "updated_at" => updated_at,
      "progress" => progress,
      "workflow_state" => workflow_state,
      "data" => self.data
    }
    data["processing_errors"] = outcome_import_errors.order(:row).limit(25).pluck(:row, :message)
    data
  end

  delegate :root_account, to: :context

  def schedule
    delay(strand: "OutcomeImport::run::#{root_account.global_id}").run
  end

  def locale
    if context.respond_to? :account
      context.account.default_locale
    elsif context.respond_to? :default_locale
      context.default_locale
    end
  end

  def run
    file = nil
    root_account.shard.activate do
      job_started!
      I18n.with_locale(locale) do
        file = attachment.open

        Outcomes::CSVImporter.new(self, file).run do |status|
          status[:errors].each do |row, error|
            add_error row, error
          end
          update!(progress: status[:progress])
        end
      end

      job_completed!
    rescue Outcomes::Import::DataFormatError => e
      add_error(1, e.message, true)
      job_failed!
    rescue => e
      report = ErrorReport.log_exception("outcomes_import", e)
      # no I18n on error report id
      add_error(1, I18n.t("An unexpected error has occurred: see error report %{id}", id: report.id.to_s), true)
      job_failed!
    ensure
      file.close
      notify_user
    end
  end

  def add_error(row, error, failure = false)
    outcome_import_errors.create!(
      row:,
      message: error,
      failure:
    )
  end

  private

  def notify_user
    return unless user

    subject, body = import_message_body
    message = Message.new({
                            to: user.email,
                            from: "notifications@instructure.com",
                            subject:,
                            body:,
                            delay_for: 0,
                            context: nil,
                            path_type: "email",
                            from_name: "Instructure Canvas"
                          })
    message.communication_channel = user.email_channel
    message.user = user
    message.save
    message.deliver
  end

  def error_count
    return outcome_import_errors.count unless succeeded? || failed?

    @error_count ||= outcome_import_errors.loaded? ? outcome_import_errors.size : outcome_import_errors.count
  end

  def n_errors(n = 25)
    if outcome_import_errors.loaded?
      outcome_import_errors.sort_by(&:row).first(n).pluck(:row, :message)
    else
      outcome_import_errors.order(:row).limit(n).pluck(:row, :message)
    end
  end

  def import_message_body
    url = "#{HostUrl.protocol}://#{HostUrl.context_host(context)}/#{context.class.to_s.downcase.pluralize}/#{context_id}/outcomes"
    if succeeded?
      subject = I18n.t "Outcomes Import Completed"
      user_name = user.name.split("@").first
      if error_count == 0
        body = I18n.t(<<~TEXT, name: user_name, url:).gsub(/^ +/, "")
          Hello %{name},

          Your outcomes were successfully imported. You can now manage them at %{url}

          Thank you,
          Instructure
        TEXT
      else
        rows = n_errors(100).map { |r, m| I18n.t("Row %{row}: %{message}", row: r, message: m) }.join("\n")
        body = I18n.t(<<~TEXT, name: user_name, rows:, url:).gsub(/^ +/, "")
          Hello %{name},

          Your outcomes were successfully imported, but with the following issues (up to the first 100 warnings):

          %{rows}

          You can now manage them at %{url}

          Thank you,
          Instructure
        TEXT
      end
    else
      subject = I18n.t "Outcomes Import Failed"
      user_name = user.name.split("@").first
      doc_url = "#{HostUrl.protocol}://#{HostUrl.context_host(context)}/doc/api/file.outcomes_csv.html"
      row = n_errors(1).map { |r, m| I18n.t("Row %{row}: %{message}", row: r, message: m) }.first
      body = I18n.t(<<~TEXT, name: user_name, row:, doc_url:, url:).gsub(/^ +/, "")
        Hello %{name},

        Your outcomes import failed due to an error with your import. Please examine your file and attempt the upload again at %{url}

        The following error occurred:
        %{row}

        To view the proper import format, please review the Canvas API Docs at %{doc_url}

        Thank you,
        Instructure
      TEXT
    end

    [subject, body]
  end
end
