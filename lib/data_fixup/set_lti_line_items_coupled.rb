#
# Copyright (C) 2020 - present Instructure, Inc.
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

# Set Lti::LineItem new "coupled" field as true only if they were previously
# protected from deletion (line_item.assignment_line_item? &&
# line_item.resource_link.present) and have extensions. The main point of this
# field is to prevent default line items that are created when a user creates
# an assignment in the UI from being deleted. These always have a resource
# link, are always the first line item associated with the resource link
# (assignment_line_item? is true), and never have extensions (extensions are
# created by creating line items in the API). There will still be some
# LineItems created thru the API that will be unnecessarily protected from
# deletion, but this is the best we can do.
#
# Note: as of 2020-05-20 there are only ~17000 line items in all of Canvas.  I
# could probably make this more efficient by looking up ResourceLinks but it
# doesn't seem worth it.
module DataFixup::SetLtiLineItemsCoupled
  def self.run
    Lti::LineItem.find_in_batches do |line_items|
      # Coupled line items are line items which:
      # 1. do not have extensions, AND
      # 2. have a resource link id, AND
      # 3. are the first (sorted by created_at) line item for their resource link.
      #   (see [old] code for line_item.assignment_line_item?)
      # Here we find line items that satisfy (1) and (2), and get all line items
      # for their resource link to see if they are the first line item for the
      # their resource link, that is, if they satisfy (3)
      maybe_coupled = line_items.select do |item|
        item.extensions.blank? && item.lti_resource_link_id.present?
      end
      rl_ids = maybe_coupled.map(&:lti_resource_link_id).uniq
      assignment_line_item_ids = Lti::LineItem.where(lti_resource_link_id: rl_ids).
        pluck(:lti_resource_link_id, :created_at, :id).
        group_by(&:first).  # hash from r_l_id -> array of [r_l_id, created_at, id]
        transform_values(&:sort). # each one sorted by created_at (first sorted by r_l_id but it's the same for each group)
        transform_values(&:first). # [r_l_id, created_at, id] for first line item of each rl
        transform_values(&:last). # id for first line item of each rl
        values
      coupled_ids = maybe_coupled.map(&:id) & assignment_line_item_ids

      uncoupled_ids = line_items.map(&:id) - coupled_ids

      Lti::LineItem.where(id: coupled_ids).update_all(coupled: true)
      Lti::LineItem.where(id: uncoupled_ids).update_all(coupled: false)
    end
  end
end
