# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe DumpHelper do
  it "complains about hashes with default procs" do
    val = Hash.new { nil }
    expect { DumpHelper.find_dump_error(val) }.to raise_error(/^val: can't dump hash with default proc: #<Proc:/)
  end

  it "complains about singleton methods" do
    val = Object.new
    def val.stuff; end
    expect { DumpHelper.find_dump_error(val) }.to raise_error("val: singleton can't be dumped (#<Object>): [:stuff]")
  end

  it "complains about procs in general" do
    expect { DumpHelper.find_dump_error(-> {}) }.to raise_error("val: no _dump_data is defined for class Proc")
  end

  it "searches through ivars" do
    val = Object.new
    val.instance_variable_set(:@ivar, -> {})
    expect { DumpHelper.find_dump_error(val) }.to raise_error("val.instance_variable_get(:@ivar): no _dump_data is defined for class Proc")
  end

  it "searches arrays" do
    val = [-> {}]
    expect { DumpHelper.find_dump_error(val) }.to raise_error("val[0]: no _dump_data is defined for class Proc")
  end

  it "searches hash keys" do
    val = { -> {} => 1 }
    expect { DumpHelper.find_dump_error(val) }.to raise_error("val.keys[0]: no _dump_data is defined for class Proc")
  end

  it "searches hash values" do
    val = { a: -> {} }
    expect { DumpHelper.find_dump_error(val) }.to raise_error("val[:a]: no _dump_data is defined for class Proc")
  end

  it "keeps searching even in the face of self-referential problems" do
    val = {}
    val[:o] = val
    val[:p] = -> {}
    expect { DumpHelper.find_dump_error(val) }.to raise_error("val[:p]: no _dump_data is defined for class Proc")
  end

  it "searches deeply through a complicated object" do
    val = Object.new
    h = { a: 1, b: -> {}, c: 3 }
    a = [val, h, h]
    val.instance_variable_set(:@key, false)
    val.instance_variable_set(:@val, nil)
    val.instance_variable_set(:@self, val)
    val.instance_variable_set(:@a, a)

    expect { DumpHelper.find_dump_error(val) }.to raise_error("val.instance_variable_get(:@a)[1][:b]: no _dump_data is defined for class Proc")
  end
end
