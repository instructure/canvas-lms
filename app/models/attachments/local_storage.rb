#
# Copyright (C) 2014 - present Instructure, Inc.
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

class Attachments::LocalStorage

  attr_reader :attachment

  def self.key
    :file_system
  end

  def initialize(attachment)
    @attachment = attachment
  end

  def exists?
    File.exists?(attachment.full_filename)
  end

  def change_namespace(old_full_filename)
    return if old_full_filename == attachment.full_filename
    FileUtils.mv old_full_filename, attachment.full_filename
  end

  def initialize_ajax_upload_params(local_upload_url, s3_success_url, options)
    {
      :upload_url => local_upload_url,
      :file_param => options[:file_param] || 'attachment[uploaded_data]', # uploadify ignores this and uses 'file'
      :upload_params => options[:upload_params] || {}
    }
  end

  def amend_policy_conditions(policy, pseudonym:, datetime: nil)
    # flash won't send the session cookie, so for local uploads we put the user id in the signed
    # policy so we can mock up the session for FilesController#create
    policy['conditions'] << { 'pseudonym_id' => pseudonym.id }
    policy['attachment_id'] = attachment.id
    policy
  end

  def shared_secret(datetime)
    Attachment.shared_secret
  end

  def sign_policy(policy_encoded, datetime)
    signature = Base64.encode64(
      OpenSSL::HMAC.digest(
        OpenSSL::Digest.new('sha1'), shared_secret(datetime), policy_encoded
      )
    ).gsub(/\n/, '')
    ['Signature', signature]
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
