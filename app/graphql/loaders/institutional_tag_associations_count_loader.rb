# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class Loaders::InstitutionalTagAssociationsCountLoader < GraphQL::Batch::Loader
  def perform(tags)
    tag_ids = tags.map(&:id)

    counts_by_tag = InstitutionalTagAssociation
                    .where(institutional_tag_id: tag_ids, workflow_state: "active")
                    .group(:institutional_tag_id)
                    .count

    tags.each { |tag| fulfill(tag, counts_by_tag.fetch(tag.id, 0)) }
  end
end
