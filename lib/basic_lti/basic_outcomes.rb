module BasicLTI::BasicOutcomes
  class Unauthorized < Exception; end

  # this is the lis_result_sourcedid field in the launch, and the
  # sourcedGUID/sourcedId in BLTI basic outcome requests.
  # it's a secure signature of the (tool, course, assignment, user). Combined with
  # the pre-determined shared secret that the tool signs requests with, this
  # ensures that only this launch of the tool can modify the score.
  def self.encode_source_id(tool, course, assignment, user)
    tool.shard.activate do
      payload = [tool.id, course.id, assignment.id, user.id].join('-')
      "#{payload}-#{Canvas::Security.hmac_sha1(payload, tool.shard.settings[:encryption_key])}"
    end
  end

  SOURCE_ID_REGEX = %r{^(\d+)-(\d+)-(\d+)-(\d+)-(\w+)$}

  def self.decode_source_id(tool, sourceid)
    tool.shard.activate do
      md = sourceid.match(SOURCE_ID_REGEX)
      return false unless md
      new_encoding = [md[1], md[2], md[3], md[4]].join('-')
      return false unless Canvas::Security.hmac_sha1(new_encoding, tool.shard.settings[:encryption_key]) == md[5]
      return false unless tool.id == md[1].to_i
      course = Course.find(md[2])
      assignment = course.assignments.active.find(md[3])
      user = course.student_enrollments.active.find_by_user_id(md[4]).user
      tag = assignment.external_tool_tag
      if !tag || tool != ContextExternalTool.find_external_tool(tag.url, course)
        return false # assignment settings have changed, this tool is no longer active
      end
      return course, assignment, user
    end
  end

  def self.process_request(tool, xml)
    res = LtiResponse.new(xml)

    unless res.handle_request(tool)
      res.code_major = 'unsupported'
    end
    return res
  end

  def self.process_legacy_request(tool, params)
    res = LtiResponse::Legacy.new(params)

    unless res.handle_request(tool)
      res.code_major = 'unsupported'
    end
    return res
  end

  class LtiResponse
    attr_accessor :code_major, :severity, :description, :body

    def initialize(lti_request)
      @lti_request = lti_request
      self.code_major = 'success'
      self.severity = 'status'
    end

    def sourcedid
      @lti_request.at_css('imsx_POXBody sourcedGUID > sourcedId').try(:content)
    end

    def message_ref_identifier
      @lti_request.at_css('imsx_POXHeader imsx_messageIdentifier').try(:content)
    end

    def operation_ref_identifier
      tag = @lti_request.at_css('imsx_POXBody *:first').try(:name)
      tag && tag.sub(%r{Request$}, '')
    end

    def result_score
      @lti_request.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultScore > textString').try(:content)
    end

    def to_xml
      xml = LtiResponse.envelope.dup
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_codeMajor').content = code_major
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_severity').content = severity
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_description').content = description
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_messageRefIdentifier').content = message_ref_identifier
      xml.at_css('imsx_POXHeader imsx_statusInfo imsx_operationRefIdentifier').content = operation_ref_identifier
      xml.at_css('imsx_POXBody').inner_html = body if body.present?
      xml.to_s
    end

    def self.envelope
      return @envelope if @envelope
      @envelope = Nokogiri::XML.parse <<-XML
      <imsx_POXEnvelopeResponse xmlns = "http://www.imsglobal.org/lis/oms1p0/pox">
        <imsx_POXHeader>
          <imsx_POXResponseHeaderInfo>
            <imsx_version>V1.0</imsx_version>
            <imsx_messageIdentifier></imsx_messageIdentifier>
            <imsx_statusInfo>
              <imsx_codeMajor></imsx_codeMajor>
              <imsx_severity>status</imsx_severity>
              <imsx_description></imsx_description>
              <imsx_messageRefIdentifier></imsx_messageRefIdentifier> 
              <imsx_operationRefIdentifier></imsx_operationRefIdentifier> 
            </imsx_statusInfo>
          </imsx_POXResponseHeaderInfo>
        </imsx_POXHeader>
        <imsx_POXBody>
        </imsx_POXBody>
      </imsx_POXEnvelopeResponse>
      XML
      @envelope.encoding = 'UTF-8'
      @envelope
    end

    def handle_request(tool)
      # verify the lis_result_sourcedid param, which will be a canvas-signed
      # tuple of (course, assignment, user) to ensure that only this launch of
      # the tool is attempting to modify this data.
      source_id = self.sourcedid
      course, assignment, user = BasicLTI::BasicOutcomes.decode_source_id(tool, source_id) if source_id

      unless course && assignment && user
        return false
      end

      op = self.operation_ref_identifier
      if self.respond_to?("handle_#{op}")
        return self.send("handle_#{op}", tool, course, assignment, user)
      end

      false
    end

    protected

    def handle_replaceResult(tool, course, assignment, user)
      text_value = self.result_score
      new_value = Float(text_value) rescue false
      if new_value && (0.0 .. 1.0).include?(new_value)
        submission_hash = { :grade => "#{new_value * 100}%", :submission_type => 'external_tool' }
        @submission = assignment.grade_student(user, submission_hash).first
        self.body = "<replaceResultResponse />"
        return true
      else
        self.code_major = 'failure'
        return true
      end
    end

    def handle_deleteResult(tool, course, assignment, user)
      assignment.grade_student(user, :grade => nil)
      self.body = "<deleteResultResponse />"
      true
    end

    def handle_readResult(tool, course, assignment, user)
      @submission = assignment.submission_for_student(user)
      self.body = %{
        <readResultResponse>
          <result>
            <resultScore>
              <language>en</language>
              <textString>#{submission_score}</textString>
            </resultScore>
          </result>
        </readResultResponse>
      }
      true
    end

    def submission_score
      if @submission.try(:graded?)
        raw_score = @submission.assignment.score_to_grade_percent(@submission.score)
        raw_score / 100.0
      end
    end

    class Legacy < LtiResponse
      def initialize(params)
        super(nil)
        @params = params
      end

      def sourcedid
        @params[:sourcedid]
      end

      def result_score
        @params[:result_resultscore_textstring]
      end

      def operation_ref_identifier
        case @params[:lti_message_type].try(:downcase)
        when 'basic-lis-updateresult'
          'replaceResult'
        when 'basic-lis-readresult'
          'readResult'
        when 'basic-lis-deleteresult'
          'deleteResult'
        end
      end

      def to_xml
        xml = LtiResponse::Legacy.envelope.dup
        xml.at_css('message_response > statusinfo > codemajor').content = code_major.capitalize
        if score = submission_score
          xml.at_css('message_response > result > sourcedid').content = sourcedid
          xml.at_css('message_response > result > resultscore > textstring').content = score
        else
          xml.at_css('message_response > result').remove
        end
        xml.to_s
      end

      def self.envelope
        return @envelope if @envelope
        @envelope = Nokogiri::XML.parse <<-XML
        <message_response>
          <lti_message_type></lti_message_type>
          <statusinfo>
            <codemajor></codemajor>
            <severity>Status</severity>
            <codeminor>fullsuccess</codeminor>
          </statusinfo>
          <result>
            <sourcedid></sourcedid>
            <resultscore>
              <resultvaluesourcedid>decimal</resultvaluesourdedid>
              <textstring></textstring>
              <language>en-US</language>
            </resultscore>
          </result>
        </message_response>
        XML
        @envelope.encoding = 'UTF-8'
        @envelope
      end

    end
  end
end
