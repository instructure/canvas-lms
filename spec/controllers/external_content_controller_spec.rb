require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExternalContentController do

  describe "GET success" do
    it "doesn't require a context" do
      get :success, service: 'equella'
      expect(response).to have_http_status(:success)
    end

    it "gets a context for external_tool_dialog" do
      c = course
      get :success, service: 'external_tool_dialog', course_id:c.id
      expect(assigns[:context]).to_not be_nil
    end
  end

  describe "POST success/external_tool_dialog" do
    it "js env is set correctly" do

      c = course
      post(:success, service: 'external_tool_dialog', course_id:c.id, lti_message_type: 'ContentItemSelection',
           lti_version: 'LTI-1p0',
           data: '',
           content_items: '{"@context":"http://purl.imsglobal.org/ctx/lti/v1/ContentItem","@graph":[{"@type":"LtiLinkItem","@id":"http://lti-tool-provider-example.dev/messages/blti","url":"http://lti-tool-provider-example.dev/messages/blti","title":"Its like sexy for your computer","text":"Arch Linux","mediaType":"application/vnd.ims.lti.v1.ltilink","windowTarget":"","placementAdvice":{"displayWidth":800,"presentationDocumentTarget":"iframe","displayHeight":600},"thumbnail":{"@id":"http://www.runeaudio.com/assets/img/banner-archlinux.png","height":128,"width":128}}]}',
           lti_msg: '',
           lti_log: '',
           lti_errormsg: '',
           lti_errorlog: '')

      expect(controller.js_env[:retrieved_data]).to_not be_nil
      expect(controller.js_env[:retrieved_data].first.instance_of?(IMS::LTI::Models::ContentItems::ContentItem)).to be_truthy

      expect(controller.js_env[:retrieved_data].first.id).to eq("http://lti-tool-provider-example.dev/messages/blti")
      expect(controller.js_env[:retrieved_data].first.url).to eq("http://lti-tool-provider-example.dev/messages/blti")
      expect(controller.js_env[:retrieved_data].first.text).to eq("Arch Linux")
      expect(controller.js_env[:retrieved_data].first.title).to eq("Its like sexy for your computer")
      expect(controller.js_env[:retrieved_data].first.placement_advice.presentation_document_target).to eq("iframe")
      expect(controller.js_env[:retrieved_data].first.placement_advice.display_height).to eq(600)
      expect(controller.js_env[:retrieved_data].first.placement_advice.display_width).to eq(800)
      expect(controller.js_env[:retrieved_data].first.media_type).to eq("application/vnd.ims.lti.v1.ltilink")
      expect(controller.js_env[:retrieved_data].first.type).to eq("LtiLinkItem")
      expect(controller.js_env[:retrieved_data].first.thumbnail.height).to eq(128)
      expect(controller.js_env[:retrieved_data].first.thumbnail.width).to eq(128)
      expect(controller.js_env[:retrieved_data].first.thumbnail.id).to eq("http://www.runeaudio.com/assets/img/banner-archlinux.png")
      expect(controller.js_env[:retrieved_data].first.canvas_url).to end_with("external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti")

    end
  end
end