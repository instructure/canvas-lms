# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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
#
class TermsOfServiceContent < ActiveRecord::Base
  include Canvas::SoftDeletable
  sanitize_field :content, CanvasSanitize::SANITIZE
  validates :terms_updated_at, presence: true

  belongs_to :account
  has_many :attachment_associations, as: :context, inverse_of: :context

  before_validation :ensure_terms_updated_at
  before_save :set_terms_updated_at
  after_save :clear_cache

  delegate :root_account, to: :account
  delegate :root_account_id, to: :account

  include LinkedAttachmentHandler

  def self.html_fields
    %w[content]
  end

  def attachment_associations_enabled?
    if account
      root_account.feature_enabled?(:file_association_access)
    else
      %w[allowed_on on].include?(Feature.definitions["file_association_access"].state)
    end
  end

  def access_for_attachment_association?(_user, _session, _association, _location_param)
    true
  end

  def content
    original = super
    return original unless account && root_account.feature_enabled?(:file_association_access)

    file_url_pattern = %r{(?<![a-zA-Z0-9:])(/(?:[\w-]+/\d+/)?(?:files/\d+(?:/[\w-]+)?|media_attachments_iframe/\d+)(?:\?[^"'<>]*)?)}

    original.gsub(file_url_pattern) do |_|
      url = Regexp.last_match(1)
      if url.include?("?")
        "#{url}&location=#{asset_string}"
      else
        "#{url}?location=#{asset_string}"
      end
    end
  end

  def ensure_terms_updated_at
    self.terms_updated_at ||= Time.now.utc
  end

  def set_terms_updated_at
    self.terms_updated_at = Time.now.utc if content_changed?
  end

  def self.ensure_content_for_account(account, saving_user)
    unique_constraint_retry do |retry_count|
      account.reload_terms_of_service_content if retry_count > 0
      account.terms_of_service_content || account.create_terms_of_service_content!(content: "", saving_user:)
    end
  end

  def clear_cache
    Shard.default.activate do
      key = ["terms_of_service_content", id].cache_key
      MultiCache.delete(key)
    end
  end
end
