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
  validates_presence_of :media_id, :context_id, :context_type
  before_save :infer_defaults
  after_create :retrieve_details_later
  after_save :update_title_on_kaltura_later
  serialize :data
  
  attr_accessor :podcast_associated_asset

  def infer_defaults
    self.user_type = "admin" if self.user && self.cached_context_grants_right?(self.user, nil, :manage_content)
    self.user_type ||= "student"
  end
  
  def user_entered_title=(val)
    @push_user_title = true
    write_attribute(:user_entered_title, val)
  end
  
  def update_title_on_kaltura_later
    send_later(:update_title_on_kaltura) if @push_user_title
    @push_user_title = nil
  end
  
  def self.add_media_files(attachments)
    attachments = Array(attachments)
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    files = []
    attachments.select{|a| !a.media_object }.each do |attachment|
      files << {
                  :name       => attachment.display_name,
                  :url        => attachment.cacheable_s3_url,
                  :media_type => (attachment.content_type || "").match(/\Avideo/) ? 'video' : 'audio',
                  :id         => attachment.id
               }
    end
    res = client.bulkUploadAdd(files)
    if !res[:ready]
      MediaObject.send_at(1.minute.from_now, :refresh_media_files, res[:id], attachments.map(&:id))
    else
      build_media_objects(res)
    end
    res
  end
  
  def self.build_media_objects(data)
    data[:entries].each do |entry|
      attachment = Attachment.find_by_id(entry[:originalId])
      if attachment
        mo = MediaObject.find_or_initialize_by_media_id(entry[:entryId])
        mo.context = attachment.context
        mo.title ||= entry[:name]
        mo.user_id ||= attachment.user_id
        mo.attachment_id = attachment.id
        mo.save
        attachment.update_attribute(:media_entry_id, entry[:entryId])
      end
    end
  end
  
  def self.refresh_media_files(bulk_upload_id, attachment_ids, attempt=0)
    client = Kaltura::ClientV3.new
    client.startSession(Kaltura::SessionType::ADMIN)
    res = client.bulkUploadGet(bulk_upload_id)
    if !res[:ready]
      if attempt < 5
        MediaObject.send_at(10.minute.from_now, :refresh_media_files, bulk_upload_id, attachment_ids, attempt + 1) 
      else
        # if it fails, then the attachment should no longer consider itself kalturable
        Attachment.update_all({:media_entry_id => nil}, "id IN (#{attachment_ids.join(",")}) OR root_attachment_id IN (#{attachment_ids.join(",")})") unless attachment_ids.empty? #['id = ? OR root_attachment_id = ?', self.attachment_id, self.attachment_id]) if self.attachment_id
      end
      res
    else
      build_media_objects(res)
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
        ErrorLogging.log_error(:default, {
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
    end
    assets = client.flavorAssetGetByEntryId(self.media_id)
    self.data[:extensions] ||= {}
    assets.each do |asset|
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
  
  workflow do
    state :active
    state :deleted
  end
end
