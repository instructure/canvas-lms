# This is a dummy implementation. The real implementation is provided by the
# Canvas analytics plugin
class Loaders::CourseStudentAnalyticsLoader < GraphQL::Batch::Loader
  def initialize(course_id, current_user:, session:)
    @course_id = course_id
    @current_user = current_user
    @session = session
  end

  def perform(users)
    users.each { |u| fulfill(u, nil) }
  end
end

