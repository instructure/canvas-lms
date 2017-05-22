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

require "selinimum/detectors/ruby_detector"

describe Selinimum::Detectors::RubyDetector do
  describe "#can_process?" do
    it "processes ruby files in the right path" do
      expect(subject.can_process?("app/views/users/user.html.erb", {})).to be_truthy
      expect(subject.can_process?("app/views/users/_partial.html.erb", {})).to be_truthy
      expect(subject.can_process?("app/controllers/users_controller.rb", {})).to be_truthy
      expect(subject.can_process?("spec/selenium/users_spec.rb", {})).to be_truthy
    end

    it "doesn't process global-y files" do
      expect(subject.can_process?("app/views/layouts/application.html.erb", {})).to be_falsy
      expect(subject.can_process?("app/views/shared/_foo.html.erb", {})).to be_falsy
      expect(subject.can_process?("app/controllers/application_controller.rb", {})).to be_falsy
    end

    it "doesn't process other ruby files" do
      expect(subject.can_process?("app/models/user.rb", {})).to be_falsy
      expect(subject.can_process?("lib/foo.rb", {})).to be_falsy
    end
  end

  describe "#dependents_for" do
    it "returns the file itself" do
      expect(subject.dependents_for("app/views/users/user.html.erb")).to eql(["file:app/views/users/user.html.erb"])
    end
  end
end

