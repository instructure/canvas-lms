require 'spec_helper'

describe Twitter::Messenger do
  let(:message) { stub() }
  let(:twitter_service) { stub({
                                 token: "twitter_token",
                                 secret: "twitter_secret",
                                 service_user_name: "twitter_name",
                                 service_user_id: "twitter_id"
                               }) }
  let(:id) { "ABC123" }
  let(:messenger) { Twitter::Messenger.new(message, twitter_service, 'host', id) }

  describe '#deliver' do

    let(:user) { stub(:user_services) }
    let(:message) { stub(:body => 'body', :url => 'url', :user => user, :asset_context => nil, :id => 0, :main_link => '') }
    let(:connection_mock) { mock() }


    context "with a twitter service" do
      before(:each) do
        Twitter::Connection.expects(:new).with("twitter_token", "twitter_secret").returns(connection_mock)
      end

      it 'delegates to the twitter module if a service is available' do
        connection_mock.expects(:send_direct_message).with("twitter_name", "twitter_id", "body ").returns(true)
        messenger.deliver.should be_true
      end
    end

    context "with no twitter service" do
      let(:messenger) { Twitter::Messenger.new(message, nil, 'host', id) }
      it 'sends nothing if there is no service' do
        connection_mock.expects(:send_direct_message).never
        messenger.deliver.should be_nil
      end
    end
  end

  describe '#url' do
    let(:message) { stub(:id => 42, :asset_context => nil, :main_link => nil, :url => nil) }
    subject { messenger.url }

    it { should =~ /host/ }
    it { should =~ /#{id}$/ }
    it { should =~ /^http:\/\// }
  end

  describe '#body' do
    let(:message) { stub(:body => @body, :asset_context => nil, :id => 0, :main_link => @link) }

    it 'leaves the body intact when it does not overrun the twitter length limit' do
      @body = "no need to alter"
      @link = 'http://learn.canvas.net/example'
      messenger.body.should == "#{@body} #{@link}"
    end

    it 'trims down the body to fit into a twitter message with the url' do
      @body = "An extremely long body that might need to be cut down a bit if we have any hope of letting twitter have it due to the length limits that service imposes"
      @link = 'http://learn.canvas.net/super/long/url/which/will/be/minified/by/twitter'
      messenger.body.should == "An extremely long body that might need to be cut down a bit if w... http://learn.canvas.net/super/long/url/which/will/be/minified/by/twitter"
    end
  end
end