# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require_relative "../../spec_helper"
require_relative "../../feature_flag_helper"
require_relative "ims/concerns/advantage_services_shared_context"
require_relative "ims/concerns/lti_services_shared_examples"

describe Lti::FeatureFlagsController do
  include WebMock::API
  include FeatureFlagHelper

  include_context "advantage services context"

  let(:account) { root_account }
  let(:course) { course_model(root_account: account) }

  before do
    silence_undefined_feature_flag_errors
    allow_any_instance_of(User).to receive(:set_default_feature_flags)
    allow(Feature).to receive(:definitions).and_return({
                                                         "account_feature" => Feature.new(feature: "account_feature", applies_to: "Account", state: "on", display_name: -> { "Account Feature FRD" }, description: -> { "FRD!!" }, beta: true, autoexpand: true),
                                                         "javascript_csp" => Feature.new(feature: "javascript_csp", applies_to: "Account", state: "on", display_name: -> { "Account Feature FRD" }, description: -> { "FRD!!" }, beta: true, autoexpand: true),
                                                         "course_feature" => Feature.new(feature: "course_feature", applies_to: "Course", state: "allowed", development: true, release_notes_url: "http://example.com", display_name: "not localized", description: "srsly"),
                                                         "compact_live_event_payloads" => Feature.new(feature: "compact_live_event_payloads", applies_to: "RootAccount", state: "allowed"),
                                                         "site_admin_feature" => Feature.new(feature: "site_admin_feature", applies_to: "SiteAdmin", state: "on", display_name: -> { "SiteAdmin Feature FRD" }, description: -> { "FRD!!" }, beta: true, autoexpand: true)
                                                       })
  end

  describe "#show" do
    shared_examples_for "course or account lti service" do
      let(:params) { raise "set in examples" }

      it_behaves_like "lti services" do
        let(:action) { :show }
        let(:expected_mime_type) { described_class::MIME_TYPE }
        let(:scope_to_remove) { TokenScopes::LTI_SHOW_FEATURE_FLAG_SCOPE }
        let(:params_overrides) { params }
      end
    end

    context "with an account lti_context_id" do
      it_behaves_like "course or account lti service" do
        let(:params) do
          {
            account_id: Lti::Asset.opaque_identifier_for(account),
            feature: "account_feature"
          }
        end
      end
    end

    context "with an account canvas id" do
      it_behaves_like "course or account lti service" do
        let(:params) do
          {
            account_id: account.id,
            feature: "account_feature"
          }
        end
      end
    end

    context "with a course lti_context_id" do
      it_behaves_like "course or account lti service" do
        let(:params) do
          {
            course_id: Lti::Asset.opaque_identifier_for(course),
            feature: "course_feature"
          }
        end
      end
    end

    context "with a course canvas id" do
      it_behaves_like "course or account lti service" do
        let(:params) do
          {
            course_id: course.id,
            feature: "course_feature"
          }
        end
      end
    end

    context "with a site-admin-only feature" do
      let(:action) { :show }
      let(:params_overrides) do
        {
          account_id: account.id,
          feature: "site_admin_feature"
        }
      end

      it "returns a valid feature" do
        send_request
        expect(response.body).not_to eq("null")
      end
    end
  end
end
