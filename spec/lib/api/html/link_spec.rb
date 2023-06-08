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
require_relative "../../../spec_helper"

module Api
  module Html
    describe Link do
      describe "#to_corrected_s" do
        it "returns the raw string if it isnt a link" do
          expect(Link.new("nonsense-data").to_corrected_s).to eq "nonsense-data"
        end

        context "for user context attachment links" do
          before do
            allow(Attachment).to receive(:where).with(id: "1").and_return(double(first: double(context_type: "User")))
          end

          it "returns the raw string for a user content link" do
            raw_link = "/users/1/files/1/download?verifier=123"
            expect(Link.new(raw_link).to_corrected_s).to eq raw_link
          end

          it "returns the raw string for a user content link even with a host" do
            raw_link = "http://something.instructure.com/files/1/download?verifier=123"
            expect(Link.new(raw_link).to_corrected_s).to eq raw_link
          end
        end

        it "strips out verifiers for Course links and scopes them to the course" do
          course_attachment = double(context_type: "Course", context_id: 1)
          allow(Attachment).to receive(:where).with(id: "1").and_return(double(first: course_attachment))
          raw_link = "/files/1/download?verifier=123"
          expect(Link.new(raw_link).to_corrected_s).to eq "/courses/1/files/1/download?"
        end

        it "scopes to the context if url includes the host" do
          course_attachment = double(context_type: "Course", context_id: 1)
          allow(Attachment).to receive(:where).with(id: "1").and_return(double(first: course_attachment))
          host = "account.instructure.com"
          port = 443
          raw_link = "https://#{host}/files/1/download?verifier=123"
          expect(Link.new(raw_link, host:, port:).to_corrected_s).to eq "/courses/1/files/1/download?"
        end

        it "strips the current host from absolute urls" do
          course_attachment = double(context_type: "Course", context_id: 1)
          allow(Attachment).to receive(:where).with(id: "1").and_return(double(first: course_attachment))
          host = "account.instructure.com"
          port = 443
          raw_link = "https://#{host}/courses/1/files/1/download?"
          expect(Link.new(raw_link, host:, port:).to_corrected_s).to eq "/courses/1/files/1/download?"
        end

        it "does not scope to the context if url includes a differnt host" do
          course_attachment = double(context_type: "Course", context_id: 1)
          allow(Attachment).to receive(:where).with(id: "1").and_return(double(first: course_attachment))
          host = "account.instructure.com"
          port = 443
          raw_link = "https://#{host}/files/1/download"
          expect(Link.new(raw_link, host: "other-host", port:).to_corrected_s).to eq raw_link
        end

        it "does not strip the current host if the ports do not match" do
          course_attachment = double(context_type: "Course", context_id: 1)
          allow(Attachment).to receive(:where).with(id: "1").and_return(double(first: course_attachment))
          host = "localhost"
          port = 3000
          raw_link = "https://#{host}:8080/some/other/file"
          expect(Link.new(raw_link, host:, port:).to_corrected_s).to eq raw_link
        end
      end
    end
  end
end
