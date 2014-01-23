module LtiOutbound
  class LTIAssignment < LTIContext
    attr_accessor :id, :source_id, :title, :points_possible, :return_types, :allowed_extensions

    add_variable_mapping '.id', :id
    add_variable_mapping '.title', :title
    add_variable_mapping '.pointsPossible', :points_possible
  end
end
