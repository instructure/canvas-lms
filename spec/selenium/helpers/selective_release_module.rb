require File.expand_path(File.dirname(__FILE__) + '/../../factories/course_factory')
require File.expand_path(File.dirname(__FILE__) + '/components_module')

module SelectiveRelease
  include Components

  class << self
    def sr_course
      @sr_course ||= create_course('Selective Release Course')
    end

    def section_a
      @section_a ||= add_section_to_course('Section A')
    end

    def section_b
      @section_b ||= add_section_to_course('Section B')
    end

    def section_c
      @section_c ||= add_section_to_course('Section C')
    end

    def setup
      Users.setup
      Homework.setup
    end

    private

    def create_course(course_name)
      course(
        course_name: course_name,
        active_course: true,
        differentiated_assignments: true
      )
    end

    def add_section_to_course(section_name)
      sr_course.course_sections.create!(name: section_name)
    end
  end

  module Homework
    class << self
      def setup
        quizzes
        assignments
        discussions
      end

      private

      def create_quiz(quiz_name)
        Components::Quiz.new(SelectiveRelease.sr_course, quiz_name)
      end

      def quizzes
        quiz_for_everyone
        quiz_for_section_a
        quiz_for_section_b
        quiz_for_sections_a_and_b
        quiz_for_first_student
        quiz_for_second_and_third_students
      end

      def assignments

      end

      def discussions

      end

      def quiz_for_everyone
        quiz = create_quiz('Quiz for Everyone')
        quiz.submit_as(Users.first_student)
      end

      def quiz_for_section_a
        quiz = create_quiz('Quiz for Section A')
        quiz.assign_to(section: SelectiveRelease.section_a)
        quiz.submit_as(Users.first_student)
      end

      def quiz_for_section_b
        quiz = create_quiz('Quiz for Section B')
        quiz.assign_to(section: SelectiveRelease.section_b)
        quiz.submit_as(Users.second_student)
      end

      def quiz_for_sections_a_and_b
        quiz = create_quiz('Quiz for Sections A and B')
        quiz.assign_to(section: SelectiveRelease.section_a)
        quiz.assign_to(section: SelectiveRelease.section_b)
        quiz.submit_as(Users.third_student)
      end

      def quiz_for_first_student
        quiz = create_quiz('Quiz for Student 1')
        quiz.assign_to(user: Users.first_student)
        quiz.submit_as(Users.first_student)
      end

      def quiz_for_second_and_third_students
        quiz = create_quiz('Quiz for Students 2 and 3')
        quiz.assign_to(user: Users.second_student)
        quiz.assign_to(user: Users.third_student)
        quiz.submit_as(Users.second_student)
        quiz.submit_as(Users.third_student)
      end
    end
  end

  module Users
    class << self
      def first_student
        @student1 ||= create_user('Student1')
      end

      def second_student
        @student2 ||= create_user('Student2')
      end

      def third_student
        @student3 ||= create_user('Student3')
      end

      def fourth_student
        @student4 ||= create_user('Student4')
      end

      def teacher
        @teacher1 ||= create_user('Teacher1')
      end

      def ta
        @ta1 ||= create_user('TeacherAssistant1')
      end

      def first_observer
        @observer1 ||= create_user('Observer1')
      end

      def third_observer
        @observer3 ||= create_user('Observer3')
      end

      def student_group
        @student_group1 ||= create_student_group('Student Group')
      end

      def setup
        enroll_teacher
        enroll_ta
        enroll_students
        enroll_observers
        student_group
      end

      private

      def create_user(username)
        user_with_pseudonym(username: username, active_all: 1)
      end

      def create_student_group(group_name)
        SelectiveRelease.sr_course.groups.create!(name: group_name)
      end

      def add_user_to_group(user, opts={})
        user_group = opts.fetch(:group, student_group)
        user_group.add_user user
        user_group.leader = user if opts.fetch(:is_leader, false)
        user_group.save!
      end

      def enroll_observers
        enroll_first_observer
        enroll_third_observer
      end

      def enroll_observer(an_observer, student_to_observe)
        SelectiveRelease.sr_course.enroll_user(
          an_observer,
          'ObserverEnrollment',
          enrollment_state: 'active',
          associated_user_id: student_to_observe.id
        )
      end

      def enroll_students
        enroll_first_student
        enroll_second_student
        enroll_third_student
        enroll_fourth_student
      end

      def enroll_teacher
        SelectiveRelease.sr_course.enroll_teacher(teacher)
      end

      def enroll_ta
        SelectiveRelease.sr_course.enroll_ta(ta)
      end

      def enroll_first_observer
        enroll_observer(first_observer, first_student)
      end

      def enroll_third_observer
        enroll_observer(third_observer, third_student)
      end

      def enroll_first_student
        student = first_student
        enroll_student_in_section_a(student)
        add_user_to_group(student, is_leader: true)
      end

      def enroll_second_student
        student = second_student
        enroll_student_in_section_b(student)
        add_user_to_group(student)
      end

      def enroll_third_student
        student = third_student
        enroll_student_in_section_a(student)
        enroll_student_in_section_b(student)
        add_user_to_group(student)
      end

      def enroll_fourth_student
        enroll_student_in_section_c(fourth_student)
      end

      def enroll_student_in_section_a(student)
        enroll_student_in_section(student, SelectiveRelease.section_a)
      end

      def enroll_student_in_section_b(student)
        enroll_student_in_section(student, SelectiveRelease.section_b)
      end

      def enroll_student_in_section_c(student)
        enroll_student_in_section(student, SelectiveRelease.section_c)
      end

      def enroll_student_in_section(student, section)
        SelectiveRelease.sr_course.self_enroll_student(student, section: section)
      end
    end
  end
end