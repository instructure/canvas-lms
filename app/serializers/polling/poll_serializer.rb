module Polling
  class PollSerializer < Canvas::APISerializer
    attributes :id, :title, :description
    
    has_many :poll_choices, embed: :ids

    def_delegators :object, :course
    def_delegators :@controller, :api_v1_course_poll_choices_url

    def poll_choices_url
      api_v1_course_poll_choices_url(course, object)
    end
  end
end
