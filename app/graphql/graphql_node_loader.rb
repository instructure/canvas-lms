module GraphQLNodeLoader
  def self.load(type, id, ctx)
    check_read_permission = make_permission_check(ctx, :read)

    case type
    when "Course"
      Loaders::IDLoader.for(Course).load(id).then(check_read_permission)
    when "Assignment"
      Loaders::IDLoader.for(Assignment).load(id).then(check_read_permission)
    when "Section"
      Loaders::IDLoader.for(CourseSection).load(id).then(check_read_permission)
    when "User"
      Loaders::IDLoader.for(User).load(id).then(
        make_permission_check(ctx, :manage, :manage_user_details)
      )
    when "Enrollment"
      Loaders::IDLoader.for(Enrollment).load(id).then do |enrollment|
        Loaders::IDLoader.for(Course).load(enrollment.course_id).then do |course|
          if enrollment.user_id == ctx[:current_user].id ||
              course.grants_right?(ctx[:current_user], ctx[:session], :read_roster)
            enrollment
          else
            nil
          end
        end
      end
    when "GradingPeriod"
      Loaders::IDLoader.for(GradingPeriod).load(id).then(check_read_permission)
    else
      raise UnsupportedTypeError.new("don't know how to load #{type}")
    end
  end

  def self.make_permission_check(ctx, *permissions)
    ->(o) {
      o.grants_any_right?(ctx[:current_user], ctx[:session], *permissions) ? o : nil
    }
  end

  class UnsupportedTypeError < StandardError; end
end
