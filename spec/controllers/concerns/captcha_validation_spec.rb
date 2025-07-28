# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe CaptchaValidation do
  controller(ApplicationController) do
    include CaptchaValidation
  end

  before do
    allow(DynamicSettings).to receive(:find).and_return({ "recaptcha_server_key" => "test_key" })
  end

  describe "#validate_captcha" do
    it "returns nil when captcha key is not configured" do
      allow(DynamicSettings).to receive(:find).and_return({})
      expect(controller.send(:validate_captcha)).to be_nil
    end

    it "returns nil for authenticated users" do
      controller.instance_variable_set(:@current_user, double(User))
      expect(controller.send(:validate_captcha)).to be_nil
    end

    it "returns error when captcha verification fails" do
      allow(CanvasHttp).to receive(:post).and_return(
        double(code: "200", body: { "success" => false, "error-codes" => ["invalid-input"] }.to_json)
      )
      expect(controller.send(:validate_captcha)).to eq(["invalid-input"])
    end

    it "returns error when hostname doesn't match" do
      allow(CanvasHttp).to receive(:post).and_return(
        double(code: "200", body: { "success" => true, "hostname" => "wrong.host" }.to_json)
      )
      allow(controller.request).to receive(:host).and_return("correct.host")
      expect(controller.send(:validate_captcha)).to eq(["invalid-hostname"])
    end

    it "returns nil when verification succeeds" do
      allow(CanvasHttp).to receive(:post).and_return(
        double(code: "200", body: { "success" => true, "hostname" => "test.host" }.to_json)
      )
      allow(controller.request).to receive(:host).and_return("test.host")
      expect(controller.send(:validate_captcha)).to be_nil
    end

    it "raises error when captcha service fails" do
      allow(CanvasHttp).to receive(:post).and_return(double(code: "500"))
      expect { controller.send(:validate_captcha) }.to raise_error(/Failed to connect to captcha service/)
    end
  end
end
