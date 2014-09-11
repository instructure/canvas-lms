class ConversationBatch < ActiveRecord::Base
  include SimpleTags
  include Workflow

  belongs_to :user
  belongs_to :root_conversation_message, :class_name => 'ConversationMessage'
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Account', 'Course']

  EXPORTABLE_ATTRIBUTES = [
    :id, :workflow_state, :user_id, :recipient_ids, :root_conversation_message_id, :conversation_message_ids, :tags, :created_at, :updated_at, :context_type,
    :context_id, :subject, :group, :generate_user_note
  ]

  EXPORTABLE_ASSOCIATIONS = [:user, :root_conversation_message, :context]

  before_save :serialize_conversation_message_ids
  after_create :queue_delivery

  validates_presence_of :user_id, :workflow_state, :root_conversation_message_id

  scope :in_progress, -> { where(:workflow_state => ['created', 'sending']) }

  attr_accessible
  attr_accessor :mode

  attr_reader :conversations
  def deliver(update_progress = true)
    chunk_size = 25

    @conversations = []
    self.user = user_map[user_id]
    existing_conversations = Conversation.find_all_private_conversations(self.user, recipient_ids.map { |id| user_map[id] })
    update_attribute :workflow_state, 'sending'

    ModelCache.with_cache(:conversations => existing_conversations, :users => {:id => user_map}) do
      recipient_ids.each_slice(chunk_size) do |ids|
        ids.each do |id|
          is_group = self.group?
          conversation = user.initiate_conversation([user_map[id]], !is_group,
            subject: subject, context_type: context_type, context_id: context_id)
          @conversations << conversation
          message = root_conversation_message.clone
          message.generate_user_note = self.generate_user_note
          conversation.add_message(message, update_for_sender: false, tags: tags)
          conversation_message_ids << message.id
        end
        # update it in chunks, not on every message
        save! if update_progress
      end
    end

    update_attribute :workflow_state, 'sent'
  rescue StandardError => e
    self.workflow_state = 'error'
    save!
  end

  def completion
    # what fraction of the total time we think we'll be waiting for the
    # job to start. this is a bit hand-wavy, but basically we guesstimate
    # the average wait time as being equivalent to sending 20 messages
    job_start_factor = 20.0 / (recipient_ids.size + 20)

    case workflow_state
      when 'sent'
        1
      when 'created'
        # the first part of the progress bar is while we wait for the job
        # to start. ideally this will just take a couple seconds. if jobs
        # are backed up, we still want to make it seem like we are making
        # headway. every minute we will advance half of the remainder of
        # job_start_factor.
        minutes = (Time.zone.now - created_at).to_i / 60.0
        job_start_factor * (1 - (1 / 2**minutes))
      else
        # the rest of the progress bar is nice and linear
        job_start_factor + ((1 - job_start_factor) * conversation_message_ids.size / recipient_ids.size)
    end
  end

  attr_writer :user_map
  def user_map
    @user_map ||= User.where(id: recipient_ids + [user_id]).index_by(&:id)
  end

  def recipient_ids
    @recipient_ids ||= read_attribute(:recipient_ids).split(',').map(&:to_i)
  end

  def recipient_ids=(ids)
    write_attribute(:recipient_ids, ids.join(','))
  end

  def recipient_count
    recipient_ids.size
  end

  def conversation_message_ids
    @conversation_message_ids ||= (read_attribute(:conversation_message_ids) || '').split(',').map(&:to_i)
  end

  def serialize_conversation_message_ids
    write_attribute :conversation_message_ids, conversation_message_ids.join(',')
  end

  def queue_delivery
    if mode == :async
      send_later :deliver
    else
      deliver(false)
    end
  end

  workflow do
    state :created
    state :sending
    state :sent
    state :error
  end

  def local_tags
    tags
  end

  def self.generate(root_message, recipients, mode = :async, options = {})
    batch = new
    batch.mode = mode
    # normally the association would do this for us, but the validation
    # fails beforehand
    root_message.save! if root_message.new_record?
    batch.root_conversation_message = root_message
    batch.user_id = root_message.author_id
    batch.recipient_ids = recipients.map(&:id)
    batch.context_type = options[:context_type]
    batch.context_id = options[:context_id]
    batch.tags = options[:tags]
    batch.subject = options[:subject]
    batch.group = !!options[:group]
    user_map = recipients.index_by(&:id)
    user_map[batch.user_id] = batch.user
    batch.user_map = user_map
    batch.generate_user_note = root_message.generate_user_note
    batch.save!
    batch
  end
end
