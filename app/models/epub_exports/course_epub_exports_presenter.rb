module EpubExports
  class CourseEpubExportsPresenter
    def initialize(current_user)
      @current_user = current_user
    end
    attr_reader :current_user

    def courses
      @_courses ||= courses_with_feature_enabled.map do |course|
        course.latest_epub_export = epub_exports.find do |epub_export|
          epub_export.course_id == course.id
        end

        course
      end
    end

    private
    def courses_not_including_epub_exports

      @_courses_not_including_epub_exports ||= Course.joins(:enrollments).
        where(Enrollment::QueryBuilder.new(:current_and_concluded).conditions).
        where(
        'enrollments.type IN (?) AND enrollments.user_id = ?',
        [StudentEnrollment, TeacherEnrollment],
        current_user
      ).to_a
    end

    def courses_with_feature_enabled
      @_courses_with_feature_enabled ||= courses_not_including_epub_exports.delete_if do |course|
        !course.feature_enabled?(:epub_export)
      end
    end

    def epub_exports
      @_epub_exports ||= EpubExport.where({
        course_id: courses_with_feature_enabled,
        user_id: current_user
      }).select("DISTINCT ON (epub_exports.course_id) epub_exports.*").
      order("course_id, created_at DESC").
      preload(:epub_attachment, :job_progress, :zip_attachment)
    end
  end
end
