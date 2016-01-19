require_relative 'selective_release_sections_module'
require_relative 'selective_release_users_module'
require_relative 'selective_release_homework_module'
require_relative 'selective_release_course_modules_module'

# Selective Release is AKA Differentiated Assignments
module SelectiveRelease
  class << self
    attr_reader :the_course

    def initialize
      @the_course = create_course
      SelectiveRelease::Sections.initialize
      SelectiveRelease::Users.initialize
      SelectiveRelease::Homework.initialize
      SelectiveRelease::CourseModules.initialize
    end

    private

      def create_course(opts = {})
        course_name = opts.fetch(:name, 'Selective Release Course')
        course(
          course_name: course_name,
          active_course: true,
          differentiated_assignments: true
        )
      end
  end

  module URLs
    class << self

      def course_home_page
        "/courses/#{SelectiveRelease.the_course.id}"
      end

      def quiz_show_page(quiz)
        "#{quizzes_index_page}/#{quiz.id}"
      end

      def quizzes_index_page
        "#{course_home_page}/quizzes"
      end

      def assignment_show_page(assignment)
        "#{assignments_index_page}/#{assignment.id}"
      end

      def assignments_index_page
        "#{course_home_page}/assignments"
      end

      def discussion_show_page(discussion)
        "#{discussions_index_page}/#{discussion.id}"
      end

      def discussions_index_page
        "#{course_home_page}/discussions"
      end

      def course_module_show_page(course_module)
        "#{course_modules_index_page}/#{course_module.id}"
      end

      def course_modules_index_page
        "#{course_home_page}/modules"
      end
    end
  end
end