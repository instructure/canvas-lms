# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Auditors::ActiveRecord::Attributes do
  describe "treating a model like it has event stream attributes" do
    before :each do
      @model_type = Class.new do
        include Auditors::ActiveRecord::Attributes
        def method_one
          :one
        end

        def method_two
          :two
        end

        def method_three
          @_three
        end

        def method_three=(value)
          @_three = value
        end
      end
    end

    it "transparently fetches values" do
      model = @model_type.new
      expect(model['attributes']['method_one']).to eq(:one)
      expect(model['attributes'].fetch('method_two')).to eq(:two)
    end

    it "sets values too" do
      model = @model_type.new
      model['attributes']['method_three'] = :four
      expect(model['attributes'].fetch('method_three')).to eq(:four)
    end
  end
end