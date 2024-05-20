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

require "apis/api_spec_helper"

describe "simply_versioned" do
  before :all do
    class Woozel < ActiveRecord::Base # rubocop:disable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration this needs to be a real class
      simply_versioned explicit: true
    end

    Woozel.connection.create_table :woozels, force: true do |t|
      t.string :name
    end
  end

  after :all do
    Woozel.connection.drop_table :woozels
    ActiveSupport::Dependencies::Reference.instance_variable_get(:@store).delete("Woozel")
    Object.send(:remove_const, :Woozel) # rubocop:disable RSpec/RemoveConst
    GC.start
  end

  describe "explicit versions" do
    let(:woozel) { Woozel.create!(name: "Eeyore") }

    it "creates the first version on save" do
      woozel = Woozel.new(name: "Eeyore")
      expect(woozel).not_to be_versioned
      woozel.save!
      expect(woozel).to be_versioned
      expect(woozel.versions.length).to be(1)
      expect(woozel.versions.current.model.name).to eql("Eeyore")
    end

    it "keeps the last version up to date for each save" do
      expect(woozel).to be_versioned
      expect(woozel.versions.length).to be(1)
      expect(woozel.versions.current.model.name).to eql("Eeyore")
      woozel.name = "Piglet"
      woozel.save!
      expect(woozel.versions.length).to be(1)
      expect(woozel.versions.current.model.name).to eql("Piglet")
    end

    it "creates a new version when asked to" do
      woozel.name = "Piglet"
      woozel.with_versioning(explicit: true, &:save!)
      expect(woozel.versions.length).to be(2)
      expect(woozel.versions.first.model.name).to eql("Eeyore")
      expect(woozel.versions.current.model.name).to eql("Piglet")
    end

    it "does not create a new version when not explicitly asked to" do
      woozel.name = "Piglet"
      woozel.with_versioning(&:save!)
      expect(woozel.versions.length).to be(1)
      expect(woozel.versions.current.model.name).to eql("Piglet")
    end

    it "does not update the last version when not versioning" do
      woozel.name = "Piglet"
      woozel.without_versioning(&:save!)
      expect(woozel.versions.length).to be(1)
      expect(woozel.versions.current.model.name).to eql("Eeyore")
    end

    it "does not reload one versionable association from the database" do
      woozel.name = "Piglet"
      woozel.with_versioning(&:save!)
      expect(woozel.versions.loaded?).to be false
      first = woozel.versions.first
      expect(Woozel.connection).not_to receive(:select_all)
      expect(first.versionable).to eq woozel
    end

    it "does not reload any versionable associations from the database" do
      woozel.name = "Piglet"
      woozel.with_versioning(&:save!)
      expect(woozel.versions.loaded?).to be false
      all = woozel.versions.to_a
      expect(Woozel.connection).not_to receive(:select_all)
      all.each do |version|
        expect(version.versionable).to eq woozel
      end
    end
  end

  describe "#model=" do
    let(:woozel) { Woozel.create!(name: "Eeyore") }

    it "assigns the model for the version" do
      expect(woozel.versions.length).to be(1)
      expect(woozel.versions.current.model.name).to eql("Eeyore")

      woozel.name = "Piglet"
      woozel.with_versioning(explicit: true, &:save!)

      expect(woozel.versions.length).to be(2)

      first_version = woozel.versions.first
      first_model   = first_version.model
      expect(first_model.name).to eql("Eeyore")

      first_model.name = "Foo"
      first_version.model = first_model
      first_version.save!

      versions = woozel.reload.versions
      expect(versions.first.model.name).to eql("Foo")
    end
  end

  describe "#current_version?" do
    before do
      @woozel = Woozel.create! name: "test"
      @woozel.with_versioning(explicit: true, &:save!)
    end

    it "is always true for models loaded directly from AR" do
      expect(@woozel).to be_current_version
      @woozel = Woozel.find(@woozel.id)
      expect(@woozel).to be_current_version
      @woozel.reload
      expect(@woozel).to be_current_version
      expect(Woozel.new(name: "test2")).to be_current_version
    end

    it "is false for the #model of any version" do
      expect(@woozel.versions.current.model).not_to be_current_version
      expect(@woozel.versions.map { |v| v.model.current_version? }).to eq [false, false]
    end
  end

  describe "#versions.current_version" do
    before do
      @woozel = Woozel.new name: "test"
    end

    it "returns nil when no current version is available" do
      expect(@woozel.versions.current_version).to be_nil

      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.current_version).not_to be_nil
    end

    it "returns the latest version" do
      @woozel.with_versioning(explicit: true, &:save!)
      @woozel.name = "testier"
      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.current_version.model.name).to eq "testier"
    end
  end

  describe "#versions.previous_version" do
    before do
      @woozel = Woozel.new name: "test"
    end

    it "returns nil when no previous version is available" do
      expect(@woozel.versions.previous_version).to be_nil

      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.previous_version).to be_nil

      @woozel.with_versioning(explicit: true, &:save!)
      expect(@woozel.versions.previous_version).not_to be_nil
    end

    context "with previous versions" do
      before do
        @woozel.with_versioning(explicit: true, &:save!)
        @woozel.name = "testier"
        @woozel.with_versioning(explicit: true, &:save!)
        @woozel.name = "testiest"
        @woozel.with_versioning(explicit: true, &:save!)
      end

      it "returns the previous version" do
        expect(@woozel.versions.previous_version.model.name).to eq "testier"
      end

      it "returns the previous version for a specific number" do
        expect(@woozel.versions.previous_version(1)).to be_nil
        expect(@woozel.versions.previous_version(2).model.name).to eq "test"
      end
    end
  end

  context "callbacks" do
    let(:woozel) { Woozel.create!(name: "test") }

    context "on_load" do
      let(:on_load) do
        ->(model, _version) { model.name = "test override" }
      end

      before do
        woozel.simply_versioned_options[:on_load] = on_load
        woozel.reload
      end

      after do
        woozel.simply_versioned_options[:on_load] = nil
      end

      it "can modify a version after loading" do
        expect(YAML.load(woozel.current_version.yaml)["name"]).to eq "test"
        expect(woozel.current_version.model.name).to eq "test override"
      end
    end
  end
end
