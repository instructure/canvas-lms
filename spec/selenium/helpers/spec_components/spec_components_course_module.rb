module SpecComponents
  class CourseModule
    attr_reader :course, :name

    def initialize(course, module_name)
      @course = course
      @component_course_module = @course.context_modules.create!(name: module_name)
      @name = @component_course_module.name
    end

    def add_assignment(assignment)
      @component_course_module.add_item(id: assignment.id, type: 'assignment')
    end

    def add_quiz(quiz)
      @component_course_module.add_item(id: quiz.id, type: 'quiz')
    end

    def add_discussion(discussion)
      @component_course_module.add_item(id: discussion.id, type: 'discussion')
    end
  end
end
