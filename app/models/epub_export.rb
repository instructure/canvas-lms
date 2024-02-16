# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class EpubExport < ActiveRecord::Base
  include CC::Exporter::Epub::Exportable
  include LocaleSelection
  include Workflow

  belongs_to :content_export
  belongs_to :course
  belongs_to :user
  has_many :attachments, -> { order("created_at DESC") }, dependent: :destroy, as: :context, inverse_of: :context, class_name: "Attachment"
  has_one :epub_attachment, -> { where(content_type: "application/epub+zip").order("created_at DESC") }, as: :context, inverse_of: :context, class_name: "Attachment"
  has_one :zip_attachment, -> { where(content_type: "application/zip").order("created_at DESC") }, as: :context, inverse_of: :context, class_name: "Attachment"
  has_one :job_progress, as: :context, inverse_of: :context, class_name: "Progress"
  validates :course_id, :workflow_state, presence: true
  has_a_broadcast_policy
  alias_method :context, :course # context is needed for the content export notification

  PERCENTAGE_COMPLETE = {
    created: 0,
    exported: 80,
    generating: 90,
    generated: 100
  }.freeze

  def update_progress_from_content_export!(val)
    multiplier = PERCENTAGE_COMPLETE[:exported].to_f / 100
    n = val * multiplier
    job_progress.update_completion!(n.to_i)
  end

  workflow do
    state :created
    state :exporting
    state :exported
    state :generating
    state :generated
    state :failed
    state :deleted
  end

  delegate :broadcast_data, to: :course, prefix: true

  set_broadcast_policy do |p|
    p.dispatch :content_export_finished
    p.to { [user] }
    p.whenever do |record|
      record.changed_state(:generated)
    end
    p.data { course_broadcast_data }

    p.dispatch :content_export_failed
    p.to { [user] }
    p.whenever do |record|
      record.changed_state(:failed)
    end
    p.data { course_broadcast_data }
  end

  after_create do
    create_job_progress(completion: 0, tag: self.class.to_s.underscore)
  end

  delegate :public_download_url, to: :attachment, allow_nil: true
  delegate :downloadable?, to: :attachment, allow_nil: true
  delegate :completion, :running?, to: :job_progress, allow_nil: true

  scope :running, -> { where(workflow_state: %w[created exporting exported generating]) }
  scope :visible_to, ->(user) { where(user_id: user) }

  set_policy do
    given do |user|
      course.grants_right?(user, :read_as_admin) ||
        course.grants_right?(user, :participate_as_student)
    end
    can :create

    given do |user|
      self.user == user || course.grants_right?(user, :read_as_admin)
    end
    can :read

    given do |user|
      grants_right?(user, :read) && generated?
    end
    can :download

    given do |user|
      ["generated", "failed"].include?(workflow_state) &&
        grants_right?(user, :create)
    end
    can :regenerate
  end

  def export
    create_content_export!({
                             user:,
                             export_type: ContentExport::COMMON_CARTRIDGE,
                             selected_content: { everything: true },
                             progress: 0,
                             context: course
                           })
    job_progress.start
    update_attribute(:workflow_state, "exporting")
    content_export.export
    true
  end
  handle_asynchronously :export, priority: Delayed::LOW_PRIORITY, on_permanent_failure: :mark_as_failed

  def mark_exported
    if content_export.failed?
      mark_as_failed
    else
      update_attribute(:workflow_state, "exported")
      job_progress.update_attribute(:completion, PERCENTAGE_COMPLETE[:exported])
      generate
    end
  end
  handle_asynchronously :mark_exported, priority: Delayed::LOW_PRIORITY

  def generate
    job_progress.update_attribute(:completion, PERCENTAGE_COMPLETE[:generating])
    update_attribute(:workflow_state, "generating")
    convert_to_epub
  end
  handle_asynchronously :generate, priority: Delayed::LOW_PRIORITY, on_permanent_failure: :mark_as_failed

  def mark_as_generated
    job_progress.complete! if job_progress.running?
    update_attribute(:workflow_state, "generated")
  end

  def mark_as_failed(error = nil)
    if error
      out = Canvas::Errors.capture_exception(:course_export, error)
      ::Rails.logger.debug("Created ErrorReport #{out[:error_report]}")
    end
    job_progress.try :fail!
    update_attribute(:workflow_state, "failed")
  end

  # Epub Exportable overrides
  def content_cartridge
    content_export.attachment
  end

  def self.fail_stuck_epub_exports(exports)
    cutoff = 2.hours.ago
    exports.select { |e| (e.generating? || e.exporting?) && e.updated_at < cutoff }.each(&:mark_as_failed)
  end

  def convert_to_epub
    begin
      file_paths = I18n.with_locale(set_locale) { super }
    rescue => e
      mark_as_failed(e)
      raise e
    end

    file_paths.each do |file_path|
      create_attachment_from_path!(file_path)
    end
    mark_as_generated
    file_paths.each { |file_path| cleanup_file_path!(file_path) }
  end
  handle_asynchronously :convert_to_epub, priority: Delayed::LOW_PRIORITY

  def create_attachment_from_path!(file_path)
    mime_type = MIME::Types.type_for(file_path).first
    file = Rack::Multipart::UploadedFile.new(
      file_path,
      mime_type.try(:content_type)
    )
    attachment = attachments.new
    attachment.filename = File.basename(file_path)
    Attachments::Storage.store_for_attachment(attachment, file)
    attachment.save!
  rescue Errno::ENOENT => e
    mark_as_failed
    raise e
  ensure
    file.try(:close)
  end

  def cleanup_file_path!(file_path)
    FileUtils.rm_rf(file_path, secure: true)
  end

  def sort_by_content_type?
    course.organize_epub_by_content_type
  end

  private

  def set_locale
    infer_locale(
      context: course,
      user:,
      root_account: course.root_account
    )
  end
end
