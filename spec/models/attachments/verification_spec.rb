# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe Attachments::Verification do
  let_once(:root_account) do
    Account.create(name: "New Account", default_time_zone: "UTC")
  end
  before(:once) do
    @user = user_with_managed_pseudonym(
      account: root_account
    )
  end

  let_once(:course) do
    course_model
    @course.offer
    @course.update_attribute(:is_public, false)
    @course
  end
  let_once(:student) do
    course.enroll_student(user_model).accept
    @user
  end
  let_once(:attachment) do
    attachment_model(context: course)
  end
  let_once(:v) do
    Attachments::Verification.new(attachment)
  end

  context "creating a verifier" do
    it "creates a verifier with the attachment id and ctx" do
      expect(CanvasSecurity).to receive(:create_jwt).with({
                                                            id: attachment.global_id, user_id: student.global_id, ctx: course.asset_string
                                                          },
                                                          nil).and_return("thetoken")

      verifier = v.verifier_for_user(student, context: course.asset_string)
      expect(verifier).to eq("thetoken")
    end

    it "does not include user id if one is not specified" do
      expect(CanvasSecurity).to receive(:create_jwt).with({
                                                            id: attachment.global_id, ctx: course.asset_string
                                                          },
                                                          nil).and_return("thetoken")

      verifier = v.verifier_for_user(nil, context: course.asset_string)
      expect(verifier).to eq("thetoken")
    end

    it "includes the expiration if supplied" do
      expires = 1.hour.from_now
      expect(CanvasSecurity).to receive(:create_jwt).with({
                                                            id: attachment.global_id, ctx: course.asset_string
                                                          },
                                                          expires).and_return("thetoken")

      verifier = v.verifier_for_user(nil, context: course.asset_string, expires:)
      expect(verifier).to eq("thetoken")
    end
  end

  context "verifying a verifier" do
    before do
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
    end

    it "verifies a legacy verifier for read and download" do
      expect(v.valid_verifier_for_permission?(attachment.uuid, :read, root_account)).to be(true)
      expect(v.valid_verifier_for_permission?(attachment.uuid, :download, root_account)).to be(true)
    end

    it "accepts the uuid of another copy of the file" do
      clone = attachment.clone_for(course_factory)
      clone.save!
      v2 = Attachments::Verification.new(clone)
      expect(v2.valid_verifier_for_permission?(attachment.uuid, :read, root_account)).to be true
      expect(v2.valid_verifier_for_permission?(attachment.uuid, :download, root_account)).to be true
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("feature_flag_check", any_args).at_least(:once)
    end

    it "skips legacy verifiers when disable_file_verifier_access feature flag is enabled" do
      root_account.enable_feature!(:disable_file_verifier_access)
      expect(v.valid_verifier_for_permission?(attachment.uuid, :read, root_account)).to be(false)
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("attachments.token_verifier_invalid")
      expect(InstStatsd::Statsd).not_to receive(:distributed_increment).with("attachments.legacy_verifier_success")
      expect(InstStatsd::Statsd).not_to receive(:distributed_increment).with("attachments.related_verifier_success")
    end

    it "returns false on an invalid verifier" do
      expect(CanvasSecurity).to receive(:decode_jwt).with("token").and_raise(CanvasSecurity::InvalidToken)
      expect(v.valid_verifier_for_permission?("token", :read, root_account)).to be(false)
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("attachments.token_verifier_invalid")
    end

    it "returns false on a verifier that is not of type String" do
      unsupported_verifier = 1
      expect(v.valid_verifier_for_permission?(unsupported_verifier, :read, root_account)).to be(false)
    end

    it "returns false on token id mismatch" do
      expect(CanvasSecurity).to receive(:decode_jwt).with("token").and_return({
                                                                                id: attachment.global_id + 1
                                                                              })
      expect(v.valid_verifier_for_permission?("token", :read, root_account)).to be(false)
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("attachments.token_verifier_id_mismatch")
    end

    it "does not let a student download an attachment that's locked" do
      att2 = attachment_model(context: course)
      att2.update_attribute(:locked, true)
      v2 = Attachments::Verification.new(att2)
      expect(CanvasSecurity).to receive(:decode_jwt).with("token").and_return({
                                                                                id: att2.global_id, user_id: student.global_id
                                                                              }).twice
      expect(v2.valid_verifier_for_permission?("token", :read, root_account)).to be(true)
      expect(v2.valid_verifier_for_permission?("token", :download, root_account)).to be(false)
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with("attachments.token_verifier_success").twice
    end

    it "follows custom permissions" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: true
      v2 = Attachments::Verification.new(att2)
      other_user = user_model
      token = v2.verifier_for_user(other_user, context: eportfolio.asset_string, permission_map_id: :r_rd)
      expect(v2.valid_verifier_for_permission?(token, :read, root_account)).to be(true)
      expect(v2.valid_verifier_for_permission?(token, :download, root_account)).to be(true)
      # revoke :read on the eportfolio, and the verifier should no longer work
      Timecop.travel(2.seconds) do # allow the eportfolio's updated_at to change to invalidate the permissions cache
        eportfolio.public = false
        eportfolio.save!
        expect(v2.valid_verifier_for_permission?(token, :read, root_account)).to be(false)
        expect(v2.valid_verifier_for_permission?(token, :download, root_account)).to be(false)
      end
    end

    it "supports session-based permissions" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: false
      v2 = Attachments::Verification.new(att2)
      other_user = user_model
      token = v2.verifier_for_user(other_user, context: eportfolio.asset_string, permission_map_id: :r_rd)
      expect(v2.valid_verifier_for_permission?(token, :read, root_account)).to be(false)
      expect(v2.valid_verifier_for_permission?(token, :download, root_account)).to be(false)

      mock_session = { eportfolio_ids: [eportfolio.id], permissions_key: SecureRandom.uuid }
      expect(v2.valid_verifier_for_permission?(token, :read, root_account, mock_session)).to be(true)
      expect(v2.valid_verifier_for_permission?(token, :download, root_account, mock_session)).to be(true)
    end

    it "supports custom permissions checks on nil (public) user" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: false
      v2 = Attachments::Verification.new(att2)
      token = v2.verifier_for_user(nil, context: eportfolio.asset_string, permission_map_id: :r_rd)

      expect(v2.valid_verifier_for_permission?(token, :read, root_account)).to be(false)
      expect(v2.valid_verifier_for_permission?(token, :download, root_account)).to be(false)
      mock_session = { eportfolio_ids: [eportfolio.id], permissions_key: SecureRandom.uuid }
      expect(v2.valid_verifier_for_permission?(token, :read, root_account, mock_session)).to be(true)
      expect(v2.valid_verifier_for_permission?(token, :download, root_account, mock_session)).to be(true)
    end
  end

  describe "#monitor_cross_domain_access" do
    let(:referer) { "https://other.canvas.example/files/1" }
    let(:request_host) { "this.canvas.example" }
    let(:request_url) { "https://this.canvas.example/files/2" }
    let(:request) do
      instance_double(
        ActionDispatch::Request,
        referer:,
        host: request_host,
        url: request_url
      )
    end
    let(:files_domain) { false }
    let(:referrer_is_canvas_domain) { false }
    let(:referrer_account) { referrer_is_canvas_domain ? instance_double(Account, id: 2) : nil }
    let(:request_account) { instance_double(Account, id: 1) }

    before do
      allow(InstStatsd::Statsd).to receive(:event)
    end

    context "when the feature flag is disabled" do
      let(:referrer_is_canvas_domain) { true }

      before do
        Account.site_admin.disable_feature!(:log_cross_domain_file_access)
        allow(LoadAccount).to receive(:from_host).with("other.canvas.example").and_return(referrer_account)
        allow(LoadAccount).to receive(:from_host).with("this.canvas.example").and_return(request_account)
        v.monitor_cross_domain_access(request, files_domain)
      end

      it "does not emit a stats event" do
        expect(InstStatsd::Statsd).not_to have_received(:event)
      end
    end

    context "when the feature flag is enabled" do
      before do
        Account.site_admin.enable_feature!(:log_cross_domain_file_access)
        allow(LoadAccount).to receive(:from_host).with("other.canvas.example").and_return(referrer_account)
        allow(LoadAccount).to receive(:from_host).with("this.canvas.example").and_return(request_account)
        v.monitor_cross_domain_access(request, files_domain)
      end

      context "when the request is nil" do
        let(:request) { nil }

        it "does not emit a stats event" do
          expect(InstStatsd::Statsd).not_to have_received(:event)
        end
      end

      context "when the referer is blank" do
        let(:referer) { "" }

        it "does not emit a stats event" do
          expect(InstStatsd::Statsd).not_to have_received(:event)
        end
      end

      context "when files_domain is true" do
        let(:files_domain) { true }
        let(:referrer_is_canvas_domain) { true }

        it "does not emit a stats event" do
          expect(InstStatsd::Statsd).not_to have_received(:event)
        end
      end

      context "when the referrer host matches the request host" do
        let(:referer) { "https://this.canvas.example/somewhere" }

        it "does not emit a stats event" do
          expect(InstStatsd::Statsd).not_to have_received(:event)
        end
      end

      context "when the referrer is not a known Canvas domain" do
        it "does not emit a stats event" do
          expect(InstStatsd::Statsd).not_to have_received(:event)
        end
      end

      context "when the referrer is another Canvas domain with the same account" do
        let(:referrer_is_canvas_domain) { true }
        let(:referrer_account) { instance_double(Account, id: 1) }

        it "does not emit a stats event" do
          expect(InstStatsd::Statsd).not_to have_received(:event)
        end
      end

      context "when the referrer is another Canvas domain with a different account" do
        let(:referrer_is_canvas_domain) { true }

        it "emits a cross_domain_file_access event" do
          expect(InstStatsd::Statsd).to have_received(:event).with(
            "File accessed from different Canvas domain",
            "Referrer: https://other.canvas.example/files/1, Request URL: https://this.canvas.example/files/2",
            type: "cross_domain_file_access",
            alert_type: :warning
          )
        end
      end

      context "when the referer URI is invalid" do
        let(:referer) { "http://[bad" }

        it "does not emit a stats event" do
          expect(InstStatsd::Statsd).not_to have_received(:event)
        end
      end
    end
  end
end
