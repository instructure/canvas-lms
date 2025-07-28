# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Flamegraphs::FlamegraphService do
  describe ".call" do
    let(:service) { Flamegraphs::FlamegraphService }
    let(:user) { site_admin_user }
    let(:source_name) { "gradebooks#speed_grader" }
    let(:attachment) { user.attachments.last }
    let(:html) { attachment.open.read }

    it "creates an attachment with an HTML flamegraph" do
      expect do
        service.call(user:, source_name:, custom_name: "custom-label") do
          # We need some operation that will take at least 1 ms in order
          # to capture at least one sample stack.
          (0..10_000).map { |i| i**i }
        end
      end.to change { user.attachments.count }.by(1)

      aggregate_failures do
        expect(attachment.display_name).to match(/^flamegraph-custom-label-gradebooks#speed_grader-.+$/)
        expect(attachment.filename).to match(/^flamegraph-custom-label-gradebooks#speed_grader-.+\.html$/)
        expect(attachment.content_type).to eql "text/html"
        expect(attachment.root_account).to eql Account.site_admin
        expect(html).to start_with("<!DOCTYPE html>")
        expect(html).to match(%r{<title>stackprof \(mode: wall\)</title>})
      end
    end

    it "creates an attachment with error information if an error occurs while generating the flamegraph" do
      service.call(user:, source_name:) { raise "Kaboom!" }

      aggregate_failures do
        expect(attachment.display_name).to match(/^flamegraph-error-gradebooks#speed_grader-.+$/)
        expect(attachment.filename).to match(/^flamegraph-error-gradebooks#speed_grader-.+\.html$/)
        expect(attachment.content_type).to eql "text/html"
        expect(attachment.root_account).to eql Account.site_admin
        expect(html).to start_with("<!DOCTYPE html>")
        expect(html).to include("<h1>Error Generating Flamegraph</h1>")
        expect(html).to include("<h2>Kaboom! (RuntimeError)</h2>")
      end
    end

    it "raises an error when not given a block" do
      expect do
        service.call(user:, source_name:)
      end.to raise_error(Flamegraphs::FlamegraphService::NoBlockError, "Must provide a block!")
    end

    it "raises an error when user is not a site admin user" do
      expect do
        service.call(user: account_admin_user, source_name:) { "a block.." }
      end.to raise_error(Flamegraphs::FlamegraphService::NonSiteAdminError, "Must be a siteadmin user!")
    end
  end
end
