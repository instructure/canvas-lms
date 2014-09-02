module DataFixup::FixInvalidCourseIdsOnEnrollments
  def self.run
    Enrollment.joins(:course_section).
      where("course_sections.course_id<>enrollments.course_id").
      includes(:course_section).find_each do |e|
      Enrollment.where(id: e).update_all(course_id: e.course_section.course_id)
    end
  end
end
