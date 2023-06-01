# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

ScryptProvider = Struct.new(:cost) do
  def encrypt(*tokens)
    SCrypt::Password.create(
      join_tokens(tokens),
      cost:
    )
  end

  # Does the hash match the tokens? Uses the same tokens that were used to encrypt.
  def matches?(hash, *tokens)
    hash = new_from_hash(hash)
    return false if hash.blank?

    hash == join_tokens(tokens)
  end

  def cost_matches?(hash)
    hash.starts_with?(cost)
  end

  private

  def join_tokens(tokens)
    tokens.flatten.join
  end

  def new_from_hash(hash)
    SCrypt::Password.new(hash)
  rescue SCrypt::Errors::InvalidHash
    nil
  end
end
