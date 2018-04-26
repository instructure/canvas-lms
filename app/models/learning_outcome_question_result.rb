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

  simply_versioned

  scope :for_associated_asset, lambda {|associated_asset|
    where(:associated_asset_type => associated_asset.class.to_s, :associated_asset_id => associated_asset.id)
  }

  delegate :hide_points, to: :learning_outcome_result

  before_save :infer_defaults

  def infer_defaults
    self.original_score ||= self.score
    self.original_possible ||= self.possible
    self.original_mastery = self.mastery if self.original_mastery.nil?
    calculate_percent!
    true
  end

  def calculate_percent!
    if self.score && self.possible
      self.percent = self.score.to_f / self.possible.to_f
    end
    self.percent = nil if self.percent && !self.percent.to_f.finite?
  end

  def save_to_version(attempt)
    if self.versions.empty?
      save
    else
      current_version = self.versions.current.model
      if current_version.attempt && attempt < current_version.attempt
        versions = self.versions.sort_by(&:created_at).reverse.select{|v| v.model.attempt == attempt}
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
    version_data = YAML::load(version.yaml)
    version_data["score"] = self.score
    version_data["mastery"] = self.mastery
    version_data["possible"] = self.possible
    version_data["attempt"] = self.attempt
    version_data["title"] = self.title
    version.yaml = version_data.to_yaml
    version.save
  end

end
