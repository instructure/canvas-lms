require 'parallel'

module Canvas
  module CDN
    class S3Uploader

      attr_accessor :bucket, :config

      def initialize(folder='dist')
        require 'aws-sdk'
        @folder = folder
        @config = Canvas::CDN.config
        @s3 = AWS::S3.new(access_key_id: config.aws_access_key_id,
                          secret_access_key: config.aws_secret_access_key)
        @bucket = @s3.buckets[config.bucket]
      end

      def local_files
        Dir.chdir(Rails.public_path) { Dir["#{@folder}/**/**"]}
      end

      def upload!
        total_files = local_files.count
        uploaded_files = 0
        Parallel.each(local_files, :in_threads=>8) do |file|
          upload_file(file)
          uploaded_files += 1
          yield (100.0 * uploaded_files / total_files) if block_given?
        end
      end

      def fingerprint?(path)
        /-[0-9a-fA-F]{32}$/.match(path.basename(path.extname).to_s)
      end

      def font?(path)
        %w{.ttf .ttc .otf .eot .woff .woff2}.include?(path.extname)
      end

      def mime_for(path)
        Mime::Type.lookup_by_extension(path.extname[1..-1])
      end

      def options_for(path)
        options = {acl: :public_read, content_type: mime_for(path)}
        if fingerprint?(path)
          options.merge!({
            cache_control: "public, max-age=#{1.year}",
            expires: 1.year.from_now.httpdate
          })
        end

        # Set headers so font's work cross-orign. While you can also set a
        # CORSConfig when you set up your s3 bucket to do the same thing, this
        # will make sure it is always set for fonts.
        options['Access-Control-Allow-Origin'] = '*' if font?(path)
        options
      end

      def upload_file(remote_path)
        local_path = Pathname.new("#{Rails.public_path}/#{remote_path}")
        return if (local_path.extname == '.gz') || local_path.directory?
        s3_object = bucket.objects[remote_path]
        return log("skipping already existing #{remote_path}") if s3_object.exists?
        options = options_for(local_path)
        gzipped = Pathname.new("#{local_path}.gz")
        if gzipped.exist?
          local_path = gzipped
          options[:content_encoding] = 'gzip'
        end
        log "uploading #{remote_path} #{options[:content_encoding]}"
        s3_object.write(local_path, options)
      end

      def log(msg)
        Rails.logger.debug "#{self.class} - #{msg}"
      end
    end
  end
end