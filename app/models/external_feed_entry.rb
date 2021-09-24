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

class ExternalFeedEntry < ActiveRecord::Base
  include Workflow

  belongs_to :user
  belongs_to :external_feed
  belongs_to :asset, polymorphic: [:discussion_topic]

  before_save :infer_defaults
  validates_presence_of :external_feed_id, :workflow_state
  validates :title, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}
  validates :message, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}
  validates :source_url, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}
  validates :url, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: true}
  validates :author_name, length: {maximum: maximum_string_length, allow_nil: true, allow_blank: false}
  validates :author_url, length: {maximum: maximum_text_length, allow_nil: true, allow_blank: false}
  validates :author_email, length: {maximum: maximum_string_length, allow_nil: true, allow_blank: false}
  sanitize_field :message, CanvasSanitize::SANITIZE

  def infer_defaults
    self.uuid ||= Digest::SHA256.hexdigest("#{title || rand.to_s}#{posted_at.strftime('%Y-%m-%d') rescue 'no-time'}")
  end
  protected :infer_defaults

  def update_feed_attributes(opts)
    self.update(opts)
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
