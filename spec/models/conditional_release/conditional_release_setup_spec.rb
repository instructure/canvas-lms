#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe ConditionalRelease::Setup do
  Service = ConditionalRelease::Service

  def stub_config
    ConfigFile.stubs(:load).returns({
      protocol: 'foo', host: 'bar',
      create_account_path: 'some/path',
      edit_rule_path: 'some/other/path',
      unique_id: 'unique@cyoe.id'
    })
  end

  def setup_cr_user(base_account)
    account = base_account.root_account
    user = User.new(name: 'Conditional Release API', sortable_name: 'API, Conditional Release')
    user.workflow_state = "registered"

    pseudo = user.pseudonyms.build(account: account, unique_id: Service.unique_id)
    pseudo.workflow_state = "active"
    pseudo.user = user
    user.save!

    admin = account.account_users.build
    admin.user = user
    admin.save! if admin.valid?
    user
  end

  def setup_cr_token_for_user(user)
    token = user.access_tokens.build(purpose: "Conditional Release Service API Token")
    token.save!
    token.full_token
  end


  def get_api_user_details(account)
    pseudo = Pseudonym.active.where(account: account.root_account, unique_id: Service.unique_id)
    user = pseudo.first.user if pseudo.present?
    token = user.access_tokens.where(purpose: "Conditional Release Service API Token") if user.present?

    { pseudonym: pseudo, user: user, token: token }
  end

  before :each do
    stub_config
    @root_account = account_model
    @sub_account = account_model parent_account: @root_account
    @course = course account: @sub_account, active_all: true
    @user = user_with_pseudonym account: @root_account
    Service.stubs(:jwt_for).returns("some.jwt.thing")
    Service.stubs(:unique_id).returns("unique@cyoe.id")
    Feature.stubs(:definitions).returns({
      'conditional_release' => Feature.new(feature: 'conditional_release', applies_to: 'Account')
    })
    @cyoe_feature = Feature.definitions['conditional_release']
    Service.stubs(:configured?).returns(true)
    @setup = ConditionalRelease::Setup.new(@account.id, @user.id)
  end

  describe "#activate!" do
    it "should not run if the Conditional Release service isn't configured" do
      Service.stubs(:configured?).returns(false)
      @setup.expects(:create_token!).never
      @setup.expects(:send_later).never
      @setup.activate!
    end

    it "should not create a new Conditional Release user for an API access token if one exists" do
      user = setup_cr_user(@root_account)
      setup_cr_token_for_user(user)
      init = ConditionalRelease::Setup.new(@account.id, @user.id)
      init.expects(:send_later).never
      init.activate!
    end

    it "should create a new Conditional Release user if not present" do
      AccountUser.any_instance.expects(:save!).once
      @setup.activate!
    end

    it "should create a new Conditional Release API access token if not present" do
      AccessToken.any_instance.expects(:save!).once
      @setup.activate!
    end

    it "should enqueue a job to POST the account data to the Conditional Release service" do
      @setup.expects(:send_later).once
      @setup.activate!
    end

    # End-to-end
    it "should activate the Conditional Release service" do
      CanvasHttp.expects(:post).once.returns(Net::HTTPSuccess.new(1.0, 202, "Accepted"))
      t_new_account = account_model
      t_new_user = user_with_pseudonym account: t_new_account

      new_init = ConditionalRelease::Setup.new(t_new_account.id, t_new_user.id)
      new_init.activate!

      details = get_api_user_details(t_new_account)

      Delayed::Job.find_by_tag("ConditionalRelease::Setup#post_to_service").invoke_job

      expect(details[:token].count).to eq 1
      expect(details[:user].is_a?(User)).to be_truthy
      expect(details[:pseudonym].count).to eq 1
    end
  end

  describe "#post_to_service" do
    context "successful request" do
      before do
        @sub_account.enable_feature! :conditional_release
        data, jwt = {payload: "data"}, "jwt"
        @test = ConditionalRelease::Setup.new(@sub_account.id, @user.id)
        @test.instance_variable_set(:@payload, data)
        @test.instance_variable_set(:@jwt, jwt)
        CanvasHttp.expects(:post).once.with(ConditionalRelease::Service.create_account_url, {
          "Authorization" => "Bearer #{jwt}"
        }, form_data: data.to_param).returns(Net::HTTPSuccess.new(1.0, 202, "Accepted"))
      end

      it "should send a POST request to the conditional release service" do
        @test.send :post_to_service
      end

      it "should not call #undo_changes! if the request succeeds" do
        @test.expects(:undo_changes!).never
        @test.send :post_to_service
      end
    end

    context "error handling" do
      before :each do
        @sub_account.enable_feature! :conditional_release
        @test = ConditionalRelease::Setup.new(@sub_account.id, @user.id)
        CanvasHttp.expects(:post).once.returns(Net::HTTPInternalServerError.new(1.0, 500, "Internal Server Error"))
      end

      it "should disable the conditional release feature flag if the request fails" do
        expect { @test.send :post_to_service }.to raise_error(ConditionalRelease::ServiceRequestError).and change {
          @sub_account.feature_flag(:conditional_release).state
        }.from("on").to("off")
      end

      it "should destroy the api user for conditional release if the request fails" do
        @test.send :create_token!

        pseudonym = Pseudonym.active.find_by(account_id: @root_account.id, unique_id: Service.unique_id)
        expect(pseudonym.present?).to be_truthy

        @test.send :post_to_service rescue nil

        pseudonym = Pseudonym.active.find_by(account_id: @root_account.id, unique_id: Service.unique_id)
        expect(pseudonym.present?).to be_falsey
      end

      it "should call #undo_changes! if the request fails" do
        @test.expects(:undo_changes!).once
        @test.send :post_to_service rescue nil
      end
    end

  end

  describe "#create_token!" do
    before :each do
      @t_new_account = account_model
      @t_new_course = course account: @t_new_account, active_all: true
      @t_new_user = user_with_pseudonym account: @t_new_account
    end

    it "should create a token for a new, unique conditional release API user" do
      new_init = ConditionalRelease::Setup.new(@t_new_account.id, @t_new_user.id)
      new_init.send :create_token!

      details = get_api_user_details(@t_new_account)

      expect(details[:token].count).to eq 1
      expect(details[:user].is_a?(User)).to be_truthy
      expect(details[:pseudonym].count).to eq 1
    end

    it "should create a token for an existing conditional release API user that lacks one" do
      setup_cr_user(@t_new_account)
      details = get_api_user_details(@t_new_account)

      expect(details[:token].count).to eq 0
      new_init = ConditionalRelease::Setup.new(@t_new_account.id, @t_new_user.id)
      new_init.send :create_token!
      expect(details[:token].reload.count).to eq 1
    end

    it "should not create new API users if one exists" do
      setup_cr_user(@t_new_account)
      details = get_api_user_details(@t_new_account)

      expect(details[:pseudonym].count).to eq 1
      new_init = ConditionalRelease::Setup.new(@t_new_account.id, @t_new_user.id)
      new_init.send :create_token!
      expect(details[:pseudonym].count).to eq 1
    end

    it "should add the API user to the account as an admin" do
      new_init = ConditionalRelease::Setup.new(@t_new_account.id, @t_new_user.id)
      new_init.send :create_token!

      details = get_api_user_details(@t_new_account)
      expect(@t_new_account.account_users.where(user: details[:user]).count).to eq 1
    end
  end
end
