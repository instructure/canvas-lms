#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe PseudonymsController, :type => :integration do
  before do
    course_with_student(:active_all => true)
    account_admin_user
    @account = @user.account
  end
  describe "pseudonym listing" do
    before do
      @account_path = "/api/v1/accounts/#{@account.id}/logins"
      @account_path_options = { :controller => 'pseudonyms', :action => 'index', :format => 'json', :account_id => @account.id.to_param }
      @user_path = "/api/v1/users/#{@student.id}/logins"
      @user_path_options = { :controller => 'pseudonyms', :action => 'index', :format => 'json', :user_id => @student.id.to_param }
    end
    context "An authorized user with a valid query" do
      it "should return a list of pseudonyms" do
        json = api_call(:get, @account_path, @account_path_options, {
          :user => { :id => @student.id }
        })
        json.should == @student.pseudonyms.map do |p|
          {
            'account_id' => p.account_id,
            'id' => p.id,
            'sis_user_id' => p.sis_user_id,
            'unique_id' => p.unique_id,
            'user_id' => p.user_id
          }
        end
      end
      it "should return multiple pseudonyms if they exist" do
        %w{ one@example.com two@example.com }.each { |id| @student.pseudonyms.create(:unique_id => id) }
        json = api_call(:get, @account_path, @account_path_options, {
          :user => { :id => @student.id }
        })
        json.count.should eql 2
      end
      it "should paginate results" do
        %w{ one@example.com two@example.com }.each { |id| @student.pseudonyms.create(:unique_id => id) }
        json = api_call(:get, "#{@account_path}?per_page=1", @account_path_options.merge({ :per_page => '1' }), {
          :user => { :id => @student.id }
        })
        json.count.should eql 1
        headers = response.headers['Link'].split(',')
        headers[0].should match /page=2&per_page=1/ # next page
        headers[1].should match /page=1&per_page=1/ # first page
        headers[2].should match /page=2&per_page=1/ # last page
      end
      it "should return all pseudonyms for a user" do
        new_account = Account.create!(:name => 'Extra Account')
        @student.pseudonyms.create!(:unique_id => 'one@example.com', :account => Account.default)
        @student.pseudonyms.create!(:unique_id => 'two@example.com', :account => new_account)

        json = api_call(:get, @user_path, @user_path_options)
        json.count.should eql 2
      end
    end
    context "An authorized user with an empty query" do
      it "should return an empty array" do
        json = api_call(:get, @account_path, @account_path_options, {
          :user => { :id => @student.id }
        })
        json.should be_empty
      end
    end
    context "An unauthorized user" do
      before do
        @user = user_with_pseudonym
      end
      it "should return 401 unauthorized when listing account pseudonyms" do
        raw_api_call(:get, @account_path, @account_path_options, {
          :user => { :id => @student.id }
        })
        response.code.should eql '401'
      end
      it "should return 401 unauthorized when listing user pseudonyms" do
        raw_api_call(:get, @user_path, @user_path_options)
        response.code.should eql '401'
      end
    end
  end

  describe "pseudonym creation" do
    before do
      @path = "/api/v1/accounts/#{@account.id}/logins"
      @path_options = { :controller => 'pseudonyms', :action => 'create', :format => 'json', :account_id => @account.id.to_param }
    end

    context "an authorized user" do
      it "should create a new pseudonym" do
        json = api_call(:post, @path, @path_options, {
          :user => { :id => @student.id },
          :login => {
            :password    => 'abc123',
            :sis_user_id => '12345',
            :unique_id   => 'test@example.com'
          }
        })
        json.should == {
          'account_id'  => @account.id,
          'id'          => json['id'],
          'sis_user_id' => '12345',
          'unique_id'   => 'test@example.com',
          'user_id'     => @student.id
        }
      end

      it "should return 400 if account_id is not a root account" do
        @subaccount = Account.create!(:parent_account => @account)
        @path = "/api/v1/accounts/#{@subaccount.id}/logins"
        @path_options = { :controller => 'pseudonyms', :action => 'create', :format => 'json', :account_id => @subaccount.id.to_param }
        raw_api_call(:post, @path, @path_options, {
          :user  => { :id => @student.id },
          :login => {
            :password => 'abc123',
            :sis_user_id => '12345',
            :unique_id => 'duplicate@example.com'
          }
        })
        response.code.should eql '400'
      end

      it "should return 400 on duplicate pseudonyms" do
        @student.pseudonyms.create(:unique_id => 'duplicate@example.com')
        raw_api_call(:post, @path, @path_options, {
          :user  => { :id => @student.id },
          :login => {
            :password => 'abc123',
            :sis_user_id => '12345',
            :unique_id => 'duplicate@example.com'
          }
        })
        response.code.should eql '400'
      end
    end

    context "an unauthorized user" do
      it "should return 401" do
        @user = @student
        raw_api_call(:post, @path, @path_options, {
          :user => { :id => @admin.id },
          :login => {
            :password => 'abc123',
            :sis_user_id => '12345',
            :unique_id => 'test@example.com'
          }
        })
        response.code.should eql '401'
      end
    end
  end
  describe "pseudonym updates" do
    before do
      @student.pseudonyms.create(:unique_id => 'student@example.com')
      @admin.pseudonyms.create(:unique_id => 'admin@example.com')
      @teacher.pseudonyms.create(:unique_id => 'teacher@example.com')
      @path = "/api/v1/accounts/#{@account.id}/logins/#{@student.pseudonym.id}"
      @path_options = { :controller => 'pseudonyms', :action => 'create', :format => 'json', :action => 'update', :account_id => @account.id.to_param, :id => @student.pseudonym.id.to_param }
    end
    context "an authorized user" do
      it "should be able to update a pseudonym" do
        json = api_call(:put, @path, @path_options, {
          :login => {
            :unique_id   => 'student+new@example.com',
            :password    => 'password123',
            :sis_user_id => 'new-12345'
          }
        })
        json.should == {
          'account_id' => @student.pseudonym.account_id,
          'id' => @student.pseudonym.id,
          'sis_user_id' => 'new-12345',
          'unique_id' => 'student+new@example.com',
          'user_id' => @student.id
        }
      end
      it "should return 400 if the unique_id already exists" do
        raw_api_call(:put, @path, @path_options, {
          :login => {
            :unique_id => 'teacher@example.com'
          }
        })
        response.code.should eql '400'
      end
      it "should return 200 if a user's sis id is updated to its current value" do
        @student.pseudonym.update_attribute(:sis_user_id, 'old-12345')
        json = api_call(:put, @path, @path_options, {
          :login => { :sis_user_id => 'old-12345' }
        })
        json['sis_user_id'].should eql 'old-12345'
      end
    end
    context "an unauthorized user" do
      it "should return 401" do
        @path = "/api/v1/accounts/#{@account.id}/logins/#{@teacher.pseudonym.id}"
        @user = @student
        raw_api_call(:put, @path, @path_options.merge({ :id => @teacher.pseudonym.id.to_param }), {
          :login => { :unique_id => 'teacher+new@example.com' }
        })
        response.code.should eql '401'
      end
    end
  end
end
