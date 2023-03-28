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

describe Auditors do
  describe ".stream" do
    it "constructs an event stream object with config on board" do
      ar_klass = Class.new
      record_klass = Class.new
      stream_obj = Auditors.stream do
        backend_strategy -> { :active_record }
        active_record_type ar_klass
        record_type record_klass
        table :test_stream_items
      end
      expect(stream_obj).to be_a(EventStream::Stream)
    end
  end
end
