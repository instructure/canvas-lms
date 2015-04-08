require 'nokogiri'

class CourseLinkValidator

  TAG = "link_validation"

  # retrieves the validation job
  def self.current_progress(course)
    Progress.where(:tag => TAG, :context_type => 'Course', :context_id => course.id).last
  end

  # creates a new validation job
  def self.queue_course(course)
    progress = current_progress(course)
    return progress if progress && progress.pending?

    progress ||= Progress.new(:tag => TAG, :context => course)
    progress.reset!
    progress.process_job(self, :process)
    progress
  end

  def self.process(progress)
    validator = self.new(progress.context)
    validator.check_course(progress)
    progress.set_results({:issues => validator.issues, :completed_at => Time.now.utc})
  rescue
    report = ErrorReport.log_exception(:course_link_validation, $!)
    progress.workflow_state = 'failed'
    progress.set_results({:error_report_id => report.id, :completed_at => Time.now.utc})
  end

  attr_accessor :course, :issues, :visited_urls

  def initialize(course)
    self.course = course
    self.issues = []
    self.visited_urls = {}
  end

  # ****************************************************************
  # this is where the magic happens
  def check_course(progress)
    # Syllabus
    find_invalid_links(self.course.syllabus_body) do |links|
      self.issues << {:name => I18n.t(:syllabus, "Course Syllabus"), :type => :syllabus,
                 :content_url => "/courses/#{self.course.id}/assignments/syllabus"}.merge(:invalid_links => links)
    end
    progress.update_completion! 5

    # Assessment questions
    self.course.assessment_questions.active.each do |aq|
      check_question(aq)
    end
    progress.update_completion! 15

    # Assignments
    self.course.assignments.active.each do |assignment|
      find_invalid_links(assignment.description) do |links|
        self.issues << {:name => assignment.title, :type => :assignment,
                   :content_url => "/courses/#{self.course.id}/assignments/#{assignment.id}"}.merge(:invalid_links => links)
      end
    end
    progress.update_completion! 25

    # Calendar events
    self.course.calendar_events.active.each do |event|
      find_invalid_links(event.description) do |links|
        self.issues << {:name => event.title, :type => :calendar_event,
                   :content_url => "/courses/#{self.course.id}/calendar_events/#{event.id}"}.merge(:invalid_links => links)
      end
    end
    progress.update_completion! 35

    # Discussion topics
    self.course.discussion_topics.active.each do |topic|
      find_invalid_links(topic.message) do |links|
        self.issues << {:name => topic.title, :type => :discussion_topic,
                   :content_url => "/courses/#{self.course.id}/discussion_topics/#{topic.id}"}.merge(:invalid_links => links)
      end
    end
    progress.update_completion! 55

    # External URL Module items (almost forgot about these)
    self.course.context_module_tags.not_deleted.where(:content_type => "ExternalUrl").each do |ct|
      find_invalid_link(ct.url) do |invalid_link|
        self.issues << {:name => ct.title, :type => :module_item,
                   :content_url => "/courses/#{self.course.id}/modules"}.merge(:invalid_links => [invalid_link])
      end
    end
    progress.update_completion! 65

    # Quizzes
    self.course.quizzes.active.each do |quiz|
      find_invalid_links(quiz.description) do |links|
        self.issues << {:name => quiz.title, :type => :quiz,
                   :content_url => "/courses/#{self.course.id}/quizzes/#{quiz.id}"}.merge(:invalid_links => links)
      end
      quiz.quiz_questions.each do |qq|
        check_question(qq)
      end
    end
    progress.update_completion! 85

    # Wiki pages
    self.course.wiki.wiki_pages.not_deleted.each do |page|
      find_invalid_links(page.body) do |links|
        self.issues << {:name => page.title, :type => :wiki_page,
                   :content_url => "/courses/#{self.course.id}/pages/#{page.url}"}.merge(:invalid_links => links)
      end
    end
    progress.update_completion! 99
  end

  def check_question(question)
    # Assessment/Quiz Questions

    links = []
    [:question_text, :correct_comments_html, :incorrect_comments_html, :neutral_comments_html, :more_comments_html].each do |field|
      find_invalid_links(question.question_data[field]) do |field_links|
        links += field_links
      end
    end

    (question.question_data[:answers] || []).each_with_index do |answer, i|
      [:html, :comments_html, :left_html].each do |field|
        find_invalid_links(answer[field]) do |field_links|
          links += field_links
        end
      end
    end

    if links.any?
      hash = {:name => question.question_data[:question_name]}.merge(:invalid_links => links)
      case question
      when AssessmentQuestion
        hash[:type] = :assessment_question
        hash[:content_url] = "/courses/#{self.course.id}/question_banks/#{question.assessment_question_bank_id}#question_#{question.id}_question_text"
      when Quizzes::QuizQuestion
        hash[:type] = :quiz_question
        hash[:content_url] = "/courses/#{self.course.id}/quizzes/#{question.quiz_id}/take?preview=1#question_#{question.id}"
      end
      issues << hash
    end
  end

  # pretty much copied from ImportedHtmlConverter
  def find_invalid_links(html)
    links = []
    doc = Nokogiri::HTML(html || "")
    attrs = ['rel', 'href', 'src', 'data', 'value']

    doc.search("*").each do |node|
      attrs.each do |attr|
        url = node[attr]
        next unless url.present?
        if attr == 'value'
          next unless node['name'] && node['name'] == 'src'
        end

        find_invalid_link(url) do |invalid_link|
          links << invalid_link
        end
      end
    end

    yield links if links.any?
  end

  # yields a hash containing the url and an error type if the url is invalid
  def find_invalid_link(url)
    unless result = self.visited_urls[url]
      begin
        if ImportedHtmlConverter.relative_url?(url)
          if url =~ /\/courses\/\d+\/file_contents\/(.*)/
            rel_path = CGI.unescape($1)
            unless Folder.find_attachment_in_context_with_path(self.course, rel_path)
              result = :missing_file
            end
          end
        elsif !url.start_with?('mailto:')
          unless reachable_url?(url)
            result = :unreachable
          end
        end
      rescue URI::InvalidURIError
        result = :unparsable
      end
      result ||= :success
      self.visited_urls[url] = result
    end

    unless result == :success
      invalid_link = {:url => url, :reason => result}
      yield invalid_link
    end
  end

  # ping the url and make sure we get a 200
  def reachable_url?(url)
    begin
      CanvasHttp.get(url).is_a?(Net::HTTPOK)
    rescue CanvasHttp::Error
      false
    rescue
      false
    end
  end
end