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

module SendToStream
  module SendToStreamClassMethods
    def self.extended(klass)
      klass.send(:class_attribute, :send_to_stream_block)
      klass.send(:class_attribute, :send_to_stream_update_block)
      klass.has_one :stream_item, :as => :asset
    end

    def on_create_send_to_streams(&block)
      self.send_to_stream_block = block
      after_create :queue_create_stream_items
      after_save :clear_stream_items_on_destroy
      after_destroy :clear_stream_items
    end
    
    def on_update_send_to_streams(&block)
      self.send_to_stream_update_block = block
      after_update :queue_update_stream_items
      after_save :clear_stream_items_on_destroy
      after_destroy :clear_stream_items
    end
  end
 
  module SendToStreamInstanceMethods
    def queue_create_stream_items
      block = self.class.send_to_stream_block rescue nil
      stream_recipients = Array(self.instance_eval(&block)) if block
      if stream_recipients && !stream_recipients.empty?
        send_later_if_production_enqueue_args(:create_stream_items,
                                              :priority => Delayed::LOW_PRIORITY)
      end
      true
    end
    
    def create_stream_items
      return if stream_item_inactive?
      block = self.class.send_to_stream_block
      stream_recipients = Array(self.instance_eval(&block)) if block
      generate_stream_items(stream_recipients) if stream_recipients
    rescue => e
      if Rails.env.production?
        ErrorReport.log_exception(:default, e, {
          :message => "SendToStream failure",
        })
      else
        raise
      end
    end
    
    def generate_stream_items(stream_recipients)
      @generated_stream_items ||= []
      self.extend TextHelper
      @stream_item_recipient_ids = stream_recipients.compact.map{|u| User.infer_id(u) }.compact.uniq
      @generated_stream_items = StreamItem.generate_all(self, @stream_item_recipient_ids)
    end
    
    def queue_update_stream_items
      block = self.class.send_to_stream_update_block
      stream_recipients = Array(self.instance_eval(&block)) if block
      if stream_recipients && !stream_recipients.empty?
        send_later_if_production_enqueue_args(:generate_stream_items,
                                              { :priority => Delayed::LOW_PRIORITY },
                                              stream_recipients)
        true
      end
    rescue => e
      ErrorReport.log_exception(:default, e, {
        :message => "SendToStream failure",
      })
      true
    end
    
    def generated_stream_items
      @generated_stream_items
    end
    
    def stream_item_recipient_ids
      @stream_item_recipient_ids
    end

    def stream_item_inactive?
      (self.respond_to?(:workflow_state) && self.workflow_state == 'deleted') || (self.respond_to?(:deleted?) && self.deleted?)
    end

    def clear_stream_items_on_destroy
      clear_stream_items if stream_item_inactive?
    end
    
    def clear_stream_items
      # We need to pass the asset_string, not the asset itself, since we're about to delete the asset
      root_object = StreamItem.root_object(self)
      StreamItem.send_later_if_production(:delete_all_for, [root_object.class.base_class.name, root_object.id], [self.class.base_class.name, self.id])
    end
  end
 
  def self.included(klass)
    klass.send :include, SendToStreamInstanceMethods
    klass.extend SendToStreamClassMethods
  end
end
 
