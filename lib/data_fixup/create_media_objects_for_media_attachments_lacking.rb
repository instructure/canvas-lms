# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "nokogiri"

module DataFixup::CreateMediaObjectsForMediaAttachmentsLacking
  CONTENT_MAP = [
    { AssessmentQuestion => :question_data },
    { Assignment => :description },
    { Course => :syllabus_body },
    { DiscussionTopic => :message },
    { DiscussionEntry => :message },
    { Quizzes::Quiz => :description },
    { Quizzes::QuizQuestion => :question_data },
    { Submission => :body },
    { WikiPage => :body }
  ].freeze

  def self.get_original_media_id(a, all_candidates = nil, safe_recursive_count = 0)
    return nil if safe_recursive_count > 6

    safe_recursive_count += 1

    media_id = a.media_entry_id
    media_id ||= a.media_object&.media_id
    return media_id if media_id || !a.migration_id

    if all_candidates # In case we already had to query all filename matching attachments, we keep using those in-memory and not querying for anything again
      # The reason we may be looking at everything *again* is because we keep trying to ensure matching via migration id, so we have to keep
      # establishing links via migration id until *something* has a media id somehow
      parent_id = all_candidates.find do |_attachment_id, mig_ids| # this attachment_id is actually used at try(:first), but it's marked _ so my IDE doesn't bother me
        mig_ids.include? a.migration_id
      end.try(:first)
    else
      # If we don't have an all_candidates variable in-memory we're at least for now still looking just at:
      # attachments from courses migrated into the course that owns the attachment we're trying to fix
      # So, just possible *clear direct* ancestors (as since we check migration id, it's always a "direct" ancestors, but whatever)
      candidates = Attachment.where(context_id: a.context.content_migrations.pluck(:source_course_id), filename: a.filename).to_h do |candidate|
        [candidate.id, [CC::CCHelper.create_key(candidate, global: true), CC::CCHelper.create_key(candidate, global: false)]]
      end

      parent_id = candidates.find do |_attachment_id, mig_ids| # Again, this attachment_id is actually used at try(:first), but IDE and so on...
        mig_ids.include? a.migration_id
      end.try(:first)
    end

    if !parent_id && !all_candidates
      # We didn't look at everything yet *and* didn't find a parent, so now we try 2 things:

      # Get the attachment ids from the media object side so it's quicker
      # WE don't use JOIN here because we want the attachment AR anyway for create_key and we don't want to
      # replicate the global_asset string logic to pass that, because create key could take that I think, but yeah, none of that...
      mo_att_ids = MediaObject.where(title: a.display_name).where.not(attachment_id: nil).pluck(:attachment_id)

      parent_id = Attachment.where(id: mo_att_ids).find do |mo_att| # then, for all of those, check if any match migration id and if so, we have found our parent
        [CC::CCHelper.create_key(mo_att, global: true), CC::CCHelper.create_key(mo_att, global: false)].include? a.migration_id
      end.try(:id)

      unless parent_id
        # if we didn't find the parent it may be a display_name/title mismatch due to special characters or duplicates having identifiers
        # that show up in just the filename (in which case we cant match MOs directly), so we do the worst thing ever and look through all
        # attachments matching filename. Arguably this is so bad we may want to remove this block and cut our losses
        all_candidates = Attachment.where(filename: a.filename).to_h do |candidate|
          [candidate.id, [CC::CCHelper.create_key(candidate, global: true), CC::CCHelper.create_key(candidate, global: false)]]
        end

        parent_id = all_candidates.find do |_attachment_id, mig_ids|
          mig_ids.include? a.migration_id
        end.try(:first)
      end
    end

    return nil unless parent_id

    parent = Attachment.find(parent_id)
    parent.media_entry_id || parent.media_object&.media_id || get_original_media_id(parent, all_candidates, safe_recursive_count)
  end

  def self.first_step_fix(model, field)
    model.where("#{field} LIKE ?", "%<iframe%").where(created_at: 2.months.ago..Time.now).find_ids_in_batches(batch_size: 100_000) do |ids|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::CreateMediaObjectsForMediaAttachmentsLacking", Shard.current.database_server.id]
      ).second_step_fix(model, field, ids)
    end
  end

  def self.second_step_fix(model, field, record_ids)
    attachment_ids = record_ids.map do |id|
      record = model.find(id)

      next unless record[field].to_s.include?("iframe") && record[field].to_s.include?("media_attachments_iframe")

      doc = Nokogiri::HTML5::DocumentFragment.parse(record[field], nil, { max_tree_depth: 10_000 })
      doc.css("iframe").map do |e|
        next unless e.get_attribute("src")&.match?('(.*\/)?media_attachments_iframe\/([^\/\?]*)(.*)')

        source_parts = e.get_attribute("src").match('(.*\/)?media_attachments_iframe\/([^\/\?]*)(.*)')
        next if !source_parts || !source_parts[2]

        # Following 2 lines for when the markup has some juicy info we can use to short circuit potentially
        # dozens of queries (likely not dozens, but you never know)
        media_id_candidate = e.get_attribute("data-media-id")
        media_id_candidate ||= e.get_attribute("id")&.match("media_comment_(.*)")&.[](1)

        {
          "attachment_id" => source_parts[2],
          "media_id" => media_id_candidate
        }
      end
    end.flatten.compact

    attachment_ids.each_slice(1000) do |id_segment|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::CreateMediaObjectsForMediaAttachmentsLacking", Shard.current.database_server.id]
      ).third_step_fix(id_segment)
    end
  end

  def self.third_step_fix(attachment_id_media_id_pairs)
    attachment_id_media_id_pairs.each do |id_pair|
      if id_pair["media_id"] && MediaObject.where(media_id: id_pair["media_id"]).any?
        Attachment.find(id_pair["attachment_id"]).update_columns(media_entry_id: id_pair["media_id"])
        next
      end

      a = Attachment.find(id_pair["attachment_id"])

      next if a.media_entry_id

      media_entry_id = get_original_media_id(a)

      next unless media_entry_id

      a.update_columns(media_entry_id:) # bypassing callbacks
    end
  end

  def self.run
    CONTENT_MAP.each do |model_map|
      model_map.each do |model, field|
        delay_if_production(
          priority: Delayed::LOW_PRIORITY,
          n_strand: ["DataFixup::CreateMediaObjectsForMediaAttachmentsLacking", Shard.current.database_server.id]
        ).first_step_fix(model, field)
      end
    end
  end
end
