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
#
class AccountPronoun < ActiveRecord::Base
  include Canvas::SoftDeletable
  belongs_to :account

  DEFAULT_OPTIONS = {
    :she_her => -> { t('she/her') },
    :he_him => -> { t('he/him') },
    :they_them => -> { t('they/them') }
  }.freeze

  def self.create_defaults
    DEFAULT_OPTIONS.each_key {|pronoun| self.where(pronoun: pronoun, account_id: nil).first_or_create!}
  end

  def display_pronoun
    self.account_id ? self.pronoun : DEFAULT_OPTIONS[self.pronoun.to_sym].call
  end
end
