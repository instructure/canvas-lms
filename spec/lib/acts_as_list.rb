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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "acts_as_list" do
  describe "#update_order" do
    it "should cast id input" do
      a1 = attachment_model
      a2 = attachment_model
      a3 = attachment_model
      a4 = attachment_model
      Attachment.expects(:update_all).with("position=CASE WHEN id=#{a2.id} THEN 1 WHEN id=#{a3.id} THEN 2 WHEN id=#{a1.id} THEN 3 WHEN id=#{a4.id} THEN 4 ELSE 0 END", anything)
      Attachment.expects(:update_all).with("position=CASE WHEN id=#{a3.id} THEN 1 WHEN id=#{a1.id} THEN 2 WHEN id=#{a2.id} THEN 3 WHEN id=#{a4.id} THEN 4 ELSE 0 END", anything)
      a1.update_order([a2.id, a3.id, a1.id])
      a1.update_order(["SELECT now()", a3.id, "evil stuff"])
    end
  end
end

