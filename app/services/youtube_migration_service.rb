# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class YoutubeMigrationService
  SUPPORTED_RESOURCES = [
    WikiPage.name,
    Quizzes::Quiz.name,
    Quizzes::QuizQuestion.name,
    AssessmentQuestion.name,
    DiscussionTopic.name,
    Announcement.name,
    DiscussionEntry.name,
    CalendarEvent.name,
    Assignment.name,
    "CourseSyllabus",
    Course.name,
  ].freeze
  NEW_QUIZZES_RESOURCES = %w[
    QuizzesNext::Quiz
    QuizzesNext::Bank
    QuizzesNext::Quiz:Item
    QuizzesNext::Quiz:Stimulus
    QuizzesNext::Bank:Item
    QuizzesNext::Bank:Stimulus
  ].freeze
  QUESTION_RCE_FIELDS = %i[
    question_text
    correct_comments_html
    incorrect_comments_html
    neutral_comments_html
    more_comments_html
  ].freeze
  SCAN_TAG = "youtube_embed_scan"
  CONVERT_TAG = "youtube_embed_convert"
  BULK_CONVERT_TAG = "youtube_embed_bulk_convert"
  STUDIO_LTI_TOOL_DOMAIN = "arc.instructure.com"
  STUCK_SCAN_THRESHOLD = 1.hour
  TIMEOUT_THRESHOLD = 3.hours
  MAX_RETRIES = 3

  class EmbedNotFoundError < StandardError; end
  class UnsupportedResourceTypeError < StandardError; end
  class ResourceNotFoundError < StandardError; end
  class StudioToolNotFoundError < StandardError; end

  def self.last_youtube_embed_scan_progress_by_course(course)
    Progress.where(tag: SCAN_TAG, context: course).last
  end

  def self.find_scan(course, scan_id)
    Progress.find_by!(tag: SCAN_TAG, context: course, id: scan_id)
  end

  def self.queue_scan_course_for_embeds(course)
    progress = Progress.where(tag: SCAN_TAG, context_type: "Course", context_id: course.id).last
    return progress if progress && (progress.pending? || progress.running?)

    progress = Progress.create!(tag: SCAN_TAG, context: course)

    # Use n_strand to make sure not monopolize the workpool
    n_strand = "youtube_embed_scan_#{course.global_id}"
    progress.process_job(self, :scan, { n_strand: })
    progress
  end

  def self.scan(progress)
    service = new(progress.context)
    resources_with_embeds = service.scan_course_for_embeds
    total_count = resources_with_embeds.values.sum { |resource| resource[:count] || 0 }

    if new_quizzes?(progress.context)
      progress.set_results({ resources: resources_with_embeds, total_count: })
      progress.wait_for_external_tool!
      call_external_tool(progress.context, progress.id)
    else
      progress.set_results({ resources: resources_with_embeds, total_count:, completed_at: Time.now.utc })
    end
  rescue
    report_id = Canvas::Errors.capture_exception(:youtube_embed_scan, $ERROR_INFO)[:error_report]
    progress.set_results({ error_report_id: report_id, completed_at: Time.now.utc })
  end

  def self.call_external_tool(course, scan_id)
    external_tool_id = course.assignments.active.type_quiz_lti.last.external_tool_tag.content_id
    payload = Struct.new(:scan_id, :canvas_id, :external_tool_id).new(
      scan_id,
      course.global_id,
      external_tool_id
    )
    Canvas::LiveEvents.scan_youtube_links(payload)
  end

  def self.new_quizzes?(course)
    Account.site_admin.feature_enabled?(:new_quizzes_scanning_youtube_links) && course.assignments.active.type_quiz_lti.any?
  end

  def resource_group_key_for(embed = nil, resource_type: nil, id: nil, resource_group_key: nil)
    if embed
      resource_type      = embed[:resource_type]
      id                 = embed[:id]
      resource_group_key = embed[:resource_group_key]
    end

    if NEW_QUIZZES_RESOURCES.include?(resource_type)
      YoutubeMigrationService.generate_resource_key(
        prepare_new_quiz_resource_type(resource_type),
        id
      )
    else
      resource_group_key || YoutubeMigrationService.generate_resource_key(resource_type, id)
    end
  end

  def self.generate_resource_key(type, id)
    "#{type}|#{id}"
  end

  attr_accessor :course

  def initialize(course)
    self.course = course
  end

  def validate_scan_exists!(scan_id)
    YoutubeMigrationService.find_scan(course, scan_id)
  rescue ActiveRecord::RecordNotFound
    raise EmbedNotFoundError, "Scan not found for id: #{scan_id}"
  end

  def validate_embed_exists_in_scan!(scan_id, embed)
    scan = YoutubeMigrationService.find_scan(course, scan_id)
    resource_group_key = resource_group_key_for(embed)

    return if scan.results.blank? || scan.results[:resources].blank?

    resource = scan.results[:resources][resource_group_key]
    raise EmbedNotFoundError, "Resource not found in scan for key: #{resource_group_key}" if resource.blank?

    embed_exists = resource[:embeds].any? do |scan_embed|
      scan_embed[:src] == embed[:src] &&
        scan_embed[:field].to_s == embed[:field].to_s &&
        scan_embed[:resource_type] == embed[:resource_type]
    end

    raise EmbedNotFoundError, "Embed not found in scan for resource: #{resource_group_key}" unless embed_exists
  end

  def prepare_new_quiz_resource_type(resource_type)
    case resource_type
    when /QuizzesNext::Quiz/
      "QuizzesNext::Quiz"
    when /QuizzesNext::Bank/
      "QuizzesNext::Bank"
    else
      resource_type
    end
  end

  def validate_supported_resource!(resource_type)
    supported = SUPPORTED_RESOURCES.include?(resource_type) || NEW_QUIZZES_RESOURCES.include?(resource_type)
    raise UnsupportedResourceTypeError, "Unsupported resource type: #{resource_type}" unless supported
  end

  def validate_resource_group_key!(resource_group_key)
    parts = resource_group_key.to_s.split("|")
    if parts.size != 2 || parts.any?(&:blank?)
      raise UnsupportedResourceTypeError, "Invalid resource group key: #{resource_group_key}"
    end
  end

  def validate_resource_exists!(resource_type, resource_id)
    # We don't store New Quizzes Data in Canvas, so we can't validate their existence
    return true if NEW_QUIZZES_RESOURCES.include?(resource_type)

    case resource_type
    when "WikiPage"
      course.wiki_pages.find(resource_id)
    when "Assignment"
      course.assignments.find(resource_id)
    when "DiscussionTopic", "Announcement"
      course.discussion_topics.find(resource_id)
    when "DiscussionEntry"
      DiscussionEntry.find(resource_id)
    when "CalendarEvent"
      course.calendar_events.find(resource_id)
    when "Quizzes::Quiz"
      course.quizzes.find(resource_id)
    when "Quizzes::QuizQuestion"
      Quizzes::QuizQuestion.find(resource_id)
    when "AssessmentQuestion"
      AssessmentQuestion.find(resource_id)
    when "CourseSyllabus", "Course"
      # For syllabus, the resource_id is the course id
      raise ResourceNotFoundError, "Course not found" unless course.id == resource_id
    else
      raise ResourceNotFoundError, "Cannot validate existence for resource type: #{resource_type}"
    end
  rescue ActiveRecord::RecordNotFound
    raise ResourceNotFoundError, "Resource not found for type: #{resource_type}, id: #{resource_id}"
  end

  def convert_embed(scan_id, embed, user_uuid: nil)
    validate_scan_exists!(scan_id)
    validate_supported_resource!(embed[:resource_type])

    resource_group_key = embed[:resource_group_key] || YoutubeMigrationService.generate_resource_key(embed[:resource_type], embed[:id])
    validate_resource_group_key!(resource_group_key)
    validate_embed_exists_in_scan!(scan_id, embed)
    validate_resource_exists!(embed[:resource_type], embed[:id])

    message = YoutubeMigrationService.generate_resource_key(embed[:resource_type], embed[:id])
    # TODO: Something will listen on this creation
    convert_progress = Progress.create!(tag: CONVERT_TAG, context: course, message:, results: { original_embed: embed })

    job_priority = Account.site_admin.feature_enabled?(:youtube_migration_high_priority) ? Delayed::HIGH_PRIORITY : Delayed::LOW_PRIORITY
    n_strand = "youtube_embed_convert_#{course.global_id}_#{resource_group_key}"
    convert_progress.process_job(YoutubeMigrationService, :perform_conversion, { n_strand:, priority: job_priority }, course.id, scan_id, embed, user_uuid:)
    convert_progress
  end

  def convert_all_embeds(scan_progress_id)
    scan_progress = YoutubeMigrationService.find_scan(course, scan_progress_id)
    convert_selected_embeds(scan_progress.results[:resources].values.flat_map { |r| r[:embeds] }, scan_progress.id)
  end

  def convert_selected_embeds(embeds_list, scan_progress_id)
    total_embeds = embeds_list.size
    return nil if total_embeds.zero?

    convert_progress = Progress.create!(
      tag: BULK_CONVERT_TAG,
      context: course,
      message: "Converting #{total_embeds} YouTube embeds",
      results: {
        scan_progress_id:,
        total_embeds:,
        completed_embeds: 0,
        failed_embeds: 0,
        errors: []
      }
    )

    n_strand = "youtube_embed_bulk_convert_#{convert_progress.id}"
    convert_progress.process_job(YoutubeMigrationService, :perform_selected_conversions, { n_strand: }, course.id, scan_progress_id)
    convert_progress
  end

  def self.perform_conversion(progress, course_id, scan_id, embed, user_uuid: nil)
    course = Course.find(course_id)
    service = new(course)
    scan_progress = YoutubeMigrationService.find_scan(course, scan_id)

    studio_tool = service.find_studio_tool
    if studio_tool.nil?
      progress.set_results({
                             error: "Studio LTI tool not found for account",
                             completed_at: Time.now.utc
                           })
      return
    end

    studio_embed_html = service.convert_youtube_to_studio(embed, studio_tool, user_uuid:)
    service.update_resource_content(embed, studio_embed_html)
    service.mark_embed_as_converted(scan_progress, embed)
    progress.set_results({
                           success: true,
                           studio_tool_id: studio_tool.id,
                           completed_at: Time.now.utc
                         })
  rescue => e
    report_id = Canvas::Errors.capture_exception(:youtube_embed_convert, e)[:error_report]
    progress.set_results({ error_report_id: report_id, completed_at: Time.now.utc })
  end

  def self.perform_all_conversions(progress, course_id, scan_progress_id)
    results = progress.results.dup

    begin
      course = Course.find(course_id)
      service = new(course)
      studio_tool = service.find_studio_tool
      if studio_tool.nil?
        results[:error] = "Studio LTI tool not found for account"
        results[:completed_at] = Time.now.utc
        progress.set_results(results)
        return
      end
      scan_progress = YoutubeMigrationService.find_scan(course, scan_progress_id)

      all_embeds = []
      scan_progress.results[:resources]&.each_value do |resource_data|
        resource_data[:embeds]&.each do |embed|
          all_embeds << embed
        end
      end
      scan_progress.save

      service.perform_embed_list_conversion(progress, scan_progress, studio_tool)
    rescue => e
      report_id = Canvas::Errors.capture_exception(:youtube_embed_bulk_convert, e)[:error_report]
      results[:error_report_id] = report_id
      results[:completed_at] = Time.now.utc
      progress.set_results(results)
    end
  end

  def self.perform_selected_conversions(progress, course_id, scan_progress_id)
    course = Course.find(course_id)
    service = new(course)
    studio_tool = service.find_studio_tool
    if studio_tool.nil?
      results = progress.results.dup
      results[:error] = "Studio LTI tool not found for account"
      results[:completed_at] = Time.now.utc
      progress.set_results(results)
      return
    end
    scan_progress = YoutubeMigrationService.find_scan(course, scan_progress_id)

    service.perform_embed_list_conversion(progress, scan_progress, studio_tool)
  rescue => e
    report_id = Canvas::Errors.capture_exception(:youtube_embed_bulk_convert, e)[:error_report]
    results = progress.results.dup
    results[:error_report_id] = report_id
    results[:completed_at] = Time.now.utc
    progress.set_results(results)
  end

  def perform_embed_list_conversion(progress, scan_progress, studio_tool)
    embeds_list = scan_progress.results[:resources].values.flat_map { |r| r[:embeds] }
    results = progress.results.dup
    completed_embeds = results[:completed_embeds] || 0
    failed_embeds = results[:failed_embeds] || 0
    errors = results[:errors] || []
    total_embeds = results[:total_embeds] || embeds_list.size

    embeds_list.each do |embed|
      begin
        studio_embed_html = convert_youtube_to_studio(embed, studio_tool)
        update_resource_content(embed, studio_embed_html)
        mark_embed_as_converted(scan_progress, embed)

        completed_embeds += 1
      rescue => e
        failed_embeds += 1
        error_report = Canvas::Errors.capture_exception(:youtube_embed_bulk_convert, e)
        error_info = {
          embed_src: embed[:src],
          resource_type: embed[:resource_type],
          resource_id: embed[:id],
          error_report_id: error_report[:error_report],
          error_message: e.message
        }
        errors << error_info
      end

      results.merge!({
                       completed_embeds:,
                       failed_embeds:,
                       errors:,
                       progress_percentage: ((completed_embeds + failed_embeds).to_f / total_embeds * 100).round(2)
                     })
      progress.set_results(results)
    end

    results.merge!({
                     success: failed_embeds == 0,
                     completed_embeds:,
                     failed_embeds:,
                     errors:,
                     progress_percentage: ((completed_embeds + failed_embeds).to_f / total_embeds * 100).round(2),
                     completed_at: Time.now.utc
                   })
    progress.set_results(results)
  end

  def scan_course_for_embeds
    resources_with_embeds = {}

    course.wiki_pages.not_deleted.find_each do |page|
      common_hash = {
        name: page.title,
        id: page.id,
        type: page.class.name,
        content_url: "/courses/#{course.id}/pages/#{page.url}",
      }

      embeds, error = scan_resource(page, :body, page.body)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.quizzes.active.preload(:quiz_questions).except(:order).find_each do |quiz|
      common_hash = {
        name: quiz.title,
        id: quiz.id,
        type: quiz.class.name,
        content_url: "/courses/#{course.id}/quizzes/#{quiz.id}",
      }

      description_embeds, description_error = scan_resource(quiz, :description, quiz.description)

      resource_group_key = YoutubeMigrationService.generate_resource_key(quiz.class.name, quiz.id)

      questions_embeds_with_errors = quiz.quiz_questions
                                         .active
                                         .without_assessment_question_association
                                         .flat_map do |question|
        QUESTION_RCE_FIELDS.map do |field|
          embeds, error = scan_resource(question, field, question.question_data[field], resource_group_key)
          [embeds, error]
        end
      end

      embeds = (description_embeds + questions_embeds_with_errors.flat_map(&:first)).flatten
      errors = [description_error, questions_embeds_with_errors.flat_map(&:second)].flatten.compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.assessment_questions.active.preload(:assessment_question_bank).except(:order).find_each do |assessment_question|
      next if assessment_question.assessment_question_bank.deleted?

      common_hash = {
        name: assessment_question.question_data[:question_name],
        id: assessment_question.id,
        type: assessment_question.class.name,
        content_url: "/courses/#{course.id}/question_banks/#{assessment_question.assessment_question_bank_id}#question_#{assessment_question.id}_question_text",
      }

      questions_embeds_with_errors = QUESTION_RCE_FIELDS.map do |field|
        embeds, error = scan_resource(assessment_question, field, assessment_question.question_data[field])
        [embeds, error]
      end

      embeds = questions_embeds_with_errors.flat_map(&:first)
      errors = questions_embeds_with_errors.flat_map(&:second).compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.discussion_topics.active.except(:order).find_each do |topic|
      common_hash = {
        name: topic.title,
        id: topic.id,
        type: topic.class.name,
        content_url: "/courses/#{course.id}/discussion_topics/#{topic.id}",
      }

      resource_group_key = YoutubeMigrationService.generate_resource_key(topic.class.name, topic.id)

      entry_embeds_with_errors = topic.discussion_entries.active.map do |entry|
        embeds, error = scan_resource(entry, :message, entry.message, resource_group_key)
        [embeds, error]
      end

      message_embeds, message_error = scan_resource(topic, :message, topic.message)

      embeds = (message_embeds + entry_embeds_with_errors.flat_map(&:first)).flatten
      errors = [message_error, entry_embeds_with_errors.flat_map(&:second)].flatten.compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.calendar_events.active.find_each do |event|
      common_hash = {
        name: event.title,
        id: event.id,
        type: event.class.name,
        content_url: "/courses/#{course.id}/calendar_events/#{event.id}",
      }

      embeds, error = scan_resource(event, :description, event.description)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    course.assignments.active.except(:order).find_each do |assignment|
      next if assignment.submission_types.include?("online_quiz") ||
              assignment.submission_types.include?("discussion_topic") ||
              assignment.submission_types.include?("external_tool")

      common_hash = {
        name: assignment.title,
        id: assignment.id,
        type: assignment.class.name,
        content_url: "/courses/#{course.id}/assignments/#{assignment.id}",
      }

      embeds, error = scan_resource(assignment, :description, assignment.description)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    if course.syllabus_body
      common_hash = {
        name: I18n.t(:syllabus, "Course Syllabus"),
        type: "Course",
        id: course.id,
        content_url: "/courses/#{course.id}/assignments/syllabus"
      }

      embeds, error = scan_resource(course, :syllabus_body, course.syllabus_body)
      errors = [error].compact

      add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    end

    # TODO: include outcomes
    # TODO: include grade comments

    resources_with_embeds
  end

  def find_studio_tool
    Course.find_studio_tool(course)
  end

  def convert_youtube_to_studio(embed, studio_tool, user_uuid: nil)
    studio_url_domain = studio_tool.url
    uri = URI.parse(studio_url_domain)
    studio_url = "#{uri.scheme}://#{uri.host}"

    account = course.account
    token = CanvasSecurity::ServicesJwt.generate({ sub: account.uuid, user_uuid: }, false, encrypt: false)
    headers = { "Authorization" => "Bearer #{token}" }

    body = {
      "url" => embed[:src],
      "course_id" => course.id,
      "course_name" => course.name
    }

    api_url = "#{studio_url}/api/internal/youtube_embed"

    response = CanvasHttp.post(api_url, headers, body: body.to_json, content_type: "application/json")

    if response.is_a?(Net::HTTPSuccess)
      response_data = JSON.parse(response.body)
      generate_studio_iframe_html(response_data, embed)
    else
      raise "Studio API request failed with status: #{response.code}. Response: #{response.body}"
    end
  end

  def generate_studio_iframe_html(studio_response, original_embed = nil)
    studio_embed_url = studio_response["embed_url"] || studio_response["url"]
    launch_url = "/courses/#{course.id}/external_tools/retrieve?display=borderless&url=#{CGI.escape(studio_embed_url)}"
    video_title = studio_response["title"] || "Studio Video"

    width = original_embed&.dig(:width) || "560"
    height = original_embed&.dig(:height) || "315"

    <<~HTML.strip
      <iframe class="lti-embed"
              style="width: #{width}px; height: #{height}px;"
              title="#{video_title}"
              src="#{launch_url}"
              width="#{width}"
              height="#{height}"
              allowfullscreen="allowfullscreen"
              webkitallowfullscreen="webkitallowfullscreen"
              mozallowfullscreen="mozallowfullscreen"
              allow="geolocation *; microphone *; camera *; midi *; encrypted-media *; autoplay *; clipboard-write *; display-capture *"
              data-studio-resizable="false"
              data-studio-tray-enabled="false"
              data-studio-convertible-to-link="true">
      </iframe>
    HTML
  end

  def update_resource_content(embed, new_html)
    resource_type = embed[:resource_type]
    resource_id = embed[:id]
    field = embed[:field]

    # If the resource is a New Quizzes resource, emit an event and return
    if NEW_QUIZZES_RESOURCES.include?(resource_type)
      Canvas::LiveEvents.convert_new_quiz_youtube_link(
        Struct.new(:resource_id, :resource_type, :src, :field, :new_html).new(
          embed[:content_id], resource_type, embed[:src], field, new_html
        )
      )
      return
    end

    case resource_type
    when "WikiPage"
      resource = course.wiki_pages.find(resource_id)
      resource.body = replace_youtube_embed_in_html(resource.body, embed, new_html)
    when "Assignment"
      resource = course.assignments.find(resource_id)
      resource.description = replace_youtube_embed_in_html(resource.description, embed, new_html)
    when "DiscussionTopic"
      resource = course.discussion_topics.find(resource_id)
      resource.message = replace_youtube_embed_in_html(resource.message, embed, new_html)
    when "Announcement"
      resource = course.announcements.find(resource_id)
      resource.message = replace_youtube_embed_in_html(resource.message, embed, new_html)
    when "DiscussionEntry"
      resource = DiscussionEntry.find(resource_id)
      resource.message = replace_youtube_embed_in_html(resource.message, embed, new_html)
    when "CalendarEvent"
      resource = course.calendar_events.find(resource_id)
      resource.description = replace_youtube_embed_in_html(resource.description, embed, new_html)
    when "Course"
      resource = course
      resource.syllabus_body = replace_youtube_embed_in_html(resource.syllabus_body, embed, new_html)
    when "AssessmentQuestion"
      # AssessmentQuestion does not include LinkedAttachmentHandler
      resource = course.assessment_questions.find(resource_id)
      question_data = resource.question_data.dup
      question_data[field] = replace_youtube_embed_in_html(question_data[field], embed, new_html) if question_data[field]
      resource.question_data = question_data
    when "Quizzes::QuizQuestion"
      resource = Quizzes::QuizQuestion.find(resource_id)
      question_data = resource.question_data.dup
      question_data[field] = replace_youtube_embed_in_html(question_data[field], embed, new_html) if question_data[field]
      resource.question_data = question_data
    when "Quizzes::Quiz"
      resource = course.quizzes.find(resource_id)
      if field == :description
        resource.description = replace_youtube_embed_in_html(resource.description, embed, new_html)
      else
        raise "Quiz field #{field} not supported for conversion"
      end
    else
      raise "Unsupported resource type for conversion: #{resource_type}"
    end
    resource.skip_attachment_association_update = true
    resource.save!
  end

  def replace_youtube_embed_in_html(html, embed, new_html)
    return html if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    iframe = find_youtube_iframe_by_src(doc, embed[:src])

    if iframe
      new_iframe = Nokogiri::HTML::DocumentFragment.parse(new_html).children.first
      iframe.replace(new_iframe)
    end

    doc.to_html
  end

  def find_youtube_iframe_by_src(doc, src)
    doc.css("iframe").find { |iframe| iframe["src"] == src }
  end

  def add_resource_with_embeds(resources_with_embeds, common_hash, embeds, errors)
    key = YoutubeMigrationService.generate_resource_key(common_hash[:type], common_hash[:id])
    unless embeds.none? && errors.none?
      resources_with_embeds[key] = {
        **common_hash,
        count: embeds.count,
        embeds:,
        errors:
      }
    end
  end

  def scan_resource(model, field, html, resource_group_key = nil)
    embeds = YoutubeEmbedScanner.embeds_from_html(html)
    [embeds.map { |embed| embed.merge({ id: model.id, resource_type: model.class.name, field:, resource_group_key: }.compact) }, nil]
  rescue
    [[], { id: model.id, resource_type: model.class.name, field: }]
  end

  def mark_embed_as_converted(scan_progress, embed)
    key = resource_group_key_for(embed)
    resource = scan_progress.results[:resources][key]
    found_embed, index = resource[:embeds].each_with_index.find do |resource_embed, _|
      embed[:path].to_s == resource_embed[:path].to_s &&
        embed[:field].to_s == resource_embed[:field].to_s &&
        embed[:resource_type].to_s == resource_embed[:resource_type].to_s &&
        embed[:id].to_s == resource_embed[:id].to_s &&
        embed[:resource_group_key].to_s == resource_embed[:resource_group_key].to_s &&
        (embed[:content_id].to_s.presence || "") ==
          (resource_embed[:content_id].to_s.presence || "")
    end

    if found_embed
      was_already_converted = resource[:embeds][index][:converted] == true

      unless was_already_converted
        resource[:embeds][index][:converted] = true
        resource[:embeds][index][:converted_at] = Time.now.utc
        resource[:converted_count] = (resource[:converted_count] || 0) + 1
        scan_progress.results[:total_converted] = (scan_progress.results[:total_converted] || 0) + 1
        scan_progress.results[:total_count] = [scan_progress.results[:total_count] - 1, 0].max
      end

      scan_progress.results[:resources][key] = resource
      scan_progress.save!
    else
      raise EmbedNotFoundError, "Embed not found for resource type: #{embed[:resource_type]}, id: #{embed[:id]}, src: #{embed[:src]}"
    end
  end

  def process_new_quizzes_scan_update(scan_id, new_quizzes_scan_status:, new_quizzes_scan_results: {})
    progress = self.class.find_scan(course, scan_id)
    results = progress.results || {}
    results[:new_quizzes_scan_status] = new_quizzes_scan_status

    begin
      if new_quizzes_scan_status == "completed"
        scan_results = (new_quizzes_scan_results || {}).deep_symbolize_keys
        new_quizzes_resources = {}

        resources_array = scan_results[:resources] || []
        resources_array.each do |resource|
          key = YoutubeMigrationService.generate_resource_key(resource[:type], resource[:id])
          new_quizzes_resources[key] = resource
        end

        merged_resources = (results[:resources] || {}).merge(new_quizzes_resources)
        merged_total_count = (results[:total_count] || 0).to_i + (scan_results[:total_count] || 0).to_i

        results[:resources] = merged_resources
        results[:total_count] = merged_total_count
      end

      results[:completed_at] = Time.now.utc
      progress.set_results(results)
      progress.complete! if progress.waiting_for_external_tool?
    rescue => e
      results[:new_quizzes_scan_status] = "failed"
      results[:completed_at] = Time.now.utc
      progress.set_results(results)
      progress.complete! if progress.waiting_for_external_tool?

      Canvas::Errors.capture(:youtube_migration_new_quizzes_scan_error, {
                               course_id: course.id,
                               scan_id: progress.id,
                               error: e.message,
                               message: "Error processing new quizzes scan update"
                             })
    end
  end

  def reset_scan_status
    stuck_progress = Progress.find_by(tag: SCAN_TAG, context: course, workflow_state: "waiting_for_external_tool")
    return unless stuck_progress

    results = (stuck_progress.results || {}).dup
    results[:new_quizzes_scan_status] = "failed"
    results[:completed_at] = Time.now.utc

    stuck_progress.set_results(results)

    stuck_progress.complete!
  end

  def self.process_stuck_scans
    Rails.logger.info("[YouTube Scan Retry] Checking for stuck scans")
    return unless Account.site_admin.feature_enabled?(:new_quizzes_scanning_youtube_links)

    stuck_scans = Progress.where(
      tag: SCAN_TAG,
      workflow_state: "waiting_for_external_tool",
      context_type: "Course"
    ).where(created_at: ..STUCK_SCAN_THRESHOLD.ago).preload(:context)

    Rails.logger.info("[YouTube Scan Retry] Found #{stuck_scans.count} stuck scans")

    stuck_scans.find_each do |progress|
      progress.with_lock do
        # Re-check state after acquiring lock to prevent race conditions
        next unless progress.waiting_for_external_tool?

        if progress.created_at <= TIMEOUT_THRESHOLD.ago || progress.results&.dig(:retry_count).to_i >= MAX_RETRIES
          timeout_scan(progress)
        else
          Rails.logger.info("[YouTube Scan Retry] Should retry scan? #{should_retry_scan?(progress)}")
          retry_scan(progress) if should_retry_scan?(progress)
        end
      end
    rescue => e
      Canvas::Errors.capture_exception(:youtube_scan_retry, e, {
                                         progress_id: progress.id,
                                         course_id: progress.context_id
                                       })
    end
  end

  def self.should_retry_scan?(progress)
    results = progress.results || {}
    last_retry = results[:last_retry_at]

    return true if last_retry.nil?

    Time.parse(last_retry.to_s).utc < STUCK_SCAN_THRESHOLD.ago
  end

  def self.retry_scan(progress)
    results = (progress.results || {}).dup
    results[:retry_count] = (results[:retry_count] || 0) + 1
    results[:last_retry_at] = Time.now.utc

    progress.set_results(results)

    call_external_tool(progress.context, progress.id)

    Rails.logger.info("[YouTube Scan Retry] Re-emitted Live Event for scan_id=#{progress.id}, course_id=#{progress.context_id}, retry_count=#{results[:retry_count]}")
  end

  def self.timeout_scan(progress)
    results = (progress.results || {}).dup
    results[:new_quizzes_scan_status] = "timeout"
    results[:error] = "Timed out waiting for New Quizzes scan results after 3 hours"
    results[:completed_at] = Time.now.utc
    results[:timeout_at] = Time.now.utc

    progress.set_results(results)
    progress.complete!

    Rails.logger.warn("[YouTube Scan Retry] Timed out scan_id=#{progress.id}, course_id=#{progress.context_id}")
  end
end
