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

class TranslateLinksOnAssessmentQuestions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    AssessmentQuestion.where("question_data LIKE '%/files/%'").find_in_batches do |batch|
      AssessmentQuestion.send_later_if_production_enqueue_args(:translate_links, { :priority => Delayed::LOWER_PRIORITY, :max_attempts => 1, :strand => 'mass_translate_links_migration' }, batch.map(&:id))
    end
  end

  def self.down
  end
end
