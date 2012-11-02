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
      stream_items = StreamItem.all(:select => "id, context_code",
                                    :conditions => { :item_asset_string => item_asset_strings })
      stream_item_ids = stream_items.map(&:id)
      stream_item_context_codes = stream_items.map(&:context_code)
      StreamItemInstance.update_all_with_invalidation(stream_item_context_codes,
                                                      { :hidden => true },
                                                      { :stream_item_id => stream_item_ids })
    end
  end

  def show_stream_items
    if self.respond_to? :submissions
      submissions        = submissions(:include => {:hidden_submission_comments => :author})
      stream_items = StreamItem.all(:select => "id, context_code",
                                    :conditions => { :item_asset_string => submissions.map(&:asset_string) })
      stream_item_ids = stream_items.map(&:id)
      stream_item_context_codes = stream_items.map(&:context_code)
      StreamItemInstance.update_all_with_invalidation(stream_item_context_codes,
                                                      { :hidden => false },
                                                      { :hidden => true, :stream_item_id => stream_item_ids })

      outstanding = submissions.map{ |submission|
        comments = submission.hidden_submission_comments.all
        next if comments.empty?
        [submission, comments.map(&:author_id).uniq.size == 1 ? [comments.last.author_id] : []]
      }.compact
      SubmissionComment.update_all({ :hidden => false }, { :hidden => true, :submission_id => submissions.map(&:id) })
      Submission.send(:preload_associations, outstanding.map(&:first), :visible_submission_comments)
      outstanding.each do |submission, skip_ids|
        submission.create_or_update_conversations!(:create, :skip_ids => skip_ids)
      end
    end
  end
end
