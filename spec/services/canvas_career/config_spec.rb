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
#

module CanvasCareer
  describe Config do
    let(:root_account) { Account.default }
    let(:request) { instance_double(ActionDispatch::Request, base_url: "https://canvascareer.instructure.com") }
    let(:dynamic_settings_yaml) do
      {
        "public_app_config" => {
          "hosts" => {}
        }
      }.to_yaml
    end

    before do
      dynamic_settings = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_call_original
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(dynamic_settings)
      allow(dynamic_settings).to receive(:[]).and_return(nil)
      allow(dynamic_settings).to receive(:[]).with("canvas_career.yml", failsafe: nil).and_return(dynamic_settings_yaml)
    end

    describe "public_app_config" do
      context "when horizon_academic_mode is not set" do
        it "returns experience preferences with skillspace and learner_assist enabled" do
          config = Config.new(root_account)
          result = config.public_app_config(request)

          expect(result["hosts"]["canvas"]).to eq("https://canvascareer.instructure.com")
          expect(result["experience_preferences"]).to eq({
                                                           features: {
                                                             notebook: true,
                                                             skillspace: true,
                                                             learner_assist: true,
                                                           }
                                                         })
        end
      end

      context "when horizon_academic_mode is true" do
        it "returns experience preferences with rubrics enabled" do
          root_account.settings[:horizon_academic_mode] = true
          root_account.save!

          config = Config.new(root_account)
          result = config.public_app_config(request)

          expect(result["hosts"]["canvas"]).to eq("https://canvascareer.instructure.com")
          expect(result["experience_preferences"]).to eq({
                                                           features: {
                                                             notebook: true,
                                                             skillspace: false,
                                                             learner_assist: false,
                                                           }
                                                         })
        end
      end
    end
  end
end
