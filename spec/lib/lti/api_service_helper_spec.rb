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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Lti
  class TestClass
    include ApiServiceHelper

    attr_accessor :request

    def initialize(request)
      @request = request
    end

    def tool_proxy
      @tool_proxy
    end


  end

  describe ApiServiceHelper do
    subject { TestClass.new(request) }
    let(:request) do
      m = mock('request')
      m.stubs(authorization:"")
      body = StringIO.new
      body.write('abc123')
      body.rewind
      m.stubs(body: body)
      m
    end
    let(:course){Course.create}
    let(:root_account){Account.create}
    let(:product_family) {
      Lti::ProductFamily.create!(vendor_code: 'a', product_code: 'b', vendor_name: 'c', root_account: root_account )
    }

    before(:each) do
      @tool_proxy = ToolProxy.create!(
          guid: 'key', shared_secret: 'secret', product_version: 1,
          lti_version: 'LTIv2p0', workflow_state: 'active', raw_data: '{}',
          product_family: product_family, context: course
      )
      OAuth::Helper.stubs(parse_header: {})
    end

    describe "#lti_authenticate" do
      before(:each) do
        subject.stubs(oauth_consumer_key: 'key')
        subject.stubs(oauth_authenticated_request?: true)
      end

      it "finds the tool_proxy" do
        expect(subject.lti_authenticate).to be_truthy
        expect(subject.tool_proxy).to eq @tool_proxy
      end

      it "renders unauthorized unless tool proxy exists" do
        subject.expects(:render_unauthorized_api)
        subject.stubs(oauth_consumer_key: 'wrong-key')
        expect(subject.lti_authenticate).to be_falsey
      end

      it "renders unauthorized unless signature validates" do
        subject.expects(:render_unauthorized_api)
        subject.stubs(oauth_authenticated_request?: false)
        expect(subject.lti_authenticate).to be_falsey
      end

      it "rejects an invalid body_hash" do
        OAuth::Helper.stubs(parse_header: {'oauth_body_hash' => 'abc'})
        subject.expects(:render_unauthorized_api)
        expect(subject.lti_authenticate).to be_falsey
      end

    end
  end
end
