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

class MediaObject < ActiveRecord::Base
  include Workflow
  include SearchTermHelper

  class VideoCaptionServiceError < Delayed::RetriableError; end

  AUTO_CAPTION_STATUSES = {
    processing: -> { I18n.t("Processing") },
    failed_initial_validation: -> { I18n.t("Error - Something went wrong") },
    failed_handoff: -> { I18n.t("Error - Failed to communicate with captioning service") },
    failed_request: -> { I18n.t("Error - Failed to request") },
    non_english_captions: -> { I18n.t("Error - Non-English detected") },
    failed_captions: -> { I18n.t("Error - Caption request failed") },
    failed_to_pull: -> { I18n.t("Error - Captions not found") },
    complete: -> { I18n.t("Complete") },
  }.freeze

  MAX_CAPTION_ATTEMPTS = 10

  belongs_to :user
  belongs_to :context,
             polymorphic:
                 [:course,
                  :group,
                  :conversation_message,
                  :account,
                  :assignment,
                  :assessment_question,
                  { context_user: "User" }],
             exhaustive: false
  belongs_to :attachment
  belongs_to :root_account, class_name: "Account"

  validates :media_id, :workflow_state, presence: true
  validates :auto_caption_status, inclusion: { in: AUTO_CAPTION_STATUSES.keys.map(&:to_s) }, allow_nil: true
  has_many :media_tracks, ->(media_object) { where(attachment_id: [nil, media_object.attachment_id]).order(:locale) }, dependent: :destroy, inverse_of: :media_object
  has_many :attachments_by_media_id, class_name: "Attachment", primary_key: :media_id, foreign_key: :media_entry_id, inverse_of: :media_object_by_media_id
  before_create :create_attachment
  after_create :retrieve_details_later
  after_save :update_title_on_kaltura_later
  serialize :data

  attr_accessor :podcast_associated_asset, :current_attachment

  def user_entered_title=(val)
    @push_user_title = true
    super
  end

  def update_title_on_kaltura_later
    delay.update_title_on_kaltura if @push_user_title
    @push_user_title = nil
  end

  def self.find_by(**kwargs)
    if kwargs.key?(:media_id) && !Rails.env.production?
      raise "Do not look up MediaObjects by media_id - use the scope by_media_id instead to support migrated content."
    end

    super
  end

  def context_root_account(user = nil)
    # Granular Permissions
    #
    # The primary use case for this method is for accurately checking
    # feature flag enablement, given a user and the calling context.
    # We want to prefer finding the root_account through the context
    # of the authorizing resource or fallback to the user's active
    # pseudonym's residing account.
    return context.account if context.is_a?(User)

    # return nil and don't raise if receiver doesn't respond to :root_account
    context.try(:root_account) || user&.account
  end

  set_policy do
    given do |user|
      (attachment.present? ? attachment.grants_right?(user, :update) : (context&.grants_right?(user, :manage_course_content_add) || (self.user && self.user == user)))
    end
    can :add_captions

    given do |user|
      (attachment.present? ? attachment.grants_right?(user, :update) : (context&.grants_right?(user, :manage_course_content_delete) || (self.user && self.user == user)))
    end
    can :delete_captions
  end

  # if wait_for_completion is true, this will wait SYNCHRONOUSLY for the bulk
  # upload to complete. Wrap it in a timeout if you ever want it to give up
  # waiting.
  def self.add_media_files(attachments, wait_for_completion)
    media_attachments = Array(attachments).reject { |att| att.media_object_by_media_id && att.media_entry_id != "maybe" }
    KalturaMediaFileHandler.new.add_media_files(media_attachments, wait_for_completion) if media_attachments.present?
  end

  def self.bulk_migration(csv, root_account_id)
    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    res = client.bulkUploadCsv(csv)
    if res[:ready]
      build_media_objects(res, root_account_id)
    else
      MediaObject.delay(run_at: 1.minute.from_now, priority: Delayed::LOW_PRIORITY)
                 .refresh_media_files(res[:id], [], root_account_id)
    end
    res
  end

  def self.migration_csv(media_objects)
    CSV.generate do |csv|
      media_objects.each do |mo|
        mo.retrieve_details unless mo.data[:download_url]
        next unless mo.data[:download_url]

        row = []
        row << mo.title
        row << ""
        row << "old_id_#{mo.media_id}"
        row << mo.data[:download_url]
        row << mo.media_type.capitalize
        csv << row
      end
    end
  end

  def self.build_media_objects(data, root_account_id)
    root_account = Account.where(id: root_account_id).first
    data[:entries].each do |entry|
      attachment_id = nil
      begin
        attachment_id = Integer(entry[:originalId]) if entry[:originalId].present?
      rescue ArgumentError
        # ignore
      end
      if !attachment_id && entry[:originalId].present? && entry[:originalId].length >= 2
        partner_data = Rack::Utils.parse_nested_query(entry[:originalId]).with_indifferent_access
        attachment_id = partner_data[:attachment_id] if partner_data[:attachment_id].present?
      end
      attachment = Attachment.where(id: attachment_id).first if attachment_id
      account = root_account || Account.default
      mo = account.shard.activate { MediaObject.where(media_id: entry[:entryId]).first_or_initialize }
      mo.root_account ||= root_account || Account.default
      mo.title ||= entry[:name]
      if attachment
        mo.user_id ||= attachment.user_id
        mo.context = attachment.context
        mo.attachment_id = attachment.id
        attachment.update_attribute(:media_entry_id, entry[:entryId])
      end
      mo.context ||= mo.root_account
      mo.save
    end
  end

  def self.refresh_media_files(bulk_upload_id, attachment_ids, root_account_id, attempt = 0)
    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    res = client.bulkUploadGet(bulk_upload_id)
    if res[:ready]
      build_media_objects(res, root_account_id)
    else
      if attempt < Setting.get("media_object_bulk_refresh_max_attempts", "5").to_i
        wait_period = Setting.get("media_object_bulk_refresh_wait_period", "30").to_i
        MediaObject.delay(run_at: wait_period.minutes.from_now, priority: Delayed::LOW_PRIORITY)
                   .refresh_media_files(bulk_upload_id, attachment_ids, root_account_id, attempt + 1)
      else
        # if it fails, then the attachment should no longer consider itself kalturable
        Attachment.where("id IN (?) OR root_attachment_id IN (?)", attachment_ids, attachment_ids).update_all(media_entry_id: nil) unless attachment_ids.empty?
      end
      res
    end
  end

  def self.media_id_exists?(media_id)
    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    info = client.mediaGet(media_id)
    !!info&.dig(:id)
  end

  def self.ensure_media_object(media_id, **create_opts)
    unless by_media_id(media_id).any?
      delay(priority: Delayed::LOW_PRIORITY).create_if_id_exists(media_id, **create_opts)
    end
  end

  # typically call this in a delayed job, since it has to contact kaltura
  def self.create_if_id_exists(media_id, **create_opts)
    if media_id_exists?(media_id) && by_media_id(media_id).none?
      create!(**create_opts, media_id:)
    end
  end

  def update_title_on_kaltura
    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    res = client.mediaUpdate(media_id, name: user_entered_title)
    unless res.nil? || res[:error]
      self.title = user_entered_title
      save
    end
    res
  end

  def retrieve_details_later
    delay.retrieve_details_ensure_codecs
  end

  def media_sources
    CanvasKaltura::ClientV3.new.media_sources(media_id)
  end

  def retrieve_details_ensure_codecs(attempt = 0)
    retrieve_details
    if !transcoded_details && created_at > 6.hours.ago
      if attempt < 10
        delay(run_at: (5 * attempt).minutes.from_now).retrieve_details_ensure_codecs(attempt + 1)
      else
        Canvas::Errors.capture(:media_object_failure,
                               {
                                 message: "Kaltura flavor retrieval failed",
                                 object: inspect,
                               },
                               :warn)
      end
    end
  end

  def name
    title
  end

  def guaranteed_title
    user_entered_title.presence || title.presence || I18n.t("Untitled")
  end

  def process_retrieved_details(entry, media_type, assets)
    if entry
      self.title = title.presence || entry[:name]
      self.media_type = media_type
      self.duration = entry[:duration].to_i
      data[:plays] = entry[:plays].to_i
      data[:download_url] = entry[:downloadUrl]
      tags = (entry[:tags] || "").split(",").map(&:strip)
      old_id = tags.detect { |t| t.include?("old_id_") }
      self.old_media_id = old_id.sub("old_id_", "") if old_id
    end
    data[:extensions] ||= {}
    assets.each do |asset|
      asset[:fileExt] = "none" if asset[:fileExt].blank?
      data[:extensions][asset[:fileExt].to_sym] = asset # .slice(:width, :height, :id, :entryId, :status, :containerFormat, :fileExt, :size
      if asset[:size]
        self.max_size = [max_size || 0, asset[:size].to_i].max
      end
    end
    self.total_size = [max_size || 0, assets.sum { |a| (a[:size] || 0).to_i }].max
    save
    ensure_attachment_media_info
    data
  end

  def retrieve_details
    return unless media_id

    # From Kaltura, retrieve the title (if it's not already set)
    # and the list of valid flavors along with their id's.
    # Might as well confirm the media type while you're at it.
    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    self.data ||= {}

    entry = client.mediaGet(media_id)
    media_type = client.mediaTypeToSymbol(entry[:mediaType]).to_s if entry
    # attachment#build_content_types_sql assumes the content_type has a "/"
    media_type = MediaObject.normalize_content_type(media_type)
    assets = client.flavorAssetGetByEntryId(media_id) || []
    process_retrieved_details(entry, media_type, assets)
  end

  def podcast_format_details
    data = transcoded_details
    unless data
      retrieve_details
      data = transcoded_details
    end
    data
  end

  def transcoded_details
    sources = media_sources
    return unless sources.present?

    mp3_media_source = sources.find { |s| s[:fileExt] == "mp3" }
    data = self.data && self.data[:extensions] && self.data[:extensions][:mp3] if mp3_media_source
    data ||= self.data && self.data[:extensions] && self.data[:extensions][:mp4]
    data
  end

  def delete_from_remote
    return unless media_id

    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    client.mediaDelete(media_id)
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = "deleted"
    attachment&.destroy
    save!
  end

  def generate_captions
    return unless Account.site_admin.feature_enabled?(:speedgrader_studio_media_capture)

    delay.request_captions(attempt: 1)
  end

  def request_captions(attempt:)
    if media_sources.any?
      VideoCaptionService.call(self)
    elsif attempt > MAX_CAPTION_ATTEMPTS
      error = VideoCaptionServiceError.new("No media sources to generate captions for and max attempts reached")
      Canvas::Errors.capture(error, { media_object_id: global_id }, :warn)
    else
      run_at = (5 + (attempt**4)).seconds.from_now # same backoff that inst-jobs uses
      delay(run_at:).request_captions(attempt: attempt + 1)
    end
  end

  def data
    self["data"] ||= {}
  end

  def viewed!
    # in the delayed job, current_attachment gets reset
    # so we pass it in here and then set it again in the next method
    delay.updated_viewed_at_and_retrieve_details(Time.zone.now, current_attachment) if !self.data[:last_viewed_at] || self.data[:last_viewed_at] > 1.hour.ago
    true
  end

  def updated_viewed_at_and_retrieve_details(time, current_attachment = nil)
    self.current_attachment = current_attachment if current_attachment
    self.data[:last_viewed_at] = [time, self.data[:last_viewed_at]].compact.max
    retrieve_details
  end

  def create_attachment
    return if current_attachment || attachment_id || Attachment.find_by(media_entry_id: media_id)
    return unless %w[Account Course Group User].include?(context_type)

    if context.is_a?(Course) && context.usage_rights_required && Account.site_admin.feature_enabled?(:default_copyright_on_attachments)
      usage_rights = context.usage_rights.find_or_create_by!(context:, use_justification: "own_copyright")
    end

    self.attachment = Folder.media_folder(context).attachments
                            .create!(
                              context:,
                              display_name: guaranteed_title,
                              filename: guaranteed_title,
                              content_type: media_type,
                              media_entry_id: media_id,
                              # in case teachers don't mean for this to be visible to students in the files section
                              file_state: "hidden",
                              workflow_state: "pending_upload",
                              usage_rights:
                            )
    attachment.handle_duplicates(:rename)
    media_tracks.update_all(attachment_id: attachment.id)
  end

  def ensure_attachment_media_info
    create_attachment
    # if there are multiple attachments attached to the media_object, we need to update the right one
    updated_attachment = current_attachment || attachment
    return unless updated_attachment && ["pending_upload", "errored"].include?(updated_attachment.workflow_state)

    file_state = updated_attachment.file_state
    sources = media_sources
    return unless sources.present?

    url = self.data[:download_url]
    ext, url = sources.find { |s| s[:isOriginal] == "1" }&.slice(:fileExt, :url)&.values if url.blank?
    ext, url = sources.min_by { |a| a[:bitrate].to_i }&.slice(:fileExt, :url)&.values if url.blank?

    updated_attachment.clone_url(url, :rename, false) # no check_quota because the bits are in kaltura
    updated_attachment.file_state = file_state
    if ext.present? && File.mime_type(updated_attachment.display_name) == "unknown/unknown"
      updated_attachment.display_name = "#{updated_attachment.display_name}.#{ext}"
    end
    updated_attachment.workflow_state = "processed"
    updated_attachment.media_entry_id = media_id
    updated_attachment.save!
  end

  def thumbnail_url
    kaltura_config = CanvasKaltura::ClientV3.config
    if kaltura_config
      kaltura_settings = kaltura_config.try(:slice, "resource_domain", "partner_id")
      domain = "https://#{kaltura_settings["resource_domain"]}"
      "#{domain}/p/#{kaltura_settings["partner_id"]}/thumbnail/entry_id/#{media_id}/width/140/height/100/bgcolor/000000/type/2/vid_sec/5"
    end
  end

  def deleted?
    workflow_state == "deleted"
  end

  def self.normalize_content_type(content_type)
    return content_type if content_type.blank? || content_type.include?("/")

    "#{content_type}/*"
  end

  scope :active, -> { where("media_objects.workflow_state<>'deleted'") }

  scope :by_media_id, ->(media_id) { where(media_id:).or(where(old_media_id: media_id).where.not(old_media_id: nil)) }

  scope :by_media_type, ->(media_type) { where(media_type:) }

  workflow do
    state :active
    state :deleted
  end
end
