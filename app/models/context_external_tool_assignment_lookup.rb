class ContextExternalToolAssignmentLookup < ActiveRecord::Base
  strong_params
  belongs_to :context_external_tool
  belongs_to :assignment
  # Do not add before_destroy or after_destroy, these records are "delete_all"ed
end
