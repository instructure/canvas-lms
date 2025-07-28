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

  belongs_to :group_category, inverse_of: :group_and_membership_importers, optional: true
  belongs_to :course, inverse_of: :group_and_membership_importers, optional: true
  belongs_to :attachment, inverse_of: :group_and_membership_importer

  attr_accessor :progress, :total_lines, :update_every, :seen_groups, :group_members, :seen_user_ids

  def self.create_import_with_attachment(import_obj, file_obj)
    is_tag_import = import_obj.is_a?(Course)
    import = is_tag_import ? GroupAndMembershipImporter.create!(course: import_obj) : GroupAndMembershipImporter.create!(group_category: import_obj)
    name = is_tag_import ? "diff_tag_import_#{import.global_id}.csv" : "category_import_#{import.global_id}.csv"
    att = Attachment.create_data_attachment(import, file_obj, name)
    import.attachment = att
    import.save!
    progress = Progress.create!(context: import_obj, tag: "course_group_import", completion: 0.0)

    progress.process_job(import,
                         :import_groups_from_attachment,
                         { strand: ["import_groups_from_attachment", import_obj.is_a?(Course) ? import_obj.global_id : import_obj.context.global_id] })
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
    @group_size = 0
    create_groups_and_members(csv_contents)
    progress.message = progress_message(groups: @group_size, users: @seen_user_ids.size)
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
    progress.message = progress_message(error:)
    progress.save!
    progress.fail
  end

  def create_groups_and_members(rows)
    rows.each_with_index do |row, index|
      group = group_from_row(row)
      next unless group

      user = user_from_row(row)
      next unless user

      seen_user_ids.include?(user.id) ? next : validate_user(user, group)

      seen_user_ids << user.id
      group_members[group] ||= []
      group_members[group] << user
      persist_memberships if index % 1_000 == 0 && index != 0
      update_progress(index)
    end
    persist_memberships
  end

  def validate_user(user, group)
    category = group_category || group.group_category
    # if they have any memberships, we are moving them via delete and add
    GroupMembership.where(group_id: category.groups.select(:id), user_id: user.id).destroy_all
  end

  def user_from_row(row)
    user_id = row["canvas_user_id"]
    user_sis_id = row["user_id"]
    login_id = row["login_id"]
    user = nil
    context = group_category&.context || course
    user_scope = context.students.where.not(enrollments: { type: "StudentViewEnrollment" })
    user = user_scope.find_by(id: user_id) if user_id
    pseudonym_scope = Pseudonym.active.where(account_id: context.root_account_id)
    user ||= user_scope.find_by(id: pseudonym_scope.where(sis_user_id: user_sis_id).limit(1).select(:user_id)) if user_sis_id
    user ||= user_scope.find_by(id: pseudonym_scope.by_unique_id(login_id).limit(1).select(:user_id)) if login_id
    user
  end

  def group_from_row(row)
    group_id = row["canvas_group_id"] || row["canvas_tag_id"]
    group_sis_id = row["group_id"] || row["tag_id"]
    group_name = row["group_name"] || row["tag_name"]
    tag_set_id = row["canvas_tag_set_id"]
    tag_set_sis_id = row["tag_set_id"]
    tag_set_name = row["tag_set_name"]
    key = group_key(group_id, group_sis_id, group_name)
    return unless key

    is_tag_import = !course.nil?
    group = seen_groups[key]
    group ||= is_tag_import ? Group.non_collaborative.where(context: course).find_by(id: group_id) : group_category.groups.find_by(id: group_id) if group_id
    group ||= is_tag_import ? Group.non_collaborative.where(context: course).find_by(sis_source_id: group_sis_id) : group_category.groups.find_by(sis_source_id: group_sis_id) if group_sis_id
    group ||= is_tag_import ? Group.non_collaborative.where(context: course).find_by(name: group_name) : group_category.groups.active.find_by(name: group_name)
    tag_set = find_tag_set(tag_set_id, tag_set_sis_id, tag_set_name) if tag_set_id || tag_set_sis_id || tag_set_name
    tag_set ||= group&.group_category
    tag_set.update!(name: tag_set_name) if tag_set && tag_set_name
    restore_group(group) if group&.deleted?

    if is_tag_import
      if group && (tag_set || tag_set_name)
        tag_set ||= create_new_tag_set(tag_set_name)
        group.update!(group_category: tag_set)
      elsif group_name
        tag_set ||= create_new_tag_set(group_name)
        group = create_new_tag(group_name, tag_set)
      end
    elsif group_name
      group ||= create_new_group(group_name)
    end
    seen_groups[key] ||= group
    group
  end

  def restore_group(group)
    group.workflow_state = "available"
    group.save!

    # For tags, restore the tag set as well if it was deleted
    group.group_category&.restore if !course.nil? && group.group_category&.deleted_at.present?
  end

  def create_new_group(name)
    InstStatsd::Statsd.increment("groups.auto_create",
                                 tags: { split_type: "csv",
                                         root_account_id: group_category.root_account&.global_id,
                                         root_account_name: group_category.root_account&.name })
    group_category.groups.create!(name:, context: group_category.context)
  end

  def create_new_tag(name, tag_set)
    InstStatsd::Statsd.increment("groups.auto_create",
                                 tags: { split_type: "csv",
                                         root_account_id: course.root_account&.global_id,
                                         root_account_name: course.root_account&.name })
    tag_set.groups.create!(name:, context: course, non_collaborative: true)
  end

  def create_new_tag_set(name)
    GroupCategory.create!(name:, context: course, non_collaborative: true)
  end

  def find_tag_set(tag_set_id, tag_set_sis_id, tag_set_name)
    tag_set = GroupCategory.non_collaborative.where(context: course).find_by(id: tag_set_id) if tag_set_id
    tag_set ||= GroupCategory.non_collaborative.where(context: course).find_by(sis_source_id: tag_set_sis_id) if tag_set_sis_id
    tag_set ||= GroupCategory.non_collaborative.where(context: course).find_by(name: tag_set_name) if tag_set_name
    tag_set.restore if tag_set&.deleted_at.present?
    tag_set
  end

  def group_key(group_id, group_sis_id, group_name)
    key = []
    key << "id:#{group_id}" if group_id
    key << "sis_id:#{group_sis_id}" if group_sis_id
    key << "name:#{group_name}" if group_name
    key.join(",").presence
  end

  def persist_memberships
    @group_size += group_members.keys.size
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

  def progress_message(groups: 0, tag_sets: 0, users: 0, error: nil)
    message = {
      type: "import_groups",
      groups:,
      users:,
      error:,
    }
    message.to_json
  end
end
