# coding: utf-8
#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')

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
    it "should create a verifier with the attachment id and ctx" do
      Canvas::Security.expects(:create_jwt).with({
        id: attachment.global_id, user_id: student.global_id, ctx: course.asset_string
      }, nil).returns("thetoken")

      verifier = v.verifier_for_user(student, context: course.asset_string)
      expect(verifier).to eq("thetoken")
    end

    it "should not include user id if one is not specified" do
      Canvas::Security.expects(:create_jwt).with({
        id: attachment.global_id, ctx: course.asset_string
      }, nil).returns("thetoken")

      verifier = v.verifier_for_user(nil, context: course.asset_string)
      expect(verifier).to eq("thetoken")
    end

    it "should include the expiration if supplied" do
      expires = 1.hour.from_now
      Canvas::Security.expects(:create_jwt).with({
        id: attachment.global_id, ctx: course.asset_string
      }, expires).returns("thetoken")

      verifier = v.verifier_for_user(nil, context: course.asset_string, expires: expires)
      expect(verifier).to eq("thetoken")
    end
  end

  context "verifying a verifier" do
    it "should verify a legacy verifier for read and download" do
      CanvasStatsd::Statsd.expects(:increment).with("attachments.legacy_verifier_success").twice
      expect(v.valid_verifier_for_permission?(attachment.uuid, :read)).to eq(true)
      expect(v.valid_verifier_for_permission?(attachment.uuid, :download)).to eq(true)
    end

    it "should return false on an expired verifier" do
      Canvas::Security.expects(:decode_jwt).with("token").raises(Canvas::Security::TokenExpired)
      CanvasStatsd::Statsd.expects(:increment).with("attachments.token_verifier_expired")

      expect(v.valid_verifier_for_permission?("token", :read)).to eq(false)
    end

    it "should return false on an invalid verifier" do
      Canvas::Security.expects(:decode_jwt).with("token").raises(Canvas::Security::InvalidToken)
      CanvasStatsd::Statsd.expects(:increment).with("attachments.token_verifier_invalid")

      expect(v.valid_verifier_for_permission?("token", :read)).to eq(false)
    end

    it "should return false on token id mismatch" do
      Canvas::Security.expects(:decode_jwt).with("token").returns({
        id: attachment.global_id + 1
      })
      CanvasStatsd::Statsd.expects(:increment).with("attachments.token_verifier_id_mismatch")

      expect(v.valid_verifier_for_permission?("token", :read)).to eq(false)
    end

    it "should not let a student download an attachment that's locked" do
      att2 = attachment_model(context: course)
      att2.update_attribute(:locked, true)
      v2 = Attachments::Verification.new(att2)
      Canvas::Security.expects(:decode_jwt).with("token").returns({
        id: att2.global_id, user_id: student.global_id
      }).twice
      CanvasStatsd::Statsd.expects(:increment).with("attachments.token_verifier_success").twice

      expect(v2.valid_verifier_for_permission?("token", :read)).to eq(true)
      expect(v2.valid_verifier_for_permission?("token", :download)).to eq(false)
    end

    it "follows custom permissions" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: true
      v2 = Attachments::Verification.new(att2)
      other_user = user_model
      token = v2.verifier_for_user(other_user, context: eportfolio.asset_string, permission_map_id: :r_rd)
      expect(v2.valid_verifier_for_permission?(token, :read)).to eq(true)
      expect(v2.valid_verifier_for_permission?(token, :download)).to eq(true)
      # revoke :read on the eportfolio, and the verifier should no longer work
      Timecop.travel(2.seconds) do # allow the eportfolio's updated_at to change to invalidate the permissions cache
        eportfolio.public = false
        eportfolio.save!
        expect(v2.valid_verifier_for_permission?(token, :read)).to eq(false)
        expect(v2.valid_verifier_for_permission?(token, :download)).to eq(false)
      end
    end

    it "supports session-based permissions" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: false
      v2 = Attachments::Verification.new(att2)
      other_user = user_model
      token = v2.verifier_for_user(other_user, context: eportfolio.asset_string, permission_map_id: :r_rd)
      expect(v2.valid_verifier_for_permission?(token, :read)).to eq(false)
      expect(v2.valid_verifier_for_permission?(token, :download)).to eq(false)

      mock_session = {eportfolio_ids: [eportfolio.id], permissions_key: SecureRandom.uuid}
      expect(v2.valid_verifier_for_permission?(token, :read, mock_session)).to eq(true)
      expect(v2.valid_verifier_for_permission?(token, :download, mock_session)).to eq(true)
    end

    it "should support custom permissions checks on nil (public) user" do
      att2 = attachment_model(context: student)
      eportfolio = student.eportfolios.create! public: false
      v2 = Attachments::Verification.new(att2)
      token = v2.verifier_for_user(nil, context: eportfolio.asset_string, permission_map_id: :r_rd)

      expect(v2.valid_verifier_for_permission?(token, :read)).to eq(false)
      expect(v2.valid_verifier_for_permission?(token, :download)).to eq(false)
      mock_session = {eportfolio_ids: [eportfolio.id], permissions_key: SecureRandom.uuid}
      expect(v2.valid_verifier_for_permission?(token, :read, mock_session)).to eq(true)
      expect(v2.valid_verifier_for_permission?(token, :download, mock_session)).to eq(true)
    end
  end
end
