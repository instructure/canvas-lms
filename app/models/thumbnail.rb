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

class Thumbnail < ActiveRecord::Base
  belongs_to :attachment, :foreign_key => "parent_id"

  # the ":keep_profile => true" part is in here so that we tell mini_magic to not try to pass the command line option -strip.
  # this is because on the servers we are actually using graphics_magic not image_magic's mogrify and graphics_magick doesn't
  # support -strip. you'd get something like:
  # MiniMagick::Error (Command ("mogrify -strip -resize \"200x50\" \"/tmp/mini_magick23816-1\"") failed: {:status_code=>1, :output=>"mogrify: Unrecognized option (-strip).\n"}):#012
  has_attachment(
      :content_type => :image,
      :storage => (Attachment.local_storage? ? :file_system : :s3),
      :path_prefix => Attachment.file_store_config['path_prefix'],
      :s3_access => 'private',
      :keep_profile => true,
      :thumbnail_max_image_size_pixels => Setting.get('thumbnail_max_image_size_pixels', 100_000_000).to_i
  )

  before_save :set_namespace
  def set_namespace
    self.namespace = attachment.namespace
  end

  def local_storage_path
    "#{HostUrl.context_host(attachment.context)}/images/thumbnails/show/#{id}/#{uuid}"
  end

  def bucket
    self.attachment.bucket
  end

  def cached_s3_url
    @cached_s3_url = authenticated_s3_url(expires_in: 144.hours)
  end

  before_save :assign_uuid
  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid
end
