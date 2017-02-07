require_relative "../../spec_helper"
require_dependency "services/rich_content"

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

      it "includes a generated JWT for the domain, user, context, and workflwos" do
        root_account = stub("root_account", feature_enabled?: true)
        user = stub("user", global_id: 'global id')
        domain = stub("domain")
        ctx = stub("ctx", grants_any_right?: true)
        jwt = stub("jwt")
        Canvas::Security::ServicesJwt.stubs(:for_user).with(domain, user, all_of(
          has_entry(workflows: [:rich_content, :ui]),
          has_entry(context: ctx)
        )).returns(jwt)
        env = described_class.env_for(root_account, user: user, domain: domain, context: ctx)
        expect(env[:JWT]).to eql(jwt)
      end

      it "includes a masquerading user if provided" do
        root_account = stub("root_account", feature_enabled?: true)
        user = stub("user", global_id: 'global id')
        masq_user = stub("masq_user", global_id: 'other global id')
        domain = stub("domain")
        jwt = stub("jwt")
        Canvas::Security::ServicesJwt.stubs(:for_user).with(
          domain,
          user,
          has_entry(real_user: masq_user),
        ).returns(jwt)
        env = described_class.env_for(root_account,
          user: user, domain: domain, real_user: masq_user)
        expect(env[:JWT]).to eql(jwt)
      end

      it "does not allow file uploading without context" do
        root_account = stub("root_account", feature_enabled?: true)
        user = stub("user", global_id: 'global id')
        env = described_class.env_for(root_account, user: user)
        expect(env[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(false)
      end

      it "lets context decide if uploading is ok" do
        root_account = stub("root_account", feature_enabled?: true)
        user = stub("user", global_id: 'global id')
        context1 = stub("allowed_context", grants_any_right?: true)
        context2 = stub("forbidden_context", grants_any_right?: false)
        env1 = described_class.env_for(root_account, user: user, context: context1)
        env2 = described_class.env_for(root_account, user: user, context: context2)
        expect(env1[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(true)
        expect(env2[:RICH_CONTENT_CAN_UPLOAD_FILES]).to eq(false)
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
