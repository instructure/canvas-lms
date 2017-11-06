#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe CutyCapt do
  before(:each) do 
    CutyCapt.config = nil
  end

  context "configuration" do
    it "should correctly look up parameters specified by string keys in the config" do
      ConfigFile.stub('cutycapt', { "path" => 'not used', 'timeout' => 1000 })
      expect(CutyCapt.config[:path]).to eq "not used"
      expect(CutyCapt.config[:timeout]).to eq 1000
    end
  end

  context "url validation" do
    it "should check for an http scheme" do
      ConfigFile.stub('cutycapt', { :path => 'not used' })
      expect(CutyCapt.verify_url("ftp://example.com/")).to be_falsey
      expect(CutyCapt.verify_url("http://example.com/")).to be_truthy
      expect(CutyCapt.verify_url("https://example.com/")).to be_truthy
    end

    it "should check for blacklisted domains" do
      ConfigFile.stub('cutycapt', { :path => 'not used', :domain_blacklist => ['example.com'] })

      expect(CutyCapt.verify_url("http://example.com/blah")).to be_falsey
      expect(CutyCapt.verify_url("http://foo.example.com/blah")).to be_falsey
      expect(CutyCapt.verify_url("http://bar.foo.example.com/blah")).to be_falsey
      expect(CutyCapt.verify_url("http://google.com/blah")).to be_truthy
    end

    it "should check for blacklisted ip blocks" do
      ConfigFile.stub('cutycapt', { :path => 'not used' })
      
      expect(CutyCapt.verify_url("http://10.0.1.1/blah")).to be_falsey
      expect(CutyCapt.verify_url("http://169.254.169.254/blah")).to be_falsey
      expect(CutyCapt.verify_url("http://4.4.4.4/blah")).to be_truthy

      allow(Resolv).to receive(:getaddresses).and_return([ "8.8.8.8", "10.0.1.1" ])
      expect(CutyCapt.verify_url("http://workingexample.com/blah")).to be_falsey
    end

    it "should check that the url resolves to something" do
      ConfigFile.stub('cutycapt', { :path => 'not used' })
      expect(CutyCapt.verify_url("http://successfull")).to be_falsey
    end
  end

  context "execution" do
    it "should time out cuty processes" do
      ConfigFile.stub('cutycapt', { :path => '/bin/sleep', :timeout => '1000' })

      allow(CutyCapt).to receive(:cuty_arguments).and_return([ "/bin/sleep", "60" ])
      expect {
        Timeout::timeout(10) { CutyCapt.snapshot_url("http://google.com/") }
      }.not_to raise_error
    end
  end
end
