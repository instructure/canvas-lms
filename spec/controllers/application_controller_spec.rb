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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do

  before(:each) do
    @controller = ApplicationController.new
    @controller.stubs(:form_authenticity_token).returns('asdf')
  end

  describe "js_env" do
    it "should set items" do
      @controller.js_env :FOO => 'bar'
      @controller.js_env[:FOO].should == 'bar'
    end

    it "should allow multiple items" do
      @controller.js_env :A => 'a', :B => 'b'
      @controller.js_env[:A].should == 'a'
      @controller.js_env[:B].should == 'b'
    end

    it "should not allow overwriting a key" do
      @controller.js_env :REAL_SLIM_SHADY => 'please stand up'
      expect { @controller.js_env(:REAL_SLIM_SHADY => 'poser') }.to raise_error
    end
  end

  describe "safe_domain_file_user" do
    before :each do
      # safe_domain_file_url wants to use request.protocol
      @controller.stubs(:request).returns(mock(:protocol => '', :host => ''))

      @user = User.create!
      @attachment = @user.attachments.new(:filename => 'foo.png')
      @attachment.content_type = 'image/png'
      @attachment.save!

      @common_params = {
        :user_id => nil,
        :ts => nil,
        :sf_verifier => nil,
        :only_path => true
      }
    end

    it "should include inline=1 in url by default" do
      @controller.expects(:file_download_url).
        with(@attachment, @common_params.merge(:inline => 1)).
        returns('')
      @controller.send(:safe_domain_file_url, @attachment)
    end

    it "should include :download=>1 in inline urls for relative contexts" do
      @controller.instance_variable_set(:@context, @attachment.context)
      @controller.stubs(:named_context_url).returns('')
      url = @controller.send(:safe_domain_file_url, @attachment)
      url.should match(/[\?&]download=1(&|$)/)
    end

    it "should not include :download=>1 in download urls for relative contexts" do
      @controller.instance_variable_set(:@context, @attachment.context)
      @controller.stubs(:named_context_url).returns('')
      url = @controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
      url.should_not match(/[\?&]download=1(&|$)/)
    end

    it "should include download_frd=1 and not include inline=1 in url when specified as for download" do
      @controller.expects(:file_download_url).
        with(@attachment, @common_params.merge(:download_frd => 1)).
        returns('')
      @controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
    end
  end

end


