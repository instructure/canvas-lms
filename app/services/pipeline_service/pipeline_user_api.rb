module PipelineService
  class PipelineUserAPI
    include Api::V1::User
    attr_accessor :services_enabled, :context, :current_user, :params, :request
    def service_enabled?(service); @services_enabled.include? service; end

    def avatar_image_url(*args); "avatar_image_url(#{args.first})"; end

    def course_student_grades_url(course_id, user_id); ""; end

    def course_user_url(course_id, user_id); ""; end

    def initialize
      @domain_root_account = Account.default
      @params = {}
      @request = OpenStruct.new
    end
  end
end
