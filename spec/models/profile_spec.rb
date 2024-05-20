# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Profile do
  context "sub-classing" do
    # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
    # Profile accesses klass.name in its inherited hook, so we can't stub this
    before do
      class FooProfile < Profile; end

      class Foo < ActiveRecord::Base
        self.table_name = :users
        prepend Profile::Association
        def root_account
          Account.default
        end
      end
    end
    # rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration

    after do
      # rubocop:disable RSpec/RemoveConst
      Object.send(:remove_const, :FooProfile)
      Object.send(:remove_const, :Foo)
      # rubocop:enable RSpec/RemoveConst
    end

    describe "initialization" do
      it "is set by default" do
        expect(Foo.new.profile).not_to be_nil
      end

      it "has the correct class when initialized" do
        expect(Foo.new.profile.class).to eq FooProfile
      end

      it "has the correct class when found" do
        Foo.new(name: "foo", workflow_state: "registered").profile.save!
        expect(Profile.first.class).to eq FooProfile
      end
    end

    describe ".path" do
      it "is inferred from the title" do
        profile = Foo.create!(name: "My Foo!", workflow_state: "registered").profile
        expect(profile.path).to eq "my-foo"
        profile.save!

        profile2 = Foo.create!(name: "My Foo?!!!", workflow_state: "registered").profile
        expect(profile2.path).to eq "my-foo-1"
      end
    end

    describe "#data" do
      it "adds accessors" do
        FooProfile.class_eval do
          data :bar, default: []
        end
        profile = FooProfile.new
        expect(profile.data).to eq({})
        expect(profile.bar).to eq []
        expect(profile.data).to eq({ bar: [] })
        profile.bar = ["lol"]
        expect(profile.data).to eq({ bar: ["lol"] })
      end
    end
  end
end
