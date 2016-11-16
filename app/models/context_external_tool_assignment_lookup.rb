class ContextExternalToolAssignmentLookup < ActiveRecord::Base
  strong_params
  belongs_to :external_tool, polymorphic: true
  belongs_to :assignment
  # Do not add before_destroy or after_destroy, these records are "delete_all"ed

  def self.tool_lookup(assignment_id, tool_id)
    assignment = Assignment.find(assignment_id)
    assignment.tool_settings_tools.find {|t| t.id == tool_id.to_i}
  end
end
