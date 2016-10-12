module AttachmentFu # :nodoc:
  module Backends
    # = AWS SDK Storage Backend
    #
    # Enables use of {Amazon's Simple Storage Service}[http://aws.amazon.com/s3] as a storage mechanism
    #
    # == Requirements
    #
    # Requires the {AWS SDK Library}[https://github.com/aws/aws-sdk-ruby] installed either
    # as a gem or a as a Rails plugin.
    #
    # == Configuration
    #
    # Configuration is done via <tt>RAILS_ROOT/config/amazon_s3.yml</tt> and is loaded according to the <tt>RAILS_ENV</tt>.
    # The minimum connection options that you must specify are a bucket name, your access key id and your secret access key.
    # If you don't already have your access keys, all you need to sign up for the S3 service is an account at Amazon.
    # You can sign up for S3 and get access keys by visiting http://aws.amazon.com/s3.
    #
    # Example configuration (RAILS_ROOT/config/amazon_s3.yml)
    # 
    #   development:
    #     bucket_name: appname_development
    #     access_key_id: <your key>
    #     secret_access_key: <your key>
    #   
    #   test:
    #     bucket_name: appname_test
    #     access_key_id: <your key>
    #     secret_access_key: <your key>
    #   
    #   production:
    #     bucket_name: appname
    #     access_key_id: <your key>
    #     secret_access_key: <your key>
    #
    # You can change the location of the config path by passing a full path to the :s3_config_path option.
    #
    #   has_attachment :storage => :s3, :s3_config_path => (RAILS_ROOT + '/config/s3.yml')
    #
    # === Required configuration parameters
    #
    # * <tt>:access_key_id</tt> - The access key id for your S3 account. Provided by Amazon.
    # * <tt>:secret_access_key</tt> - The secret access key for your S3 account. Provided by Amazon.
    # * <tt>:bucket_name</tt> - A unique bucket name (think of the bucket_name as being like a database name).
    #
    # If any of these required arguments is missing, a MissingAccessKey exception will be raised from AWS::S3.
    #
    # == About bucket names
    #
    # Bucket names have to be globally unique across the S3 system. And you can only have up to 100 of them,
    # so it's a good idea to think of a bucket as being like a database, hence the correspondance in this
    # implementation to the development, test, and production environments.
    #
    # The number of objects you can store in a bucket is, for all intents and purposes, unlimited.
    #
    # === Optional configuration parameters
    #
    # * <tt>:server</tt> - The server to make requests to. Defaults to <tt>s3.amazonaws.com</tt>.
    # * <tt>:port</tt> - The port to the requests should be made on. Defaults to 80 or 443 if <tt>:use_ssl</tt> is set.
    # * <tt>:use_ssl</tt> - If set to true, <tt>:port</tt> will be implicitly set to 443, unless specified otherwise. Defaults to false.
    #
    # == Usage
    #
    # To specify S3 as the storage mechanism for a model, set the acts_as_attachment <tt>:storage</tt> option to <tt>:s3</tt>.
    #
    #   class Photo < ActiveRecord::Base
    #     has_attachment :storage => :s3
    #   end
    #
    # === Customizing the path
    #
    # By default, files are prefixed using a pseudo hierarchy in the form of <tt>:table_name/:id</tt>, which results
    # in S3 urls that look like: http(s)://:server/:bucket_name/:table_name/:id/:filename with :table_name
    # representing the customizable portion of the path. You can customize this prefix using the <tt>:path_prefix</tt>
    # option:
    #
    #   class Photo < ActiveRecord::Base
    #     has_attachment :storage => :s3, :path_prefix => 'my/custom/path'
    #   end
    #
    # Which would result in URLs like <tt>http(s)://:server/:bucket_name/my/custom/path/:id/:filename.</tt>
    #
    # === Permissions
    #
    # By default, files are stored on S3 with public access permissions. You can customize this using
    # the <tt>:s3_access</tt> option to <tt>has_attachment</tt>. Available values are 
    # <tt>:private</tt>, <tt>:public_read_write</tt>, and <tt>:authenticated_read</tt>.
    #
    # === Other options
    #
    # Of course, all the usual configuration options apply, such as content_type and thumbnails:
    #
    #   class Photo < ActiveRecord::Base
    #     has_attachment :storage => :s3, :content_type => ['application/pdf', :image], :resize_to => 'x50'
    #     has_attachment :storage => :s3, :thumbnails => { :thumb => [50, 50], :geometry => 'x50' }
    #   end
    #
    # === Accessing S3 URLs
    #
    # You can get an object's URL using the s3_url accessor. For example, assuming that for your postcard app
    # you had a bucket name like 'postcard_world_development', and an attachment model called Photo:
    #
    #   @postcard.s3_url # => http(s)://s3.amazonaws.com/postcard_world_development/photos/1/mexico.jpg
    #
    # The resulting url is in the form: http(s)://:server/:bucket_name/:table_name/:id/:file.
    # The optional thumbnail argument will output the thumbnail's filename (if any).
    #
    # Additionally, you can get an object's base path relative to the bucket root using
    # <tt>base_path</tt>:
    #
    #   @photo.file_base_path # => photos/1
    #
    # And the full path (including the filename) using <tt>full_filename</tt>:
    #
    #   @photo.full_filename # => photos/
    #
    # Niether <tt>base_path</tt> or <tt>full_filename</tt> include the bucket name as part of the path.
    # You can retrieve the bucket name using the <tt>bucket_name</tt> method.
    module S3Backend
      class RequiredLibraryNotFoundError < StandardError; end
      class ConfigFileNotFoundError < StandardError; end

      mattr_reader :bucket

      def self.included(base) #:nodoc:
        begin
          require 'aws-sdk-v1'
        rescue LoadError
          raise RequiredLibraryNotFoundError.new('AWS SDK could not be loaded')
        end

        begin
          s3_config_path = base.attachment_options[:s3_config_path] || (Rails.root + 'config/amazon_s3.yml')
          s3_config = YAML.load(ERB.new(File.read(s3_config_path)).result)[Rails.env].symbolize_keys
        #rescue
        #  raise ConfigFileNotFoundError.new('File %s not found' % @@s3_config_path)
        end

        # backcompat for AWS::S3 gem options
        s3_config[:proxy_uri] = s3_config.delete(:proxy) if s3_config.key?(:proxy)
        s3_config[:s3_endpoint] = s3_config.delete(:server) if s3_config.key?(:server)

        s3 = AWS::S3.new(s3_config)

        @@bucket = s3.buckets[s3_config[:bucket_name]]

        # s3.create_bucket(s3_config[:bucket_name])

        base.before_update :rename_file
      end

      # Overwrites the base filename writer in order to store the old filename
      def filename=(value)
        @old_filename = filename unless filename.nil? || @old_filename
        write_attribute :filename, sanitize_filename(value)
      end

      def sanitize_filename(filename)
        if self.respond_to?(:root_attachment) && self.root_attachment && self.root_attachment.filename
          filename = self.root_attachment.filename
        else
          filename = Attachment.truncate_filename(filename, 255) do |component, len|
            CanvasTextHelper.cgi_escape_truncate(component, len)
          end
        end
        filename
      end


      # The attachment ID used in the full path of a file
      def attachment_path_id
        ((respond_to?(:parent_id) && parent_id) || id).to_s
      end
      
      # INSTRUCTURE: fallback to old path style if there is no cluster attribute
      def namespaced_path
        obj = (respond_to?(:root_attachment) && self.root_attachment) || self
        if namespace = obj.read_attribute(:namespace)
          File.join(namespace, obj.attachment_options[:path_prefix])
        else
          obj.attachment_options[:path_prefix]
        end
      end

      # The pseudo hierarchy containing the file relative to the bucket name
      # Example: <tt>:table_name/:id</tt>
      def base_path
        File.join(namespaced_path, attachment_path_id)
      end

      # The full path to the file relative to the bucket name
      # Example: <tt>:table_name/:id/:filename</tt>
      def full_filename(thumbnail = nil)
        # the old AWS::S3 gem would not encode +'s, causing S3 to interpret
        # them as spaces. Continue that behavior.
        basename = thumbnail_name_for(thumbnail).gsub('+', ' ')
        File.join(base_path, basename)
      end

      def s3object(thumbnail = nil)
        bucket.objects[full_filename(thumbnail)]
      end

      # All public objects are accessible via a GET request to the S3 servers. You can generate a
      # url for an object using the s3_url method.
      #
      #   @photo.s3_url
      #
      # The resulting url is in the form: <tt>http(s)://:server/:bucket_name/:table_name/:id/:file</tt> where
      # the <tt>:server</tt> variable defaults to <tt>AWS::S3 URL::DEFAULT_HOST</tt> (s3.amazonaws.com) and can be
      # set using the configuration parameters in <tt>RAILS_ROOT/config/amazon_s3.yml</tt>.
      #
      # The optional thumbnail argument will output the thumbnail's filename (if any).
      def s3_url(thumbnail = nil)
        s3object(thumbnail).public_url
      end
      alias :public_filename :s3_url

      # All private objects are accessible via an authenticated GET request to the S3 servers. You can generate an 
      # authenticated url for an object like this:
      #
      #   @photo.authenticated_s3_url
      #
      # By default authenticated urls expire 1 hour after they were generated.
      #
      # Expiration options can be specified either with an absolute time using the <tt>:expires</tt> option,
      # or with a number of seconds relative to now with the <tt>:expires</tt> option:
      #
      #   # Absolute expiration date (October 13th, 2025)
      #   @photo.authenticated_s3_url(:expires => Time.mktime(2025,10,13).to_i)
      #   
      #   # Expiration in five hours from now
      #   @photo.authenticated_s3_url(:expires => 5.hours)
      #
      # You can specify whether the url should go over SSL with the <tt>:secure</tt> option.
      # By default, the ssl settings for the current connection will be used:
      #
      #   @photo.authenticated_s3_url(:secure => true)
      #
      # Finally, the optional thumbnail argument will output the thumbnail's filename (if any):
      #
      #   @photo.authenticated_s3_url('thumbnail', :expires_in => 5.hours, :use_ssl => true)
      def authenticated_s3_url(*args)
        thumbnail = args.first.is_a?(String) ? args.first : nil
        options   = args.last.is_a?(Hash)    ? args.last  : {}
        s3object(thumbnail).url_for(:read, options).to_s
      end

      def create_temp_file
        write_to_temp_file current_data
      end

      def current_data
        s3object.read
      end

      protected
        # Called in the after_destroy callback
        def destroy_file
          # INSTRUCTURE: We don't want to actually delete objects from s3 (at
          # least not due to the Attachment being destroyed). With our root
          # attachment deduplication scheme it just gets too messy and buggy.
          # We'll just GC them later.
          true
        end

        def rename_file
          # INSTRUCTURE: We don't actually want to rename Attachments.
          # The problem is that we're re-using our s3 storage if you copy
          # a file or if two files have the same md5 and size.  In that case
          # there are multiple attachments pointing to the same place on s3
          # and we don't want to get rid of the original... 
          # TODO: we'll just have to figure out a different way to clean out
          # the cruft that happens because of this
          return
          return unless @old_filename && @old_filename != filename
          
          old_full_filename = File.join(base_path, @old_filename)

          # INSTRUCTURE: this dies when the file did not already exist,
          # but we need it to not throw an angry exception in production.
          # I've added some additional provisions in Attachment.rb, but
          # it looks like they're not always working for some reason
          begin
            bucket.objects[old_full_filename].rename_to(full_filename, :acl => attachment_options[:s3_access])
          rescue => e
            filename = @old_filename
          end

          @old_filename = nil
          true
        end

        def save_to_storage
          if save_attachment?
            s3object.write((temp_path ? File.open(temp_path, 'rb') : temp_data),
                           :content_type => content_type,
                           :acl => attachment_options[:s3_access])
          end

          @old_filename = nil
          true
        end
    end
  end
end
