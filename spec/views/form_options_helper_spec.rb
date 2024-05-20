# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe ActionView::Helpers::FormOptionsHelper do
  describe "#time_zone_options_for_select" do
    let(:form) do
      f = Object.new
      f.extend(ActionView::Helpers::FormOptionsHelper)
      f
    end

    it "does not include non-Rails zones by default" do
      expect(form.time_zone_options_for_select).not_to include("Africa/Lagos")
    end

    it "includes non-rails zone when the non-rails zone is selected" do
      expect(form.time_zone_options_for_select("Africa/Lagos")).to include("Africa/Lagos (+")
    end
  end
end
