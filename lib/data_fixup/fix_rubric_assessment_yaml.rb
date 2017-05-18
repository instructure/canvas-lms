#
# Copyright (C) 2016 - present Instructure, Inc.
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

module DataFixup
  module FixRubricAssessmentYAML
    def self.run
      # TODO: can remove when Syckness is removed
      RubricAssessment.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
        RubricAssessment.where(:id => min_id..max_id).
          where("data LIKE ? AND data LIKE ?", "%#{Syckness::TAG}", "%comments_html:%").
          pluck("id", "data as d1").each do |id, yaml|

          new_yaml = yaml.gsub(/\:comments_html\:\s*([^!\s])/) do
            ":comments_html: !str #{$1}"
          end
          if new_yaml != yaml
            RubricAssessment.where(:id => id).update_all(:data => YAML.load(new_yaml))
          end
        end
      end
    end
  end
end