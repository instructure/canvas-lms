module Mutable

  attr_accessor :recently_unmuted

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def declare_mutable_broadcast_policy(options)
      policy       = options[:policy]
      participants = options[:participants]

      policy.dispatch :assignment_unmuted
      policy.to { participants }
      policy.whenever do |record|
        !self.suppress_broadcast and
        @recently_unmuted
      end
    end
  end

  def mute!
    self.update_attribute(:muted, true)
    clear_sent_messages
    hide_stream_items
  end

  def unmute!
    self.update_attribute(:muted, false)
    broadcast_unmute_event
    show_stream_items
  end

  def broadcast_unmute_event
    @recently_unmuted = true
    self.save!
    @recently_unmuted = false
  end

  protected
  def clear_sent_messages
    self.clear_broadcast_messages if self.respond_to? :clear_broadcast_messages
  end

  def hide_stream_items
    if self.respond_to? :submissions
      item_asset_strings = submissions.map { |s| "submission_#{s.id}" }
      stream_item_ids   = StreamItem.all(
        :select => "id",
        :conditions => { :item_asset_string => item_asset_strings }
      ).map(&:id)
      StreamItemInstance.update_all({ :hidden => true }, { :stream_item_id => stream_item_ids })
    end
  end

  def show_stream_items
    if self.respond_to? :submissions
      submission_ids     = submissions.map(&:id)
      item_asset_strings = submissions.map { |s| "submission_#{s.id}" }
      stream_item_ids   = StreamItem.all(
        :select => "id",
        :conditions => { :item_asset_string => item_asset_strings }
      ).map(&:id)
      StreamItemInstance.update_all({ :hidden => false }, { :stream_item_id => stream_item_ids })
      SubmissionComment.update_all({ :hidden => false }, { :submission_id => submission_ids })
    end
  end
end
