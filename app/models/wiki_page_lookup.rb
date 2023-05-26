# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class WikiPageLookup < ApplicationRecord
  extend RootAccountResolver

  belongs_to :wiki_page, inverse_of: :wiki_page_lookups
  belongs_to :context, polymorphic: [:course, :group]
  before_save :set_context

  resolves_root_account through: :wiki_page

  scope :by_wiki_id, ->(wiki_id) { joins(:wiki_page).where(wiki_page: { wiki: wiki_id }) }

  def set_context
    self.context_type ||= wiki_page.context_type
    self.context_id ||= wiki_page.context_id
  end
end
