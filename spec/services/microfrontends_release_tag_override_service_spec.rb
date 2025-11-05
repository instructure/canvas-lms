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

require_relative "../spec_helper"

RSpec.describe MicrofrontendsReleaseTagOverrideService do
  let(:session) { {} }
  let(:service) { described_class.new(session) }

  describe "with valid session" do
    describe "#set_override" do
      it "stores override in session" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test")

        expect(session[:microfrontend_overrides]).to eq({ "canvas_career_learner" => "https://assets.instructure.com/test" })
      end

      it "stores multiple overrides" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test1")
        service.set_override(app: "canvas_career_learning_provider", assets_url: "https://assets.instructure.com/test2")

        expect(session[:microfrontend_overrides]).to eq({
                                                          "canvas_career_learner" => "https://assets.instructure.com/test1",
                                                          "canvas_career_learning_provider" => "https://assets.instructure.com/test2"
                                                        })
      end
    end

    describe "#get_override" do
      it "returns nil when no overrides set" do
        expect(service.get_override("canvas_career_learner")).to be_nil
      end

      it "returns override when set" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test")

        expect(service.get_override("canvas_career_learner")).to eq("https://assets.instructure.com/test")
      end

      it "returns nil for non-existent override" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test")

        expect(service.get_override("canvas_career_learning_provider")).to be_nil
      end
    end

    describe "#clear_overrides" do
      it "removes all overrides from session" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test1")
        service.set_override(app: "canvas_career_learning_provider", assets_url: "https://assets.instructure.com/test2")

        service.clear_overrides

        expect(session[:microfrontend_overrides]).to be_nil
      end
    end

    describe "#overrides_summary" do
      it "returns empty hash when no overrides set" do
        expect(service.overrides_summary).to eq({})
      end

      it "returns hash of all overrides" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test1")
        service.set_override(app: "canvas_career_learning_provider", assets_url: "https://assets.instructure.com/test2")

        summary = service.overrides_summary
        expect(summary).to eq({
                                "canvas_career_learner" => "https://assets.instructure.com/test1",
                                "canvas_career_learning_provider" => "https://assets.instructure.com/test2"
                              })
      end

      it "returns a copy of the overrides hash" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test")

        summary = service.overrides_summary
        summary["canvas_career_learner"] = "modified"

        expect(service.get_override("canvas_career_learner")).to eq("https://assets.instructure.com/test")
      end
    end

    describe "#overrides_active?" do
      it "returns false when no overrides set" do
        expect(service.overrides_active?).to be(false)
      end

      it "returns true when overrides are set" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test")

        expect(service.overrides_active?).to be(true)
      end

      it "returns false after clearing overrides" do
        service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test")
        service.clear_overrides

        expect(service.overrides_active?).to be(false)
      end
    end
  end

  describe "with nil session" do
    let(:service) { described_class.new(nil) }

    describe "#set_override" do
      it "does nothing" do
        expect { service.set_override(app: "canvas_career_learner", assets_url: "https://assets.instructure.com/test") }.not_to raise_error
      end
    end

    describe "#get_override" do
      it "returns nil" do
        expect(service.get_override("canvas_career_learner")).to be_nil
      end
    end

    describe "#clear_overrides" do
      it "does nothing" do
        expect { service.clear_overrides }.not_to raise_error
      end
    end

    describe "#overrides_summary" do
      it "returns empty hash" do
        expect(service.overrides_summary).to eq({})
      end
    end

    describe "#overrides_active?" do
      it "returns false" do
        expect(service.overrides_active?).to be(false)
      end
    end
  end
end
