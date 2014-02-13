module LtiOutbound
  class LTICourse < LTIContext
    proc_accessor :course_code, :name

    add_variable_mapping '$Canvas.course.id', :id
    add_variable_mapping '$Canvas.course.sisSourceId', :sis_source_id
  end
end