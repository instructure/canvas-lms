module GqlNodeLoader
  def self.load(type, id, ctx)
    check_read_permission = ->(o) {
      o.grants_right?(ctx[:current_user], ctx[:session], :read) ? o : nil
    }

    case type
    when "Course"
      Loaders::IDLoader.for(Course).load(id).then(check_read_permission)
    when "Assignment"
      Loaders::IDLoader.for(Assignment).load(id).then(check_read_permission)
    when "Section"
      Loaders::IDLoader.for(CourseSection).load(id).then(check_read_permission)
    else
      raise UnsupportedTypeError.new("don't know how to load #{type}")
    end
  end

  class UnsupportedTypeError < StandardError; end
end
