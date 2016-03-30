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

      it "populates hosts with an error signal when consul is down" do
        Canvas::DynamicSettings.stubs(:find).with("rich-content-service").
          raises(Faraday::ConnectionFailed, "can't talk to consul")
        root_account = stub("root_account", feature_enabled?: true)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        expect(env[:RICH_CONTENT_APP_HOST]).to eq("error")
        expect(env[:RICH_CONTENT_CDN_HOST]).to eq("error")
      end

      it "logs errors for later consideration" do
        Canvas::DynamicSettings.stubs(:find).with("rich-content-service").
          raises(Canvas::DynamicSettings::ConsulError, "can't talk to consul")
        root_account = stub("root_account", feature_enabled?: true)
        Canvas::Errors.expects(:capture_exception).with do |type, e|
          expect(type).to eq(:rce_flag)
          expect(e.is_a?(Canvas::DynamicSettings::ConsulError)).to be_truthy
        end
        described_class.env_for(root_account)
      end

      it "includes a JWT for the domain and user's global id" do
        root_account = stub("root_account", feature_enabled?: true)
        user = stub("user", global_id: 'global id')
        domain = stub("domain")
        jwt = stub("jwt")
        Canvas::Security::ServicesJwt.stubs(:generate).with(sub: user.global_id, domain: domain).returns(jwt)
        env = described_class.env_for(root_account, user: user, domain: domain)
        expect(env[:JWT]).to eql(jwt)
      end

      it "includes a masquerading user if provided" do
        root_account = stub("root_account", feature_enabled?: true)
        user = stub("user", global_id: 'global id')
        masq_user = stub("masq_user", global_id: 'other global id')
        domain = stub("domain")
        jwt = stub("jwt")
        Canvas::Security::ServicesJwt.stubs(:generate).
          with(sub: user.global_id, domain: domain, masq_sub: masq_user.global_id).
          returns(jwt)
        env = described_class.env_for(root_account,
          user: user, domain: domain, real_user: masq_user)
        expect(env[:JWT]).to eql(jwt)
      end

      context "with only lowest level flag on" do
        let(:root_account){ stub("root_account") }

        before(:each) do
          root_account.stubs(:feature_enabled?).with(:rich_content_service).returns(true)
          root_account.stubs(:feature_enabled?).with(:rich_content_service_with_sidebar).returns(false)
          root_account.stubs(:feature_enabled?).with(:rich_content_service_high_risk).returns(false)
        end

        it "assumes high risk without being specified" do
          env = described_class.env_for(root_account)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
        end

        it "is contextually on for low risk areas" do
          env = described_class.env_for(root_account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually off for medium risk areas" do
          env = described_class.env_for(root_account, risk_level: :sidebar)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
        end

        it "is contextually off for high risk areas" do
          env = described_class.env_for(root_account, risk_level: :highrisk)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
        end
      end

      context "with all flags on" do
        let(:root_account){ stub("root_account") }

        before(:each) do
          root_account.stubs(:feature_enabled?).with(:rich_content_service).returns(true)
          root_account.stubs(:feature_enabled?).with(:rich_content_service_with_sidebar).returns(true)
          root_account.stubs(:feature_enabled?).with(:rich_content_service_high_risk).returns(true)
        end

        it "is contextually on for low risk areas" do
          env = described_class.env_for(root_account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually on for medium risk areas" do
          env = described_class.env_for(root_account, risk_level: :sidebar)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end

        it "is contextually on for high risk areas" do
          env = described_class.env_for(root_account, risk_level: :highrisk)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_truthy
        end
      end

      context "with all flags off" do
        let(:root_account){ stub("root_account") }

        before(:each) do
          root_account.stubs(:feature_enabled?).returns(false)
        end

        it "is contextually off when no risk specified" do
          env = described_class.env_for(root_account)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
        end

        it "is contextually off even for low risk areas" do
          env = described_class.env_for(root_account, risk_level: :basic)
          expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
        end
      end

      it "can be totally disabled with the lowest flag" do
        root_account = stub("root_account")
        root_account.stubs(:feature_enabled?).with(:rich_content_service).returns(false)
        root_account.stubs(:feature_enabled?).with(:rich_content_service_with_sidebar).returns(true)
        root_account.stubs(:feature_enabled?).with(:rich_content_service_high_risk).returns(true)
        env = described_class.env_for(root_account)
        expect(env[:RICH_CONTENT_SERVICE_ENABLED]).to be_falsey
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
        end
      end
    end
  end
end
