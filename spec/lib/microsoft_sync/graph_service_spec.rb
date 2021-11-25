# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe MicrosoftSync::GraphService do
  subject { described_class.new("mytenant", foo: "bar") }

  it "passes the initialize parameters on to the GraphService::Http" do
    expect(subject.http.tenant).to eq("mytenant")
    expect(subject.http.extra_statsd_tags).to eq(foo: "bar")
  end

  %i[education_classes groups teams users].each do |met|
    describe "##{met}" do
      let(:endpoints) { subject.send(met) }

      it "is #{met} endpoints" do
        expect(endpoints).to be_a("MicrosoftSync::GraphService::#{met.to_s.camelcase}Endpoints".constantize)
      end

      it "passes the initialize parameters on to the endpoints' GraphService::Http" do
        expect(endpoints.http).to be_a(MicrosoftSync::GraphService::Http)
        expect(endpoints.http.tenant).to eq("mytenant")
        expect(endpoints.http.extra_statsd_tags).to eq(foo: "bar")
      end
    end
  end
end
