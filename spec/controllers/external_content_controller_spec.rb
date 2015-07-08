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

end