module LtiOutbound
  class LTIAssignment < LTIModel
    proc_accessor :id, :source_id, :title, :points_possible, :return_types, :allowed_extensions, 
                  :unlock_at, :due_at, :lock_at
  end
end
