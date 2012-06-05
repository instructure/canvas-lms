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

# See the uploads controller and views for examples on how to use this model.
class Attachment < ActiveRecord::Base
  attr_accessible :context, :folder, :filename, :display_name, :user, :locked, :position, :lock_at, :unlock_at, :uploaded_data
  include HasContentTags
  
  belongs_to :context, :polymorphic => true
  belongs_to :cloned_item
  belongs_to :folder
  belongs_to :user
  has_one :account_report
  has_one :media_object
  has_many :submissions
  has_many :attachment_associations
  has_one :context_module_tag, :as => :content, :class_name => 'ContentTag', :conditions => ['content_tags.tag_type = ? AND workflow_state != ?', 'context_module', 'deleted'], :include => {:context_module => :context_module_progressions}
  belongs_to :root_attachment, :class_name => 'Attachment'
  belongs_to :scribd_mime_type
  belongs_to :scribd_account
  has_one :sis_batch
  has_one :thumbnail, :foreign_key => "parent_id", :conditions => {:thumbnail => "thumb"}
  has_many :thumbnails, :foreign_key => "parent_id"

  before_save :infer_display_name
  before_save :default_values
  
  before_validation :assert_attachment
  before_destroy :delete_scribd_doc
  acts_as_list :scope => :folder
  after_save :touch_context_if_appropriate
  after_save :build_media_object
  
  attr_accessor :podcast_associated_asset

  # this mixin can be added to a has_many :attachments association, and it'll
  # handle finding replaced attachments. In other words, if an attachment fond
  # by id is deleted but an active attachment in the same context has the same
  # path, it'll return that attachment.
  module FindInContextAssociation
    def find(*a, &b)
      return super if a.first.is_a?(Symbol)
      find_with_possibly_replaced(super)
    end

    def method_missing(method, *a, &b)
      return super unless method.to_s =~ /^find(?:_all)?_by_id$/
      find_with_possibly_replaced(super)
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
      if att.deleted?
        new_att = Folder.find_attachment_in_context_with_path(proxy_owner, att.full_display_path)
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
    touch_context unless context_type == 'ConversationMessage'
  end

  # this is a magic method that gets run by attachment-fu after it is done sending to s3,
  # that is the moment that we also want to submit it to scribd.
  # note, that the time it takes to send to s3 is the bad guy.  
  # It blocks and makes the user wait.  The good thing is that sending 
  # it to scribd from that point does not make the user wait since that 
  # does happen asynchronously and the data goes directly from s3 to scribd.
  def after_attachment_saved
    if !self.scribdable?
      # We aren't scribdable, so just mark as processed. (pending_upload and processing are the
      # only states that define transitions to process, so for other states this is correctly
      # a no-op.)
      self.process
    elsif ScribdAPI.enabled? && !Attachment.skip_scribd_submits?
      send_later_enqueue_args(:submit_to_scribd!, { :n_strand => 'scribd', :max_attempts => 1 })
    end

    send_later(:infer_encoding) if self.encoding.nil? && self.content_type =~ /text/
    if respond_to?(:process_attachment_with_processing) && thumbnailable? && !attachment_options[:thumbnails].blank? && parent_id.nil?
      temp_file = temp_path || create_temp_file
      self.class.attachment_options[:thumbnails].each { |suffix, size| send_later_if_production(:create_thumbnail_size, suffix) }
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
      Attachment.update_all({:encoding => 'UTF-8'}, {:id => self.id})
    rescue Iconv::Failure
      self.encoding = ''
      Attachment.update_all({:encoding => ''}, {:id => self.id})
      return
    end
  end
  
  # this is here becase attachment_fu looks to make sure that parent_id is nil before it will create a thumbnail of something.  
  # basically, it makes a false assumption that the thumbnail class is the same as the original class
  # which in our case is false because we use the Thumbnail model for the thumbnails.
  def parent_id;end 
  
  attr_accessor :clone_updated
  def clone_for(context, dup=nil, options={})
    if !self.cloned_item && !self.new_record?
      self.cloned_item ||= ClonedItem.create(:original_item => self)
      self.save!
    end
    existing = context.attachments.active.find_by_id(self.id)
    existing ||= self.cloned_item_id ? context.attachments.active.find_by_cloned_item_id(self.cloned_item_id) : nil
    return existing if existing && !options[:overwrite] && !options[:force_copy]
    existing ||= self.cloned_item_id ? context.attachments.find_by_cloned_item_id(self.cloned_item_id) : nil
    dup ||= Attachment.new
    dup = existing if existing && options[:overwrite]
    self.attributes.delete_if{|k,v| [:id, :uuid, :folder_id, :user_id, :filename].include?(k.to_sym) }.each do |key, val|
      dup.send("#{key}=", val)
    end
    dup.write_attribute(:filename, self.filename)
    dup.root_attachment_id = self.root_attachment_id || self.id
    dup.context = context
    dup.migration_id = CC::CCHelper.create_key(self)
    context.log_merge_result("File \"#{dup.folder.full_name rescue ''}/#{dup.display_name}\" created") if context.respond_to?(:log_merge_result)
    dup.updated_at = Time.now
    dup.clone_updated = true
    dup
  end
  
  def build_media_object
    return true if self.class.skip_media_object_creation?
    in_the_right_state = self.file_state == 'available' && self.workflow_state !~ /^unattached/
    transitioned_to_this_state = self.id_was == nil || self.file_state_changed? && self.workflow_state_was =~ /^unattached/
    if in_the_right_state && transitioned_to_this_state &&
        self.content_type && self.content_type.match(/\A(video|audio)/)
      delay = Setting.get_cached('attachment_build_media_object_delay_seconds', 10.to_s).to_i
      MediaObject.send_later_enqueue_args(:add_media_files, { :run_at => delay.seconds.from_now, :priority => Delayed::LOWER_PRIORITY }, self, false)
    end
  end

  def self.process_migration(data, migration)
    attachments = data['file_map'] ? data['file_map']: {}
    # TODO i18n
    attachments.values.each do |att|
      if !att['is_folder'] && migration.import_object?("files", att['migration_id'])
        begin
          import_from_migration(att, migration.context)
        rescue
          migration.add_warning("Couldn't import file \"#{att[:display_name] || att[:path_name]}\"", $!)
        end
      end
    end
    
    if data[:locked_folders]
      data[:locked_folders].each do |path|
        # TODO i18n
        if f = migration.context.active_folders.find_by_full_name("course files/#{path}")
          f.locked = true
          f.save
        end
      end
    end
    if data[:hidden_folders]
      data[:hidden_folders].each do |path|
        # TODO i18n
        if f = migration.context.active_folders.find_by_full_name("course files/#{path}")
          f.workflow_state = 'hidden'
          f.save
        end
      end
    end
  end

  def self.import_from_migration(hash, context, item=nil)
    hash = hash.with_indifferent_access
    hash[:migration_id] ||= hash[:attachment_id] || hash[:file_id]
    return nil if hash[:migration_id] && hash[:files_to_import] && !hash[:files_to_import][hash[:migration_id]]
    item ||= find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id])
    item ||= find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
    item ||= Attachment.find_from_path(hash[:path_name], context)
    if item
      item.context = context
      item.migration_id = hash[:migration_id]
      item.locked = true if hash[:locked]
      item.file_state = 'hidden' if hash[:hidden]
      item.display_name = hash[:display_name] if hash[:display_name]
      item.save!
      context.imported_migration_items << item if context.imported_migration_items
    end
    item
  end
  
  def assert_attachment
    if !self.to_be_zipped? && !self.zipping? && !self.errored? && (!filename || !content_type || !downloadable?)
      self.errors.add_to_base(t('errors.not_found', "File data could not be found"))
      return false
    end
  end
  
  after_create :flag_as_recently_created
  attr_accessor :recently_created

  validates_presence_of :context_id
  validates_presence_of :context_type
  
  serialize :scribd_doc, Scribd::Document
  
  def delete_scribd_doc
    return true unless self.scribd_doc && ScribdAPI.enabled? && !self.root_attachment_id
    ScribdAPI.instance.set_user(self.scribd_account)
    self.scribd_doc.destroy
  end
  protected :delete_scribd_doc
  
  # This method retrieves a URL to the thumbnail of a document, in a given size, and for any page in that document. Note that docs.getSettings and docs.getList also retrieve thumbnail URLs in default size - this method is really for resizing those. IMPORTANT - it is possible that at some time in the future, Scribd will redesign its image system, invalidating these URLs. So if you cache them, please have an update strategy in place so that you can update them if neceessary.
  # 
  # Parameters
  # integer width  (optional) Width in px of the desired image. If not included, will use the default thumb size.
  # integer height   (optional) Height in px of the desired image. If not included, will use the default thumb size.
  # integer page   (optional) Page to generate a thumbnail of. Defaults to 1.
  #
  # usage: Attachment.scribdable?.last.scribd_thumbnail(:height => 1100, :width=> 850, :page => 2)
  #   => "http://imgv2-4.scribdassets.com/img/word_document_page/34518627/850x1100/b0c489ddf1/1279739442/2"
  # or just some_attachment.scribd_thumbnail  #will give you the default tumbnail for the document.
  def scribd_thumbnail(options={})
    return unless self.scribd_doc && ScribdAPI.enabled?
    if options.empty? && self.cached_scribd_thumbnail
      self.cached_scribd_thumbnail
    else
      begin
      # if we aren't requesting special demensions, fetch and save it to the db.
      if options.empty?
        ScribdAPI.instance.set_user(self.scribd_account)
        self.cached_scribd_thumbnail = self.scribd_doc.thumbnail(options)
        # just update the cached_scribd_thumbnail column of this attachment without running callbacks
        Attachment.update_all({:cached_scribd_thumbnail => self.cached_scribd_thumbnail}, {:id => self.id})
        self.cached_scribd_thumbnail
      else
        Rails.cache.fetch(['scribd_thumb', self, options].cache_key) do
          ScribdAPI.instance.set_user(self.scribd_account)
          self.scribd_doc.thumbnail(options)
        end
      end
      rescue Scribd::NotReadyError
        nil
      rescue => e
        nil
      end
    end  
  end
  memoize :scribd_thumbnail
  
  def turnitinable?
    self.content_type && [
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/pdf',
      'text/plain',
      'text/html',
      'application/rtf',
      'text/richtext',
      'application/vnd.wordperfect'
    ].include?(self.content_type)
  end
  
  def flag_as_recently_created
    @recently_created = true
  end
  protected :flag_as_recently_created
  def recently_created?
    @recently_created || (self.created_at && self.created_at > Time.now - (60*5))
  end
  
  def scribdable_context?
    case self.context
    when Group
      true
    when User
      true
    when Course
      true
    else
      false
    end
  end
  protected :scribdable_context?
  
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
    self.display_name = nil if self.display_name && self.display_name.empty?
    self.display_name ||= unencoded_filename
    self.file_state ||= "available"
    self.last_unlock_at = self.unlock_at if self.unlock_at
    self.last_lock_at = self.lock_at if self.lock_at
    self.assert_file_extension
    self.folder_id = nil if !self.folder || self.folder.context != self.context
    self.folder_id = nil if self.folder && self.folder.deleted? && !self.deleted?
    self.folder_id ||= Folder.unfiled_folder(self.context).id rescue nil
    self.scribd_attempts ||= 0
    self.folder_id ||= Folder.root_folders(context).first.id rescue nil
    if self.root_attachment && self.new_record?
      [:md5, :size, :content_type, :scribd_mime_type_id, :scribd_user, :submitted_to_scribd_at, :workflow_state, :scribd_doc].each do |key|
        self.send("#{key.to_s}=", self.root_attachment.send(key))
      end
      self.write_attribute(:filename, self.root_attachment.filename)
    end
    self.context = self.folder.context if self.folder && (!self.context || (self.context.respond_to?(:is_a_context? ) && self.context.is_a_context?))

    if !self.scribd_mime_type_id && !['text/html', 'application/xhtml+xml', 'application/xml', 'text/xml'].include?(self.content_type)
      @@mime_ids ||= {}
      @@mime_ids[self.content_type] ||= self.content_type && ScribdMimeType.find_by_name(self.content_type).try(:id)
      self.scribd_mime_type_id = @@mime_ids[self.content_type]
      if !self.scribd_mime_type_id
        @@mime_ids[self.after_extension] ||= self.after_extension && ScribdMimeType.find_by_extension(self.after_extension).try(:id)
        self.scribd_mime_type_id = @@mime_ids[self.after_extension]
      end
    end

    if self.respond_to?(:namespace=) && self.new_record?
      self.namespace = infer_namespace
    end
    
    self.media_entry_id ||= 'maybe' if self.new_record? && self.content_type && self.content_type.match(/(video|audio)/)

    # Raise an error if this is scribdable without a scribdable context?
    if scribdable_context? and scribdable? and ScribdAPI.enabled?
      unless context.scribd_account 
        ScribdAccount.create(:scribdable => context) 
        self.context.reload
      end
      self.scribd_account_id ||= context.scribd_account.id
    end
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
    ns = Attachment.domain_namespace
    ns ||= self.context.root_account.file_namespace rescue nil
    ns ||= self.context.account.file_namespace rescue nil
    if Rails.env.development? && Attachment.local_storage?
      ns ||= ""
      ns = "_localstorage_/#{ns}"
    end
    ns = nil if ns && ns.empty?
    ns
  end

  def process_s3_details!(details)
    unless workflow_state == 'unattached_temporary'
      self.workflow_state = nil
      self.file_state = 'available'
    end
    self.md5 = (details['etag'] || "").gsub(/\"/, '')
    self.content_type = details['content-type']
    self.size = details['content-length']

    if md5.present? && ns = infer_namespace
      if existing_attachment = Attachment.find_all_by_md5_and_namespace(md5, ns).detect{|a| a.id != id && !a.root_attachment_id && a.content_type == content_type }
        AWS::S3::S3Object.delete(full_filename, bucket_name) rescue nil
        self.root_attachment = existing_attachment
        write_attribute(:filename, nil)
        clear_cached_urls
      end
    end

    save!

    # normally this would be called by attachment_fu after it had uploaded the file to S3.
    after_attachment_saved
  end

  CONTENT_LENGTH_RANGE = 10.gigabytes
  S3_EXPIRATION_TIME = 30.minutes

  def ajax_upload_params(pseudonym, local_upload_url, s3_success_url, options = {})
    if Attachment.s3_storage?
      res = {
        :upload_url => "#{options[:ssl] ? "https" : "http"}://#{bucket_name}.s3.amazonaws.com/",
        :remote_url => true,
        :file_param => 'file',
        :success_url => s3_success_url,
        :upload_params => {
          'AWSAccessKeyId' => AWS::S3::Base.connection.access_key_id
        }
      }
    elsif Attachment.local_storage?
      res = {
        :upload_url => local_upload_url,
        :remote_url => false,
        :file_param => options[:file_param] || 'attachment[uploaded_data]', #uploadify ignores this and uses 'file',
        :upload_params => options[:upload_params] || {}
      }
    else
      raise "Unknown storage system configured"
    end

    # Build the data that will be needed for the user to upload to s3
    # without us being the middle-man
    sanitized_filename = full_filename.gsub(/\+/, " ")
    policy = {
      'expiration' => (options[:expiration] || S3_EXPIRATION_TIME).from_now.utc.iso8601,
      'conditions' => [
        {'bucket' => bucket_name},
        {'key' => sanitized_filename},
        {'acl' => 'private'},
        ['starts-with', '$Filename', ''],
        ['starts-with', '$folder', ''],
        ['content-length-range', 1, (options[:max_size] || CONTENT_LENGTH_RANGE)]
      ]
    }
    extras = []
    if options[:no_redirect]
      extras << {'success_action_status' => '201'}
    elsif res[:success_url]
      extras << {'success_action_redirect' => res[:success_url]}
    end
    if content_type && content_type != "unknown/unknown"
      extras << {'content-type' => content_type}
    end
    policy['conditions'] += extras
    # flash won't send the session cookie, so for local uploads we put the user id in the signed
    # policy so we can mock up the session for FilesController#create
    if Attachment.local_storage?
      policy['conditions'] << { 'pseudonym_id' => pseudonym.id }
      policy['attachment_id'] = self.id
    end

    policy_encoded = Base64.encode64(policy.to_json).gsub(/\n/, '')
    signature = Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'), Attachment.shared_secret, policy_encoded
      )
    ).gsub(/\n/, '')

    res[:id] = id
    res[:upload_params].merge!({
       'Filename' => '',
       'folder' => '',
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
    return nil if OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new("sha1"), Attachment.shared_secret, policy_str) != signature
    policy = JSON.parse(Base64.decode64(policy_str))
    return nil unless Time.zone.parse(policy['expiration']) >= Time.now
    attachment = Attachment.find(policy['attachment_id'])
    return nil unless attachment.try(:state) == :unattached
    return policy, attachment
  end

  def unencoded_filename
    CGI::unescape(self.filename || t(:default_filename, "File"))
  end
  
  def handle_duplicates(method)
    return [] unless method.present? && self.folder
    method = method.to_sym
    deleted_attachments = []
    other_attachments = 
    if method == :rename
      self.display_name = Attachment.make_unique_filename(self.display_name, self.folder.active_file_attachments.reject {|a| a.id == self.id }.map(&:display_name))
      self.save
    elsif method == :overwrite
      self.folder.active_file_attachments.find_all_by_display_name(self.display_name).reject {|a| a.id == self.id }.each do |a|
        a.destroy
        deleted_attachments << a
      end
    end
    return deleted_attachments
  end

  def self.destroy_files(ids)
    Attachment.find_all_by_id(ids).compact.each(&:destroy)
  end
  
  before_save :assign_uuid
  def assign_uuid
    self.uuid ||= AutoHandle.generate_securish_uuid
  end
  protected :assign_uuid
  
  def inline_content?
    self.content_type.match(/\Atext/) || self.extension == '.html' || self.extension == '.htm' || self.extension == '.swf'
  end
  
  def self.s3_config
    # Return existing value, even if nil, as long as it's defined
    return @s3_config if defined?(@s3_config)
    @s3_config ||= YAML.load_file(RAILS_ROOT + "/config/amazon_s3.yml")[RAILS_ENV].symbolize_keys rescue nil
  end

  def s3_config
    @s3_config ||= (self.class.s3_config || {}).merge(PluginSetting.settings_for_plugin('s3').symbolize_keys || {})
  end
  
  def self.file_store_config
    # Return existing value, even if nil, as long as it's defined
    @file_store_config ||= YAML.load_file(RAILS_ROOT + "/config/file_store.yml")[RAILS_ENV] rescue nil
    @file_store_config ||= { 'storage' => 'local' }
    # default the secure setting to true only in production
    @file_store_config['secure'] = Rails.env.production? unless @file_store_config.has_key?('secure')
    @file_store_config['path_prefix'] ||= @file_store_config['path'] || 'tmp/files'
    if RAILS_ENV == "test"
      # yes, a rescue nil; the problem is that in an automated test environment, this may be
      # in the auto-require path, before the DB is even created; obviously it hasn't been
      # overridden yet
      file_storage_test_override = Setting.get("file_storage_test_override", nil) rescue nil
      return @file_store_config.merge({"storage" => file_storage_test_override}) if file_storage_test_override
    end
    return @file_store_config
  end
  
  def self.s3_storage?
    (file_store_config['storage'] rescue nil) == 's3' && s3_config
  end
  
  def self.local_storage?
    rv = !s3_storage?
    raise "Unknown storage type!" if rv && file_store_config['storage'] != 'local'
    rv
  end

  def self.shared_secret
    self.s3_storage? ? AWS::S3::Base.connection.secret_access_key : "local_storage" + Canvas::Security.encryption_key
  end

  def downloadable?
    !!(self.authenticated_s3_url rescue false)
  end

  # Haaay... you're changing stuff here? Don't forget about the Thumbnail model
  # too, it cares about local vs s3 storage.
  if local_storage?
    has_attachment(
        :path_prefix => file_store_config['path_prefix'],
        :thumbnails => { :thumb => '200x50' }, 
        :thumbnail_class => 'Thumbnail'
    )
    def authenticated_s3_url(*args)
      return root_attachment.authenticated_s3_url(*args) if root_attachment
      protocol = args[0].is_a?(Hash) && args[0][:protocol]
      protocol ||= self.class.file_store_config['secure'] ? "https://" : "http://"
      protocol ||= "//"
      "#{protocol}#{HostUrl.context_host(context)}/#{context_type.underscore.pluralize}/#{context_id}/files/#{id}/download?verifier=#{uuid}"
    end

    alias_method :attachment_fu_filename=, :filename=
    def filename=(val)
      if self.new_record?
        write_attribute(:filename, val)
      else
        self.attachment_fu_filename = val
      end
    end

    def bucket_name; "no-bucket"; end
  else
    has_attachment(
        :storage => :s3, 
        :s3_access => :private, 
        :thumbnails => { :thumb => '200x50' }, 
        :thumbnail_class => 'Thumbnail'
    )
    def bucket_name
      s3_config[:bucket_name]
    end
  end

  def content_type_with_encoding
    encoding.blank? ? content_type : "#{content_type}; charset=#{encoding}"
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
    if Attachment.local_storage?
      if block
        File.open(self.full_filename, 'rb') { |file|
          chunk = file.read(4096)
          while chunk
            yield chunk
            chunk = file.read(4096)
          end
        }
      else
        File.open(self.full_filename, 'rb')
      end
    elsif block
      AWS::S3::S3Object.stream(self.full_filename, self.bucket_name, &block)
    else
      # TODO: !need_local_file -- net/http and thus AWS::S3::S3Object don't
      # natively support streaming the response, except when a block is given.
      # so without Fibers, there's not a great way to return an IO-like object
      # that streams the response. A separate thread, I guess. Bleck. Need to
      # investigate other options.
      if opts[:temp_folder].present? && !File.exist?(opts[:temp_folder])
        FileUtils.mkdir_p(opts[:temp_folder])
      end
      tempfile = Tempfile.new(["attachment_#{self.id}", self.extension],
                              opts[:temp_folder].presence || Dir::tmpdir)
      AWS::S3::S3Object.stream(self.full_filename, self.bucket_name) do |chunk|
        tempfile.write(chunk)
      end
      tempfile.rewind
      tempfile
    end
  end

  # you should be able to pass an optional width, height, and page_number/video_seconds to this method
  # can't handle arbitrary thumbnails for our attachment_fu thumbnails on s3 though, we could handle a couple *predefined* sizes though
  def thumbnail_url(options={})
    return nil if Attachment.skip_thumbnails
    if self.scribd_doc #handle if it is a scribd doc, get the thumbnail from scribd's api
      self.scribd_thumbnail(options)
    elsif self.thumbnail || (options && options[:size].present?)
      if options && options[:size].present?
        geometry = options[:size]
        if self.class.dynamic_thumbnail_sizes.include?(geometry)
          to_use = thumbnails.loaded? ? thumbnails.detect { |t| t.thumbnail == geometry } : thumbnails.find_by_thumbnail(geometry)
          to_use ||= create_dynamic_thumbnail(geometry)
        end
      end
      to_use ||= self.thumbnail

      to_use.cached_s3_url
    elsif self.media_object && self.media_object.media_id
      Kaltura::ClientV3.new.thumbnail_url(self.media_object.media_id,
                                          :width => options[:width] || 140,
                                          :height => options[:height] || 100,
                                          :vid_sec => options[:video_seconds] || 5)
    else
      # "still need to handle things that are not images with thumbnails, scribd_docs, or kaltura docs"
    end
  end
  memoize :thumbnail_url
  
  alias_method :original_sanitize_filename, :sanitize_filename
  def sanitize_filename(filename)
    filename = CGI::escape(filename)
    filename = self.root_attachment.filename if self.root_attachment && self.root_attachment.filename
    chunks = (filename || "").scan(/\./).length + 1
    filename.gsub!(/[^\.]+/) do |str|
      str[0, 220/chunks]
    end
    filename
  end

  def infer_display_name
    self.display_name ||= unencoded_filename
  end
  protected :infer_display_name
  
  # Accepts an array of words and returns an array of words, some of them
  # combined by a dash.
  def dashed_map(words, n=30)
    line_length = 0
    words.inject([]) do |list, word|
      
      # Get the length of the word
      word_size = word.size
      # Add 1 for the space preceding the word
      # There is no space added before the first word
      word_size += 1 unless list.empty?

      # If adding a word takes us over our limit,
      # join two words by a dash and insert that 
      if word_size >= n
        word_pieces = []
        ((word_size / 15) + 1).times do |i|
          word_pieces << word[(i * 15)..(((i+1) * 15)-1)]
        end
        word = word_pieces.compact.select{|p| p.length > 0}.join('-')
        list << word
        line_length = word.size
      elsif (line_length + word_size >= n) and not list.empty?
        previous = list.pop
        previous ||= ''
        list << previous + '-' + word
        line_length = word_size
      # Otherwise just add the word to the list
      else
        list << word
        line_length += word_size
      end

      # Return the list so that inject works
      list
    end
  end
  protected :dashed_map
  
  
  def readable_size
    h = ActionView::Base.new
    h.extend ActionView::Helpers::NumberHelper
    h.number_to_human_size(self.size) rescue "size unknown"
  end
  
  def clear_cached_urls
    Rails.cache.delete(['cacheable_s3_urls', self].cache_key)
    self.cached_scribd_thumbnail = nil
  end
  
  def cacheable_s3_download_url
    cacheable_s3_urls['attachment']
  end

  def cacheable_s3_inline_url
    cacheable_s3_urls['inline']
  end

  def cacheable_s3_urls
    Rails.cache.fetch(['cacheable_s3_urls', self].cache_key, :expires_in => 24.hours) do
      ascii_filename = Iconv.conv("ASCII//TRANSLIT//IGNORE", "UTF-8", display_name)

      # response-content-disposition will be url encoded in the depths of
      # aws-s3, doesn't need to happen here. we'll be nice and ghetto http
      # quote the filename string, though.
      quoted_ascii = ascii_filename.gsub(/([\x00-\x1f"\x7f])/, '\\\\\\1')

      # awesome browsers will use the filename* and get the proper unicode filename,
      # everyone else will get the sanitized ascii version of the filename
      quoted_unicode = "UTF-8''#{URI.escape(display_name, /[^A-Za-z0-9.]/)}"
      filename = %(filename="#{quoted_ascii}"; filename*=#{quoted_unicode})

      # we need to have versions of the url for each content-disposition
      {
        'inline' => authenticated_s3_url(:expires_in => 6.days, "response-content-disposition" => "inline; " + filename),
        'attachment' => authenticated_s3_url(:expires_in => 6.days, "response-content-disposition" => "attachment; " + filename)
      }
    end
  end
  protected :cacheable_s3_urls
  
  def attachment_path_id
    a = (self.respond_to?(:root_attachment) && self.root_attachment) || self
    ((a.respond_to?(:parent_id) && a.parent_id) || a.id).to_s
  end
  
  def filename
    read_attribute(:filename) || (self.root_attachment && self.root_attachment.filename)
  end

  def thumbnail_with_root_attachment
    self.thumbnail_without_root_attachment || self.root_attachment.try(:thumbnail)
  end
  alias_method_chain :thumbnail, :root_attachment

  def scribd_doc
    self.read_attribute(:scribd_doc) || self.root_attachment.try(:scribd_doc)
  end

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
      "image/x-psd" => "image",
      "application/x-rar" => "zip", 
      "application/x-rar-compressed" => "zip", 
      "application/x-zip" => "zip", 
      "application/x-zip-compressed" => "zip", 
      "application/xml" => "code", 
      "application/zip" => "zip",
      "audio/mpeg" => "audio",
      "audio/basic" => "audio",
      "audio/mid" => "audio",
      "audio/mpeg" => "audio",
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

  set_policy do
    given { |user, session| self.cached_context_grants_right?(user, session, :manage_files) } #admins.include? user }
    can :read and can :update and can :delete and can :create and can :download
    
    given { |user, session| self.public? }
    can :read and can :download
    
    given { |user, session| self.cached_context_grants_right?(user, session, :read) } #students.include? user }
    can :read
    
    given { |user, session| 
      self.cached_context_grants_right?(user, session, :read) && 
      (self.cached_context_grants_right?(user, session, :manage_files) || !self.locked_for?(user))
    }
    can :download
    
    given { |user, session| self.context_type == 'Submission' && self.context.grant_rights?(user, session, :comment) }
    can :create
    
    given { |user, session|
        session && session['file_access_user_id'].present? &&
        (u = User.find_by_id(session['file_access_user_id'])) &&
        self.cached_context_grants_right?(u, session, :read) &&
        session['file_access_expiration'] && session['file_access_expiration'].to_i > Time.now.to_i
    }
    can :read
    
    given { |user, session|
        session && session['file_access_user_id'].present? &&
        (u = User.find_by_id(session['file_access_user_id'])) &&
        self.cached_context_grants_right?(u, session, :read) &&
        (self.cached_context_grants_right?(u, session, :manage_files) || !self.locked_for?(u)) &&
        session['file_access_expiration'] && session['file_access_expiration'].to_i > Time.now.to_i
    }
    can :download
  end
  
  def locked_for?(user, opts={})
    @locks ||= {}
    return false if opts[:check_policies] && self.grants_right?(user, nil, :update)
    return {:manually_locked => true} if self.locked || (self.folder && self.folder.locked?)
    @locks[user ? user.id : 0] ||= Rails.cache.fetch(locked_cache_key(user), :expires_in => 1.minute) do
      locked = false
      if (self.unlock_at && Time.now < self.unlock_at)
        locked = {:asset_string => self.asset_string, :unlock_at => self.unlock_at}
      elsif (self.lock_at && Time.now > self.lock_at)
        locked = {:asset_string => self.asset_string, :lock_at => self.lock_at}
      elsif (self.could_be_locked && self.context_module_tag && !self.context_module_tag.available_for?(user, opts[:deep_check_if_needed]))
        locked = {:asset_string => self.asset_string, :context_module => self.context_module_tag.context_module.attributes}
      end
      locked
    end
  end
  
  def hidden?
    self.file_state == 'hidden' || (self.folder && self.folder.hidden?)
  end
  memoize :hidden?
  
  def just_hide
    self.file_state == 'hidden'
  end
  
  def public?
    self.file_state == 'public'
  end
  memoize :public?
  
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
    self.context_module_tag.context_module_action(user, action) if self.context_module_tag
  end

  include Workflow
  
  # Right now, using the state machine to manage whether an attachment has
  # been uploaded to Scribd.  It can be uploaded to other places, or
  # scrubbed in other ways.  All that work should be managed by the state
  # machine. 
  workflow do
    state :pending_upload do
      event :upload, :transitions_to => :processing do
        self.submitted_to_scribd_at = Time.now
        self.scribd_attempts ||= 0
        self.scribd_attempts += 1
      end
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
    state :to_be_zipped
    state :zipping
    state :zipped
    state :unattached
    state :unattached_temporary
  end
  
  named_scope :to_be_zipped, lambda{
    {:conditions => ['attachments.workflow_state = ? AND attachments.scribd_attempts < ?', 'to_be_zipped', 10], :order => 'created_at' }
  }

  named_scope :active, lambda {
    { :conditions => ['attachments.file_state != ?', 'deleted'] }
  }

  alias_method :destroy!, :destroy
  # file_state is like workflow_state, which was already taken
  # possible values are: available, deleted
  def destroy(delete_media_object = true)
    return if self.new_record?
    self.file_state = 'deleted' #destroy
    self.deleted_at = Time.now
    ContentTag.delete_for(self)
    MediaObject.update_all({:workflow_state => 'deleted', :updated_at => Time.now.utc}, {:attachment_id => self.id}) if self.id && delete_media_object
    save!
    # if the attachment being deleted belongs to a user and the uuid (hash of file) matches the avatar_image_url
    # then clear the avatar_image_url value.
    self.context.clear_avatar_image_url_with_uuid(self.uuid) if self.context_type == 'User' && self.uuid.present?
  end
  
  def restore
    self.file_state = 'active'
    self.save
  end
  
  def deleted?
    self.file_state == 'deleted'
  end
  
  def available?
    self.file_state == 'available'
  end
  
  def scribdable?
    ScribdAPI.enabled? && self.scribd_mime_type_id ? true : false
  end
  
  def self.submit_to_scribd(ids)
    Attachment.find_all_by_id(ids).compact.each do |attachment|
      attachment.submit_to_scribd! rescue nil
    end
  end
  
  def self.skip_scribd_submits(skip=true)
    @skip_scribd_submits = skip
  end
  
  def self.skip_broadcast_messages(skip=true)
    @skip_broadcast_messages = skip
  end
  
  def self.skip_scribd_submits?
    !!@skip_scribd_submits
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
  
  # This is the engine of the Scribd machine.  Submits the code to
  # scribd when appropriate, otherwise adjusts the state machine. This
  # should be called from another service, creating an asynchronous upload
  # to Scribd. This is fairly forgiving, so that if I ask to submit
  # something that shouldn't be submitted, it just returns false.  If it's
  # something that should never be submitted, it should just update the
  # state to processed so that it doesn't try to do that again. 
  def submit_to_scribd!
    # Newly created record that needs to be submitted to scribd
    if self.pending_upload? and self.scribdable? and self.filename and ScribdAPI.enabled?
      ScribdAPI.instance.set_user(self.scribd_account)
      begin
        upload_path = if Attachment.local_storage?
                 self.full_filename
               else
                 self.authenticated_s3_url(:expires_in => 1.year)
               end
        self.write_attribute(:scribd_doc, ScribdAPI.upload(upload_path, self.after_extension || self.scribd_mime_type.extension))
        self.cached_scribd_thumbnail = self.scribd_doc.thumbnail
        self.workflow_state = 'processing'
      rescue => e
        self.workflow_state = 'errored'
        ErrorReport.log_exception(:scribd, e, :attachment_id => self.id)
      end
      self.submitted_to_scribd_at = Time.now
      self.scribd_attempts ||= 0
      self.scribd_attempts += 1
      self.save
      return true
    # Newly created record that isn't appropriate for scribd
    elsif self.pending_upload? and not self.scribdable?
      self.process!
      return true
    else
      return false
    end
  end

  def resubmit_to_scribd!
    if self.scribd_doc && ScribdAPI.enabled?
      ScribdAPI.instance.set_user(self.scribd_account)
      self.scribd_doc.destroy rescue nil
    end
    self.workflow_state = 'pending_upload'
    self.submit_to_scribd!
  end
  
  # Should be one of "PROCESSING", "DISPLAYABLE", "DONE", "ERROR".  "DONE"
  # should mean indexed, "DISPLAYABLE" is good enough for showing a user
  # the iPaper.  I added a state, "NOT SUBMITTED", for any attachment that
  # hasn't been submitted, regardless of whether it should be.  As long as
  # we go through the submit_to_scribd! gateway, we'll be fine.
  #
  # This is a cached view of the status, it doesn't query scribd directly. That
  # happens in a periodic job. Our javascript is set up to check scribd for the
  # document if status is "PROCESSING" so we don't have to actually wait for
  # the periodic job to find the doc is done.
  def conversion_status
    return 'DONE' if !ScribdAPI.enabled?
    return 'ERROR' if self.errored?
    if !self.scribd_doc
      if !self.scribdable?
        self.process
      end
      return 'NOT SUBMITTED'
    end
    return 'DONE' if self.processed?
    return 'PROCESSING'
  end

  def query_conversion_status!
    return unless ScribdAPI.enabled? && self.scribdable?
    if self.scribd_doc
      ScribdAPI.set_user(self.scribd_account) rescue nil
      res = ScribdAPI.get_status(self.scribd_doc) rescue 'ERROR'
      case res
      when 'DONE'
        self.process
      when 'ERROR'
        self.mark_errored
      end
      res.to_s.upcase
    else
      self.send_at(10.minutes.from_now, :resubmit_to_scribd!)
    end
  end

  # Returns a link to get the document remotely.
  def download_url(format='original')
    return @download_url if @download_url
    return nil unless ScribdAPI.enabled?
    ScribdAPI.set_user(self.scribd_account)
    begin
      @download_url = self.scribd_doc.download_url(format)
    rescue Scribd::ResponseError => e
      return nil
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
  
  def full_path
    folder = (self.folder.full_name + '/') rescue Folder.root_folders(self.context).first.name + '/'
    folder + self.filename
  end

  def matches_full_path?(path)
    f_path = full_path
    f_path == path || URI.unescape(f_path) == path || f_path.downcase == path.downcase || URI.unescape(f_path).downcase == path.downcase
  end

  def full_display_path
    folder = (self.folder.full_name + '/') rescue Folder.root_folders(self.context).first.name + '/'
    folder + self.display_name
  end

  def matches_full_display_path?(path)
    fd_path = full_display_path
    fd_path == path || URI.unescape(fd_path) == path || fd_path.downcase == path.downcase || URI.unescape(fd_path).downcase == path.downcase
  end

  def matches_filename?(match)
    filename == match || display_name == match ||
      URI.unescape(filename) == match || URI.unescape(display_name) == match ||
      filename.downcase == match.downcase || display_name.downcase == match.downcase ||
      URI.unescape(filename).downcase == match.downcase || URI.unescape(display_name).downcase == match.downcase
  end

  def protect_for(user)
    @cant_preview_scribd_doc = !self.grants_right?(user, nil, :download)
  end
  
  def self.attachment_list_from_migration(context, ids)
    return "" if !ids || !ids.is_a?(Array) || ids.empty?
    description = "<h3>#{t 'title.migration_list', "Associated Files"}</h3><ul>"
    ids.each do |id|
      attachment = context.attachments.find_by_migration_id(id)
      description += "<li><a href='/courses/#{context.id}/files/#{attachment.id}/download' class='#{'instructure_file_link' if attachment.scribdable?}'>#{attachment.display_name}</a></li>" if attachment
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
    folder ||= context.folders.active.find_by_full_name(list.join('/'))
    context.folder_name_lookups ||= {}
    context.folder_name_lookups[list.join('/')] = folder
    file = nil
    if folder
      file = folder.file_attachments.find_by_filename(filename)
      file ||= folder.file_attachments.find_by_display_name(filename)
    end
    file
  end
  
  def self.domain_namespace=(val)
    @@domain_namespace = val
  end
  
  def self.domain_namespace
    @@domain_namespace ||= nil
  end
  
  def self.serialization_methods; [:mime_class, :scribdable?, :currently_locked]; end
  cattr_accessor :skip_thumbnails
  
  
  named_scope :scribdable?, :conditions => ['scribd_mime_type_id is not null']
  named_scope :recyclable, :conditions => ['attachments.scribd_attempts < ? AND attachments.workflow_state = ?', 3, 'errored']
  named_scope :needing_scribd_conversion_status, :conditions => ['attachments.workflow_state = ? AND attachments.updated_at < ?', 'processing', 30.minutes.ago], :limit => 50
  named_scope :uploadable, :conditions => ['workflow_state = ?', 'pending_upload']
  named_scope :active, :conditions => ['file_state = ?', 'available']
  named_scope :thumbnailable?, :conditions => {:content_type => Technoweenie::AttachmentFu.content_types}  
  def self.serialization_excludes; [:uuid, :namespace]; end
  def set_serialization_options
    if self.scribd_doc
      @scribd_password = self.scribd_doc.secret_password
      @scribd_doc_backup = self.scribd_doc.dup
      @scribd_doc_backup.instance_variable_set('@attributes', self.scribd_doc.instance_variable_get('@attributes').dup)
      self.scribd_doc.secret_password = ''
      self.scribd_doc = nil if @cant_preview_scribd_doc
    end
  end
  def revert_from_serialization_options
    self.scribd_doc = @scribd_doc_backup
    self.scribd_doc.secret_password = @scribd_password if self.scribd_doc
  end
  
  def self.process_scribd_conversion_statuses
    # Runs periodically
    @attachments = Attachment.needing_scribd_conversion_status
    @attachments.each do |attachment|
      attachment.query_conversion_status!
    end
    @attachments = Attachment.scribdable?.recyclable
    @attachments.each do |attachment|
      attachment.resubmit_to_scribd!
    end
  end

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
    DYNAMIC_THUMBNAIL_SIZES + Setting.get_cached("attachment_thumbnail_sizes", "").split(",")
  end

  def create_dynamic_thumbnail(geometry_string)
    tmp = self.create_temp_file
    Attachment.unique_constraint_retry do
      self.create_or_update_thumbnail(tmp, geometry_string, geometry_string)
    end
  end
end
