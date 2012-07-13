#
# Copyright (C) 2011 Instructure, Inc.
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
  belongs_to :user
  belongs_to :context, :polymorphic => true
  belongs_to :attachment
  belongs_to :root_account, :class_name => 'Account'
  validates_presence_of :media_id, :context_id, :context_type
  after_create :retrieve_details_later
  after_save :update_title_on_kaltura_later
  serialize :data

  attr_accessible :media_id, :title, :context, :user

  attr_accessor :podcast_associated_asset

  def user_entered_title=(val)
    @push_user_title = true
    write_attribute(:user_entered_title, val)
  end
  
  def update_title_on_kaltura_later
    send_later(:update_title_on_kaltura) if @push_user_title
    @push_user_title = nil
  end
  
  def self.find_by_media_id(media_id)
    unless Rails.env.production?
      raise "Do not look up MediaObjects by media_id - use the scope by_media_id instead to support migrated content."
    end
    super
  end

  # if wait_for_completion is true, this will wait SYNCHRONOUSLY for the bulk
  # upload to complete. Wrap it in a timeout if you ever want it to give up
  # waiting.
  def self.add_media_files(attachments, wait_for_completion)
    return unless Kaltura::ClientV3.config
    attachments = Array(attachments)
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    files = []
    root_account_id = attachments.map{|a| a.root_account_id }.compact.first
    attachments.select{|a| !a.media_object }.each do |attachment|
      files << {
                  :name       => attachment.display_name,
                  :url        => attachment.cacheable_s3_download_url,
                  :media_type => (attachment.content_type || "").match(/\Avideo/) ? 'video' : 'audio',
                  :id         => attachment.id
               }
    end
    res = client.bulkUploadAdd(files)

    if !res[:ready]
      if wait_for_completion
        bulk_upload_id = res[:id]
        Rails.logger.debug "waiting for bulk upload id: #{bulk_upload_id}"
        while !res[:ready]
          sleep(1.minute.to_i)
          res = client.bulkUploadGet(bulk_upload_id)
        end
      else
        MediaObject.send_later_enqueue_args(:refresh_media_files, {:run_at => 1.minute.from_now, :priority => Delayed::LOW_PRIORITY}, res[:id], attachments.map(&:id), root_account_id)
      end
    end

    if res[:ready]
      build_media_objects(res, root_account_id)
    end
    res
  end
  
  def self.bulk_migration(csv, root_account_id)
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    res = client.bulkUploadCsv(csv)
    if !res[:ready]
      MediaObject.send_later_enqueue_args(:refresh_media_files, {:run_at => 1.minute.from_now, :priority => Delayed::LOW_PRIORITY}, res[:id], [], root_account_id)
    else
      build_media_objects(res, root_account_id)
    end
    res
  end
  
  def self.migration_csv(media_objects)
    FasterCSV.generate do |csv|
      media_objects.each do |mo|
        mo.retrieve_details unless mo.data[:download_url]
        if mo.data[:download_url]
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
  end

  def self.build_media_objects(data, root_account_id)
    root_account = Account.find_by_id(root_account_id)
    data[:entries].each do |entry|
      attachment = Attachment.find_by_id(entry[:originalId]) if entry[:originalId].present?
      mo = MediaObject.find_or_initialize_by_media_id(entry[:entryId])
      mo.root_account ||= root_account || Account.default
      mo.title ||= entry[:name]
      if attachment
        mo.user_id ||= attachment.user_id
        mo.context = attachment.context
        mo.attachment_id = attachment.id
        attachment.update_attribute(:media_entry_id, entry[:entryId])
        # check for attachments that were created temporarily, just to import a media object
        if attachment.full_path.starts_with?(File.join(Folder::ROOT_FOLDER_NAME, CC::CCHelper::MEDIA_OBJECTS_FOLDER) + '/')
          attachment.destroy(false)
        end
      end
      mo.context ||= mo.root_account
      mo.save
    end
  end

  def self.refresh_media_files(bulk_upload_id, attachment_ids, root_account_id, attempt=0)
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    res = client.bulkUploadGet(bulk_upload_id)
    if !res[:ready]
      if attempt < Setting.get('media_object_bulk_refresh_max_attempts', '5').to_i
        wait_period = Setting.get('media_object_bulk_refresh_wait_period', '30').to_i
        MediaObject.send_later_enqueue_args(:refresh_media_files, {:run_at => wait_period.minutes.from_now, :priority => Delayed::LOW_PRIORITY}, bulk_upload_id, attachment_ids, root_account_id, attempt + 1)
      else
        # if it fails, then the attachment should no longer consider itself kalturable
        Attachment.update_all({:media_entry_id => nil}, "id IN (#{attachment_ids.join(",")}) OR root_attachment_id IN (#{attachment_ids.join(",")})") unless attachment_ids.empty?
      end
      res
    else
      build_media_objects(res, root_account_id)
    end
  end

  def self.media_id_exists?(media_id)
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    info = client.mediaGet(media_id)
    return !!info[:id]
  end

  def self.ensure_media_object(media_id, create_opts = {})
    if !by_media_id(media_id).any?
      self.send_later_enqueue_args(:create_if_id_exists, { :priority => Delayed::LOW_PRIORITY }, media_id, create_opts)
    end
  end

  # typically call this in a delayed job, since it has to contact kaltura
  def self.create_if_id_exists(media_id, create_opts = {})
    if media_id_exists?(media_id) && !by_media_id(media_id).any?
      create!(create_opts.merge(:media_id => media_id))
    end
  end

  def update_title_on_kaltura
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    res = client.mediaUpdate(self.media_id, :name => self.user_entered_title)
    if !res[:error]
      self.title = self.user_entered_title
      self.save
    end
    res
  end
  
  def retrieve_details_later
    send_later(:retrieve_details_ensure_codecs)
  end
  
  def retrieve_details_ensure_codecs(attempt=0)
    retrieve_details
    if (!self.data || !self.data[:extensions] || !self.data[:extensions][:flv]) && self.created_at > 6.hours.ago
      if(attempt < 10)
        send_at((5 * attempt).minutes.from_now, :retrieve_details_ensure_codecs, attempt + 1)
      else
        ErrorReport.log_error(:default, {
          :message => "Kaltura flavor retrieval failed",
          :object => self.inspect.to_s,
        })
      end
    end
  end
  
  def name
    self.title
  end
  
  def retrieve_details
    return unless self.media_id
    # From Kaltura, retrieve the title (if it's not already set)
    # and the list of valid flavors along with their id's.
    # Might as well confirm the media type while you're at it.
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    self.data ||= {}
    entry = client.mediaGet(self.media_id)
    if entry
      self.title = entry[:name]
      self.media_type = client.mediaTypeToSymbol(entry[:mediaType]).to_s
      self.duration = entry[:duration].to_i
      self.data[:plays] = entry[:plays].to_i
      self.data[:download_url] = entry[:downloadUrl]
      tags = (entry[:tags] || "").split(/,/).map(&:strip)
      old_id = tags.detect{|t| t.match(/old_id_/) }
      self.old_media_id = old_id.sub(/old_id_/, '') if old_id
    end
    assets = client.flavorAssetGetByEntryId(self.media_id)
    self.data[:extensions] ||= {}
    assets.each do |asset|
      asset[:fileExt] = "none" if asset[:fileExt].blank?
      self.data[:extensions][asset[:fileExt].to_sym] = asset #.slice(:width, :height, :id, :entryId, :status, :containerFormat, :fileExt, :size
      if asset[:size]
        self.max_size = [self.max_size || 0, asset[:size].to_i].max
      end
    end
    self.total_size = [self.max_size || 0, assets.map{|a| (a[:size] || 0).to_i }.sum].max
    self.save
    self.data
  end
  
  def podcast_format_details
    data = self.data && self.data[:extensions] && self.data[:extensions][:mp3]
    data ||= self.data && self.data[:extensions] && self.data[:extensions][:mp4]
    if !data
      self.retrieve_details
      data ||= self.data && self.data[:extensions] && self.data[:extensions][:mp3]
      data ||= self.data && self.data[:extensions] && self.data[:extensions][:mp4]
    end
    data
  end
  
  def delete_from_remote
    return unless self.media_id

    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    client.mediaDelete(self.media_id)
  end
  
  alias_method :destroy!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    self.attachment.destroy if self.attachment
    save!
  end
  
  def data
    self.read_attribute(:data) || self.write_attribute(:data, {})
  end

  def viewed!
    send_later(:updated_viewed_at_and_retrieve_details, Time.now) if !self.data[:last_viewed_at] || self.data[:last_viewed_at] > 1.hour.ago
    true
  end
    
  def updated_viewed_at_and_retrieve_details(time)
    self.data[:last_viewed_at] = [time, self.data[:last_viewed_at]].compact.max
    self.retrieve_details
  end
  
  def destroy_without_destroying_attachment
    self.workflow_state = 'deleted'
    self.attachment_id = nil
    save!
  end
  
  named_scope :active, lambda{
    {:conditions => ['media_objects.workflow_state != ?', 'deleted'] }
  }
  
  named_scope :by_media_id, lambda { |media_id|
    { :conditions => [ 'media_objects.media_id = ? OR media_objects.old_media_id = ?', media_id, media_id ] }
  }
  
  named_scope :by_media_type, lambda { |media_type|
    { :conditions => [ 'media_objects.media_type = ?', media_type ]}
  }
  
  workflow do
    state :active
    state :deleted
  end
end
