class CourseDateRange
  attr_reader :start_at, :end_at
  def initialize(course)
    valid_date_range(course)
  end

  def valid_date_range(course)
    if course.restrict_enrollments_to_course_dates
      @start_at = {date: course.start_at, date_context: "course"} if course.start_at
      @end_at = {date: course.end_at, date_context: "course"} if course.end_at
    end
    @start_at ||= {date: course.enrollment_term.start_at, date_context: "term"}
    @end_at ||= {date: course.enrollment_term.end_at, date_context: "term"}
  end
end
