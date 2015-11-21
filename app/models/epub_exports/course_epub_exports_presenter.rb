module EpubExports
  class CourseEpubExportsPresenter
    def initialize(current_user)
      @current_user = current_user
    end
    attr_reader :current_user

    def courses
      @_courses ||= courses_without_epub_exports.map do |course|
        course.latest_epub_export = epub_exports.find do |epub_export|
          epub_export.course_id == course.id
        end

        course
      end
    end

    private
    def courses_without_epub_exports
      @_courses_without_epub_exports ||= current_user.current_and_concluded_courses
    end

    def epub_exports
      @_epub_exports ||= EpubExport.where({
        course_id: courses_without_epub_exports,
        user_id: current_user
      }).select("DISTINCT ON (epub_exports.course_id) epub_exports.*").
      order("course_id, created_at DESC").
      preload(:epub_attachment, :job_progress, :zip_attachment)
    end
  end
end
