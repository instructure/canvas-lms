class Quizzes::QuizSubmissionZipper < ContentZipper

  attr_reader :submissions, :attachments, :zip_attachment, :quiz, :filename

  def initialize(hash)
    super(hash)
    @quiz = hash.fetch :quiz
    @zip_attachment = hash.fetch :zip_attachment
    @submissions = find_submissions
    @attachments = find_attachments
    @filename = quiz_zip_filename quiz
  end

  def zip!
    @logger.debug("zipping into attachment: #{zip_attachment.id}")
    mark_attachment_as_zipping!(zip_attachment)
    make_zip_tmpdir(filename) do |zip_name|
      @logger.debug("creating #{zip_name}")
      Zip::File.open(zip_name, Zip::File::CREATE) do |zipfile|
        count = attachments_with_filenames.size
        attachments_with_filenames.each_with_index do |arr, idx|
          attachment, filename = arr
          mark_successful! if add_attachment_to_zip(attachment, zipfile, filename)
          update_progress(zip_attachment, idx, count)
        end
      end
      @logger.debug("added #{submissions.length} submissions")
      complete_attachment!(zip_attachment, zip_name)
    end
  end

  def attachments_with_filenames
    return @attachments_with_filenames if @attachments_with_filenames
    @attachments_with_filenames = []
    submissions.each do |submission|
      user = submission.user
      submission.submission_data.each do |sub_hash|
        next unless sub_hash[:attachment_ids].present?
        sub_hash[:attachment_ids].each do |id|
          attachment = attachments[id.to_i]
          @attachments_with_filenames <<
          question_attachment_filename(sub_hash, attachment, user)
        end
      end
    end
    @attachments_with_filenames
  end

  private
  def question_attachment_filename(question, attach, user)
    name = user.last_name_first.gsub(/_(\d+)_/, '-\1-')
    name = name + user.id.to_s
    name = name.gsub(/ /, "_").gsub(/[^-\w]/, "").downcase
    name = "#{name}_question_#{question[:question_id]}_#{attach.id}_#{attach.display_name}"
    [attach, name]
  end

  # TODO: Refactor me! This pattern is also used for Student Analysis CSVs.
  def find_attachments
    ids = submissions.map(&:submission_data).compact.flatten.select do |submission|
      submission[:attachment_ids].present?
    end.map do |submission|
      submission[:attachment_ids]
    end.flatten
    Attachment.where(:id => ids).inject({}) do |hash, attachment|
      hash[attachment.id] = attachment; hash
    end
  end

  def find_submissions
    submissions = quiz.quiz_submissions
    if zip_attachment.user && quiz.context.enrollment_visibility_level_for(zip_attachment.user) != :full
      visible_student_ids = quiz.context.enrollments_visible_to(zip_attachment.user).pluck(:user_id)
      submissions = submissions.where(:user_id => visible_student_ids)
    end
    @submissions = submissions.map(&:latest_submitted_attempt).compact
  end

  def quiz_zip_filename(quiz)
    "#{quiz.context.short_name_slug}-#{quiz.title} submissions"
  end

end
