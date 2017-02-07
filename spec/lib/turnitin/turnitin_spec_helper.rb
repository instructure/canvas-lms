require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

RSpec.shared_context "shared_tii_lti", :shared_context => :metadata do
  let(:lti_student) { user_model }
  let(:lti_course) { course_with_student({user: lti_student}).course }
  let(:tool) do
    tool = lti_course.context_external_tools.new(
      name: "bob",
      consumer_key: "bob",
      shared_secret: "bob",
      tool_id: 'some_tool',
      privacy_level: 'public'
    )
    tool.url = "http://www.example.com/basic_lti"
    tool.resource_selection = {
      :url => "http://#{HostUrl.default_host}/selection_test",
      :selection_width => 400,
      :selection_height => 400}
    tool.save!
    tool
  end

  let(:lti_assignment) do
    assignment = assignment_model(course: lti_course)
    tag = assignment.build_external_tool_tag(url: tool.url)
    tag.content_type = 'ContextExternalTool'
    tag.content_id = tool.id
    tag.save!
    assignment
  end

  let(:attachment) do
    Attachment.create! uploaded_data: StringIO.new('blah'),
                       context: lti_course,
                       filename: 'blah.txt'
  end

  let(:tii_client) do
    tii_mock = mock('tii_client')
    tii_mock.stubs(:original_submission).yields(response_mock)
    tii_mock
  end
  let(:filename) { 'my_new_filename.txt' }
  let(:response_mock) do
    r_mock = mock('response')
    r_mock.stubs(:headers).
      returns({
                'content-disposition' => "attachment; filename=#{filename}",
                'content-type' => 'plain/text'
              })
    r_mock.stubs(:body).returns('abcdef')
    r_mock
  end

  let(:outcome_response_json) do
    {
      "paperid" => 200505101,
      "outcomes_tool_placement_url" => "https://turnitin.example.com/api/lti/1p0/outcome_tool_data/201?lang=en_us",
      "lis_result_sourcedid" => Lti::LtiOutboundAdapter.new(
        tool,
        lti_student,
        lti_course
      ).encode_source_id(lti_assignment)
    }
  end

  let(:tii_response) do
    {"outcome_grademark" => {
      "text" => "--",
      "label" => "Open GradeMark",
      "roles" => ["Instructor"],
      "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/dv/grademark/200587213?lang=en_us",
      "numeric" => {"score" => nil, "max" => 10}
    },
     "outcome_pdffile" => {
       "text" => nil,
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/download/pdf/200587213?lang=en_us",
       "roles" => ["Learner", "Instructor"],
       "label" => "Download File in PDF Format"
     },
     "meta" => {
       "date_uploaded" => "2016-10-24T19:48:40Z"
     },
     "outcome_originalityreport" => {
       "label" => "Open Originality Report",
       "numeric" => {
         "max" => 100,
         "score" => nil
       },
       "roles" => ["Instructor"],
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/dv/report/200587213?lang=en_us",
       "breakdown" => {
         "submitted_works_score" => nil,
         "internet_score" => nil,
         "publications_score" => nil
       },
       "text" => "Pending"
     },
     "outcome_originalfile" => {
       "text" => nil,
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/download/orig/200587213?lang=en_us",
       "roles" => ["Learner", "Instructor"],
       "label" => "Download File in Original Format"
     },
     "outcome_resubmit" => {
       "label" => "Resubmit File",
       "launch_url" => "https://sandbox.turnitin.com/api/lti/1p0/upload/resubmit/200587213?lang=en_us",
       "roles" => ["Learner"],
       "text" => nil
     }
    }
  end

end

