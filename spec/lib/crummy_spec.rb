#
# Copyright (C) 2013 Instructure, Inc.
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

# add_crumb would only execute the proc once, making the crumb
# first crumb name returned stick, even when the crumb name
# should have been re-evaluated
#
# this caused particular problem with class-level crumbs; a crumb
# name would only be evaluated once, preventing translation of a
# crumb, among other things
describe "CrummyController" do
  CrummyController = Class.new(super_class=ActionController::Base) do
    def self.filter_blocks
      @filter_blocks ||= []
    end

    def self.before_action(*filters, &block)
      filter_blocks.push block
    end

    def run_filter_blocks
      self.class.filter_blocks.each do |filter_block|
        filter_block.call self
      end
    end
  end

  context "name proc" do
    name_run = false
    name_run_proc = proc { |instance|
      if !name_run
        name_run = true
        "A"
      else
        "B"
      end
    }

    CrummyNameController = Class.new(super_class=CrummyController) do
      add_crumb(name_run_proc, "http://")
    end

    it "should reevaluate the proc on each run" do
      # first run should add crumb "A"
      a = CrummyNameController.new
      a.run_filter_blocks
      expect(a.crumbs.length).to eq 1
      expect(a.crumbs[0][0]).to eq "A"

      # second run should add crumb "B"
      b = CrummyNameController.new
      b.run_filter_blocks
      expect(b.crumbs.length).to eq 1
      expect(b.crumbs[0][0]).to eq "B"
    end
  end

  context "url proc" do
    url_run = false
    url_run_proc = proc { |instance|
      if !url_run
        url_run = true
        "http://a"
      else
        "http://b"
      end
    }

    CrummyUrlController = Class.new(super_class=CrummyController) do
      add_crumb("Name", &url_run_proc)
    end

    it "should reevaluate the proc on each run" do
      # first run should add crumb "A"
      a = CrummyUrlController.new
      a.run_filter_blocks
      expect(a.crumbs.length).to eq 1
      expect(a.crumbs[0][1]).to eq "http://a"

      # second run should add crumb "B"
      b = CrummyUrlController.new
      b.run_filter_blocks
      expect(b.crumbs.length).to eq 1
      expect(b.crumbs[0][1]).to eq "http://b"
    end
  end
end
