require 'attachment_fu/railtie'
require 'attachment_fu/processors/mini_magick_processor'
require 'attachment_fu/backends/file_system_backend'
require 'attachment_fu/backends/s3_backend'

module AttachmentFu # :nodoc:
  @@default_processors = %w(MiniMagick)
  # Instructure: I (ryan shaw) just copied and pasted this from http://github.com/technoweenie/attachment_fu/blob/master/lib/technoweenie/attachment_fu.rb
  @@content_types      = [
    'image/jpeg',
    'image/pjpeg',
    'image/jpg',
    'image/gif',
    'image/png',
    'image/x-png',
    'image/jpg',
    'image/x-ms-bmp',
    'image/bmp',
    'image/x-bmp',
    'image/x-bitmap',
    'image/x-xbitmap',
    'image/x-win-bitmap',
    'image/x-windows-bmp',
    'image/ms-bmp',
    'application/bmp',
    'application/x-bmp',
    'application/x-win-bitmap',
    'application/preview',
    'image/jp_',
    'application/jpg',
    'application/x-jpg',
    'image/pipeg',
    'image/vnd.swiftview-jpeg',
    'image/x-xbitmap',
    'application/png',
    'application/x-png',
    'image/gi_',
    'image/x-citrix-pjpeg'
  ]
  mattr_reader :content_types, :tempfile_path, :default_processors
  mattr_writer :tempfile_path

  class ThumbnailError < StandardError;  end
  class AttachmentError < StandardError; end

  module ActMethods
    # Options:
    # *  <tt>:content_type</tt> - Allowed content types.  Allows all by default.  Use :image to allow all standard image types.
    # *  <tt>:min_size</tt> - Minimum size allowed.  1 byte is the default.
    # *  <tt>:max_size</tt> - Maximum size allowed.  1.megabyte is the default.
    # *  <tt>:size</tt> - Range of sizes allowed.  (1..1.megabyte) is the default.  This overrides the :min_size and :max_size options.
    # *  <tt>:resize_to</tt> - Used by RMagick to resize images.  Pass either an array of width/height, or a geometry string.
    # *  <tt>:thumbnails</tt> - Specifies a set of thumbnails to generate.  This accepts a hash of filename suffixes and RMagick resizing options.
    # *  <tt>:thumbnail_class</tt> - Set what class to use for thumbnails.  This attachment class is used by default.
    # *  <tt>:path_prefix</tt> - path to store the uploaded files.  Uses public/#{table_name} by default for the filesystem, and just #{table_name}
    #      for the S3 backend.  Setting this sets the :storage to :file_system.
    # *  <tt>:storage</tt> - Use :file_system to specify the attachment data is stored with the file system.  Defaults to :db_system.

    # *  <tt>:keep_profile</tt> By default image EXIF data will be stripped to minimize image size. For small thumbnails this proivides important savings. Picture quality is not affected. Set to false if you want to keep the image profile as is. ImageScience will allways keep EXIF data.
    #
    # Examples:
    #   has_attachment :max_size => 1.kilobyte
    #   has_attachment :size => 1.megabyte..2.megabytes
    #   has_attachment :content_type => 'application/pdf'
    #   has_attachment :content_type => ['application/pdf', 'application/msword', 'text/plain']
    #   has_attachment :content_type => :image, :resize_to => [50,50]
    #   has_attachment :content_type => ['application/pdf', :image], :resize_to => 'x50'
    #   has_attachment :thumbnails => { :thumb => [50, 50], :geometry => 'x50' }
    #   has_attachment :storage => :file_system, :path_prefix => 'public/files'
    #   has_attachment :storage => :file_system, :path_prefix => 'public/files',
    #     :content_type => :image, :resize_to => [50,50]
    #   has_attachment :storage => :file_system, :path_prefix => 'public/files',
    #     :thumbnails => { :thumb => [50, 50], :geometry => 'x50' }
    #   has_attachment :storage => :s3
    def has_attachment(options = {})
      # this allows you to redefine the acts' options for each subclass, however
      options[:min_size]         ||= 1
      options[:max_size]         ||= 1.megabyte
      options[:size]             ||= (options[:min_size]..options[:max_size])
      options[:thumbnails]       ||= {}
      options[:thumbnail_class]  ||= self
      options[:s3_access]        ||= :public_read
      options[:content_type] = [options[:content_type]].flatten.collect! { |t| t == :image ? AttachmentFu.content_types : t }.flatten unless options[:content_type].nil?

      unless options[:thumbnails].is_a?(Hash)
        raise ArgumentError, ":thumbnails option should be a hash: e.g. :thumbnails => { :foo => '50x50' }"
      end

      extend ClassMethods unless (class << self; included_modules; end).include?(ClassMethods)
      include InstanceMethods unless included_modules.include?(InstanceMethods)

      parent_options = attachment_options || {}
      # doing these shenanigans so that #attachment_options is available to processors and backends
      self.attachment_options = options

      attr_accessor :thumbnail_resize_options

      attachment_options[:storage]     ||= (attachment_options[:file_system_path] || attachment_options[:path_prefix]) ? :file_system : :db_file
      attachment_options[:storage]     ||= parent_options[:storage]
      attachment_options[:path_prefix] ||= attachment_options[:file_system_path]
      if attachment_options[:path_prefix].nil?
        attachment_options[:path_prefix] = attachment_options[:storage] == :s3 ? table_name : File.join("public", table_name)
      end
      attachment_options[:path_prefix]   = attachment_options[:path_prefix][1..-1] if options[:path_prefix].first == '/'

      with_options :foreign_key => 'parent_id' do |m|
        m.has_many   :thumbnails, :class_name => "::#{attachment_options[:thumbnail_class]}"
        m.belongs_to :parent, :class_name => "::#{base_class}" unless options[:thumbnails].empty?
      end

      storage_mod = AttachmentFu::Backends.const_get("#{options[:storage].to_s.classify}Backend")
      include storage_mod unless included_modules.include?(storage_mod)

      case attachment_options[:processor]
      when :none, nil
        processors = AttachmentFu.default_processors.dup
        begin
          if processors.any?
            attachment_options[:processor] = "#{processors.first}Processor"
            processor_mod = AttachmentFu::Processors.const_get(attachment_options[:processor])
            prepend processor_mod unless included_modules.include?(processor_mod)
          end
        rescue Object, Exception
          raise unless load_related_exception?($!)

          processors.shift
          retry
        end
      else
        begin
          processor_mod = AttachmentFu::Processors.const_get("#{attachment_options[:processor].to_s.classify}Processor")
          include processor_mod unless included_modules.include?(processor_mod)
        rescue Object, Exception
          raise unless load_related_exception?($!)

          puts "Problems loading #{options[:processor]}Processor: #{$!}"
        end
      end unless parent_options[:processor] # Don't let child override processor
    end

    def load_related_exception?(e) #:nodoc: implementation specific
      case
      when e.kind_of?(LoadError), e.kind_of?(MissingSourceFile), $!.class.name == "CompilationError"
        # We can't rescue CompilationError directly, as it is part of the RubyInline library.
        # We must instead rescue RuntimeError, and check the class' name.
        true
      else
        false
      end
    end
    private :load_related_exception?
  end

  module ClassMethods
    delegate :content_types, :to => AttachmentFu

    # Performs common validations for attachment models.
    def validates_as_attachment
      validates_presence_of :size, :content_type, :filename
      validate              :attachment_attributes_valid?
    end

    # Returns true or false if the given content type is recognized as an image.
    def image?(content_type)
      content_types.include?(content_type)
    end

    def self.extended(base)
      base.class_attribute :attachment_options
      base.before_destroy :destroy_thumbnails
      base.before_validation :set_size_from_temp_path
      base.after_save :after_process_attachment
      base.after_destroy :destroy_file
      base.after_validation :process_attachment
      base.define_model_callbacks :save_and_attachment_processing, only: [:after]
    end

    # Get the thumbnail class, which is the current attachment class by default.
    # Configure this with the :thumbnail_class option.
    def thumbnail_class
      attachment_options[:thumbnail_class] = attachment_options[:thumbnail_class].constantize unless attachment_options[:thumbnail_class].is_a?(Class)
      attachment_options[:thumbnail_class]
    end

    # Copies the given file path to a new tempfile, returning the closed tempfile.
    def copy_to_temp_file(file, temp_base_name)
      Tempfile.new(['',temp_base_name], AttachmentFu.tempfile_path).tap do |tmp|
        tmp.close
        FileUtils.cp file, tmp.path
      end
    end

    # Writes the given data to a new tempfile, returning the closed tempfile.
    def write_to_temp_file(data, temp_base_name)
      Tempfile.new(['',temp_base_name], AttachmentFu.tempfile_path).tap do |tmp|
        tmp.binmode
        tmp.write data
        tmp.close
      end
    end

    if Rails.env.test?
      # thanks to test_after_commit, we can use transactional fixtures,
      # but we still need reach into connection, since we conditionally
      # use after_transaction_commit based on transaction nesting
      def open_transactions
        connection.instance_variable_get(:@test_open_transactions)
      end
    else
      def open_transactions
        connection.open_transactions
      end
    end
  end

  module InstanceMethods
    require 'rack'

    # Checks whether the attachment's content type is an image content type
    def image?
      self.class.image?(content_type)
    end

    # Returns true/false if an attachment is thumbnailable.  A thumbnailable attachment has an image content type and the parent_id attribute.
    def thumbnailable?
      image? && respond_to?(:parent_id) && parent_id.nil?
    end

    # Returns the class used to create new thumbnails for this attachment.
    def thumbnail_class
      self.class.thumbnail_class
    end

    # Gets the thumbnail name for a filename.  'foo.jpg' becomes 'foo_thumbnail.jpg'
    def thumbnail_name_for(thumbnail = nil)
      return filename if thumbnail.blank?
      ext = nil
      basename = filename.gsub /\.\w+$/ do |s|
        ext = s; ''
      end
      # ImageScience doesn't create gif thumbnails, only pngs
      ext.sub!(/gif$/, 'png') if attachment_options[:processor] == "ImageScience"
      name = "#{basename}_#{thumbnail}#{ext}"
      if name.length > 255
        name = "#{basename[0..(254 - name.length)]}_#{thumbnail}#{ext}"
      end
      name
    end

    # Creates or updates the thumbnail for the current attachment.
    def create_or_update_thumbnail(temp_file, file_name_suffix, *size)
      thumbnailable? || raise(ThumbnailError.new("Can't create a thumbnail if the content type is not an image or there is no parent_id column"))
      find_or_initialize_thumbnail(file_name_suffix).tap do |thumb|
        thumb.attributes = {
          :content_type             => content_type,
          :filename                 => thumbnail_name_for(file_name_suffix),
          :temp_path                => temp_file,
          :thumbnail_resize_options => size
        }
        if thumb.valid?
          thumb.process_attachment
          thumb.save!
        end
      end
    end

    def create_thumbnail_size(target_size)
      actual_size = self.attachment_options[:thumbnails][target_size]
      raise "this class doesn't have a thubnail size for #{target_size}" if actual_size.nil?
      begin
        tmp = self.create_temp_file
        res = self.create_or_update_thumbnail(tmp, target_size.to_s, actual_size)
      rescue AWS::S3::Errors::NoSuchKey => e
        logger.warn("error when trying to make thumbnail for attachment_id: #{self.id} (the image probably doesn't exist on s3) error details: #{e.inspect}")
      rescue ThumbnailError => e
        logger.warn("error creating thumbnail for attachment_id #{self.id}: #{e.inspect}")
      ensure
        tmp.unlink if tmp
      end

      res
    end

    # Sets the content type.
    def content_type=(new_type)
      write_attribute :content_type, new_type.to_s.strip
    end

    # Sanitizes a filename.
    def filename=(new_name)
      write_attribute :filename, sanitize_filename(new_name)
    end

    # Returns the width/height in a suitable format for the image_tag helper: (100x100)
    def image_size
      [width.to_s, height.to_s] * 'x'
    end

    # Returns true if the attachment data will be written to the storage system on the next save
    def save_attachment?
      if self.is_a?(Attachment)
        if self.root_attachment_id && self.new_record?
          return false
        end
        self.filename && File.file?(temp_path.to_s)
      else
        File.file?(temp_path.to_s)
      end
    end

    # nil placeholder in case this field is used in a form.
    def uploaded_data() nil; end

    # This method handles the uploaded file object.  If you set the field name to uploaded_data, you don't need
    # any special code in your controller.
    #
    #   <% form_for :attachment, :html => { :multipart => true } do |f| -%>
    #     <p><%= f.file_field :uploaded_data %></p>
    #     <p><%= submit_tag :Save %>
    #   <% end -%>
    #
    #   @attachment = Attachment.create! params[:attachment]
    #
    # TODO: Allow it to work with Merb tempfiles too.
    def uploaded_data=(file_data)
      if self.is_a?(Attachment)
        return nil if file_data.nil? || (file_data.respond_to?(:size) && file_data.size == 0)
        # glean information from the file handle
        self.content_type = detect_mimetype(file_data)
        self.filename     = file_data.original_filename if respond_to?(:filename) && file_data.respond_to?(:original_filename)
        file_from_path = true
        unless file_data.respond_to?(:path) && file_data.path.present?
          file_data.rewind
          self.temp_data = file_data.read
          file_from_path = false
        else
          self.temp_paths.unshift file_data
        end
        # If we're overwriting an existing file, we need to take serious
        # precautions, since other Attachment records could be using this file.
        # We first remove any root references for this file, and then we generate
        # a new unique filename for this file so anybody children of this attachment
        # will still be able to get at the original.
        if !self.new_record?
          self.root_attachment = nil
          self.root_attachment_id = nil
          self.workflow_state = nil
          self.filename = filename.sub(/\A\d+_\d+__/, "")
          self.filename = "#{Time.now.to_i}_#{rand(999)}__#{self.filename}" if self.filename
        end
        read_bytes = false
        digest = Digest::MD5.new
        begin
          io = file_data
          if file_from_path
            io = File.open(self.temp_path, 'rb')
          end
          io.rewind
          io.each_line do |line|
            digest.update(line)
            read_bytes = true
          end
        rescue => e
        ensure
          io.close if file_from_path
        end
        self.md5 = read_bytes ? digest.hexdigest : nil
        if existing_attachment = find_existing_attachment_for_md5
          self.temp_path = nil if respond_to?(:temp_path=)
          self.temp_data = nil if respond_to?(:temp_data=)
          write_attribute(:filename, nil) if respond_to?(:filename=)
          self.root_attachment = existing_attachment
        end
        file_data
      else
        return nil if file_data.nil? || file_data.size == 0
        self.content_type = file_data.content_type
        self.filename     = file_data.original_filename if respond_to?(:filename)
        unless file_data.respond_to?(:path)
          file_data.rewind
          self.temp_data = file_data.read
        else
          self.temp_path = file_data
        end
      end
    end

    def find_existing_attachment_for_md5
      self.shard.activate do
        Shackles.activate(:slave) do
          if self.md5.present? && (ns = self.infer_namespace)
            scope = Attachment.where(md5: md5, namespace: ns, root_attachment_id: nil, content_type: content_type)
            scope = scope.where("filename IS NOT NULL")
            scope = scope.where("id<>?", self) unless new_record?
            scope.detect { |a| a.store.exists? }
          end
        end
      end
    end

    def detect_mimetype(file_data)
      if file_data && file_data.respond_to?(:content_type) && (file_data.content_type.blank? || file_data.content_type.strip == "application/octet-stream")
        res = nil
        res ||= File.mime_type?(file_data.original_filename) if file_data.respond_to?(:original_filename)
        res ||= File.mime_type?(file_data)
        res ||= "text/plain" if !file_data.respond_to?(:path)
        res || 'unknown/unknown'
      elsif file_data.respond_to?(:content_type)
        return file_data.content_type
      else
        'unknown/unknown'
      end
    end

    # Gets the latest temp path from the collection of temp paths.  While working with an attachment,
    # multiple Tempfile objects may be created for various processing purposes (resizing, for example).
    # An array of all the tempfile objects is stored so that the Tempfile instance is held on to until
    # it's not needed anymore.  The collection is cleared after saving the attachment.
    def temp_path
      p = temp_paths.first
      p.respond_to?(:path) ? p.path : p.to_s
    end

    # Gets an array of the currently used temp paths.  Defaults to a copy of #full_filename.
    def temp_paths
      # INSTRUCTURE: was "@temp_paths ||= (new_record? || !respond_to?(:full_filename) || !File.exist?(full_filename) ?"
      @temp_paths ||= (new_record? || !respond_to?(:full_filename) || !full_filename || !File.exist?(full_filename) ?
        [] : [copy_to_temp_file(full_filename)])
    end

    # Adds a new temp_path to the array.  This should take a string or a Tempfile.  This class makes no
    # attempt to remove the files, so Tempfiles should be used.  Tempfiles remove themselves when they go out of scope.
    # You can also use string paths for temporary files, such as those used for uploaded files in a web server.
    def temp_path=(value)
      temp_paths.unshift value
      temp_path
    end

    # Gets the data from the latest temp file.  This will read the file into memory.
    def temp_data
      save_attachment? ? File.read(temp_path) : nil
    end

    # Writes the given data to a Tempfile and adds it to the collection of temp files.
    def temp_data=(data)
      self.temp_path = write_to_temp_file data unless data.nil?
    end

    # Copies the given file to a randomly named Tempfile.
    def copy_to_temp_file(file)
      self.class.copy_to_temp_file file, random_tempfile_filename
    end

    # Writes the given file to a randomly named Tempfile.
    def write_to_temp_file(data)
      self.class.write_to_temp_file data, random_tempfile_filename
    end

    # Stub for creating a temp file from the attachment data.  This should be defined in the backend module.
    def create_temp_file() end

    # Allows you to work with a processed representation (RMagick, ImageScience, etc) of the attachment in a block.
    #
    #   @attachment.with_image do |img|
    #     self.data = img.thumbnail(100, 100).to_blob
    #   end
    #
    def with_image(&block)
      self.class.with_image(temp_path, &block)
    end

    protected
      # Generates a unique filename for a Tempfile.
      def random_tempfile_filename
        "#{rand Time.now.to_i}#{filename && filename.last(50) || 'attachment'}"
      end

      def sanitize_filename(filename)
        filename.strip.tap do |name|
          # NOTE: File.basename doesn't work right with Windows paths on Unix
          # get only the filename, not the whole path
          name.gsub! /^.*(\\|\/)/, ''

          # Finally, replace all non alphanumeric, underscore or periods with underscore
          name.gsub! /[^\w\.\-]/, '_'
        end
      end

      # before_validation callback.
      def set_size_from_temp_path
        self.size = File.size(temp_path) if save_attachment?
      end

      # validates the size and content_type attributes according to the current model's options
      def attachment_attributes_valid?
        [:size, :content_type].each do |attr_name|
          enum = attachment_options[attr_name]
          errors.add attr_name, ActiveRecord::Errors.default_error_messages[:inclusion] unless enum.nil? || enum.include?(send(attr_name))
        end
      end

      # Initializes a new thumbnail with the given suffix.
      def find_or_initialize_thumbnail(file_name_suffix)
        scope = thumbnail_class.where(thumbnail: file_name_suffix.to_s)
        scope = scope.where(parent_id: id) if respond_to?(:parent_id)
        scope.first_or_initialize
      end

      # Stub for a #process_attachment method in a processor
      def process_attachment
        @saved_attachment = save_attachment?
        run_before_attachment_saved if @saved_attachment && self.respond_to?(:run_before_attachment_saved)
        @saved_attachment
      end

      # Cleans up after processing.  Thumbnails are created, the attachment is stored to the backend, and the temp_paths are cleared.
      def after_process_attachment
        if @saved_attachment
          # # INSTRUCTURE I (ryan shaw) commented these next lines out so that the thumbnailing does not happen syncronisly as part of the request.
          # # we are going to do the same thing as delayed_jobs
          # if respond_to?(:process_attachment) && thumbnailable? && !attachment_options[:thumbnails].blank? && parent_id.nil?
          #   temp_file = temp_path || create_temp_file
          #   attachment_options[:thumbnails].each { |suffix, size| create_or_update_thumbnail(temp_file, suffix, *size) }
          # end

          # In normal attachment upload usage, the only transaction we should
          # be inside is the AR#save transaction. If that's the case, defer
          # the upload and callbacks until after the transaction commits. If
          # the upload fails, that will leave this attachment in an
          # unattached state, but that's already the case in other error
          # situations as well.
          #
          # If there is no transaction, or more than one transaction, then
          # just upload immediately. This can happen if
          # after_process_attachment is called directly, or if we're inside
          # an rspec test run (which is wrapped in an outer transaction).
          # It can also happen if somebody explicitly uploads file data
          # inside a .transaction block, which we normally shouldn't do.
          save_and_callbacks = proc do
            save_to_storage
            @temp_paths.clear
            @saved_attachment = nil
            run_after_attachment_saved if self.respond_to?(:run_after_attachment_saved)
            run_callbacks(:save_and_attachment_processing)
          end

          if self.class.open_transactions == 1 # yes, == 1, not > 0 ... see comment above
            self.class.connection.after_transaction_commit(&save_and_callbacks)
          else
            save_and_callbacks.call()
          end
        else
          run_callbacks(:save_and_attachment_processing)
        end
      end

      # Resizes the given processed img object with either the attachment resize options or the thumbnail resize options.
      def resize_image_or_thumbnail!(img)
        if (!respond_to?(:parent_id) || parent_id.nil?) && attachment_options[:resize_to] # parent image
          resize_image(img, attachment_options[:resize_to])
        elsif thumbnail_resize_options # thumbnail
          resize_image(img, thumbnail_resize_options)
        end
      end

      # Removes the thumbnails for the attachment, if it has any
      def destroy_thumbnails
        self.thumbnails.each { |thumbnail| thumbnail.destroy } if thumbnailable?
      end
  end
end

# backwards-compatible shim
module Technoweenie
  AttachmentFu = ::AttachmentFu
end
