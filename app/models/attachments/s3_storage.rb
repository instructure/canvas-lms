class Attachments::S3Storage
  attr_reader :attachment

  def self.key
    :s3
  end

  def initialize(attachment)
    @attachment = attachment
  end

  def bucket
    attachment.bucket
  end

  def exists?
    attachment.s3object.exists?
  end

  def change_namespace(old_full_filename)
    # copying rather than moving to avoid unhappy accidents
    # note that GC of the S3 bucket isn't yet implemented,
    # so there's a bit of a cost here
    if !exists?
      if !attachment.size
        attachment.size = bucket.object(old_full_filename).content_length
      end
      options = { acl: attachment.attachment_options[:s3_access] }
      if attachment.size >= 5.gigabytes
        options[:multipart_copy] = true
        options[:content_length] = attachment.size
      end
      bucket.object(old_full_filename).copy_to(bucket.object(attachment.full_filename), options)
    end
  end

  def initialize_ajax_upload_params(local_upload_url, s3_success_url, options)
    {
        :upload_url => bucket.url,
        :file_param => 'file',
        :success_url => s3_success_url,
        :upload_params => {
            'AWSAccessKeyId' => bucket.client.config.access_key_id
        }
    }
  end

  def amend_policy_conditions(policy, _)
    policy['conditions'].unshift({'bucket' => bucket.name})
    policy
  end

  def shared_secret
    bucket.client.config.secret_access_key
  end

  def open(opts, &block)
    if block_given?
      attachment.s3object.get(&block)
    else
      # TODO: !need_local_file -- net/http and thus AWS::S3::S3Object don't
      # natively support streaming the response, except when a block is given.
      # so without Fibers, there's not a great way to return an IO-like object
      # that streams the response. A separate thread, I guess. Bleck. Need to
      # investigate other options.
      if opts[:temp_folder].present? && !File.exist?(opts[:temp_folder])
        FileUtils.mkdir_p(opts[:temp_folder])
      end
      tempfile = Tempfile.new(["attachment_#{attachment.id}", attachment.extension],
                              opts[:temp_folder].presence || Dir::tmpdir)
      tempfile.binmode
      attachment.s3object.get(response_target: tempfile)
      tempfile.rewind
      tempfile
    end
  end

end
