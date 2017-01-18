require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExternalContentController do

  describe "GET success" do
    it "doesn't require a context" do
      get :success, service: 'equella'
      expect(response).to have_http_status(:success)
    end

    it "gets a context for external_tool_dialog" do
      c = course
      get :success, service: 'external_tool_dialog', course_id: c.id
      expect(assigns[:context]).to_not be_nil
    end
  end

  describe "POST success/external_tool_dialog" do
    it "js env is set correctly" do

      c = course
      post(:success, service: 'external_tool_dialog', course_id: c.id, lti_message_type: 'ContentItemSelection',
           lti_version: 'LTI-1p0',
           data: '',
           content_items: File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'content_items.json')),
           lti_msg: '',
           lti_log: '',
           lti_errormsg: '',
           lti_errorlog: '')

      data = controller.js_env[:retrieved_data]
      expect(data).to_not be_nil
      expect(data.first.is_a?(IMS::LTI::Models::ContentItems::ContentItem)).to be_truthy

      expect(data.first.id).to eq("http://lti-tool-provider-example.dev/messages/blti")
      expect(data.first.url).to eq("http://lti-tool-provider-example.dev/messages/blti")
      expect(data.first.text).to eq("Arch Linux")
      expect(data.first.title).to eq("Its your computer")
      expect(data.first.placement_advice.presentation_document_target).to eq("iframe")
      expect(data.first.placement_advice.display_height).to eq(600)
      expect(data.first.placement_advice.display_width).to eq(800)
      expect(data.first.media_type).to eq("application/vnd.ims.lti.v1.ltilink")
      expect(data.first.type).to eq("LtiLinkItem")
      expect(data.first.thumbnail.height).to eq(128)
      expect(data.first.thumbnail.width).to eq(128)
      expect(data.first.thumbnail.id).to eq("http://www.runeaudio.com/assets/img/banner-archlinux.png")

      e = "external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti"
      expect(data.first.canvas_url).to end_with(e)

    end

    context 'external_tool service_id' do
      let(:test_course) {course}
      let(:launch_url) {'http://test.com/launch'}
      let(:tool) do
        test_course.context_external_tools.create!(
          {
            name: 'test tool',
            domain:'test.com',
            consumer_key: oauth_consumer_key,
            shared_secret: 'secret'
          }
        )
      end
      let(:service_id) {"3"}
      let(:oauth_consumer_key) {"key"}
      let(:content_item_selection) do
        message = IMS::LTI::Models::Messages::ContentItemSelection.new(
          {
            lti_message_type: 'ContentItemSelection',
            lti_version: 'LTI-1p0',
            content_items: File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'content_items.json')),
            data: Canvas::Security.create_jwt({content_item_id: service_id, oauth_consumer_key: oauth_consumer_key}),
            lti_msg: '',
            lti_log: '',
            lti_errormsg: '',
            lti_errorlog: ''
          }
        )
        message.launch_url = launch_url
        message.oauth_consumer_key = oauth_consumer_key
        message
      end

      before(:each) do
        Lti::MessageAuthenticator.any_instance.stubs(:valid?).returns(true)
        course_with_teacher
        user_session(@teacher)
      end

      it 'validates the signature' do
        Lti::MessageAuthenticator.any_instance.expects(:valid?).returns(false)
        post(
          :success,
          {
            service: 'external_tool_dialog',
            course_id: test_course.id,
            id: service_id,
          }.merge(content_item_selection.signed_post_params(tool.shared_secret))
        )
        expect(response).to have_http_status(:unauthorized)
      end

      it "sets the service_id if one is passed in" do
        post(
          :success,
          {
            service: 'external_tool_dialog',
            course_id: test_course.id,
            id: service_id,
          }.merge(content_item_selection.signed_post_params(tool.shared_secret))
        )
        expect(controller.js_env[:service_id]).to eq service_id
      end

      it "returns a 401 if the service_id, and data attribute don't match" do
        params = content_item_selection.signed_post_params(tool.shared_secret).
            merge(
              {
                service: 'external_tool_dialog',
                course_id: test_course.id,
                id: 3,
                data: Canvas::Security.create_jwt({content_item_id: "1"})
              }
            )
        post(:success, params)
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns a 401 if the consumer_key, and data attribute don't match" do
        params = content_item_selection.signed_post_params(tool.shared_secret).
          merge(
            {
              service: 'external_tool_dialog',
              course_id: test_course.id,
              id: service_id,
              data: Canvas::Security.create_jwt({content_item_id: service_id, oauth_consumer_key:'invalid'})
            }
          )
        post(:success, params)
        expect(response).to have_http_status(:unauthorized)
      end

    end



  end


  describe "#content_items_for_canvas" do
    it 'sets default placement advice' do
      c = course
      post(:success, service: 'external_tool_dialog', course_id: c.id, lti_message_type: 'ContentItemSelection',
           lti_version: 'LTI-1p0',
           data: '',
           content_items: File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'content_items_2.json')),
           lti_msg: '',
           lti_log: '',
           lti_errormsg: '',
           lti_errorlog: '')

      data = controller.js_env[:retrieved_data]
      expect(data.first.placement_advice.presentation_document_target).to eq("default")
      expect(data.first.placement_advice.display_height).to eq(600)
      expect(data.first.placement_advice.display_width).to eq(800)
    end

    it "uses the default url if one isn't provided" do
      c = course
      json = JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'content_items_2.json')))
      json['@graph'][0].delete('url')
      launch_url = 'http://example.com/launch'
      post(:success, service: 'external_tool_dialog', course_id: c.id, lti_message_type: 'ContentItemSelection',
           lti_version: 'LTI-1p0',
           data: Canvas::Security.create_jwt({default_launch_url: launch_url}),
           content_items: json.to_json,
           lti_msg: '',
           lti_log: '',
           lti_errormsg: '',
           lti_errorlog: '')

      data = controller.js_env[:retrieved_data]
      expect(data.first.canvas_url).to include "http%3A%2F%2Fexample.com%2Flaunch"
    end

  end

end