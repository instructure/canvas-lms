# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Lti::IMS::Concerns::AdvantageServices do
  let(:controller_class) { Lti::IMS::NamesAndRolesController }

  describe "tool" do
    it "finds only tools for the developer key and context" do
      dk1 = DeveloperKey.create!
      dk2 = DeveloperKey.create!
      c1 = course_model
      c2 = course_model
      tool = external_tool_1_3_model(context: c1, developer_key: dk1)

      results = {}
      [c1, c2].each do |ctx|
        [dk1, dk2].each do |dev_key|
          controller = controller_class.new
          expect(controller).to receive(:context).at_least(:once).and_return ctx
          expect(controller).to receive(:developer_key).at_least(:once).and_return dev_key
          results[[dev_key.id, ctx.id]] = controller.tool
        end
      end

      expect(results).to eq(
        [dk1.id, c1.id] => tool,
        [dk1.id, c2.id] => nil,
        [dk2.id, c1.id] => nil,
        [dk2.id, c2.id] => nil
      )
    end
  end
end
