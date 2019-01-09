#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
    progress.set_results({:issues => validator.issues, :completed_at => Time.now.utc, :version => 2})
  rescue
    report_id = Canvas::Errors.capture_exception(:course_link_validation, $ERROR_INFO)[:error_report]
    progress.workflow_state = 'failed'
    progress.set_results({error_report_id: report_id, completed_at: Time.now.utc})
  end

  attr_accessor :course, :domain_regex, :issues, :visited_urls

  def initialize(course)
    self.course = course
    domain = course.root_account.domain
    self.domain_regex = %r{\w+:?\/\/#{domain}\/} if domain
    self.issues = []
    self.visited_urls = {}
  end

  # ****************************************************************
  # this is where the magic happens
  def check_course(progress)
    # Course card image
    if self.course.image_url.present?
      find_invalid_link(self.course.image_url) do |link|
        self.issues << {:name => I18n.t("Course Card Image"), :type => :course_card_image,
                   :content_url => "/courses/#{self.course.id}/settings",
                   :invalid_links => [link.merge(:image => true)]}
      end
      progress.update_completion! 1
    end

    # Syllabus
    find_invalid_links(self.course.syllabus_body) do |links|
      self.issues << {:name => I18n.t(:syllabus, "Course Syllabus"), :type => :syllabus,
                 :content_url => "/courses/#{self.course.id}/assignments/syllabus"}.merge(:invalid_links => links)
    end
    progress.update_completion! 5

    # Assessment questions
    self.course.assessment_questions.active.each do |aq|
      next if aq.assessment_question_bank.deleted?
      check_question(aq)
    end
    progress.update_completion! 15

    # Assignments
    self.course.assignments.active.each do |assignment|
      next if assignment.quiz || assignment.discussion_topic
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
    invalid_module_links = {}
    self.course.context_module_tags.not_deleted.where(:content_type => "ExternalUrl").preload(:context_module).each do |ct|
      find_invalid_link(ct.url) do |invalid_link|
        (invalid_module_links[ct.context_module] ||= []) << invalid_link.merge(:link_text => ct.title)
      end
    end
    invalid_module_links.each do |mod, invalid_module_links|
      self.issues << {:name => mod.name, :type => :module,
                 :content_url => "/courses/#{self.course.id}/modules#module_#{mod.id}"}.merge(:invalid_links => invalid_module_links)
    end

    progress.update_completion! 65

    # Quizzes
    self.course.quizzes.active.each do |quiz|
      find_invalid_links(quiz.description) do |links|
        self.issues << {:name => quiz.title, :type => :quiz,
                   :content_url => "/courses/#{self.course.id}/quizzes/#{quiz.id}"}.merge(:invalid_links => links)
      end
      quiz.quiz_questions.active.each do |qq|
        check_question(qq)
      end
    end
    progress.update_completion! 85

    # Wiki pages
    self.course.wiki_pages.not_deleted.each do |page|
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
          link_text = node.text.presence
          invalid_link[:link_text] = link_text if link_text
          invalid_link[:image] = true if node.name == 'img'
          links << invalid_link
        end
      end
    end

    yield links if links.any?
  end

  ITEM_CLASSES = {
    'assignments' => Assignment,
    'announcements' => Announcement,
    'calendar_events' => CalendarEvent,
    'discussion_topics' => DiscussionTopic,
    'collaborations' => Collaboration,
    'files' => Attachment,
    'quizzes' => Quizzes::Quiz,
    'groups' => Group,
    'wiki' => WikiPage,
    'pages' => WikiPage,
    'modules' => ContextModule,
    'items' => ContentTag
  }

  # yields a hash containing the url and an error type if the url is invalid
  def find_invalid_link(url)
    return if url.start_with?('mailto:')
    unless result = self.visited_urls[url]
      begin
        if ImportedHtmlConverter.relative_url?(url) || (self.domain_regex && url.match(self.domain_regex))
          if valid_route?(url)
            if url.match(/\/courses\/(\d+)/) && self.course.id.to_s != $1
              result = :course_mismatch
            else
              result = check_object_status(url)
            end
          else
            result = :unreachable
          end
        else
          unless reachable_url?(url)
            result = :unreachable
          end
        end
      rescue URI::Error
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

  # checks against the Rails routes to see if the url matches anything
  def valid_route?(url)
    path = URI.parse(url).path
    path = path.chomp("/")

    @route_set ||= ::Rails.application.routes.set.routes.select{|r| r.verb === "GET"}
    @route_set.any?{|r| r.path.match(path)} || (!Pathname(path).each_filename.include?('..') && File.exists?(File.join(Rails.root, "public", path)))
  end

  # makes sure that links to course objects exist and are in a visible state
  def check_object_status(url)
    result = nil
    case url
    when /\/courses\/\d+\/file_contents\/(.*)/
      rel_path = CGI.unescape($1)
      unless (att = Folder.find_attachment_in_context_with_path(self.course, rel_path)) && !att.deleted?
        result = :missing_item
      end
    when /\/courses\/\d+\/(pages|wiki)\/([^\s"<'\?\/#]*)/
      if obj = self.course.wiki.find_page(CGI.unescape($2))
        if obj.workflow_state == 'unpublished'
          result = :unpublished_item
        end
      else
        result = :missing_item
      end
    when /\/courses\/\d+\/(.*)\/(\d+)/
      obj_type =  $1
      obj_id = $2

      if obj_class = ITEM_CLASSES[obj_type]
        if (obj_class == Attachment) && (obj = self.course.attachments.find_by_id(obj_id)) # attachments.find_by_id uses the replacement hackery
          if obj.file_state == 'deleted'
            result = :missing_item
          elsif obj.locked?
            result = :unpublished_item
          end
        elsif (obj = obj_class.where(:id => obj_id).first)
          if obj.workflow_state == 'deleted'
            result = :missing_item
          elsif obj.workflow_state == 'unpublished'
            result = :unpublished_item
          end
        else
          result = :missing_item
        end
      end
    end
    result
  end

  # ping the url and make sure we get a 200
  def reachable_url?(url)
    @unavailable_photo_redirect_pattern ||= Regexp.new(Setting.get('unavailable_photo_redirect_pattern', 'yimg\.com/.+/photo_unavailable.png$'))
    redirect_proc = lambda do |response|
      # flickr does a redirect to this file when a photo is deleted/not found;
      # treat this as a broken image instead of following the redirect
      url = response['Location']
      raise RuntimeError("photo unavailable") if url =~ @unavailable_photo_redirect_pattern
    end

    begin
      response = CanvasHttp.head(url, { "Accept-Encoding" => "gzip" }, redirect_limit: 9, redirect_spy: redirect_proc)
      if %w{404 405}.include?(response.code)
        response = CanvasHttp.get(url, { "Accept-Encoding" => "gzip" }, redirect_limit: 9, redirect_spy: redirect_proc) do
          # don't read the response body
        end
      end

      case response.code
      when /^2/ # 2xx code
        true
      when "401", "403", "503"
        # we accept unauthorized and forbidden codes here because sometimes servers refuse to serve our requests
        # and someone can link to a site that requires authentication anyway - doesn't necessarily make it invalid
        true
      else
        false
      end
    rescue
      false
    end
  end
end
