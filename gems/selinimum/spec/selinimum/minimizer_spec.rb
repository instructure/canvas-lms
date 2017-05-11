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

require "selinimum/minimizer"

describe Selinimum::Minimizer do
  describe "#filter" do
    class NopeDetector
      def can_process?(_, _)
        true
      end

      def dependents_for(file)
        raise Selinimum::TooManyDependentsError, file
      end

      def commit_files=(*); end
    end

    class FooDetector
      def can_process?(file, _)
        file =~ /foo/
      end

      def dependents_for(file)
        ["file:#{file}"]
      end

      def commit_files=(*); end
    end

    let(:spec_dependency_map) { { "spec/selenium/foo_spec.rb" => ["file:app/views/foos/show.html.erb"] } }
    let(:spec_files) do
      [
        "spec/selenium/foo_spec.rb",
        "spec/selenium/bar_spec.rb"
      ]
    end

    it "returns the spec_files if there is no corresponding dependent detector" do
      minimizer = Selinimum::Minimizer.new(spec_dependency_map, [])

      expect(minimizer.filter(["app/views/foos/show.html.erb"], spec_files)).to eql(spec_files)
    end

    it "returns the spec_files if a file's dependents can't be inferred" do
      minimizer = Selinimum::Minimizer.new(spec_dependency_map, [NopeDetector.new])

      expect(minimizer.filter(["app/views/foos/show.html.erb"], spec_files)).to eql(spec_files)
    end

    it "returns the filtered spec_files if every file's dependents can be inferred" do
      minimizer = Selinimum::Minimizer.new(spec_dependency_map, [FooDetector.new])

      expect(minimizer.filter(["app/views/foos/show.html.erb"], spec_files)).to eql(["spec/selenium/foo_spec.rb"])
    end
  end
end
