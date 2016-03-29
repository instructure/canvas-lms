require_relative "../../spec_helper"

module Services
  describe RichContent do
    describe ".config_for" do
      it "just returns disabled value if no root_account" do
        expect(described_class.env_for(nil)).to eq({
          RICH_CONTENT_SERVICE_ENABLED: false
        })
      end

      it "fills out host values when enabled" do
        Canvas::DynamicSettings.stubs(:find).with("rich-content-service").returns({
          "app-host" => "rce-app",
          "cdn-host" => "rce-cdn"
        })
        root_account = stub("root_account", feature_enabled?: true)
        env = described_class.env_for(root_account)
        expect(env).to eq({
          RICH_CONTENT_SERVICE_ENABLED: true,
          RICH_CONTENT_APP_HOST: "rce-app",
          RICH_CONTENT_CDN_HOST: "rce-cdn"
        })
      end
    end
  end
end
