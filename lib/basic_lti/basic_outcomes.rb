module BasicLTI::BasicOutcomes
  # this is the lis_result_sourcedid field in the launch, and the
  # sourcedGUID/sourcedId in BLTI basic outcome requests.
  # it's a secure signature of the (tool, course, assignment, user). Combined with
  # the pre-determined shared secret that the tool signs requests with, this
  # ensures that only this launch of the tool can modify the score.
  def self.result_source_id(tool, course, assignment, user)
    Canvas::Security.hmac_sha1("#{tool.id}-#{course.id}-#{assignment.id}-#{user.id}")
  end

  def self.process_request(tool, course, assignment, user, xml)
    res = LtiResponse.new(xml)
    unless self.handle_request(tool, course, assignment, user, xml, res)
      res.code_major = 'unsupported'
    end
    return res
  end

  protected

  def self.handle_request(tool, course, assignment, user, xml, res)
    # verify the lis_result_sourcedid param, which will be a canvas-signed
    # tuple of (course, assignment, user) to ensure that only this launch of
    # the tool is attempting to modify this data.
    source_id = xml.at_css('imsx_POXBody sourcedGUID > sourcedId').try(:content)
    unless source_id && source_id == BasicLTI::BasicOutcomes.result_source_id(tool, course, assignment, user)
      return false
    end

    op = res.operation_ref_identifier
    if self.respond_to?("handle_#{op}")
      return self.send("handle_#{op}", tool, course, assignment, user, xml, res)
    end

    false
  end

  def self.handle_replaceResult(tool, course, assignment, user, xml, res)
    text_value = xml.at_css('imsx_POXBody > replaceResultRequest > resultRecord > result > resultScore > textString').try(:content)
    new_value = Float(text_value) rescue false
    if new_value && (0.0 .. 1.0).include?(new_value)
      submission_hash = { :grade => "#{new_value * 100}%" }
      submission = assignment.grade_student(user, submission_hash).first
      res.body = "<replaceResultResponse />"
      return true
    else
      res.code_major = 'failure'
      return true
    end
  end

  def self.handle_deleteResult(tool, course, assignment, user, xml, res)
    assignment.grade_student(user, :grade => nil)
    res.body = "<deleteResultResponse />"
    true
  end

  def self.handle_readResult(tool, course, assignment, user, xml, res)
    submission = assignment.submission_for_student(user)
    if submission.graded?
      raw_score = assignment.score_to_grade_percent(submission.score)
      score = raw_score / 100.0
    end
    res.body = %{
      <readResultResponse>
        <result>
          <resultScore>
            <language>en</language>
            <textString>#{score}</textString>
          </resultScore>
        </result>
      </readResultResponse>
    }
    true
  end

  class LtiResponse
    attr_accessor :code_major, :severity, :description, :body

    def initialize(lti_request)
      @lti_request = lti_request
      self.code_major = 'success'
      self.severity = 'status'
    end

    def message_ref_identifier
      @lti_request.at_css('imsx_POXHeader imsx_messageIdentifier').try(:content)
    end

    def operation_ref_identifier
      tag = @lti_request.at_css('imsx_POXBody *:first').try(:name)
      tag && tag.sub(%r{Request$}, '')
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
  end
end
