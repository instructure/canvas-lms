module Canvas
  module Help
    def self.default_links
      [
        {
          :available_to => ['student'],
          :text => I18n.t('#help_dialog.instructor_question', 'Ask Your Instructor a Question'),
          :subtext => I18n.t('#help_dialog.instructor_question_sub', 'Questions are submitted to your instructor'),
          :url => '#teacher_feedback'
        },
        {
          :available_to => ['user', 'student', 'teacher', 'admin'],
          :text => I18n.t('#help_dialog.search_the_canvas_guides', 'Search the Canvas Guides'),
          :subtext => I18n.t('#help_dialog.canvas_help_sub', 'Find answers to common questions'),
          :url => 'http://guides.instructure.com'
        },
        {
          :available_to => ['user', 'student', 'teacher', 'admin'],
          :text => I18n.t('#help_dialog.report_problem', 'Report a Problem'),
          :subtext => I18n.t('#help_dialog.report_problem_sub', 'If Canvas misbehaves, tell us about it'),
          :url => '#create_ticket'
        }
      ]
    end
  end
end
