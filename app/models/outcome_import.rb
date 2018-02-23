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
    data["processing_errors"] = self.outcome_import_errors.limit(25).pluck(:row, :message)
    data
  end
end
