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

class ExternalFeedEntry < ActiveRecord::Base
  include Workflow
  
  belongs_to :user
  belongs_to :external_feed
  belongs_to :asset, :polymorphic => true
  validates_inclusion_of :asset_type, :allow_nil => true, :in => ['DiscussionTopic']

  before_save :infer_defaults
  validates_presence_of :external_feed_id, :workflow_state
  validates_length_of :message, :maximum => maximum_text_length, :allow_nil => true, :allow_blank => true
  sanitize_field :message, CanvasSanitize::SANITIZE

  attr_accessible :title, :message, :source_name, :source_url, :posted_at, :start_at, :end_at, :user, :url, :uuid, :author_name, :author_url, :author_email, :asset
  
  def infer_defaults
    self.uuid ||= Digest::MD5.hexdigest("#{title || rand.to_s}#{posted_at.strftime('%Y-%m-%d') rescue 'no-time'}")
  end
  protected :infer_defaults
  
  def update_feed_attributes(opts)
    self.update_attributes(opts)
    @feed_entry_updated = self.changed?
  end
  
  def entry_changed?
    @feed_entry_updated
  end
  
  workflow do
    state :active do
      event :delete_it, :transitions_to => :deleted
      event :cancel_it, :transitions_to => :cancelled
    end
    
    state :deleted
    state :cancelled
  end
  
  def self.serialization_excludes; [:uuid]; end
end
