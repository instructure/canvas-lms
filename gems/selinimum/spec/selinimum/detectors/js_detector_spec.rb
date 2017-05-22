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

require "selinimum/detectors/js_detector"

describe Selinimum::Detectors::JSDetector do
  describe "#can_process?" do
    it "processes js files in the right path" do
      expect(subject.can_process?("public/javascripts/quizzes.js", {})).to be_truthy
    end
  end

  describe "#dependents_for" do
    it "finds top-level bundle(s)" do
      expect(subject)
        .to receive(:graph).and_return({"./public/javascripts/foo.js" => ["bar"]})
      expect(subject.dependents_for("public/javascripts/foo.js")).to eql(["js:bar"])
    end

    it "raises on no bundle" do
      expect(subject)
        .to receive(:graph).and_return({})
      expect { subject.dependents_for("public/javascripts/foo.js") }.to raise_error(Selinimum::UnknownDependentsError)
    end

    it "raises on the common bundle" do
      expect(subject)
        .to receive(:graph).and_return({"./public/javascripts/foo.js" => ["common"]})
      expect { subject.dependents_for("public/javascripts/foo.js") }.to raise_error(Selinimum::TooManyDependentsError)
    end
  end
end
