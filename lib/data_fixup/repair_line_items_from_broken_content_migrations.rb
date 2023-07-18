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

module DataFixup::RepairLineItemsFromBrokenContentMigrations
  # set specific date on all modified line items for future reference
  UPDATED_AT = Time.parse("2023-07-11 00:42:00Z")

  def self.run(shard_id)
    # Objective: Identify all line items that were part of a course copy
    # between 7/5 and 7/10 that did not properly copy (errors in BP code did not
    # copy over resource_id, label, tag, score_maximum, extensions), and track
    # down the source line item by reversing the migration id process.
    #
    # Note: this won't catch "chain" line items, where a course was copied, then
    # the copy was copied again, but that's ok.
    #
    # Assignment -> has Lti::ResourceLink
    #            -> has many Lti::LineItems
    # Lti::LineItem -> belongs to Lti::ResourceLink
    # Lti::ResourceLink -> has many Lti::LineItems
    #

    scope = Lti::LineItem
            .joins(:assignment)
            .where.not(assignment: { migration_id: nil }) # came from course copy
            .where(resource_id: nil) # this isn't the only affected field but it's something to start with
            .where("assignment.updated_at > ? and assignment.updated_at < ?", "2023-07-04", "2023-07-11") # we can fudge on these dates a little, since the resource_id: nil check is the most crucial

    scope.find_ids_in_ranges(batch_size: 1000) do |min_id, max_id| # process batches in another job to avoid long-running transactions
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::CopyLineItemsFromContentMigrations#handle_batch", shard_id]
      ).handle_batch(scope.where(id: min_id..max_id).pluck(:id))
    end
  end

  def self.handle_batch(ids)
    GuardRail.activate(:secondary) do
      resource_link_table = Lti::ResourceLink.quoted_table_name
      assignment_table = Assignment.quoted_table_name
      line_item_table = Lti::LineItem.quoted_table_name

      batch = Lti::LineItem.where(id: ids).joins(:resource_link)

      # query: get dest lookup uuids from this scope
      lookup_uuids = batch.select("#{resource_link_table}.lookup_uuid as lookup_uuid").map(&:lookup_uuid).uniq

      # query: pull src candidates based on dest lookup uuids
      # This works bc the lookup uuid is purposely the same across all iterations of the ResourceLink,
      # to allow copied LTI links in rich content to still launch to the same tool.
      # Note: this is the spicy query for sure, took about 10 seconds to load all objects into memory
      candidates = Lti::LineItem
                   .joins(:resource_link)
                   .preload(:resource_link)
                   .where(resource_link: { lookup_uuid: lookup_uuids })
                   .select("#{line_item_table}.*", "resource_link.lookup_uuid as lookup_uuid")
                   .order(:created_at)
                   .group_by(&:lookup_uuid)

      # in-memory: match src and dest line items based on migration id
      batch.joins(:assignment).select("#{line_item_table}.*, #{resource_link_table}.lookup_uuid as lookup_uuid", "#{assignment_table}.migration_id as migration_id").each do |line_item|
        src_line_items = candidates[line_item.lookup_uuid]&.select do |src_li|
          src_li != line_item && migration_ids_for(Assignment.new(id: src_li.assignment_id)).include?(line_item.migration_id)
        end
        next if src_line_items.blank?

        GuardRail.activate(:primary) do
          # handle first line item, which was auto-created along with the dest assignment
          # since the importer raised an error, it never properly got assigned its attributes.
          # remove it from the list.
          default_line_item = src_line_items.shift
          update_attrs = {
            resource_id: default_line_item.resource_id,
            tag: default_line_item.tag,
            extensions: default_line_item.extensions,
            label: default_line_item.label,
            score_maximum: default_line_item.score_maximum,
            updated_at: UPDATED_AT
          }.compact
          line_item.update! update_attrs

          line_item.resource_link.update! url: default_line_item.resource_link.url if default_line_item.resource_link.url && !line_item.resource_link.url

          # if there were multiple line items for the src assignment (rare, but possible
          # via the AGS), they didn't even get created for the dest assignment, since the
          # importer raised an error well before then.
          # "import" these and make sure they are pointed to the dest resources.
          src_line_items.each do |li|
            dest_line_item = li.dup
            dest_line_item.assignment_id = line_item.assignment_id
            dest_line_item.lti_resource_link_id = line_item.lti_resource_link_id
            dest_line_item.updated_at = UPDATED_AT
            dest_line_item.save!
          end
        end
      end
    end
  end

  # we can't be sure if the migration used local or global ids, so we need to check both
  # _most_ migrations use global but if any items came from a local migration then that
  # is used instead, so just check against both.
  def self.migration_ids_for(assignment)
    [
      CC::CCHelper.create_key(assignment, global: false),
      CC::CCHelper.create_key(assignment, global: true)
    ]
  end
end
