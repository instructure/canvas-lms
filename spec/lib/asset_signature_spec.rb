require File.expand_path('../spec_helper', File.dirname(__FILE__))

class SomeModel < Struct.new(:id); end

describe AssetSignature do
  def example_encode(classname, id)
    Canvas::Security.hmac_sha1("#{classname}#{id}")[0,8]
  end

  describe '.generate' do
    it 'produces a combination of id and hmac to use as a url signature' do
      asset = stub(:id=>24)
      AssetSignature.generate(asset).should == "24-#{example_encode(stub.class.to_s, 24)}"
    end

    it 'produces a different hmac for each asset id' do
      asset = stub(:id=>0)
      AssetSignature.generate(asset).should == "0-#{example_encode(asset.class, 0)}"
    end

    it 'produces a difference hmac for each asset class' do
      asset = SomeModel.new(24)
      AssetSignature.generate(asset).should == "24-#{example_encode('SomeModel', 24)}"
      AssetSignature.generate(asset).should_not == AssetSignature.generate(stub(:id=>24))
    end

  end

  describe '.find_by_signature' do

    it 'finds the model if the hmac matches' do
      SomeModel.expects(:where).with(id: 24).once.returns(stub(first: nil))
      AssetSignature.find_by_signature(SomeModel, "24-#{example_encode('SomeModel',24)}")
    end

    it 'returns nil if the signature does not check out' do
      SomeModel.expects(:where).never
      AssetSignature.find_by_signature(SomeModel, '24-not-the-sig').should be_nil
    end

    #TODO: Remove this after the next release cycle
    # its just here for temporary backwards compatibility
    it 'will also find the model by the old id method' do
      SomeModel.expects(:where).with(id: '24').once.returns(stub(first: nil))
      AssetSignature.find_by_signature(SomeModel, '24')
    end
    ################################################
  end
end

