# frozen_string_literal: true

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

  delegate :bucket, to: :attachment

  def exists?
    attachment.s3object.exists?
  end

  def change_namespace(old_full_filename)
    # copying rather than moving to avoid unhappy accidents
    # note that GC of the S3 bucket isn't yet implemented,
    # so there's a bit of a cost here
    return if attachment.instfs_hosted?

    unless exists?
      unless attachment.size
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

  def initialize_ajax_upload_params(_local_upload_url, s3_success_url, options)
    {
      upload_url: bucket.url,
      file_param: "file",
      success_url: s3_success_url,
      upload_params: cred_params(options[:datetime])
    }
  end

  def amend_policy_conditions(policy, datetime:)
    policy["conditions"].unshift({ "bucket" => bucket.name })
    cred_params(datetime).each do |k, v|
      policy["conditions"] << { k => v }
    end
    policy
  end

  def cred_params(datetime)
    access_key = bucket.client.config.credentials.credentials.access_key_id
    session_token = bucket.client.config.credentials.credentials.session_token
    day_string = datetime[0, 8]
    region = bucket.client.config.region
    credential = "#{access_key}/#{day_string}/#{region}/s3/aws4_request"
    params = {
      "x-amz-credential" => credential,
      "x-amz-algorithm" => "AWS4-HMAC-SHA256",
      "x-amz-date" => datetime,
    }
    params["x-amz-security-token"] = session_token if session_token
    params
  end

  def shared_secret(datetime)
    config = bucket.client.config
    sha256 = OpenSSL::Digest.new("SHA256")
    date_key = OpenSSL::HMAC.digest(sha256, "AWS4#{config.credentials.credentials.secret_access_key}", datetime[0, 8])
    date_region_key = OpenSSL::HMAC.digest(sha256, date_key, config.region)
    date_region_service_key = OpenSSL::HMAC.digest(sha256, date_region_key, "s3")
    OpenSSL::HMAC.digest(sha256, date_region_service_key, "aws4_request")
  end

  def sign_policy(policy_encoded, datetime)
    signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"), shared_secret(datetime), policy_encoded
    )
    ["x-amz-signature", signature]
  end

  def open(temp_folder: nil, integrity_check: false)
    tempfile = attachment.create_tempfile(temp_folder:) do |file|
      attachment.s3object.get(response_target: file)
    end
    attachment.validate_hash { |hash_context| hash_context&.file(tempfile.path) } if integrity_check

    if block_given?
      File.open(tempfile.path, "rb") do |file|
        chunk = file.read(64_000)
        while chunk
          yield chunk
          chunk = file.read(64_000)
        end
      end
    end

    tempfile
  end
end
