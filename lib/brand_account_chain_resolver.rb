# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# Find the reverse account chain starting at the specified root account and
# ending at the lowest sub-account such that all of the accounts with which
# the user is associated (e.g. through an enrollment), and which descend from
# that root account, also descend from one of the accounts in the chain.
#
# In other words, if the users associated accounts made a tree, it would be the
# chain between the root and the first branching point:
#
#         /-E
#     A-B-
#     ^ ^ \-C-
#             \-D
#
# The only exception to this is when the user has active enrollments exclusively
# in one sub-account, then the chain is the path from the root (A) all the way
# to that sub-account (D):
#
#         /-E
#     A-B-
#     ^ ^ \-C-
#           ^ \-D*
#               ^
#
# This is used in the context of deciding which theme the user should be using
# when it comes to non-contextual pages, like the dashboard. See the specs for
# a more visual representation of the expected behavior.
#
class BrandAccountChainResolver
  attr_reader :root_account, :user

  def initialize(root_account:, user:)
    @root_account = root_account
    @user = user
  end

  def resolve
    return nil if associated_accounts.blank?

    # if there's only one account that has an active enrollment, just use that
    actives = enrollment_account_ids & associated_accounts.map(&:id)
    if actives.count == 1
      return associated_accounts.detect { |x| x.id == actives[0] }
    end

    longest_chain = [root_account]
    loop do
      break if enrollment_account_ids.include?(longest_chain.last.id)

      next_children = sub_accounts_of(longest_chain.last)
      break unless next_children.present? && next_children.count == 1

      longest_chain << next_children.first
    end
    longest_chain.last
  end

  private

  def associated_accounts
    @associated_accounts ||= user.associated_accounts.where(
      "accounts.id = ? OR accounts.root_account_id = ?",
      root_account.id,
      root_account.id
    )
  end

  def sub_accounts_of(account)
    @sub_account_index ||= associate_accounts_to_parents
    @sub_account_index[account.id]
  end

  def associate_accounts_to_parents
    associated_accounts.each_with_object({}) do |account, hash|
      hash[account.id] ||= []

      if account.parent_account_id.present?
        hash[account.parent_account_id] ||= []
        hash[account.parent_account_id] << account
      end
    end
  end

  def enrollment_account_ids
    @enrollment_account_ids ||= root_account
                                .all_enrollments
                                .current # don't want concluded enrollments to count, only active ones
                                .where(user_id: user)
                                .joins(:course)
                                .distinct
                                .pluck(:account_id)
  end
end
