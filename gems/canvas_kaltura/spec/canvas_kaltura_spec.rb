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

require 'spec_helper'

describe CanvasKaltura do
  context ".timeout_protector" do
    it "call block if not set" do
      CanvasKaltura.timeout_protector_proc = nil
      expect(CanvasKaltura.with_timeout_protector { 2 }).to be 2
    end

    it "call timeout protector if set" do
      CanvasKaltura.timeout_protector_proc = lambda { |options, &block| 27 }
      expect(CanvasKaltura.with_timeout_protector).to be 27
    end
  end
end
