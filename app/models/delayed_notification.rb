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

class DelayedNotification < ActiveRecord::Base
  include Workflow
  belongs_to :asset, :polymorphic => true
  belongs_to :notification
  belongs_to :asset_context, :polymorphic => true
  attr_accessible :asset, :notification, :recipient_keys, :asset_context, :data
  attr_accessor :data
  
  serialize :recipient_keys
  
  workflow do
    state :to_be_processed do
      event :do_process, :transitions_to => :processed
    end
    state :processed
    state :errored
  end
  
  def self.process(asset, notification, recipient_keys, asset_context, data)
    dn = DelayedNotification.new(:asset => asset, :notification => notification, :recipient_keys => recipient_keys,
      :asset_context => asset_context, :data => data)
    dn.process
  end
  
  def process
    tos = self.to_list
    if self.asset && !tos.empty?
      res = self.notification.create_message(self.asset, tos, :asset_context => self.asset_context, :data => self.data)
    end
    self.do_process unless self.new_record?
    res
  rescue => e
    ErrorReport.log_exception(:default, e, {
      :message => "Delayed Notification processing failed",
    })
    logger.error "delayed notification processing failed: #{e.message}\n#{e.backtrace.join "\n"}"
    self.workflow_state = 'errored'
    self.save
    []
  end
  
  def to_list
    lookups = {}
    (recipient_keys || []).each do |key|
      pieces = key.split('_')
      id = pieces.pop
      klass = pieces.join('_').classify.constantize
      lookups[klass] ||= []
      lookups[klass] << id
    end
    res = []
    lookups.each do |klass, ids|
      includes = []
      includes = [:user] if klass == CommunicationChannel
      res += klass.where(:id => ids).includes(includes).all rescue []
    end
    res.uniq
  end
  memoize :to_list
  
  named_scope :to_be_processed, lambda {|limit|
    {:conditions => ['delayed_notifications.workflow_state = ?', 'to_be_processed'], :limit => limit, :order => 'delayed_notifications.created_at'}
  }
end
