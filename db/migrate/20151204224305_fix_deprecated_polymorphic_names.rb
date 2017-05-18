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

class FixDeprecatedPolymorphicNames < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    reflections = [Quizzes::Quiz, Quizzes::QuizSubmission].map do |klass|
      klass.reflections.values.select { |r| r.macro == :has_many && r.options[:as] }
    end
    reflections.flatten!
    reflections.group_by(&:klass).each do |(klass, klass_reflections)|
      next unless klass.table_exists?
      klass.find_ids_in_ranges(batch_size: 10000) do |min_id, max_id|
        klass_reflections.each do |reflection|
          klass.where(id: min_id..max_id,
                      reflection.type => reflection.active_record.name.sub("Quizzes::", "")).
                update_all(reflection.type => reflection.active_record.name)
        end
      end
    end
  end
end
