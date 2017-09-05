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

  validates :content, presence: true
  validates :terms_updated_at, presence: true

  before_validation :ensure_terms_updated_at
  before_save :set_terms_updated_at

  def ensure_terms_updated_at
    self.terms_updated_at ||= Time.now.utc
  end

  def set_terms_updated_at
    self.terms_updated_at = Time.now.utc if self.content_changed?
  end
end
