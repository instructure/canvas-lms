class Attachments::LocalStorage

  attr_reader :attachment

  def self.key
    :file_system
  end

  def initialize(attachment)
    @attachment = attachment
  end

  def exists?
    true
  end

  def change_namespace(old_full_filename)
    return if old_full_filename == attachment.full_filename
    FileUtils.mv old_full_filename, attachment.full_filename
  end

  def initialize_ajax_upload_params(local_upload_url, s3_success_url, options)
    {
        :upload_url => local_upload_url,
        :file_param => options[:file_param] || 'attachment[uploaded_data]', #uploadify ignores this and uses 'file',
        :upload_params => options[:upload_params] || {}
    }
  end

  def amend_policy_conditions(policy, pseudonym)
    # flash won't send the session cookie, so for local uploads we put the user id in the signed
    # policy so we can mock up the session for FilesController#create
    policy['conditions'] << { 'pseudonym_id' => pseudonym.id }
    policy['attachment_id'] = attachment.id
    policy
  end

  def shared_secret
    Attachment.shared_secret
  end

  def open(opts)
    if block_given?
      File.open(attachment.full_filename, 'rb') do |file|
        chunk = file.read(4096)
        while chunk
          yield chunk
          chunk = file.read(4096)
        end
      end
    else
      File.open(attachment.full_filename, 'rb')
    end
  end
end
