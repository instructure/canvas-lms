class GradesPresenter
  def initialize(enrollments)
    @enrollments = enrollments
  end

  def student_enrollments
    @student_enrollments ||= begin
      current_enrollments.select { |e| e.student? }.index_by { |e| e.course }
    end
  end

  def observed_enrollments
    @observed_enrollments ||= begin
      observer_enrollments.map { |e|
        e.shard.activate do
          StudentEnrollment.active.where(user_id: e.associated_user_id, course_id: e.course_id).first
        end
      }.uniq.compact
    end
  end

  def course_grade_summaries
    @course_grade_summaries ||= begin
      teacher_enrollments.each_with_object({}) do |e, hash|
        hash[e.course_id] = e.shard.activate do
          Rails.cache.fetch(['computed_avg_grade_for', e.course].cache_key) do
            student_enrollments = e.course.student_enrollments.not_fake.preload(:scores)
            current_scores = student_enrollments.group_by(&:user_id).map do |_, enrollments|
              enrollments.max(&:computed_current_score).computed_current_score
            end.compact
            score = (current_scores.sum.to_f * 100.0 / current_scores.length.to_f).round.to_f / 100.0 rescue nil
            {:score => score, :students => current_scores.length }
          end
        end
      end
    end
  end

  def teacher_enrollments
    @teacher_enrollments ||= current_enrollments.select { |e| e.instructor? }.index_by { |e| e.course }.values
  end

  def prior_enrollments
    []
  end

  def has_single_enrollment?
    student_enrollments.length + teacher_enrollments.length + observed_enrollments.length == 1
  end

  def single_enrollment
    student_enrollments.values.first || teacher_enrollments.first || observed_enrollments.first
  end

  private

  def observer_enrollments
    @observer_enrollments ||= begin
      current_enrollments.select { |e| e.is_a?(ObserverEnrollment) && e.associated_user_id }
    end
  end

  def current_enrollments
    @current_enrollments ||= begin
      @enrollments.select { |e| e.state_based_on_date == :active }
    end
  end

end
