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
class TermsOfService < ActiveRecord::Base
  include Canvas::SoftDeletable
  belongs_to :account
  belongs_to :terms_of_service_content
  validates :terms_type, :passive, presence: true

  validate :validate_account_is_root

  cattr_accessor :skip_automatic_terms_creation

  def validate_account_is_root
    if self.account_id_changed? && !self.account.root_account?
      self.errors.add(:account, "must be root account")
    end
  end

  def self.ensure_terms_for_account(account)
    unless !self.table_exists? || self.skip_automatic_terms_creation || account.terms_of_service
      account.shard.activate do
        account.create_terms_of_service!(term_options_for_account(account))
      end
    end
  end

  DEFAULT_OPTIONS = {:terms_type => "default_url"}.freeze
  def self.term_options_for_account(account)
    DEFAULT_OPTIONS
  end
end
