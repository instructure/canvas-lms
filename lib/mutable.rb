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
      stream_items = StreamItem.select([:id, :context_type, :context_id]).
          where(:asset_type => 'Submission', :asset_id => submissions).
          includes(:context)
      stream_item_contexts = stream_items.map { |si| [si.context_type, si.context_id] }
      associated_shards = stream_items.inject([]) { |result, si| result | si.associated_shards }
      Shard.with_each_shard(associated_shards) do
        StreamItemInstance.where(:stream_item_id => stream_items).
            update_all_with_invalidation(stream_item_contexts, :hidden => true)
      end
    end
  end

  def show_stream_items
    if self.respond_to? :submissions
      submissions        = submissions(:include => {:hidden_submission_comments => :author})
      stream_items = StreamItem.select([:id, :context_type, :context_id]).
          where(:asset_type => 'Submission', :asset_id => submissions).
          includes(:context)
      stream_item_contexts = stream_items.map { |si| [si.context_type, si.context_id] }
      associated_shards = stream_items.inject([]) { |result, si| result | si.associated_shards }
      Shard.with_each_shard(associated_shards) do
        StreamItemInstance.where(:hidden => true, :stream_item_id => stream_items).
            update_all_with_invalidation(stream_item_contexts, :hidden => false)
      end

      outstanding = submissions.map{ |submission|
        comments = submission.hidden_submission_comments.all
        next if comments.empty?
        [submission, comments.map(&:author_id).uniq.size == 1 ? [comments.last.author] : []]
      }.compact
      SubmissionComment.where(:hidden => true, :submission_id => submissions).update_all(:hidden => false)
      Submission.send(:preload_associations, outstanding.map(&:first), :visible_submission_comments)
      outstanding.each do |submission, skip_users|
        submission.create_or_update_conversations!(:create, :skip_users => skip_users)
      end
    end
  end
end
