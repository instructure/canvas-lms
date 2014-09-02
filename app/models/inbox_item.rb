#
# Copyright (C) 2011-2013 Instructure, Inc.
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

class InboxItem < ActiveRecord::Base
  # Included modules
  include Workflow

  # Associations
  belongs_to :asset,  :polymorphic => true
  validates_inclusion_of :asset_type, :allow_nil => true, :in => ['DiscussionEntry', 'SubmissionComment', 'ContextMessage']
  belongs_to :author, :class_name => 'User', :foreign_key => :sender_id
  belongs_to :user

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :sender_id, :asset_id, :subject, :body_teaser, :asset_type, :workflow_state, :sender, :created_at, :updated_at, :context_code]
  EXPORTABLE_ASSOCIATIONS = [:asset, :author, :user]

  # Callbacks
  before_save       :flag_changed
  before_save       :infer_context_code
  before_validation :trim_subject
  after_destroy     :update_user_inbox_items_count
  after_save        :update_user_inbox_items_count

  # Validations
  validates_presence_of :user_id, :sender_id, :asset_id, :asset_type, :workflow_state
  validates_length_of :subject, :maximum => 255

  # Access control
  attr_accessible :user_id, :asset, :subject, :body_teaser, :sender_id

  # Named scopes
  scope :active, -> { where("workflow_state NOT IN ('deleted', 'retired', 'retired_unread')") }
  scope :unread, -> { where(:workflow_state => 'unread') }

  # State machine
  workflow do
    state :unread
    state :read
    state :deleted
    state :retired
    state :retired_unread
  end

  def infer_context_code
    self.context_code ||= asset.context_code rescue nil
    self.context_code ||= asset.context.asset_string rescue nil
  end

  def mark_as_read
    update_attribute(:workflow_state, 'read')
  end

  def sender_name
    User.cached_name(sender_id)
  end

  def context
    Context.find_by_asset_string(context_code) rescue nil
  end

  def context_short_name
    return unless context_code.present?
    Rails.cache.fetch(['short_name_lookup', context_code].cache_key) do
      Context.find_by_asset_string(context_code).short_name rescue ''
    end
  end

  def flag_changed
    @item_state_changed = new_record? || workflow_state_changed?
    true
  end

  # Public: Limit the subject line to 255 characters by stripping any "Re: "
  # occurrences and then truncating what's left to 255 characters.
  #
  # Returns nothing.
  def trim_subject
    return unless subject.present?

    subject.strip!
    subject.sub!(/^(Re:\s*)+/, '')

    self.subject = subject[0..254]
  end

  def update_user_inbox_items_count
    new_unread_count = user.inbox_items.unread.count rescue 0
    User.where(:id => user_id).update_all(:unread_inbox_items_count => new_unread_count)
  end

  def context_type_plural
    context_code.split('_')[0..-2].join('_').pluralize
  end

  def context_id
    context_code.split('_').last.to_i rescue nil
  end

  def item_asset_string
    "#{asset_type.underscore}_#{asset_id}"
  end

end
