require 'nokogiri'

module Wiziq
  class ResponseData
    include ApiConstants::ResponseNodes

    attr_reader :doc_root, :api_method, :api_status, :hash
    attr_accessor :optional_params

    def initialize(response_xml)
      @optional_params ||= []
      @hash = {"code" => -1, "msg" => ""}
      res_doc = Nokogiri::XML(response_xml)
      @doc_root = res_doc.root
      raise 'Invalid api response' if @doc_root.blank?
      @api_status = @doc_root["status"]
      @api_method = @doc_root.xpath("method/text()").text
    end

    # parse response based upon api_method
    def parse_schedule_class_response
      return parse_error_response if @api_status == "fail"
      class_id = @doc_root.xpath("//"+Schedule::CLASS_ID).text
      @hash.store(Schedule::CLASS_ID, class_id)
      recording_url = @doc_root.xpath("//" + Schedule::RECORDING_URL).text
      @hash.store(Schedule::RECORDING_URL, recording_url)
      presenters = []
      @doc_root.xpath("//" + Schedule::PRESENTER).each do |presenter|
        next if presenter.is_a?(Nokogiri::XML::Text)
        presenters << Hash[
          Schedule::PRESENTER_URL, presenter.xpath("//" + Schedule::PRESENTER_URL).text,
          Schedule::PRESENTER_ID, presenter.xpath("//" + Schedule::PRESENTER_ID).text
        ]
      end
      @hash.store("presenters", presenters)
      @hash
    end

    def parse_add_attendee_response
      return parse_error_response if @api_status == "fail"
      class_id = @doc_root.xpath("//" + AddAttendee::CLASS_ID).text
      @hash.store(AddAttendee::CLASS_ID, class_id)
      @hash.store(AddAttendee::ATTENDEE_ID, @doc_root.xpath("//" + AddAttendee::ATTENDEE_ID).text)
      @hash.store(AddAttendee::ATTENDEE_URL, @doc_root.xpath("//" + AddAttendee::ATTENDEE_URL).text)
      @hash.store(AddAttendee::LANGUAGE, @doc_root.xpath("//" + AddAttendee::LANGUAGE).text)
      @hash
    end

    def parse_error_response
      msg = @doc_root.xpath("error/@msg").to_s
      code = @doc_root.xpath("error/@code").to_s.to_i
      @hash.store "code", code
      @hash.store "msg", msg
      @hash
    end

    def parse_class_info
      return parse_error_response if @api_status == "fail"
      @optional_params.each do |node|
        next if node.is_a?(Nokogiri::XML::Text)
        @hash.store(node, @doc_root.xpath("//#{node}").text)
      end
      @hash
    end
  end
end
