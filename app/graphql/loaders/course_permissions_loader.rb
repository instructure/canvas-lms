# this is not a generally useful loader (it should be passed into the
# CoursePermissionType)
class Loaders::CoursePermissionsLoader < GraphQL::Batch::Loader
  def initialize(course, current_user:, session:)
    @course = course
    @current_user = current_user
    @session = session
  end

  def perform(permissions)
    rights = @course.rights_status(@current_user, @session, *permissions)
    rights.each { |right, perm| fulfill(right, perm) }
  end
end
