#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradebooksHelper do
  
  #Delete this example and add some real ones or delete this file
  it "should be included in the object returned by #helper" do
    included_modules = (class << helper; self; end).send :included_modules
    included_modules.should be_include(GradebooksHelper)
  end

  describe "gradebook_url_for" do
    let(:user) { User.new }
    let(:context) { course }
    let(:assignment) { nil }

    subject {
      helper.gradebook_url_for(user, context, assignment)
    }

    before do
      context.stubs(:id => 1)
    end

    context "when the user prefers gradebook1" do
      before { user.stubs(:prefers_gradebook2? => false) }

      it { should match /#{"/courses/1/gradebook"}$/ }

      context "with an assignment" do
        let(:assignment) { mock(:id => 2) }

        it { should match /#{"/courses/1/gradebook#assignment/2"}$/ }
      end
    end

    context "when the user prefers gradebook2" do
      before { user.stubs(:prefers_gradebook2? => true) }

      it { should match /#{"/courses/1/gradebook2"}$/ }

      context "with an assignment" do
        let(:assignment) { stubs(:id => 2) }

        # Doesn't include the assignment
        it { should match /#{"/courses/1/gradebook2"}$/ }
      end
    end

    context "with a nil user" do
      let(:user) { nil }
      it { should match /#{"/courses/1/gradebook2"}$/ }
    end
  end
end
