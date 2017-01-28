module DifferentiatedAssignments
  module Sections
    class << self
      attr_reader :section_a, :section_b, :section_c

      def initialize
        @section_a = create_section('Section A')
        @section_b = create_section('Section B')
        @section_c = create_section('Section C')
      end

      private

        def create_section(section_name)
          DifferentiatedAssignments.the_course.course_sections.create!(name: section_name)
        end
    end
  end
end
