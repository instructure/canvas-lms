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
  belongs_to :context, polymorphic: %i[account course]
  belongs_to :attachment
  belongs_to :user
  has_many :outcome_import_errors

  validates :context_type, presence: true
  validates :context_id, presence: true
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

  IMPORT_TYPES = %w(instructure_csv).freeze

  def self.valid_import_type?(type)
    IMPORT_TYPES.include? type
  end

  # If you are going to change any settings on the import before it's processed,
  # do it in the block passed into this method, so that the changes are saved
  # before the import is marked created and eligible for processing.
  def self.create_with_attachment(context, import_type, attachment, user = nil)
    import = OutcomeImport.create!(
      context: context,
      progress: 0,
      workflow_state: :initializing,
      data:  { import_type: import_type },
      user: user
    )

    att = create_data_attachment(import, attachment, "outcome_upload_#{import.global_id}.csv")
    import.attachment = att

    yield import if block_given?
    import.workflow_state = :created
    import.save!

    import
  end

  def self.create_data_attachment(import, data, display_name)
    Attachment.new.tap do |att|
      Attachment.skip_3rd_party_submits(true)
      att.context = import
      att.uploaded_data = data
      att.display_name = display_name
      att.save!
    end
  ensure
    Attachment.skip_3rd_party_submits(false)
  end

  def as_json(_options={})
    data = {
      "id" => self.id,
      "created_at" => self.created_at,
      "ended_at" => self.ended_at,
      "updated_at" => self.updated_at,
      "progress" => self.progress,
      "workflow_state" => self.workflow_state,
      "data" => self.data
    }
    data["processing_errors"] = self.outcome_import_errors.order(:row).limit(25).pluck(:row, :message)
    data
  end

  def root_account
    context.root_account
  end

  def schedule
    send_later_enqueue_args(:run, {
      strand: "OutcomeImport::run::#{root_account.global_id}"
    })
  end

  def run
    root_account.shard.activate do
      job_started!
      file = self.attachment.open(need_local_file: true)
      begin
        Outcomes::CsvImporter.new(self, file).run do |status|
          status[:errors].each do |row, error|
            add_error row, error
          end
          self.update!(progress: status[:progress])
        end

        if error_count == 0
          job_completed!
        else
          job_failed!
        end
      rescue
        add_error(1, I18n.t('An unexpected error has occurred'))
        job_failed!
        raise
      ensure
        file.close
        notify_user
      end
    end
  end

  def add_error(row, error)
    outcome_import_errors.create!(
      row: row,
      message: error
    )
  end

  private

  def notify_user
    return unless user

    subject, body = import_message_body
    message = Message.new({
      to: user.email,
      from: "notifications@instructure.com",
      subject: subject,
      body: body,
      delay_for: 0,
      context: nil,
      path_type: 'email',
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
      subject = I18n.t 'Outcomes Import Completed'
      user_name = user.name.split('@').first
      body = I18n.t(<<-BODY, name: user_name, url: url).gsub(/^ +/, '')
      Hello %{name},

      Your outcomes were successfully imported. You can now manage them at %{url}

      Thank you,
      Instructure
      BODY
    else
      subject = I18n.t 'Outcomes Import Failed'
      user_name = user.name.split('@').first
      errors_count = I18n.t({one: "1 error", other: "%{count} errors"}, count: error_count)
      errors_lead = error_count <= 100 ? I18n.t('The following errors occurred:') : I18n.t('Here are the first 100 errors that occurred:')
      rows = n_errors(100).map { |r, m| I18n.t("Row %{row}: %{message}", row: r, message: m) }.join("\n")
      body = I18n.t(<<-BODY, name: user_name, errors_count: errors_count, errors_lead: errors_lead, rows: rows, url: url).gsub(/^ +/, '')
      Hello %{name},

      Your outcomes import failed due to %{errors_count} with your import. Please examine your file and attempt the upload again at %{url}

      %{errors_lead}
      %{rows}

      Thank you,
      Instructure
      BODY
    end

    [subject, body]
  end
end
