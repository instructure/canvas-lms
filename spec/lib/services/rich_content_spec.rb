require_relative "../../spec_helper"

module Services
  describe RichContent do
    before do
      Canvas::DynamicSettings.stubs(:find).with("rich-content-service").returns({
        "app-host" => "rce-app",
        "cdn-host" => "rce-cdn"
      })
    end

    describe ".env_for" do
      it "just returns disabled value if no root_account" do
        expect(described_class.env_for(nil)).to eq({
          RICH_CONTENT_SERVICE_ENABLED: false
        })
      end

      it "fills out host values when enabled" do
        root_account = stub("root_account", feature_enabled?: true)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_APP_HOST]).to eq("rce-app")
        expect(env[:RICH_CONTENT_CDN_HOST]).to eq("rce-cdn")
      end

      it "can enable only the non-sidebar use cases" do
        root_account = stub("root_account")
        root_account.stubs(:feature_enabled?).with(:rich_content_service).returns(true)
        root_account.stubs(:feature_enabled?).with(:rich_content_service_with_sidebar).returns(false)
        root_account.stubs(:feature_enabled?).with(:rich_content_service_high_risk).returns(false)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        expect(env[:RICH_CONTENT_SIDEBAR_ENABLED]).to be_falsey
        expect(env[:RICH_CONTENT_HIGH_RISK_ENABLED]).to be_falsey
      end

      it "can be totally disabled with the lowest flag" do
        root_account = stub("root_account")
        root_account.stubs(:feature_enabled?).with(:rich_content_service).returns(false)
        root_account.stubs(:feature_enabled?).with(:rich_content_service_with_sidebar).returns(true)
        root_account.stubs(:feature_enabled?).with(:rich_content_service_high_risk).returns(true)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
        expect(env[:RICH_CONTENT_SIDEBAR_ENABLED]).to be_falsey
        expect(env[:RICH_CONTENT_HIGH_RISK_ENABLED]).to be_falsey
      end

      it "treats nil feature values as false" do
        root_account = stub("root_account")
        root_account.stubs(:feature_enabled?).with(:rich_content_service).returns(nil)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to eq(false)
      end

      context "integrating with a real account and feature flags" do
        it "sets all levels to true when all flags set" do
          account = account_model
          account.enable_feature!(:rich_content_service)
          account.enable_feature!(:rich_content_service_with_sidebar)
          account.enable_feature!(:rich_content_service_high_risk)
          env = described_class.env_for(account)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
          expect(env[:RICH_CONTENT_SIDEBAR_ENABLED]).to be_truthy
          expect(env[:RICH_CONTENT_HIGH_RISK_ENABLED]).to be_truthy
        end
      end
    end
  end
end
