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
#
class SisBatchError < ActiveRecord::Base
  belongs_to :sis_batch, inverse_of: :sis_batch_errors
  belongs_to :parallel_importer, inverse_of: :sis_batch_errors
  belongs_to :root_account, class_name: 'Account', inverse_of: :sis_batch_errors

  scope :expired_errors, -> {where('created_at < ?', 30.days.ago)}
  scope :failed, -> {where(failure: true)}
  scope :warnings, -> {where(failure: false)}

  def self.cleanup_old_errors
    cleanup = expired_errors.limit(10_000)
    while cleanup.delete_all > 0; end
  end

  def description
    (self.file || "") + " - " + (self.message || "")
  end

end
