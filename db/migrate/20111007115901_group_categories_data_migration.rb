#
# Copyright (C) 2011 - present Instructure, Inc.
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

class GroupCategoriesDataMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.uncached_group_category_id_for(context, name)
    if !context.is_a?(Account) && name == "Student Groups"
      GroupCategory.student_organized_for(context).id
    elsif name == "Imported Groups"
      GroupCategory.imported_for(context).id
    else
      context.group_categories.where(name: name).first_or_create.id
    end
  end

  def self.group_category_id_for(record)
    context = record.context
    name = record.group_category_name
    @cache ||= {}
    @cache[context] ||= {}
    @cache[context][name] ||= uncached_group_category_id_for(context, name)
  end

  def self.update_records_for_record(record)
    return unless record.context.present? and record.group_category_name.present?
    category_column = (record.class == Group ? 'category' : 'group_category')
    records = record.class.where("context_id=? AND context_type=? AND #{category_column}=? AND group_category_id IS NULL",
      record.context_id,
      record.context_type,
      record.group_category_name)
    records.update_all(:group_category_id => group_category_id_for(record))
  end

  def self.up
    Group.select([:context_id, :context_type, :category]).distinct.
      where('context_id IS NOT NULL AND category IS NOT NULL AND group_category_id IS NULL').each do |record|
      update_records_for_record(record)
    end

    Assignment.select([:context_id, :context_type, :group_category]).distinct.
      where('context_id IS NOT NULL AND group_category IS NOT NULL AND group_category_id IS NULL').each do |record|
      update_records_for_record(record)
    end

    # groups.category and assignments.group_category are now deprecated, but
    # should be maintained alongside *.group_category_id in the models
  end

  def self.down
    # no data migration, since groups.category and assignments.group_category
    # are maintained along with *.group_category_id, even though deprecated.
  end
end
