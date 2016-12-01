#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require 'atom'
require 'crocodoc'

# See the uploads controller and views for examples on how to use this model.
class Attachment < ActiveRecord::Base
  def self.display_name_order_by_clause(table = nil)
    col = table ? "#{table}.display_name" : 'display_name'
    best_unicode_collation_key(col)
  end
  strong_params

  PERMITTED_ATTRIBUTES = [:filename, :display_name, :locked, :position, :lock_at,
    :unlock_at, :uploaded_data, :hidden, :viewed_at].freeze
  def self.permitted_attributes
    PERMITTED_ATTRIBUTES
  end

  EXCLUDED_COPY_ATTRIBUTES = %w{id root_attachment_id uuid folder_id user_id
                                filename namespace workflow_state}

  include HasContentTags
  include ContextModuleItem
  include SearchTermHelper

  attr_accessor :podcast_associated_asset

  # this is a gross hack to work around freaking SubmissionComment#attachments=
  attr_accessor :ok_for_submission_comment

  belongs_to :context, exhaustive: false, polymorphic:
      [:account, :assessment_question, :assignment, :attachment,
       :content_export, :content_migration, :course, :eportfolio, :epub_export,
       :gradebook_upload, :group, :submission,
       { context_folder: 'Folder', context_sis_batch: 'SisBatch',
         context_user: 'User', quiz: 'Quizzes::Quiz',
         quiz_statistics: 'Quizzes::QuizStatistics',
         quiz_submission: 'Quizzes::QuizSubmission' }]
  belongs_to :cloned_item
  belongs_to :folder
  belongs_to :user
  has_one :account_report
  has_one :media_object
  has_many :submissions
  has_many :attachment_associations
  belongs_to :root_attachment, :class_name => 'Attachment'
  belongs_to :replacement_attachment, :class_name => 'Attachment'
  has_one :sis_batch
  has_one :thumbnail, -> { where(thumbnail: 'thumb') }, foreign_key: "parent_id"
  has_many :thumbnails, :foreign_key => "parent_id"
  has_many :children, foreign_key: :root_attachment_id, class_name: 'Attachment'
  has_one :crocodoc_document
  has_one :canvadoc
  belongs_to :usage_rights

  before_save :infer_display_name
  before_save :default_values
  before_save :set_need_notify

  before_validation :assert_attachment
  acts_as_list :scope => :folder

  def self.file_store_config
    # Return existing value, even if nil, as long as it's defined
    @file_store_config ||= ConfigFile.load('file_store')
    @file_store_config ||= { 'storage' => 'local' }
    @file_store_config['path_prefix'] ||= @file_store_config['path'] || 'tmp/files'
    @file_store_config['path_prefix'] = nil if @file_store_config['path_prefix'] == 'tmp/files' && @file_store_config['storage'] == 's3'
    return @file_store_config
  end

  def self.s3_config
    # Return existing value, even if nil, as long as it's defined
    return @s3_config if defined?(@s3_config)
    @s3_config ||= ConfigFile.load('amazon_s3')
  end

  def self.s3_storage?
    (file_store_config['storage'] rescue nil) == 's3' && s3_config
  end

  def self.local_storage?
    rv = !s3_storage?
    raise "Unknown storage type!" if rv && file_store_config['storage'] != 'local'
    rv
  end

  def self.store_type
    if s3_storage?
      Attachments::S3Storage
    elsif local_storage?
      Attachments::LocalStorage
    else
      raise "Unknown storage system configured"
    end
  end

  def store
    @store ||= Attachment.store_type.new(self)
  end

  # Haaay... you're changing stuff here? Don't forget about the Thumbnail model
  # too, it cares about local vs s3 storage.
  has_attachment(
      :storage => self.store_type.key,
      :path_prefix => file_store_config['path_prefix'],
      :s3_access => :private,
      :thumbnails => { :thumb => '128x128' },
      :thumbnail_class => 'Thumbnail'
  )

  # These callbacks happen after the attachment data is saved to disk/s3, or
  # immediately after save if no data is being uploading during this save cycle.
  # That means you can't rely on these happening in the same transaction as the save.
  after_save_and_attachment_processing :touch_context_if_appropriate
  after_save_and_attachment_processing :ensure_media_object

  # this mixin can be added to a has_many :attachments association, and it'll
  # handle finding replaced attachments. In other words, if an attachment fond
  # by id is deleted but an active attachment in the same context has the same
  # path, it'll return that attachment.
  module FindInContextAssociation
    def find(*a)
      find_with_possibly_replaced(super)
    end

    def find_by_id(id)
      find_with_possibly_replaced(where(id: id).first)
    end

    def find_all_by_id(ids)
      find_with_possibly_replaced(where(id: ids).to_a)
    end

    def find_with_possibly_replaced(a_or_as)
      if a_or_as.is_a?(Attachment)
        find_attachment_possibly_replaced(a_or_as)
      elsif a_or_as.is_a?(Array)
        a_or_as.map { |a| find_attachment_possibly_replaced(a) }
      end
    end

    def find_attachment_possibly_replaced(att)
      # if they found a deleted attachment by id, but there's an available
      # attachment in the same context and the same full path, we return that
      # instead, to emulate replacing a file without having to update every
      # by-id reference in every user content field.
      if self.respond_to?(:proxy_association)
        owner = proxy_association.owner
      end

      if att.deleted? && owner
        new_att = owner.attachments.where(id: att.replacement_attachment_id).first if att.replacement_attachment_id
        new_att ||= Folder.find_attachment_in_context_with_path(owner, att.full_display_path)
        new_att || att
      else
        att
      end
    end
  end

  RELATIVE_CONTEXT_TYPES = %w(Course Group User Account)
  # returns true if the context is a type that supports relative file paths
  def self.relative_context?(context_class)
    RELATIVE_CONTEXT_TYPES.include?(context_class.to_s)
  end

  def touch_context_if_appropriate
    unless context_type == 'ConversationMessage'
      self.class.connection.after_transaction_commit { touch_context }
    end
  end

  def run_before_attachment_saved
    @after_attachment_saved_workflow_state = self.workflow_state
    self.workflow_state = 'unattached'
  end

  # this is a magic method that gets run by attachment-fu after it is done sending to s3,
  # note, that the time it takes to send to s3 is the bad guy.
  # It blocks and makes the user wait.
  def run_after_attachment_saved
    if workflow_state == 'unattached' && @after_attachment_saved_workflow_state
      self.workflow_state = @after_attachment_saved_workflow_state
      @after_attachment_saved_workflow_state = nil
    end

    if %w(pending_upload processing).include?(workflow_state)
      # we don't call .process here so that we don't have to go through another whole save cycle
      self.workflow_state = 'processed'
    end

    # directly update workflow_state so we don't trigger another save cycle
    if self.workflow_state_changed?
      self.shard.activate do
        self.class.where(:id => self).update_all(:workflow_state => self.workflow_state)
      end
    end

    # try an infer encoding if it would be useful to do so
    send_later(:infer_encoding) if self.encoding.nil? && self.content_type =~ /text/ && self.context_type != 'SisBatch'
    if respond_to?(:process_attachment, true) && thumbnailable? && !attachment_options[:thumbnails].blank? && parent_id.nil?
      self.class.attachment_options[:thumbnails].each do |suffix, size|
        send_later_if_production_enqueue_args(:create_thumbnail_size, {:singleton => "attachment_thumbnail_#{self.global_id}_#{suffix}"}, suffix)
      end
    end
  end

  def infer_encoding
    return unless self.encoding.nil?
    begin
      Iconv.open('UTF-8', 'UTF-8') do |iconv|
        self.open do |chunk|
          iconv.iconv(chunk)
        end
        iconv.iconv(nil)
      end
      self.encoding = 'UTF-8'
      Attachment.where(:id => self).update_all(:encoding => 'UTF-8')
    rescue Iconv::Failure
      self.encoding = ''
      Attachment.where(:id => self).update_all(:encoding => '')
      return
    rescue IOError => e
      logger.error("Error inferring encoding for attachment #{self.global_id}: #{e.message}")
    end
  end

  # this is here becase attachment_fu looks to make sure that parent_id is nil before it will create a thumbnail of something.
  # basically, it makes a false assumption that the thumbnail class is the same as the original class
  # which in our case is false because we use the Thumbnail model for the thumbnails.
  def parent_id;end

  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={})
    if !self.cloned_item && !self.new_record?
      self.cloned_item = ClonedItem.create(:original_item => self) # do we even use this for anything?
      Attachment.where(:id => self).update_all(:cloned_item_id => self.cloned_item.id) # don't touch it for no reason
    end
    existing = context.attachments.active.find_by_id(self)
    existing ||= self.cloned_item_id ? context.attachments.active.where(cloned_item_id: self.cloned_item_id).first : nil
    return existing if existing && !options[:overwrite] && !options[:force_copy]
    existing ||= self.cloned_item_id ? context.attachments.where(cloned_item_id: self.cloned_item_id).first : nil
    dup ||= Attachment.new
    dup = existing if existing && options[:overwrite]

    excluded_atts = EXCLUDED_COPY_ATTRIBUTES
    excluded_atts += ["locked", "hidden"] if dup == existing
    dup.assign_attributes(self.attributes.except(*excluded_atts), :without_protection => true)

    dup.write_attribute(:filename, self.filename)
    # avoid cycles (a -> b -> a) and self-references (a -> a) in root_attachment_id pointers
    if dup.new_record? || ![self.id, self.root_attachment_id].include?(dup.id)
      dup.root_attachment_id = self.root_attachment_id || self.id
    end
    dup.context = context
    dup.migration_id = options[:migration_id] || CC::CCHelper.create_key(self)
    if context.respond_to?(:log_merge_result)
      context.log_merge_result("File \"#{dup.folder && dup.folder.full_name}/#{dup.display_name}\" created")
    end
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup.set_publish_state_for_usage_rights unless self.locked?
    dup
  end

  def copy_to_folder!(folder, on_duplicate = :rename)
    copy = self.clone_for(folder.context, nil, force_copy: true)
    copy.folder = folder
    copy.save!
    copy.handle_duplicates(on_duplicate)
    copy
  end

  def ensure_media_object
    return true if self.class.skip_media_object_creation?
    in_the_right_state = self.file_state == 'available' && self.workflow_state !~ /^unattached/
    if in_the_right_state && self.media_entry_id == 'maybe' &&
        self.content_type && self.content_type.match(/\A(video|audio)/)
      build_media_object
    end
  end

  def build_media_object
    tag = 'add_media_files'
    delay = Setting.get('attachment_build_media_object_delay_seconds', 10.to_s).to_i
    progress = Progress.where(context_type: 'Attachment', context_id: self, tag: tag).last
    progress ||= Progress.new context: self, tag: tag

    if progress.new_record?
      progress.reset!
      progress.process_job(MediaObject, :add_media_files, { :run_at => delay.seconds.from_now, :priority => Delayed::LOWER_PRIORITY, :preserve_method_args => true, :max_attempts => 5 }, self, false) && true
    else
      progress.completed? && !progress.failed?
    end
  end

  def assert_attachment
    if !self.to_be_zipped? && !self.zipping? && !self.errored? && !self.deleted? && (!filename || !content_type || !downloadable?)
      self.errors.add(:base, t('errors.not_found', "File data could not be found"))
      return false
    end
  end

  after_create :flag_as_recently_created
  attr_accessor :recently_created

  validates_presence_of :context_id, :context_type, :workflow_state
  validates_length_of :content_type, :maximum => maximum_string_length, :allow_blank => true

  # related_attachments: our root attachment, anyone who shares our root attachment,
  # and anyone who calls us a root attachment
  def related_attachments
    if root_attachment_id
      Attachment.where("id=? OR root_attachment_id=? OR (root_attachment_id=? AND id<>?)",
                       root_attachment_id, id, root_attachment_id, id)
    else
      Attachment.where(:root_attachment_id => id)
    end
  end

  TURNITINABLE_MIME_TYPES = %w[
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/pdf
    application/vnd.oasis.opendocument.text
    text/plain
    text/html
    application/rtf
    text/richtext
    application/vnd.wordperfect
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
  ].to_set.freeze

  def turnitinable?
    TURNITINABLE_MIME_TYPES.include?(content_type)
  end

  def vericiteable?
    # accept any file format
    true
  end

  def flag_as_recently_created
    @recently_created = true
  end
  protected :flag_as_recently_created
  def recently_created?
    @recently_created || (self.created_at && self.created_at > Time.now - (60*5))
  end

  def after_extension
    res = self.extension[1..-1] rescue nil
    res = nil if res == "" || res == "unknown"
    res
  end

  def assert_file_extension
    self.content_type = nil if self.content_type && (self.content_type == 'application/x-unknown' || self.content_type.match(/ERROR/))
    self.content_type ||= self.mimetype(self.filename)
    if self.filename && self.filename.split(".").length < 2
      # we actually have better luck assuming zip files without extensions
      # are docx files than assuming they're zip files
      self.content_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' if self.content_type.match(/zip/)
      ext = self.extension
      self.write_attribute(:filename, self.filename + ext) unless ext == '.unknown'
    end
  end


  def extension
    res = (self.filename || "").match(/(\.[^\.]*)\z/).to_s
    res = nil if res == ""
    if !res || res == ""
      res = File.mime_types[self.content_type].to_s rescue nil
      res = "." + res if res
    end
    res = nil if res == "."
    res ||= ".unknown"
    res.to_s
  end

  def self.clear_cached_mime_ids
    @@mime_ids = {}
  end

  def default_values
    self.modified_at = Time.now.utc if self.modified_at.nil?
    self.display_name = nil if self.display_name && self.display_name.empty?
    self.display_name ||= unencoded_filename
    self.file_state ||= "available"
    self.last_unlock_at = self.unlock_at if self.unlock_at
    self.last_lock_at = self.lock_at if self.lock_at
    self.assert_file_extension
    self.folder_id = nil if !self.folder || self.folder.context != self.context
    self.folder_id = nil if self.folder && self.folder.deleted? && !self.deleted?
    self.folder_id ||= Folder.unfiled_folder(self.context).id rescue nil
    self.folder_id ||= Folder.root_folders(context).first.id rescue nil
    if self.root_attachment && self.new_record?
      [:md5, :size, :content_type].each do |key|
        self.send("#{key}=", self.root_attachment.send(key))
      end
      self.workflow_state = 'processed'
      self.write_attribute(:filename, self.root_attachment.filename)
    end
    self.context = self.folder.context if self.folder && (!self.context || (self.context.respond_to?(:is_a_context? ) && self.context.is_a_context?))

    if self.respond_to?(:namespace=) && self.new_record?
      self.namespace = infer_namespace
    end

    self.media_entry_id ||= 'maybe' if self.new_record? && self.previewable_media?
  end
  protected :default_values

  def root_account_id
    # see note in infer_namespace below
    splits = namespace.try(:split, /_/)
    return nil if splits.blank?
    if splits[1] == "localstorage"
      splits[3].to_i
    else
      splits[1].to_i
    end
  end

  def namespace
    read_attribute(:namespace) || (new_record? ? write_attribute(:namespace, infer_namespace) : nil)
  end

  def infer_namespace
    # If you are thinking about changing the format of this, take note: some
    # code relies on the namespace as a hacky way to efficiently get the
    # attachment's account id. Look for anybody who is accessing namespace and
    # splitting the string, etc.
    #
    # I've added the root_account_id accessor above, but I didn't verify there
    # isn't any code still accessing the namespace for the account id directly.
    ns = root_attachment.try(:namespace) if root_attachment_id
    ns ||= Attachment.domain_namespace
    ns ||= self.context.root_account.file_namespace rescue nil
    ns ||= self.context.account.file_namespace rescue nil
    if Rails.env.development? && Attachment.local_storage?
      ns ||= ""
      ns = "_localstorage_/#{ns}" unless ns.start_with?('_localstorage_/')
    end
    ns = nil if ns && ns.empty?
    ns
  end

  def change_namespace(new_namespace)
    raise "change_namespace must be called on a root attachment" if self.root_attachment
    return if new_namespace == self.namespace

    old_full_filename = self.full_filename
    write_attribute(:namespace, new_namespace)

    self.store.change_namespace(old_full_filename)
    shard.activate do
      Attachment.where("id=? OR root_attachment_id=?", self, self).update_all(namespace: new_namespace)
    end
  end

  def process_s3_details!(details)
    unless workflow_state == 'unattached_temporary'
      self.workflow_state = nil
      self.file_state = 'available'
    end
    self.md5 = (details[:etag] || "").gsub(/\"/, '')
    self.content_type = details[:content_type]
    self.size = details[:content_length]

    self.shard.activate do
      if existing_attachment = find_existing_attachment_for_md5
        if existing_attachment.s3object.exists?
          # deduplicate. the existing attachment's s3object should be the same as
          # that just uploaded ('cuz md5 match). delete the new copy and just
          # have this attachment inherit from the existing attachment.
          s3object.delete rescue nil
          self.root_attachment = existing_attachment
          write_attribute(:filename, nil)
        else
          # it looks like we had a duplicate, but the existing attachment doesn't
          # actually have an s3object (probably from an earlier bug). update it
          # and all its inheritors to inherit instead from this attachment.
          existing_attachment.root_attachment = self
          existing_attachment.write_attribute(:filename, nil)
          existing_attachment.save!
          Attachment.where(root_attachment_id: existing_attachment).update_all(
            root_attachment_id: self,
            filename: nil,
            updated_at: Time.zone.now)
        end
      end
      save!
      # normally this would be called by attachment_fu after it had uploaded the file to S3.
      run_after_attachment_saved
    end
  end

  CONTENT_LENGTH_RANGE = 10.gigabytes
  S3_EXPIRATION_TIME = 30.minutes

  def ajax_upload_params(pseudonym, local_upload_url, s3_success_url, options = {})

    # Build the data that will be needed for the user to upload to s3
    # without us being the middle-man
    sanitized_filename = full_filename.gsub(/\+/, " ")
    policy = {
      'expiration' => (options[:expiration] || S3_EXPIRATION_TIME).from_now.utc.iso8601,
      'conditions' => [
        {'key' => sanitized_filename},
        {'acl' => 'private'},
        ['starts-with', '$Filename', ''],
        ['content-length-range', 1, (options[:max_size] || CONTENT_LENGTH_RANGE)]
      ]
    }

    res = self.store.initialize_ajax_upload_params(local_upload_url, s3_success_url, options)
    policy = self.store.amend_policy_conditions(policy, pseudonym)

    if res[:upload_params]['folder'].present?
      policy['conditions'] << ['starts-with', '$folder', '']
    end

    extras = []
    if options[:no_redirect]
      extras << {'success_action_status' => '201'}
      extras << {'success_url' => res[:success_url]}
    elsif res[:success_url]
      extras << {'success_action_redirect' => res[:success_url]}
    end
    if content_type && content_type != "unknown/unknown"
      extras << {'content-type' => content_type}
    elsif options[:default_content_type]
      extras << {'content-type' => options[:default_content_type]}
    end
    policy['conditions'] += extras

    policy_encoded = Base64.encode64(policy.to_json).gsub(/\n/, '')
    signature = Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha1'), shared_secret, policy_encoded
      )
    ).gsub(/\n/, '')

    res[:id] = id
    res[:upload_params].merge!({
       'Filename' => filename,
       'key' => sanitized_filename,
       'acl' => 'private',
       'Policy' => policy_encoded,
       'Signature' => signature,
    })
    extras.map(&:to_a).each{ |extra| res[:upload_params][extra.first.first] = extra.first.last }
    res
  end

  def self.decode_policy(policy_str, signature_str)
    return nil if policy_str.blank? || signature_str.blank?
    signature = Base64.decode64(signature_str)
    return nil if OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha1"), self.shared_secret, policy_str) != signature
    policy = JSON.parse(Base64.decode64(policy_str))
    return nil unless Time.zone.parse(policy['expiration']) >= Time.now
    attachment = Attachment.find(policy['attachment_id'])
    return nil unless attachment.try(:state) == :unattached
    return policy, attachment
  end

  def unencoded_filename
    CGI::unescape(self.filename || t(:default_filename, "File"))
  end

  def quota_exemption_key
    assign_uuid
    Canvas::Security.hmac_sha1(uuid + "quota_exempt")[0,10]
  end

  def verify_quota_exemption_key(hmac)
    Canvas::Security.verify_hmac_sha1(hmac, uuid + "quota_exempt", truncate: 10)
  end

  def self.minimum_size_for_quota
    Setting.get('attachment_minimum_size_for_quota', '512').to_i
  end

  def self.get_quota(context)
    quota = 0
    quota_used = 0
    context = context.quota_context if context.respond_to?(:quota_context) && context.quota_context
    if context
      Shackles.activate(:slave) do
        context.shard.activate do
          quota = Setting.get('context_default_quota', 50.megabytes.to_s).to_i
          quota = context.quota if (context.respond_to?("quota") && context.quota)

          attachment_scope = context.attachments.active.where(root_attachment_id: nil)

          if context.is_a?(User) || context.is_a?(Group)
            excluded_attachment_ids = []
            if context.is_a?(User)
              excluded_attachment_ids += context.attachments.joins(:attachment_associations).where("attachment_associations.context_type = ?", "Submission").pluck(:id)
            end
            excluded_attachment_ids += context.attachments.where(folder_id: context.submissions_folders).pluck(:id)
            attachment_scope = attachment_scope.where("id NOT IN (?)", excluded_attachment_ids) if excluded_attachment_ids.any?
          end

          min = self.minimum_size_for_quota
          # translated to ruby this is [size, min].max || 0
          quota_used = attachment_scope.sum("COALESCE(CASE when size < #{min} THEN #{min} ELSE size END, 0)").to_i
        end
      end
    end
    {:quota => quota, :quota_used => quota_used}
  end

  # Returns a boolean indicating whether the given context is over quota
  # If additional_quota > 0, that'll be added to the current quota used
  # (for example, to check if a new attachment of size additional_quota would
  # put the context over quota.)
  def self.over_quota?(context, additional_quota = nil)
    quota = self.get_quota(context)
    return quota[:quota] < quota[:quota_used] + (additional_quota || 0)
  end

  def handle_duplicates(method, opts = {})
    return [] unless method.present? && self.folder
    if self.folder.for_submissions?
      method = :rename
    else
      method = method.to_sym
    end
    deleted_attachments = []
    if method == :rename
      self.save! unless self.id

      valid_name = false
      self.shard.activate do
        while !valid_name
          existing_names = self.folder.active_file_attachments.where("id <> ?", self.id).pluck(:display_name)
          new_name = opts[:name] || self.display_name
          self.display_name = Attachment.make_unique_filename(new_name, existing_names)

          if Attachment.where("id = ? AND NOT EXISTS (?)", self,
                              Attachment.where("id <> ? AND display_name = ? AND folder_id = ? AND file_state <> ?",
                                self, display_name, folder_id, 'deleted')).
              limit(1).
              update_all(display_name: display_name) > 0
            valid_name = true
          end
        end
      end
    elsif method == :overwrite
      atts = self.folder.active_file_attachments.where("display_name=? AND id<>?", self.display_name, self.id)
      atts.update_all(:replacement_attachment_id => self) # so we can find the new file in content links
      copy_access_attributes!(atts.first) unless atts.empty?
      atts.each do |a|
        # update content tags to refer to the new file
        ContentTag.where(:content_id => a, :content_type => 'Attachment').update_all(:content_id => self)
        # update replacement pointers pointing at the overwritten file
        context.attachments.where(:replacement_attachment_id => a).update_all(:replacement_attachment_id => self)
        # delete the overwritten file (unless the caller is queueing them up)
        a.destroy unless opts[:caller_will_destroy]
        deleted_attachments << a
      end
    end
    return deleted_attachments
  end

  def copy_access_attributes!(source)
    self.file_state = 'hidden' if source.file_state == 'hidden'
    self.locked = source.locked
    self.unlock_at = source.unlock_at
    self.lock_at = source.lock_at
    self.usage_rights_id = source.usage_rights_id
    save! if changed?
  end

  def self.destroy_files(ids)
    Attachment.where(id: ids).each(&:destroy)
  end

  before_save :assign_uuid
  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  def inline_content?
    self.content_type.match(/\Atext/) || self.extension == '.html' || self.extension == '.htm' || self.extension == '.swf'
  end

  def self.shared_secret
    raise 'Cannot call Attachment.shared_secret when configured for s3 storage' if s3_storage?
    "local_storage" + Canvas::Security.encryption_key
  end

  def shared_secret
    store.shared_secret
  end

  def downloadable?
    !!(self.authenticated_s3_url rescue false)
  end

  def local_storage_path
    "#{HostUrl.context_host(context)}/#{context_type.underscore.pluralize}/#{context_id}/files/#{id}/download?verifier=#{uuid}"
  end

  def content_type_with_encoding
    encoding.blank? ? content_type : "#{content_type}; charset=#{encoding}"
  end

  def content_type_with_text_match
    # treats all text/X files as text/plain (except text/html)
    (content_type.to_s.match(/^text\/.*/) && content_type.to_s != "text/html") ? "text/plain" : content_type
  end

  # Returns an IO-like object containing the contents of the attachment file.
  # Any resources are guaranteed to be cleaned up when the object is garbage
  # collected (for instance, using the Tempfile class). Calling close on the
  # object may clean up things faster.
  #
  # By default, this method will stream the file as it is read, if it's stored
  # remotely and streaming is possible.  If opts[:need_local_file] is true,
  # then a local Tempfile will be created if necessary and the IO object
  # returned will always respond_to :path and :rewind, and have the right file
  # extension.
  #
  # Be warned! If local storage is used, a File handle to the actual file will
  # be returned, not a Tempfile handle. So don't rm the file's .path or
  # anything crazy like that. If you need to test whether you can move the file
  # at .path, or if you need to copy it, check if the file is_a?(Tempfile) (and
  # pass :need_local_file => true of course).
  #
  # If opts[:temp_folder] is given, and a local temporary file is created, this
  # path will be used instead of the default system temporary path. It'll be
  # created if necessary.
  def open(opts = {}, &block)
    store.open(opts, &block)
  end

  # you should be able to pass an optional width, height, and page_number/video_seconds to this method
  # can't handle arbitrary thumbnails for our attachment_fu thumbnails on s3 though, we could handle a couple *predefined* sizes though
  def thumbnail_url(options={})
    return nil if Attachment.skip_thumbnails

    geometry = options[:size]
    if self.thumbnail || geometry.present?
      to_use = thumbnail_for_size(geometry) || self.thumbnail
      to_use.cached_s3_url
    elsif self.media_object && self.media_object.media_id
      CanvasKaltura::ClientV3.new.thumbnail_url(self.media_object.media_id,
                                          :width => options[:width] || 140,
                                          :height => options[:height] || 100,
                                          :vid_sec => options[:video_seconds] || 5)
    else
      # "still need to handle things that are not images with thumbnails or kaltura docs"
    end
  end

  def thumbnail_for_size(geometry)
    if self.class.allows_thumbnails_of_size?(geometry)
      to_use = thumbnails.loaded? ? thumbnails.detect { |t| t.thumbnail == geometry } : thumbnails.where(thumbnail: geometry).first
      to_use ||= create_dynamic_thumbnail(geometry)
    end
  end

  def self.allows_thumbnails_of_size?(geometry)
    self.dynamic_thumbnail_sizes.include?(geometry)
  end

  def self.truncate_filename(filename, len, &block)
    block ||= lambda { |str, len| str[0...len] }
    ext_index = filename.rindex('.')
    if ext_index
      ext = block.call(filename[ext_index..-1], len / 2 + 1)
      base = block.call(filename[0...ext_index], len - ext.length)
      base + ext
    else
      block.call(filename, len)
    end
  end

  def save_without_broadcasting
    begin
      @skip_broadcasts = true
      save
    ensure
      @skip_broadcasts = false
    end
  end

  def save_without_broadcasting!
    begin
      @skip_broadcasts = true
      save!
    ensure
      @skip_broadcasts = false
    end
  end

  # called before save
  # notification is not sent until file becomes 'available'
  # (i.e., don't notify before it finishes uploading)
  def set_need_notify
    self.need_notify = true if !@skip_broadcasts &&
        file_state_changed? &&
        file_state == 'available' &&
        context.respond_to?(:state) && context.state == :available &&
        folder && folder.visible?
  end

  # generate notifications for recent file operations
  # (this should be run in a delayed job)
  def self.do_notifications
    # consider a batch complete when no uploads happen in this time
    quiet_period = Setting.get("attachment_notify_quiet_period_minutes", "5").to_i.minutes.ago

    # if a batch is older than this, just drop it rather than notifying
    discard_older_than = Setting.get("attachment_notify_discard_older_than_hours", "120").to_i.hours.ago

    while true
      file_batches = Attachment.
          where("need_notify").
          group(:context_id, :context_type).
          having("MAX(updated_at)<?", quiet_period).
          limit(500).
          pluck("COUNT(attachments.id), MIN(attachments.id), MAX(updated_at), context_id, context_type")
      break if file_batches.empty?
      file_batches.each do |count, attachment_id, last_updated_at, context_id, context_type|
        # clear the need_notify flag for this batch
        Attachment.where("need_notify AND updated_at <= ? AND context_id = ? AND context_type = ?", last_updated_at, context_id, context_type).
            update_all(:need_notify => nil)

        # skip the notification if this batch is too old to be timely
        next if last_updated_at.to_time < discard_older_than

        # now generate the notification
        record = Attachment.find(attachment_id)
        next if record.context.is_a?(Course) && (!record.context.available? || record.context.concluded?)
        if record.context.is_a?(Course) && (record.folder.locked? || record.context.tab_hidden?(Course::TAB_FILES))
          # only notify course students if they are able to access it
          to_list = record.context.participating_admins - [record.user]
        elsif record.context.respond_to?(:participants)
          to_list = record.context.participants - [record.user]
        end
        recipient_keys = (to_list || []).compact.map(&:asset_string)
        next if recipient_keys.empty?

        notification = BroadcastPolicy.notification_finder.by_name(count.to_i > 1 ? 'New Files Added' : 'New File Added')
        asset_context = record.context
        data = { :count => count }
        DelayedNotification.send_later_if_production_enqueue_args(
            :process,
            { :priority => Delayed::LOW_PRIORITY },
            record, notification, recipient_keys, asset_context, data)
      end
    end
  end

  def infer_display_name
    self.display_name ||= unencoded_filename
  end
  protected :infer_display_name

  def readable_size
    h = ActionView::Base.new
    h.extend ActionView::Helpers::NumberHelper
    h.number_to_human_size(self.size) rescue "size unknown"
  end

  def download_url(ttl = url_ttl)
    authenticated_s3_url(expires: ttl, response_content_disposition: "attachment; " + disposition_filename)
  end

  def inline_url(ttl = url_ttl)
    authenticated_s3_url(expires: ttl, response_content_disposition: "inline; " + disposition_filename)
  end

  def url_ttl
    Setting.get('attachment_url_ttl', 1.day.to_s).to_i
  end
  protected :url_ttl

  def disposition_filename
    ascii_filename = Iconv.conv("ASCII//TRANSLIT//IGNORE", "UTF-8", display_name)

    # response-content-disposition will be url encoded in the depths of
    # aws-s3, doesn't need to happen here. we'll be nice and ghetto http
    # quote the filename string, though.
    quoted_ascii = ascii_filename.gsub(/([\x00-\x1f"\x7f])/, '\\\\\\1')

    # awesome browsers will use the filename* and get the proper unicode filename,
    # everyone else will get the sanitized ascii version of the filename
    quoted_unicode = "UTF-8''#{URI.escape(display_name, /[^A-Za-z0-9.]/)}"
    %(filename="#{quoted_ascii}"; filename*=#{quoted_unicode})
  end
  protected :disposition_filename

  def attachment_path_id
    a = (self.respond_to?(:root_attachment) && self.root_attachment) || self
    ((a.respond_to?(:parent_id) && a.parent_id) || a.id).to_s
  end

  def filename
    read_attribute(:filename) || (self.root_attachment && self.root_attachment.filename)
  end

  def filename=(name)
    # infer a display name without round-tripping through truncated CGI-escaped filename
    # (which reduces the length of unicode filenames to as few as 28 characters)
    self.display_name ||= Attachment.truncate_filename(name, 255)
    super(name)
  end

  def thumbnail_with_root_attachment
    self.thumbnail_without_root_attachment || self.root_attachment.try(:thumbnail)
  end
  alias_method_chain :thumbnail, :root_attachment

  def content_directory
    self.directory_name || Folder.root_folders(self.context).first.name
  end

  def to_atom(opts={})
    Atom::Entry.new do |entry|
      entry.title     = t(:feed_title, "File: %{title}", :title => self.context.name) unless opts[:include_context]
      entry.title     = t(:feed_title_with_context, "File, %{course_or_group}: %{title}", :course_or_group => self.context.name, :title => self.context.name) if opts[:include_context]
      entry.authors  << Atom::Person.new(:name => self.context.name)
      entry.updated   = self.updated_at
      entry.published = self.created_at
      entry.id        = "tag:#{HostUrl.default_host},#{self.created_at.strftime("%Y-%m-%d")}:/files/#{self.feed_code}"
      entry.links    << Atom::Link.new(:rel => 'alternate',
                                       :href => "http://#{HostUrl.context_host(self.context)}/#{context_url_prefix}/files/#{self.id}")
      entry.content   = Atom::Content::Html.new("#{self.display_name}")
    end
  end

  def name
    display_name
  end

  def title
    display_name
  end

  def associate_with(context)
    self.attachment_associations.create(:context => context)
  end

  def mime_class
    {
      'text/html' => 'html',
      "text/x-csharp" => "code",
      "text/xml" => "code",
      "text/css" => 'code',
      "text" => "text",
      "text/plain" => "text",
      "application/rtf" => "doc",
      "text/rtf" => "doc",
      "application/vnd.oasis.opendocument.text" => "doc",
      "application/pdf" => "pdf",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => "doc",
      "application/x-docx" => "doc",
      "application/msword" => "doc",
      "application/vnd.ms-powerpoint" => "ppt",
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" => "ppt",
      "application/vnd.ms-excel" => "xls",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => "xls",
      "application/vnd.oasis.opendocument.spreadsheet" => "xls",
      "image/jpeg" => "image",
      "image/pjpeg" => "image",
      "image/png" => "image",
      "image/gif" => "image",
      "application/x-rar" => "zip",
      "application/x-rar-compressed" => "zip",
      "application/x-zip" => "zip",
      "application/x-zip-compressed" => "zip",
      "application/xml" => "code",
      "application/zip" => "zip",
      "audio/mpeg" => "audio",
      "audio/mp3" => "audio",
      "audio/basic" => "audio",
      "audio/mid" => "audio",
      "audio/3gpp" => "audio",
      "audio/x-aiff" => "audio",
      "audio/x-mpegurl" => "audio",
      "audio/x-pn-realaudio" => "audio",
      "audio/x-wav" => "audio",
      "video/mpeg" => "video",
      "video/quicktime" => "video",
      "video/x-la-asf" => "video",
      "video/x-ms-asf" => "video",
      "video/x-msvideo" => "video",
      "video/x-sgi-movie" => "video",
      "video/3gpp" => "video",
      "video/mp4" => "video",
      "application/x-shockwave-flash" => "flash"
    }[content_type] || "file"
  end

  def associated_with_submission?
    @associated_with_submission ||= self.attachment_associations.where(context_type: 'Submission').exists?
  end

  set_policy do
    given { |user, session|
      self.context.grants_right?(user, session, :manage_files) &&
        !self.associated_with_submission? &&
        (!self.folder || self.folder.grants_right?(user, session, :manage_contents))
    }
    can :delete and can :update

    given { |user, session| self.context.grants_right?(user, session, :manage_files) }
    can :read and can :create and can :download and can :read_as_admin

    given { self.public? }
    can :read and can :download

    given { |user, session| self.context.grants_right?(user, session, :read) } #students.include? user }
    can :read

    given { |user, session| self.context.grants_right?(user, session, :read_as_admin) }
    can :read_as_admin

    given { |user, session|
      self.context.grants_right?(user, session, :read) && !self.locked_for?(user, :check_policies => true)
    }
    can :download

    given { |user, session| self.context_type == 'Submission' && self.context.grant_right?(user, session, :comment) }
    can :create

    given { |user, session|
        session && session['file_access_user_id'].present? &&
        (u = User.where(id: session['file_access_user_id']).first) &&
        (self.context.grants_right?(u, session, :read) ||
          (self.context.respond_to?(:is_public_to_auth_users?) && self.context.is_public_to_auth_users?)) &&
        session['file_access_expiration'] && session['file_access_expiration'].to_i > Time.now.to_i
    }
    can :read

    given { |user, session|
        session && session['file_access_user_id'].present? &&
        (u = User.where(id: session['file_access_user_id']).first) &&
        (self.context.grants_right?(u, session, :read) ||
          (self.context.respond_to?(:is_public_to_auth_users?) && self.context.is_public_to_auth_users?)) &&
        !self.locked_for?(u, :check_policies => true) &&
        session['file_access_expiration'] && session['file_access_expiration'].to_i > Time.now.to_i
    }
    can :download

    given { |user|
      owner = self.user
      context_type == 'Assignment' && user == owner
    }
    can :attach_to_submission_comment
  end

  # checking if an attachment is locked is expensive and pointless for
  # submission attachments
  attr_writer :skip_submission_attachment_lock_checks

  # prevent an access attempt shortly before unlock_at from caching permissions beyond that time
  def touch_on_unlock
    Shackles.activate(:master) do
      send_later_enqueue_args(:touch, { :run_at => unlock_at,
                                        :singleton => "touch_on_unlock_attachment_#{global_id}" })
    end
  end

  def locked_for?(user, opts={})
    return false if @skip_submission_attachment_lock_checks
    return false if opts[:check_policies] && self.grants_right?(user, :read_as_admin)
    return {:asset_string => self.asset_string, :manually_locked => true} if self.locked || Folder.is_locked?(self.folder_id)
    Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      locked = false
      if (self.unlock_at && Time.now < self.unlock_at)
        touch_on_unlock if Time.now + 1.hour >= self.unlock_at
        locked = {:asset_string => self.asset_string, :unlock_at => self.unlock_at}
      elsif (self.lock_at && Time.now > self.lock_at)
        locked = {:asset_string => self.asset_string, :lock_at => self.lock_at}
      elsif self.could_be_locked && item = locked_by_module_item?(user, opts)
        locked = {:asset_string => self.asset_string, :context_module => item.context_module.attributes}
        locked[:unlock_at] = locked[:context_module]["unlock_at"] if locked[:context_module]["unlock_at"] && locked[:context_module]["unlock_at"] > Time.now.utc
      end
      locked
    end
  end

  def hidden?
    return @hidden if defined?(@hidden)
    @hidden = self.file_state == 'hidden' || (self.folder && self.folder.hidden?)
  end

  def published?; !locked?; end

  def publish!
    self.locked = false
    save!
  end

  def just_hide
    self.file_state == 'hidden'
  end

  def public?
    self.file_state == 'public'
  end

  def currently_locked
    self.locked || (self.lock_at && Time.now > self.lock_at) || (self.unlock_at && Time.now < self.unlock_at) || self.file_state == 'hidden'
  end

  def hidden
    hidden?
  end

  def hidden=(val)
    self.file_state = (val == true || val == '1' ? 'hidden' : 'available')
  end

  def context_module_action(user, action)
    self.context_module_tags.each { |tag| tag.context_module_action(user, action) }
  end

  include Workflow

  # Right now, using the state machine to manage whether an attachment has
  # been uploaded to Scribd.  It can be uploaded to other places, or
  # scrubbed in other ways.  All that work should be managed by the state
  # machine.
  workflow do
    state :pending_upload do
      event :upload, :transitions_to => :processing
      event :process, :transitions_to => :processed
      event :mark_errored, :transitions_to => :errored
    end

    state :processing do
      event :process, :transitions_to => :processed
      event :mark_errored, :transitions_to => :errored
    end

    state :processed do
      event :recycle, :transitions_to => :pending_upload
    end
    state :errored do
      event :recycle, :transitions_to => :pending_upload
    end
    state :deleted
    state :to_be_zipped
    state :zipping
    state :zipped
    state :unattached
    state :unattached_temporary
  end

  scope :visible, -> { where(['attachments.file_state in (?, ?)', 'available', 'public']) }
  scope :not_deleted, -> { where("attachments.file_state<>'deleted'") }

  scope :not_hidden, -> { where("attachments.file_state<>'hidden'") }
  scope :not_locked, -> {
    where("(attachments.locked IS NULL OR attachments.locked=?) AND ((attachments.lock_at IS NULL) OR
      (attachments.lock_at>? OR (attachments.unlock_at IS NOT NULL AND attachments.unlock_at<?)))", false, Time.now.utc, Time.now.utc)
  }
  scope :by_content_types, lambda { |types|
    clauses = []
    types.each do |type|
      if type.include? '/'
        clauses << sanitize_sql_array(["(attachments.content_type=?)", type])
      else
        clauses << wildcard('attachments.content_type', type + '/', :type => :right)
      end
    end
    condition_sql = clauses.join(' OR ')
    where(condition_sql)
  }

  alias_method :destroy_permanently!, :destroy
  # file_state is like workflow_state, which was already taken
  # possible values are: available, deleted
  def destroy
    return if self.new_record?
    self.file_state = 'deleted' #destroy
    self.deleted_at = Time.now.utc
    ContentTag.delete_for(self)
    MediaObject.where(:attachment_id => self.id).update_all(:attachment_id => nil, :updated_at => Time.now.utc)
    save!
    # if the attachment being deleted belongs to a user and the uuid (hash of file) matches the avatar_image_url
    # then clear the avatar_image_url value.
    self.context.clear_avatar_image_url_with_uuid(self.uuid) if self.context_type == 'User' && self.uuid.present?
    true
  end

  def make_childless(preferred_child = nil)
    child = preferred_child || children.take
    raise "must be a child" unless child.root_attachment_id == id
    child.root_attachment_id = nil
    child.filename = filename if filename
    if Attachment.s3_storage?
      if filename && s3object.exists? && !child.s3object.exists?
        s3object.copy_to(child.s3object)
      end
    else
      old_content_type = self.content_type
      Attachment.where(:id => self).update_all(:content_type => "invalid/invalid") # prevents find_existing_attachment_for_md5 from reattaching the child to the old root
      child.uploaded_data = open
      Attachment.where(:id => self).update_all(:content_type => old_content_type)
    end
    child.save!
    Attachment.where(root_attachment_id: self).where.not(id: child).update_all(root_attachment_id: child)
  end

  def restore
    self.file_state = 'available'
    self.save
  end

  def deleted?
    self.file_state == 'deleted'
  end

  def available?
    self.file_state == 'available'
  end

  def crocodocable?
    Canvas::Crocodoc.enabled? &&
      CrocodocDocument::MIME_TYPES.include?(content_type)
  end

  def canvadocable?
    Canvadocs.enabled? && Canvadoc.mime_types.include?(content_type_with_text_match)
  end

  def self.submit_to_canvadocs(ids)
    Attachment.where(id: ids).find_each do |a|
      a.submit_to_canvadocs
    end
  end

  def self.skip_3rd_party_submits(skip=true)
    @skip_3rd_party_submits = skip
  end

  def self.skip_3rd_party_submits?
    !!@skip_3rd_party_submits
  end

  def self.skip_media_object_creation(&block)
    @skip_media_object_creation = true
    block.call
  ensure
    @skip_media_object_creation = false
  end
  def self.skip_media_object_creation?
    !!@skip_media_object_creation
  end

  def submit_to_canvadocs(attempt = 1, opts = {})
    # ... or crocodoc (this will go away soon)
    return if Attachment.skip_3rd_party_submits?

    submit_to_crocodoc_instead = opts[:force_crocodoc] ||
                                 (opts[:wants_annotation] &&
                                  crocodocable? &&
                                  !Canvadocs.annotations_supported?)
    if submit_to_crocodoc_instead
      # get crocodoc off the canvadocs strand
      # (maybe :wants_annotation was a dumb idea)
      send_later_enqueue_args :submit_to_crocodoc, {
        n_strand: 'crocodoc',
        max_attempts: 1,
        priority: Delayed::LOW_PRIORITY,
      }, attempt
    elsif canvadocable?
      doc = canvadoc || create_canvadoc
      doc.upload({
        annotatable: opts[:wants_annotation],
        preferred_plugins: opts[:preferred_plugins]
      })
      update_attribute(:workflow_state, 'processing')
    end
  rescue => e
    update_attribute(:workflow_state, 'errored')
    Canvas::Errors.capture(e, type: :canvadocs, attachment_id: id, annotatable: opts[:wants_annotation])

    if attempt <= Setting.get('max_canvadocs_attempts', '5').to_i
      send_later_enqueue_args :submit_to_canvadocs, {
        :n_strand => 'canvadocs_retries',
        :run_at => (5 * attempt).minutes.from_now,
        :max_attempts => 1,
        :priority => Delayed::LOW_PRIORITY,
      }, attempt + 1, opts
    end
  end

  def submit_to_crocodoc(attempt = 1)
    if crocodocable? && !Attachment.skip_3rd_party_submits?
      crocodoc = crocodoc_document || create_crocodoc_document
      crocodoc.upload
      update_attribute(:workflow_state, 'processing')
    end
  rescue => e
    update_attribute(:workflow_state, 'errored')
    Canvas::Errors.capture(e, type: :canvadocs, attachment_id: id)

    if attempt <= Setting.get('max_crocodoc_attempts', '5').to_i
      send_later_enqueue_args :submit_to_crocodoc, {
        :n_strand => 'crocodoc_retries',
        :run_at => (5 * attempt).minutes.from_now,
        :max_attempts => 1,
        :priority => Delayed::LOW_PRIORITY,
      }, attempt + 1
    end
  end

  def self.mimetype(filename)
    res = nil
    res = File.mime_type?(filename) if !res || res == 'unknown/unknown'
    res ||= "unknown/unknown"
    res
  end

  def mimetype(fn=nil)
    res = Attachment.mimetype(filename)
    res = File.mime_type?(self.uploaded_data) if (!res || res == 'unknown/unknown') && self.uploaded_data
    res ||= "unknown/unknown"
    res
  end


  def folder_path
    if folder
      folder.full_name
    else
      Folder.root_folders(self.context).first.try(:name)
    end
  end

  def full_path
    "#{folder_path}/#{filename}"
  end

  def matches_full_path?(path)
    f_path = full_path
    f_path == path || URI.unescape(f_path) == path || f_path.downcase == path.downcase || URI.unescape(f_path).downcase == path.downcase
  rescue
    false
  end

  def full_display_path
    "#{folder_path}/#{display_name}"
  end

  def matches_full_display_path?(path)
    fd_path = full_display_path
    fd_path == path || URI.unescape(fd_path) == path || fd_path.downcase == path.downcase || URI.unescape(fd_path).downcase == path.downcase
  rescue
    false
  end

  def matches_filename?(match)
    filename == match || display_name == match ||
      URI.unescape(filename) == match || URI.unescape(display_name) == match ||
      filename.downcase == match.downcase || display_name.downcase == match.downcase ||
      URI.unescape(filename).downcase == match.downcase || URI.unescape(display_name).downcase == match.downcase
  rescue
    false
  end

  def self.attachment_list_from_migration(context, ids)
    return "" if !ids || !ids.is_a?(Array) || ids.empty?
    description = "<h3>#{ERB::Util.h(t('title.migration_list', "Associated Files"))}</h3><ul>"
    ids.each do |id|
      attachment = context.attachments.where(migration_id: id).first
      description += "<li><a href='/courses/#{context.id}/files/#{attachment.id}/download'>#{ERB::Util.h(attachment.display_name)}</a></li>" if attachment
    end
    description += "</ul>";
    description
  end

  def self.find_from_path(path, context)
    list = path.split("/").select{|f| !f.empty? }
    if list[0] != Folder.root_folders(context).first.name
      list.unshift(Folder.root_folders(context).first.name)
    end
    filename = list.pop
    folder = context.folder_name_lookups[list.join('/')] rescue nil
    folder ||= context.folders.active.where(full_name: list.join('/')).first
    context.folder_name_lookups ||= {}
    context.folder_name_lookups[list.join('/')] = folder
    file = nil
    if folder
      file = folder.file_attachments.where(filename: filename).first
      file ||= folder.file_attachments.where(display_name: filename).first
    end
    file
  end

  def self.domain_namespace=(val)
    @@domain_namespace = val
  end

  def self.domain_namespace
    @@domain_namespace ||= nil
  end

  def self.serialization_methods; [:mime_class, :currently_locked, :crocodoc_available?]; end
  cattr_accessor :skip_thumbnails

  scope :uploadable, -> { where(:workflow_state => 'pending_upload') }
  scope :active, -> { where(:file_state => 'available') }
  scope :thumbnailable?, -> { where(:content_type => AttachmentFu.content_types) }
  scope :by_display_name, -> { order(display_name_order_by_clause('attachments')) }
  scope :by_position_then_display_name, -> { order("attachments.position, #{display_name_order_by_clause('attachments')}") }
  def self.serialization_excludes; [:uuid, :namespace]; end

  # returns filename, if it's already unique, or returns a modified version of
  # filename that makes it unique. you can either pass existing_files as string
  # filenames, in which case it'll test against those, or a block that'll be
  # called repeatedly with a filename until it returns true.
  def self.make_unique_filename(filename, existing_files = [], &block)
    unless block
      block = proc { |fname| !existing_files.include?(fname) }
    end

    return filename if block.call(filename)

    new_name = filename
    addition = 1
    dir = File.dirname(filename)
    dir = dir == "." ? "" : "#{dir}/"
    extname = File.extname(filename)
    basename = File.basename(filename, extname)

    until block.call(new_name = "#{dir}#{basename}-#{addition}#{extname}")
      addition += 1
    end
    new_name
  end

  DYNAMIC_THUMBNAIL_SIZES = %w(640x>)

  # the list of allowed thumbnail sizes to be generated dynamically
  def self.dynamic_thumbnail_sizes
    DYNAMIC_THUMBNAIL_SIZES + Setting.get("attachment_thumbnail_sizes", "").split(",")
  end

  def create_dynamic_thumbnail(geometry_string)
    tmp = self.create_temp_file
    Attachment.unique_constraint_retry do
      self.create_or_update_thumbnail(tmp, geometry_string, geometry_string)
    end
  end

  class OverQuotaError < StandardError; end

  def clone_url(url, duplicate_handling, check_quota, opts={})
    begin
      Attachment.clone_url_as_attachment(url, :attachment => self)

      if check_quota
        self.save! # save to calculate attachment size, otherwise self.size is nil
        if Attachment.over_quota?(opts[:quota_context] || self.context, self.size)
          raise OverQuotaError, t(:over_quota, 'The downloaded file exceeds the quota.')
        end
      end

      self.file_state = 'available'
      self.save!
      handle_duplicates(duplicate_handling || 'overwrite')
    rescue Exception, Timeout::Error => e
      self.file_state = 'errored'
      self.workflow_state = 'errored'
      case e
      when CanvasHttp::TooManyRedirectsError
        self.upload_error_message = t :upload_error_too_many_redirects, "Too many redirects"
      when CanvasHttp::InvalidResponseCodeError
        self.upload_error_message = t :upload_error_invalid_response_code, "Invalid response code, expected 200 got %{code}", :code => e.code
      when CanvasHttp::RelativeUriError
        self.upload_error_message = t :upload_error_relative_uri, "No host provided for the URL: %{url}", :url => url
      when URI::Error, ArgumentError
        # assigning all ArgumentError to InvalidUri may be incorrect
        self.upload_error_message = t :upload_error_invalid_url, "Could not parse the URL: %{url}", :url => url
      when Timeout::Error
        self.upload_error_message = t :upload_error_timeout, "The request timed out: %{url}", :url => url
      when OverQuotaError
        self.upload_error_message = t :upload_error_over_quota, "file size exceeds quota limits: %{bytes} bytes", :bytes => self.size
      else
        self.upload_error_message = t :upload_error_unexpected, "An unknown error occurred downloading from %{url}", :url => url
      end
      self.save!
    end
  end

  def crocodoc_available?
    crocodoc_document.try(:available?)
  end

  def canvadoc_available?
    canvadoc.try(:available?)
  end

  def view_inline_ping_url
    "/#{context_url_prefix}/files/#{self.id}/inline_view"
  end

  def canvadoc_url(user)
    return unless canvadocable?
    "/api/v1/canvadoc_session?#{preview_params(user, "canvadoc")}"
  end

  def crocodoc_url(user, crocodoc_ids = nil)
    return unless crocodoc_available?
    "/api/v1/crocodoc_session?#{preview_params(user, "crocodoc", crocodoc_ids)}"
  end

  def previewable_media?
    self.content_type && self.content_type.match(/\A(video|audio)/)
  end

  def preview_params(user, type, crocodoc_ids = nil)
    h = {
      user_id: user.try(:global_id),
      attachment_id: id,
      type: type
    }
    h.merge!(crocodoc_ids: crocodoc_ids) if crocodoc_ids.present?
    blob = h.to_json
    hmac = Canvas::Security.hmac_sha1(blob)
    "blob=#{URI.encode blob}&hmac=#{URI.encode hmac}"
  end
  private :preview_params

  def can_unpublish?
    false
  end

  def set_publish_state_for_usage_rights
    if self.context &&
       self.context.respond_to?(:feature_enabled?) &&
       self.context.feature_enabled?(:usage_rights_required)
      self.locked = self.usage_rights.nil?
    end
  end

  # Download a URL using a GET request and return a new un-saved Attachment
  # with the data at that URL. Tries to detect the correct content_type as
  # well.
  #
  # This handles large files well.
  #
  # Pass an existing attachment in opts[:attachment] to use that, rather than
  # creating a new attachment.
  def self.clone_url_as_attachment(url, opts = {})
    _, uri = CanvasHttp.validate_url(url)

    CanvasHttp.get(url) do |http_response|
      if http_response.code.to_i == 200
        tmpfile = CanvasHttp.tempfile_for_uri(uri)
        # net/http doesn't make this very obvious, but read_body can take any
        # object that responds to << as the destination of the body, and it'll
        # stream in chunks rather than reading the whole body into memory (as
        # long as you use the block form of http.request, which
        # CanvasHttp.get does)
        http_response.read_body(tmpfile)
        tmpfile.rewind
        attachment = opts[:attachment] || Attachment.new(:filename => File.basename(uri.path))
        attachment.filename ||= File.basename(uri.path)
        attachment.uploaded_data = tmpfile
        if attachment.content_type.blank? || attachment.content_type == "unknown/unknown"
          attachment.content_type = http_response.content_type
        end
        return attachment
      else
        raise CanvasHttp::InvalidResponseCodeError.new(http_response.code.to_i)
      end
    end
  end

  def self.migrate_attachments(from_context, to_context, scope = nil)
    from_attachments = scope
    from_attachments ||= from_context.shard.activate do
      Attachment.where(:context_type => from_context.class.name, :context_id => from_context).not_deleted.to_a
    end

    to_context.shard.activate do
      to_attachments = Attachment.where(:context_type => to_context.class.name, :context_id => to_context).not_deleted.to_a

      from_attachments.each do |attachment|
        match = to_attachments.detect{|a| attachment.matches_full_display_path?(a.full_display_path)}
        next if match && match.md5 == attachment.md5

        if from_context.shard == to_context.shard
          og_attachment = attachment
          og_attachment.context = to_context
          og_attachment.folder = Folder.assert_path(attachment.folder_path, to_context)
          og_attachment.save_without_broadcasting!
          if match
            og_attachment.folder.reload
            og_attachment.handle_duplicates(:rename)
          end
        else
          new_attachment = Attachment.new
          new_attachment.assign_attributes(attachment.attributes.except(*EXCLUDED_COPY_ATTRIBUTES), :without_protection => true)

          new_attachment.user_id = to_context.id if to_context.is_a? User
          new_attachment.context = to_context
          new_attachment.folder = Folder.assert_path(attachment.folder_path, to_context)
          new_attachment.namespace = new_attachment.infer_namespace
          if existing_attachment = new_attachment.find_existing_attachment_for_md5
            new_attachment.root_attachment = existing_attachment
          else
            new_attachment.write_attribute(:filename, attachment.filename)
            new_attachment.uploaded_data = attachment.open
          end

          new_attachment.content_type = attachment.content_type

          new_attachment.save_without_broadcasting!
          if match
            new_attachment.folder.reload
            new_attachment.handle_duplicates(:rename)
          end
        end
      end
    end
  end
end
