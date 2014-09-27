#
# Copyright (C) 2014 Instructure, Inc.
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
require_relative '../../../spec_helper.rb'

module Api
  module Html
    describe Link do
      describe '#to_corrected_s' do

        it 'returns the raw string if it isnt a link' do
          Link.new("nonsense-data").to_corrected_s.should == "nonsense-data"
        end

        context "for user context attachment links" do
          before do
            Attachment.stubs(:where).with(id: "1").returns(stub(first: stub(context_type: "User")))
          end

          it 'returns the raw string for a user content link' do
            raw_link = "/users/1/files/1/download?verifier=123"
            Link.new(raw_link).to_corrected_s.should == raw_link
          end

          it 'returns the raw string for a user content link even with a host' do
            raw_link = "http://something.instructure.com/files/1/download?verifier=123"
            Link.new(raw_link).to_corrected_s.should == raw_link
          end
        end

        it 'strips out verifiers for Course links and scopes them to the course' do
          course_attachment = stub(context_type: "Course", context_id: 1)
          Attachment.stubs(:where).with(id: "1").returns(stub(first: course_attachment))
          raw_link = "/files/1/download?verifier=123"
          Link.new(raw_link).to_corrected_s.should == "/courses/1/files/1/download?"
        end
      end
    end
  end
end
