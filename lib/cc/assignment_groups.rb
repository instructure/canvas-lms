#
# Copyright (C) 2011 Instructure, Inc.
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
module CC
  module AssignmentGroups
    def create_assignment_groups(document=nil)
      return nil unless @course.assignment_groups.active.count > 0

      if document
        group_file = nil
        rel_path = nil
      else
        group_file = File.new(File.join(@canvas_resource_dir, CCHelper::ASSIGNMENT_GROUPS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::ASSIGNMENT_GROUPS)
        document = Builder::XmlMarkup.new(:target=>group_file, :indent=>2)
      end

      document.instruct!
      document.assignmentGroups(
              "xmlns" => CCHelper::CANVAS_NAMESPACE,
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |groups_node|
        @course.assignment_groups.active.each do |group|
          next unless export_object?(group)
          add_exported_asset(group)

          migration_id = CCHelper.create_key(group)
          groups_node.assignmentGroup(:identifier=>migration_id) do |group_node|
            group_node.title group.name
            group_node.position group.position
            group_node.group_weight group.group_weight if group.group_weight
            unless group.rules.blank?
              # This turns the rules column from something like:
              # "drop_lowest:1\ndrop_highest:2\nnever_drop:259\n"
              # to something like:
              # [["drop_lowest", "1"], ["drop_highest", "2"], ["never_drop", "259"]]
              rules = group.rules.split("\n").map{|r|r.split(':')}
              group_node.rules do |rules_node|
                rules.each do |rule|
                  a = nil
                  if rule.first == 'never_drop'
                    a = @course.assignments.where(id: rule.last).first
                    next unless a
                  end
                  rules_node.rule do |rule_node|
                    rule_node.drop_type rule.first
                    if rule.first == 'never_drop'
                      rule_node.identifierref CCHelper.create_key(a)
                    else
                      rule_node.drop_count rule.last
                    end
                  end
                end
              end
            end
          end
        end
      end

      group_file.close if group_file
      rel_path
    end
  end
end