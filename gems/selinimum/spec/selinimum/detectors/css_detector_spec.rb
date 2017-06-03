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

require "selinimum/detectors/css_detector"

describe Selinimum::Detectors::CSSDetector do
  describe "#can_process?" do
    it "process scss files in the right path" do
      expect(subject.can_process?("app/stylesheets/foo.scss", {})).to be_truthy
    end
  end

  describe "#dependents_for" do
    let(:filename) { "app/stylesheets/_colors.scss" }

    it "finds top-level bundle(s)" do
      expect(subject)
        .to receive(:find_bundles_for).with(filename)
              .and_return(["app/stylesheets/bundles/foo.scss", "app/stylesheets/bundles/bar.scss"])
      expect(subject.dependents_for(filename)).to eql(["css:foo", "css:bar"])
    end

    it "defers to super if this belongs to a jst file" do
      expect_any_instance_of(Selinimum::Detectors::JSDetector)
        .to receive(:dependents_for).with("jst/foo").and_return(["js:foo"])
      expect(subject)
        .to receive(:find_bundles_for).with(filename).and_return(["app/stylesheets/jst/foo.scss"])

      expect(subject.dependents_for(filename)).to eql(["js:foo"])
    end

    it "raises on no bundle" do
      allow(subject).to receive(:find_bundles_for).with(filename).and_return([])
      expect { subject.dependents_for(filename) }.to raise_error(Selinimum::UnknownDependentsError)
    end

    it "raises on the common bundle" do
      allow(subject)
        .to receive(:find_bundles_for).with(filename).and_return(["app/stylesheets/bundles/common.scss"])
      expect { subject.dependents_for(filename) }.to raise_error(Selinimum::TooManyDependentsError)
    end
  end
end
