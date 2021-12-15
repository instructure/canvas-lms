# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class LearningOutcomeQuestionResult < ActiveRecord::Base
  belongs_to :learning_outcome_result
  belongs_to :learning_outcome
  belongs_to :associated_asset, polymorphic: [:assessment_question]
  belongs_to :root_account, class_name: "Account"

  simply_versioned

  scope :for_associated_asset, lambda { |associated_asset|
    where(associated_asset_type: associated_asset.class.to_s, associated_asset_id: associated_asset.id)
  }

  delegate :hide_points, to: :learning_outcome_result

  before_save :infer_defaults
  before_save :set_root_account_id

  def infer_defaults
    self.original_score ||= score
    self.original_possible ||= possible
    self.original_mastery = mastery if original_mastery.nil?
    calculate_percent!
    true
  end

  def set_root_account_id
    return if root_account_id.present?

    self.root_account_id = learning_outcome_result.root_account_id
  end

  def calculate_percent!
    if score && possible
      self.percent = score.to_f / possible.to_f
    end
    self.percent = nil if percent && !percent.to_f.finite?
  end

  def save_to_version(attempt)
    if versions.empty?
      save
    else
      current_version = versions.current.model
      if current_version.attempt && attempt < current_version.attempt
        versions = self.versions.sort_by(&:created_at).reverse.select { |v| v.model.attempt == attempt }
        unless versions.empty?
          versions.all? do |version|
            update_version_data(version)
          end
        end
      else
        save
      end
    end
  end

  private

  def update_version_data(version)
    version_data = YAML.load(version.yaml)
    version_data["score"] = score
    version_data["mastery"] = mastery
    version_data["possible"] = possible
    version_data["attempt"] = attempt
    version_data["title"] = title
    version.yaml = version_data.to_yaml
    version.save
  end
end
