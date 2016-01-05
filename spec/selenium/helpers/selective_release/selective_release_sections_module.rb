module SelectiveRelease
  module Sections
    class << self
      attr_reader :course, :section_a, :section_b, :section_c

      def initialize(course)
        @course    = course
        @section_a = create_section('Section A')
        @section_b = create_section('Section B')
        @section_c = create_section('Section C')
      end

      private

        def create_section(section_name)
          self.course.course_sections.create!(name: section_name)
        end
    end
  end
end