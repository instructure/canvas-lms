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
  module FixOldSubmissionVersionYAML
    def self.run
      Version.find_ids_in_ranges do |min_id, max_id|
        Version.where(:id => min_id..max_id, :versionable_type => "Submission").
                where("yaml LIKE ?", "%cached_due_date: !ruby/string%").each do |version|
          begin
            yaml = version.yaml.sub("cached_due_date: !ruby/string", "cached_due_date: ")
            obj = YAML.load(yaml)
            obj["cached_due_date"] = Time.parse(obj["cached_due_date"]["str"])
            version.yaml = YAML.dump(obj)
            version.save!
          rescue
            Rails.logger.error("Error occured trying to process Version #{version.global_id}")
          end
        end
      end
    end
  end
end
