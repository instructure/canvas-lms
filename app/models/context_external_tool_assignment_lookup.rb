class ContextExternalToolAssignmentLookup < ActiveRecord::Base
  belongs_to :external_tool, polymorphic: true
  belongs_to :assignment
  # Do not add before_destroy or after_destroy, these records are "delete_all"ed
end
