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
  let_once(:user) { user_model }
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
      allow(InstStatsd::Statsd).to receive(:increment)
    end

    it "verifies a legacy verifier for read and download" do
      expect(v.valid_verifier_for_permission?(attachment.uuid, :read)).to be(true)
      expect(v.valid_verifier_for_permission?(attachment.uuid, :download)).to be(true)
      expect(InstStatsd::Statsd).to have_received(:increment).with("attachments.legacy_verifier_success").twice
    end

    it "accepts the uuid of another copy of the file" do
      clone = attachment.clone_for(course_factory)
      clone.save!
      v2 = Attachments::Verification.new(clone)
      expect(v2.valid_verifier_for_permission?(attachment.uuid, :read)).to be true
      expect(v2.valid_verifier_for_permission?(attachment.uuid, :download)).to be true
      expect(InstStatsd::Statsd).to have_received(:increment).with("attachments.related_verifier_success").twice
      expect(InstStatsd::Statsd).to have_received(:increment).with("feature_flag_check", any_args).at_least(:once)
    end

    it "returns false on an invalid verifier" do
      expect(CanvasSecurity).to receive(:decode_jwt).with("token").and_raise(CanvasSecurity::InvalidToken)
      expect(v.valid_verifier_for_permission?("token", :read)).to be(false)
      expect(InstStatsd::Statsd).to have_received(:increment).with("attachments.token_verifier_invalid")
    end

    it "returns false on a verifier that is not of type String" do
      unsupported_verifier = 1
      expect(v.valid_verifier_for_permission?(unsupported_verifier, :read)).to be(false)
    end

    it "returns false on token id mismatch" do
      expect(CanvasSecurity).to receive(:decode_jwt).with("token").and_return({
                                                                                id: attachment.global_id + 1
                                                                              })
      expect(v.valid_verifier_for_permission?("token", :read)).to be(false)
      expect(InstStatsd::Statsd).to have_received(:increment).with("attachments.token_verifier_id_mismatch")
    end

    it "does not let a student download an attachment that's locked" do
      att2 = attachment_model(context: course)
      att2.update_attribute(:locked, true)
      v2 = Attachments::Verification.new(att2)
      expect(CanvasSecurity).to receive(:decode_jwt).with("token").and_return({
                                                                                id: att2.global_id, user_id: student.global_id
                                                                              }).twice
      expect(v2.valid_verifier_for_permission?("token", :read)).to be(true)
      expect(v2.valid_verifier_for_permission?("token", :download)).to be(false)
      expect(InstStatsd::Statsd).to have_received(:increment).with("attachments.token_verifier_success").twice
      expect(InstStatsd::Statsd).to have_received(:increment).with("feature_flag_check", any_args).at_least(:once)
    end

    it "follows custom permissions" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: true
      v2 = Attachments::Verification.new(att2)
      other_user = user_model
      token = v2.verifier_for_user(other_user, context: eportfolio.asset_string, permission_map_id: :r_rd)
      expect(v2.valid_verifier_for_permission?(token, :read)).to be(true)
      expect(v2.valid_verifier_for_permission?(token, :download)).to be(true)
      # revoke :read on the eportfolio, and the verifier should no longer work
      Timecop.travel(2.seconds) do # allow the eportfolio's updated_at to change to invalidate the permissions cache
        eportfolio.public = false
        eportfolio.save!
        expect(v2.valid_verifier_for_permission?(token, :read)).to be(false)
        expect(v2.valid_verifier_for_permission?(token, :download)).to be(false)
      end
    end

    it "supports session-based permissions" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: false
      v2 = Attachments::Verification.new(att2)
      other_user = user_model
      token = v2.verifier_for_user(other_user, context: eportfolio.asset_string, permission_map_id: :r_rd)
      expect(v2.valid_verifier_for_permission?(token, :read)).to be(false)
      expect(v2.valid_verifier_for_permission?(token, :download)).to be(false)

      mock_session = { eportfolio_ids: [eportfolio.id], permissions_key: SecureRandom.uuid }
      expect(v2.valid_verifier_for_permission?(token, :read, mock_session)).to be(true)
      expect(v2.valid_verifier_for_permission?(token, :download, mock_session)).to be(true)
    end

    it "supports custom permissions checks on nil (public) user" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: false
      v2 = Attachments::Verification.new(att2)
      token = v2.verifier_for_user(nil, context: eportfolio.asset_string, permission_map_id: :r_rd)

      expect(v2.valid_verifier_for_permission?(token, :read)).to be(false)
      expect(v2.valid_verifier_for_permission?(token, :download)).to be(false)
      mock_session = { eportfolio_ids: [eportfolio.id], permissions_key: SecureRandom.uuid }
      expect(v2.valid_verifier_for_permission?(token, :read, mock_session)).to be(true)
      expect(v2.valid_verifier_for_permission?(token, :download, mock_session)).to be(true)
    end
  end
end
