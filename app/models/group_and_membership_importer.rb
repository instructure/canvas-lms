# frozen_string_literal: true

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
#

class GroupAndMembershipImporter < ActiveRecord::Base
  include Canvas::SoftDeletable

  belongs_to :group_category, inverse_of: :group_and_membership_importers
  belongs_to :attachment, inverse_of: :group_and_membership_importer

  attr_accessor :progress, :total_lines, :update_every, :seen_groups, :group_members, :seen_user_ids

  def self.create_import_with_attachment(group_category, file_obj)
    import = GroupAndMembershipImporter.create!(group_category:)
    att = Attachment.create_data_attachment(import, file_obj, "category_import_#{import.global_id}.csv")
    import.attachment = att
    import.save!
    progress = Progress.create!(context: group_category, tag: "course_group_import", completion: 0.0)

    progress.process_job(import,
                         :import_groups_from_attachment,
                         { strand: ["import_groups_from_attachment", group_category.context.global_id] })
    progress
  end

  def import_groups_from_attachment(progress)
    @progress = progress
    progress.start
    csv = begin
      file = attachment.open
      { fullpath: file.path, file: attachment.display_name, attachment: }
    end
    validate_file(csv)
    return unless progress.reload.running?

    begin
      csv_contents = CSV.read(csv[:fullpath], **SIS::CSV::CSVBaseImporter::PARSE_ARGS)
    rescue CSV::MalformedCSVError
      fail_import(I18n.t("Malformed CSV"))
    end
    @total_lines = csv_contents.length
    @update_every ||= [total_lines / 99.to_f.round(0), 50].max
    @seen_groups = {}
    @seen_user_ids = Set.new
    @group_members = {}
    create_groups_and_members(csv_contents)
    progress.complete
    progress.save!
    self.workflow_state = "completed"
    save!
  end

  workflow do
    state :active
    state :completed
    state :deleted
    state :failed
  end

  def validate_file(csv)
    fail_import(I18n.t("Unable to read file")) unless File.file?(csv[:fullpath])
    fail_import(I18n.t("Only CSV files are supported.")) unless File.extname(csv[:fullpath]).casecmp(".csv").zero?
    fail_import(I18n.t("Invalid UTF-8")) unless Attachment.valid_utf8?(File.open(csv[:fullpath]))
  end

  def fail_import(error)
    self.workflow_state = "failed"
    save!
    progress.message = error
    progress.save!
    progress.fail
  end

  def create_groups_and_members(rows)
    rows.each_with_index do |row, index|
      group = group_from_row(row)
      next unless group

      user = user_from_row(row)
      next unless user

      seen_user_ids.include?(user.id) ? next : validate_user(user)

      seen_user_ids << user.id
      group_members[group] ||= []
      group_members[group] << user
      persist_memberships if index % 1_000 == 0 && index != 0
      update_progress(index)
    end
    persist_memberships
  end

  def validate_user(user)
    # if they have any memberships, we are moving them via delete and add
    GroupMembership.where(group_id: group_category.groups.select(:id), user_id: user.id).destroy_all
  end

  def user_from_row(row)
    user_id = row["canvas_user_id"]
    user_sis_id = row["user_id"]
    login_id = row["login_id"]
    user = nil
    user_scope = group_category.context.students.where.not(enrollments: { type: "StudentViewEnrollment" })
    user = user_scope.where(id: user_id).take if user_id
    pseudonym_scope = Pseudonym.active.where(account_id: group_category.root_account_id)
    user ||= user_scope.where(id: pseudonym_scope.where(sis_user_id: user_sis_id).limit(1).select(:user_id)).take if user_sis_id
    user ||= user_scope.where(id: pseudonym_scope.by_unique_id(login_id).limit(1).select(:user_id)).take if login_id
    user
  end

  def group_from_row(row)
    group_id = row["canvas_group_id"]
    group_sis_id = row["group_id"]
    group_name = row["group_name"]
    key = group_key(group_id, group_sis_id, group_name)
    return unless key

    group = seen_groups[key]
    group ||= group_category.groups.where(id: group_id).take if group_id
    group ||= group_category.groups.where(sis_source_id: group_sis_id).take if group_sis_id
    restore_group(group) if group&.deleted?
    if group_name
      group ||= group_category.groups.active.where(name: group_name).take
      group ||= create_new_group(group_name)
    end
    seen_groups[key] ||= group
    group
  end

  def restore_group(group)
    group.workflow_state = "available"
    group.save!
  end

  def create_new_group(name)
    InstStatsd::Statsd.increment("groups.auto_create",
                                 tags: { split_type: "csv",
                                         root_account_id: group_category.root_account&.global_id,
                                         root_account_name: group_category.root_account&.name })
    group_category.groups.create!(name:, context: group_category.context)
  end

  def group_key(group_id, group_sis_id, group_name)
    key = []
    key << "id:#{group_id}" if group_id
    key << "sis_id:#{group_sis_id}" if group_sis_id
    key << "name:#{group_name}" if group_name
    key.join(",").presence
  end

  def persist_memberships
    group_members.each do |group, users|
      group.bulk_add_users_to_group(users)
    end
    @group_members = {}
  end

  def update_progress(index)
    if index % update_every == 0
      progress.calculate_completion!(index, total_lines)
    end
  end
end
