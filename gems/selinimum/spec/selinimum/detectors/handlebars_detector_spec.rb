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

require "selinimum/detectors/handlebars_detector"

describe Selinimum::Detectors::HandlebarsDetector do
  before do
    allow_any_instance_of(Selinimum::Detectors::HandlebarsDetector)
      .to receive(:template_graph).and_return({
        "app/views/jst/foo/_item.handlebars" => ["app/views/jst/foo/_items.handlebars"],
        "app/views/jst/foo/_items.handlebars" => ["app/views/jst/foo/template.handlebars"]
      })
  end

  describe "#can_process?" do
    it "process handlebars files in the right path" do
      expect(subject.can_process?("app/views/jst/foo/_item.handlebars", {})).to be_truthy
    end
  end
end
