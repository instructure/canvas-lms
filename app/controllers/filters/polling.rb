module Filters::Polling
  protected

  def require_course
    id = params.has_key?(:course_id) ? params[:course_id] : params[:id]
    unless @course = Course.find(id)
      raise ActiveRecord::RecordNotFound.new('Course not found')
    end

    @course
  end

  def require_poll
    id = params.has_key?(:poll_id) ? params[:poll_id] : params[:id]

    unless @poll = @course.polls.find(id)
      raise ActiveRecord::RecordNotFound.new('Poll not found')
    end

    @poll
  end
end
