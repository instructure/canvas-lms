require File.expand_path(File.dirname(__FILE__) + '/../common')

def da_setup
  # use after already calling course_with_role_logged_in
  @course.enable_feature!(:differentiated_assignments)
  @section1 = @course.course_sections.create!(:name => 'Section A')
end

def observer_setup()
  course_with_observer_logged_in
  course_with_student(:course => @course)
  observer_enrollment = @observer.enrollments.first!
  @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :section => @other_section)
  observer_enrollment.update_attribute(:associated_user_id, @student.id)
  observer_enrollment.save!
  @observer
end

def da_module_setup
  create_da_assignments
  @module = @course.context_modules.create!(:name => "SelRel Module")
  @tag_assignment = @module.add_item(:type => 'assignment', :id => @da_assignment.id)
  @tag_discussion = @module.add_item(:type => 'discussion_topic', :id => @da_discussion.id)
  @tag_quiz = @module.add_item(:type => 'quiz', :id => @da_quiz.id)
end

def create_section_overrides(section)
  create_section_override_for_assignment(@da_assignment, course_section: section) if @da_assignment
  create_section_override_for_assignment(@da_discussion.assignment, course_section: section) if @da_discussion.assignment
  create_section_override_for_assignment(@da_quiz, course_section: section) if @da_quiz
end

def create_da_assignments
  @da_quiz = @course.quizzes.create!(:title => 'DA Quiz', :allowed_attempts => '2', :only_visible_to_overrides => true)
  @da_quiz.publish!
  assignment_data = {
      :title => 'DA assignment',
      :points_possible => 10,
      :due_at => Time.now + 2.day,
      :submission_types => 'online_text_entry',
      :only_visible_to_overrides => true
  }
  @da_assignment = @course.assignments.create!(assignment_data)
  @da_d_assignment = @course.assignments.create!(assignment_data)
  @da_discussion = @course.discussion_topics.create!(:title => 'DA Discussion', :assignment => @da_d_assignment)
end

def grade_da_assignments
  @da_quiz.assignment.grade_student(@student, {:grade => 10})
  @da_discussion.assignment.grade_student(@student, {:grade => 10})
  @da_assignment.grade_student(@student, {:grade => 10})
end

def create_da_assignment
  @da_assignment = @course.assignments.create!(
      :title => 'DA assignment',
      :points_possible => 10,
      :submission_types => 'online_text_entry',
      :only_visible_to_overrides => true
  )
end

def create_da_quiz
  @da_quiz = @course.quizzes.create!({
                                      :title => 'DA Quiz',
                                      :allowed_attempts => '2',
                                      :only_visible_to_overrides => true
                                     })
  @da_quiz.publish!
  @da_quiz
end

def create_da_discussion
  assignment = @course.assignments.create!(
      :title => 'DA assignment',
      :points_possible => 10,
      :due_at => Time.now + 2.day,
      :submission_types => 'online_text_entry',
      :only_visible_to_overrides => true)
  @da_discussion = @course.discussion_topics.create!(:title => 'DA Discussion', :assignment => assignment)
  @da_discussion
end

def submit_quiz(quizobject)
  user_session(@student)
  get "/courses/#{@course.id}/quizzes/#{quizobject.id}"
  f("#take_quiz_link").click
  wait_for_ajaximations
  f("#submit_quiz_button").click
end
