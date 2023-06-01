# frozen_string_literal: true

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
#

class CustomGradebookColumnDatum < ActiveRecord::Base
  belongs_to :custom_gradebook_column

  validates :content, length: { maximum: maximum_string_length,
                                allow_nil: true }
  validates :user_id, uniqueness: { scope: :custom_gradebook_column_id }

  set_policy do
    given do |user|
      custom_gradebook_column.grants_right? user, :manage
    end
    can :update
  end

  before_save :set_root_account_id

  def self.queue_bulk_update_custom_columns(context, column_data)
    progress = Progress.create!(context:, tag: "custom_columns_submissions_update")
    progress.process_job(self, :process_bulk_update_custom_columns, {}, context, column_data)
    progress
  end

  def self.process_bulk_update_custom_columns(_, context, column_data)
    root_account = context.root_account
    Delayed::Batch.serial_batch(priority: Delayed::LOW_PRIORITY, n_strand: ["bulk_update_submissions", root_account.global_id]) do
      custom_gradebook_columns = context.custom_gradebook_columns.preload(:custom_gradebook_column_data)
      column_data.each do |data_point|
        column_id = data_point.fetch(:column_id)
        custom_column = custom_gradebook_columns.find { |custom_col| custom_col.id == column_id.to_i }
        next if custom_column.blank?

        content = data_point.fetch(:content)
        user_id = data_point.fetch(:user_id)
        if content.present?
          CustomGradebookColumnDatum.unique_constraint_retry do
            datum = custom_column.custom_gradebook_column_data.find_or_initialize_by(user_id:)
            datum.content = content
            datum.root_account_id ||= root_account.id
            datum.save!
          end
        else
          custom_column.custom_gradebook_column_data.find_by(user_id:)&.destroy!
        end
      end
    end
  end

  private

  def set_root_account_id
    self.root_account_id ||= custom_gradebook_column&.course&.root_account_id
  end
end
