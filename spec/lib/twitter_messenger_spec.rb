require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe TwitterMessenger do

  before { HostUrl.stubs(:short_host => 'host') }

  let(:message) { stub() }
  let(:messenger) { TwitterMessenger.new(message) }

  describe '#deliver' do

    let(:user) { stub(:user_services=>stub(:find_by_service=>@service)) }
    let(:message) { stub(:body=>'body',:url=>'url',:user => user, :asset_context=>nil, :id=>0, :main_link => '') }

    it 'delegates to the twitter module if a service is available' do
      @service = stub()
      messenger.stubs(:twitter_self_dm).returns(true)
      messenger.deliver.should be_true
    end

    it 'sends nothing if there is no service' do
      messenger.expects(:twitter_self_dm).times(0)
      messenger.deliver.should be_nil
    end
  end

  describe '#url' do
    let(:message) { stub(:id => 42, :asset_context=>nil, :main_link => nil, :url => nil) }
    subject { messenger.url }

    it { should =~ /host/ }
    it { should =~ /#{AssetSignature.generate(message)}$/ }
    it { should =~ /^http:\/\// }
  end

  describe '#body' do
    let(:message) { stub(:body=>@body, :asset_context => nil, :id => 0, :main_link => @link) }

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

  describe '#host' do
    let(:context) { stub }
    let(:message) { stub(:asset_context => context) }

    it 'delegates to the HostUrl lib' do
      HostUrl.expects(:short_host).with(context)
      messenger.host
    end
  end

end
