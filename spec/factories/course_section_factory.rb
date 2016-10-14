def add_section(section_name)
  @course_section = @course.course_sections.create!(:name => section_name)
  @course.reload
  @course_section
end
