module CanvasEmberUrl
  class UrlMappings
    def initialize(mappings = [])
      @mappings = mappings
    end

    # quiz urls are built off the base url passed in
    def course_quizzes_url
      @mappings[:course_quizzes]
    end

    def course_quiz_url(id, options={})
      headless = '?headless=1' if options[:headless]
      "#{course_quizzes_url}#{headless}#/#{id}"
    end

    def course_quiz_preview_url(id)
      "#{course_quiz_url(id)}/preview"
    end

    def course_quiz_moderate_url(id)
      "#{course_quiz_url(id)}/moderate"
    end

    def course_quiz_statistics_url(id)
      "#{course_quiz_url(id)}/statistics"
    end
  end
end
