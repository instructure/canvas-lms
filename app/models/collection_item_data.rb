#
# Copyright (C) 2012 Instructure, Inc.
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

class CollectionItemData < ActiveRecord::Base
  include CustomValidations

  belongs_to :root_item, :class_name => "CollectionItem"
  belongs_to :image_attachment, :class_name => "Attachment"
  has_many :collection_item_upvotes

  VALID_ITEM_TYPES = %w(url image audio video)
  THUMBNAIL_SIZE = "640x>"

  validates_inclusion_of :item_type, :in => VALID_ITEM_TYPES
  validates_as_url :link_url
  validates_presence_of :link_url

  attr_accessible :root_item, :item_type, :link_url, :image_url, :description, :title

  before_create :prepare_to_snapshot_link_url
  after_create :snapshot_link_url

  def prepare_to_snapshot_link_url
    self.image_pending = true
  end

  def snapshot_link_url
    embedly_data = Canvas::Embedly.new(link_url)

    self.html_preview = embedly_data.object_html
    self.title = embedly_data.title if self.title.blank?
    self.description = embedly_data.description if self.description.blank?

    if self.item_type == "url" && VALID_ITEM_TYPES.include?(embedly_data.data_type)
      self.item_type = embedly_data.data_type
    end

    if image_url.present?
      attachment = Canvas::HTTP.clone_url_as_attachment(image_url)
    elsif embedly_data.images.first
      attachment = Canvas::HTTP.clone_url_as_attachment(embedly_data.images.first.url)
    else
      attachment = CutyCapt.snapshot_attachment_for_url(link_url)
    end

    if attachment && attachment.image?
      attachment.context = Account.default # these images belong to nobody
      attachment.save!
      self.image_attachment = attachment

      # we know we want this thumbnail size, so generate it now
      attachment.create_dynamic_thumbnail(THUMBNAIL_SIZE)
    end

    self.image_pending = false
    self.save!
  end
  handle_asynchronously :snapshot_link_url, :priority => Delayed::LOW_PRIORITY

  # convert a given url string into a CollectionItemData
  # if the url points to another collection item in this canvas instance, it'll
  # verify the user can access that item and then create a clone of that
  def self.data_for_url(url, creating_user)
    # TODO: handle other canvas hostnames
    # TODO: restrict this to be more precise on what urls it will accept as a clone
    if url.match(%r{https?://#{Regexp.escape HostUrl.default_host}/api/v1/collections/items/(\d+)$})
      original_item = CollectionItem.active.find($1)
      collection = original_item.active_collection
      if collection.grants_right?(@current_user, :read)
        return original_item.collection_item_data
      else
        return nil
      end
    else
      return CollectionItemData.new(:item_type => "url", :link_url => url)
    end
  end

  attr_accessor :upvoted_by_user
  # sets the upvoted_by_user attribute on each item passed in
  def self.load_upvoted_by_user(datas, user)
    user.shard.activate do
      data_ids = datas.map(&:id)
      upvoted_ids = Set.new(connection.select_values(sanitize_sql_for_conditions(["SELECT collection_item_data_id FROM collection_item_upvotes WHERE collection_item_data_id IN (?) AND user_id = ?", data_ids, user.id])))
      datas.each { |item| item.upvoted_by_user = upvoted_ids.include?(item.id.to_s) }
    end
  end
end
