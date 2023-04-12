# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

module ActiveSupport::Callbacks::Suspension
  describe Registry do
    context "#any_registered?" do
      it "is false when nothing has been registered" do
        expect(Registry.new.any_registered?(:find)).to be false
      end

      it "is true when a suspension has been registered" do
        registry = Registry.new
        registry.update([], [:find], [])
        expect(registry.any_registered?(:find)).to be true
      end

      it "is still false when a suspension has been registered, then removed" do
        registry = Registry.new
        delta = registry.update([], [:find], [])
        registry.revert(delta)
        expect(registry.any_registered?(:find)).to be false
      end

      it "is true when a global suspension has been registered" do
        registry = Registry.new
        registry.update([], [], [])
        expect(registry.any_registered?(:find)).to be true
      end
    end
  end
end
