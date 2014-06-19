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

    unless @poll = Polling::Poll.find(id)
      raise ActiveRecord::RecordNotFound.new('Poll not found')
    end

    @poll
  end

  def require_poll_session
    id = params[:poll_session_id]

    unless @poll_session = @poll.poll_sessions.find(id)
      raise ActiveRecord::RecordNotFound.new('Poll session not found')
    end

    @poll_session
  end
end
