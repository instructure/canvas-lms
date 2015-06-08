require_relative "../api_spec_helper"

describe ErrorsController, type: :request do
  describe "reporting an error" do
    let(:path){ "/api/v1/error_reports" }

    let(:api_options) do
      {
        controller: "errors",
        action: "create",
        format: "json"
      }
    end

    before { user_with_pseudonym }

    it "processes a simple API request" do
      json = api_call :post, path, api_options, {
        error: {
          subject: "My Subject",
          email: "TestErrorsEmail@example.com",
          comments: "My Description"
        }
      }
      expect(json['logged']).to eq(true)
      expect(ErrorReport.last.email).to eq("TestErrorsEmail@example.com")
    end

    it "handles arbitrary metadata in the httpenv attribute" do
      json = api_call :post, path, api_options, {
        error: {
          subject: "My Subject",
          email: "TestErrorsEmail@example.com",
          comments: "My Description",
          http_env: {
            foo: 'bar',
            meta: 'data'
          }
        }
      }
      expect(json['logged']).to eq(true)
      report = ErrorReport.last
      expect(report.http_env['foo']).to eq("bar")
      expect(report.http_env['meta']).to eq("data")
    end
  end
end
