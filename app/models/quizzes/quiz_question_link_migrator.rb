module Quizzes::QuizQuestionLinkMigrator
  QUESTION_FIELDS = [
    :question_text,
    :correct_comments,
    :incorrect_comments,
    :neutral_comments
  ]

  BAD_LINK_REGEX = %r{/courses/(\d+)/files/\d+/[^'" ]*}

  CANDIDATE_LINK_REGEX_TEMPLATE = %{/assessment_questions/%d/files/(?:%s)/[^'" ]*}

  def self.log(question, link, message)
    ActiveRecord::Base.logger.warn "<Quizzes::QuizQuestionLinkMigrator> " \
      "[created: #{question.created_at.utc.iso8601} question: #{question.id}] " \
    "(#{link}) #{message}"
  end

  def self.for_each_interesting_field(question_data)
    return unless question_data
    QUESTION_FIELDS.each do |field_name|
      yield question_data[field_name] if question_data[field_name].present?
    end
    if question_data[:answers]
      question_data[:answers].each do |answer|
        yield answer[:comments] if answer[:comments].present?
      end
    end
  end

  def self.related_attachment_ids(file_id)
    # find the list of ids of copies of the file from the link
    attachment_ids = [file_id]
    file = Attachment.where(id: file_id).first
    return attachment_ids unless file
    if file.cloned_item_id
      copies = Attachment.where(cloned_item_id: file.cloned_item_id).pluck(:id)
      attachment_ids.concat(copies)
    end
    root_file_id = file.root_attachment_id || file_id
    copies = Attachment.where(root_attachment_id: root_file_id).pluck(:id)
    attachment_ids.concat(copies)
    attachment_ids << root_file_id
    return attachment_ids.uniq
  end

  def self.uncached_migrate_file_link(question, link)
    # make sure we have an assessment question to look for replacement links in
    if question.assessment_question.nil?
      if question.question_data[:question_type] == 'text_only_question'
        log(question, link, "missing AssessmentQuestion (expected, text_only_question)")
      else
        log(question, link, "missing AssessmentQuestion (unexpected)")
      end
      return link
    end

    # look for links for related files in the assessment question
    file_id = link.scan(%r{/files/(\d+)/}).first.first.to_i
    candidate_link_regex = CANDIDATE_LINK_REGEX_TEMPLATE %
      [ question.assessment_question.id, related_attachment_ids(file_id).join('|') ]
    candidate_link_regex = Regexp.new(candidate_link_regex)
    candidates = []
    source_data = question.assessment_question.question_data
    for_each_interesting_field(source_data) do |field|
      candidates.concat(field.scan(candidate_link_regex))
    end

    if candidates.empty?
      log(question, link, "no replacement link found in AssessmentQuestion")
      return link
    end

    # use first such link (and cache), but warn if there are others
    new_link = candidates.shift
    unless candidates.empty?
      log(question, link, "multiple replacement links found in AssessmentQuestion")
    end

    log(question, link, "translated to #{new_link}")
    return new_link
  end

  def self.reset_cache!
    @cached_link_migrations = {}
  end

  def self.migrate_file_link(question, link)
    # check for an existing translation we already figured out
    @cached_link_migrations ||= {}
    @cached_link_migrations[question.id] ||= {}
    cache = @cached_link_migrations[question.id]
    if cache[link]
      log(question, link, "using cached value #{cache[link]}")
    else
      cache[link] = uncached_migrate_file_link(question, link)
    end
    return cache[link]
  end

  # the following 'migrate_file_links_in_*' methods operate on their target
  # argument in place, and return true iff something was changed.
  def self.migrate_file_links_in_blob(blob, question, quiz)
    return unless blob && question && quiz
    expected_course_id = quiz.context_id
    changed = false
    blob.gsub!(BAD_LINK_REGEX) do |link|
      if $1.to_i == expected_course_id
        link
      else
        new_link = migrate_file_link(question, link)
        changed = true unless new_link == link
        new_link
      end
    end
    changed
  end

  def self.migrate_file_links_in_question_data(question_data, context={})
    return unless question_data
    changed = false
    question = context[:question] || Quizzes::QuizQuestion.includes(:quiz, :assessment_question).where(id: question_data[:id]).first
    return unless question
    quiz = context[:quiz] || question.quiz
    for_each_interesting_field(question_data) do |field|
      changed = true if migrate_file_links_in_blob(field, question, quiz)
    end
    changed
  end

  def self.migrate_file_links_in_question(question)
    return unless question
    migrate_file_links_in_question_data(question.question_data, :question => question)
  end

  def self.migrate_file_links_in_quiz(quiz)
    return unless quiz && quiz.quiz_data
    changed = false
    quiz.quiz_data.each do |quiz_item|
      if quiz_item[:question_type]
        changed = true if migrate_file_links_in_question_data(quiz_item, :quiz => quiz)
      elsif quiz_item[:entry_type] == 'quiz_group'
        next unless quiz_item[:questions]
        quiz_item[:questions].each do |question_data|
          changed = true if migrate_file_links_in_question_data(question_data, :quiz => quiz)
        end
      end
    end
    changed
  end
end
