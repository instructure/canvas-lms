module LtiOutbound
  class LTIAssignment < LTIModel
    proc_accessor :id, :source_id, :title, :points_possible, :return_types, :allowed_extensions

    add_variable_mapping '$Canvas.assignment.id', :id
    add_variable_mapping '$Canvas.assignment.title', :title
    add_variable_mapping '$Canvas.assignment.pointsPossible', :points_possible
  end
end
