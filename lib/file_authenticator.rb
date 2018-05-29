#
# Copyright (C) 2018 - present Instructure, Inc.
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

class FileAuthenticator
  attr_reader :user, :acting_as, :access_token, :root_account, :oauth_host

  def initialize(user:, acting_as:, access_token:, root_account:, oauth_host:)
    @user = user # logged in user
    @acting_as = acting_as # user being acted as
    @access_token = access_token # access token used to authenticate the logged in user, if any
    @root_account = root_account # domain root account where the request occurred
    @oauth_host = oauth_host # host against which inst-fs should oauth the user
  end

  def fingerprint
    # note: this does _not_ incorporate the users' updated_at values like
    # putting the user object in the cache key would, because this fingerprint
    # is not intended to differentiate caches of information _about_ the user.
    # just to differentiate caches _across_ user identities.
    Digest::MD5.hexdigest("#{@user&.global_id}|#{@acting_as&.global_id}|#{@oauth_host}")
  end

  def instfs_options(attachment, extras={})
    {
      user: @user,
      acting_as: @acting_as,
      access_token: @access_token,
      root_account: @root_account,
      oauth_host: @oauth_host,
      expires_in: attachment.url_ttl,
    }.merge(extras)
  end

  def download_url(attachment)
    return nil unless attachment
    if attachment.instfs_hosted?
      options = instfs_options(attachment, download: true)
      InstFS.authenticated_url(attachment, options)
    else
      # s3 doesn't distinguish authenticated and public urls
      attachment.public_download_url
    end
  end

  def inline_url(attachment)
    return nil unless attachment
    if attachment.instfs_hosted?
      options = instfs_options(attachment, download: false)
      InstFS.authenticated_url(attachment, options)
    else
      # s3 doesn't distinguish authenticated and public urls
      attachment.public_inline_url
    end
  end

  def thumbnail_url(attachment, options={})
    return nil unless attachment
    if !Attachment.skip_thumbnails && attachment.instfs_hosted? && attachment.thumbnailable?
      options = instfs_options(attachment, geometry: options[:size])
      InstFS.authenticated_thumbnail_url(attachment, options)
    else
      attachment.thumbnail_url(options)
    end
  end
end
