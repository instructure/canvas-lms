module Wiziq

  class AgliveComUtil
    attr_reader :api_request, :api_method, :attendee_url

    def initialize(api_method)
      @api_method = api_method
      @api_request = BaseRequestBuilder.new(api_method)
    end

    def schedule_class(wiziq_class_hash)
      @api_request.add_params wiziq_class_hash
      response_data = ResponseData.new(@api_request.send_api_request)
      return response_data.parse_schedule_class_response
    end

    def add_attendee_to_session(class_id, attendee_id, screen_name)
      attendee_util = AttendeeUtil.new
      attendee_util.add_attendee(attendee_id, screen_name)
      @api_request.add_params(
        ApiConstants::ParamsAddAttendee::CLASS_ID => class_id,
        ApiConstants::ParamsAddAttendee::ATTENDEE_XML => attendee_util.get_attendee_xml
      )
      response_data = ResponseData.new(@api_request.send_api_request)
      return response_data.parse_add_attendee_response
    end

    def get_wiziq_class_status(class_id)
      get_class_info(class_id,
                     [ApiConstants::ListColumnOptions::STATUS,
                      ApiConstants::ListColumnOptions::TIME_TO_START])
    end

    def get_class_presenter_info(class_id)
      get_class_info(class_id, [ApiConstants::ListColumnOptions::PRESENTER_URL])
    end

    private

    def get_class_info(class_id, columns=[])
      @api_request.add_param(ApiConstants::ParamsList::CLASS_ID, class_id)
      @api_request.add_param(ApiConstants::ParamsList::COLUMNS, columns.join(",")) if !columns.blank?
      response_data = ResponseData.new(@api_request.send_api_request)
      response_data.optional_params = columns
      return response_data.parse_class_info
    end
  end
end
