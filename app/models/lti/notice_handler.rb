# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Lti::NoticeHandler < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  belongs_to :account, inverse_of: :lti_notice_handlers, optional: false
  belongs_to :context_external_tool, optional: false

  # We don't actually currently need to enforce a minimum max_batch_size, but
  # we are insisting on a 'reasonable minimum batch size' (from the spec) in
  # case we want to batch in the future. In the future we might want
  # notice-type specific values, or we can simply set this to 1 if we don't
  # need the restriction.
  MIN_MAX_BATCH_SIZE = 10

  validates :max_batch_size,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MIN_MAX_BATCH_SIZE,
            },
            allow_nil: true,
            if: :active?

  validates :notice_type, inclusion: { in: Lti::Pns::NoticeTypes::ALL, message: "not in #{Lti::Pns::NoticeTypes::ALL}" }, if: :active?
  validate :validate_tool_url, if: :active?

  def validate_tool_url
    if !url&.match?(URI::DEFAULT_PARSER.make_regexp)
      errors.add(:url, "is not a valid URL")
    elsif !context_external_tool&.matches_host?(url) && !context_external_tool&.developer_key&.redirect_uri_matches?(url)
      errors.add(:url, "should match tool's domain or redirect uri")
    end
  end

  resolves_root_account through: :account
end
