module MasterCourses
  def self.table_name_prefix
    'master_courses_'
  end

  # probably not be a comprehensive list but oh well
  ALLOWED_CONTENT_TYPES = %w{
    Announcement AssessmentQuestionBank Assignment Attachment CalendarEvent
    DiscussionTopic ContextExternalTool ContextModule LearningOutcome Quizzes::Quiz Rubric WikiPage
  }.freeze
end
