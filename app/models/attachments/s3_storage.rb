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
        :upload_params => cred_params(options[:datetime])
    }
  end

  def amend_policy_conditions(policy, datetime:, pseudonym: nil)
    policy['conditions'].unshift({'bucket' => bucket.name})
    cred_params(datetime).each do |k, v|
      policy['conditions'] << { k => v }
    end
    policy
  end

  def cred_params(datetime)
    access_key = bucket.client.config.access_key_id
    day_string = datetime[0,8]
    region = bucket.client.config.region
    credential = "#{access_key}/#{day_string}/#{region}/s3/aws4_request"
    {
      'x-amz-credential' => credential,
      'x-amz-algorithm' => "AWS4-HMAC-SHA256",
      'x-amz-date' => datetime
    }
  end

  def shared_secret(datetime)
    config = bucket.client.config
    sha256 = OpenSSL::Digest::SHA256.new
    date_key = OpenSSL::HMAC.digest(sha256, "AWS4#{config.secret_access_key}", datetime[0,8])
    date_region_key = OpenSSL::HMAC.digest(sha256, date_key, config.region)
    date_region_service_key = OpenSSL::HMAC.digest(sha256, date_region_key, "s3")
    OpenSSL::HMAC.digest(sha256, date_region_service_key, "aws4_request")
  end

  def sign_policy(policy_encoded, datetime)
    signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'), shared_secret(datetime), policy_encoded
    )
    ['x-amz-signature', signature]
  end

  def open(opts, &block)
    # TODO: !need_local_file -- net/http and thus AWS::S3::S3Object don't
    # natively support streaming the response, except when a block is given.
    # so without Fibers, there's not a great way to return an IO-like object
    # that streams the response. A separate thread, I guess. Bleck. Need to
    # investigate other options.
    if opts[:temp_folder].present? && !File.exist?(opts[:temp_folder])
      FileUtils.mkdir_p(opts[:temp_folder])
    end
    tempfile = attachment.create_tempfile(opts) do |file|
      attachment.s3object.get(response_target: file)
    end

    if block_given?
      File.open(tempfile.path, 'rb') do |file|
        chunk = file.read(64000)
        while chunk
          yield chunk
          chunk = file.read(64000)
        end
      end
    end

    tempfile
  end
end
