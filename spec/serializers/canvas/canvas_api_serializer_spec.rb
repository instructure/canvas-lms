require 'spec_helper'

describe Canvas::APISerializer do

  attr_reader :serializer, :options

  let(:controller) { ActiveModel::FakeController.new }

  before do
    @options = {scope: {}, controller: controller}
    @serializer = Canvas::APISerializer.new({}, options)
  end

  it "aliases user to options[:scope]" do
    serializer.user.should == options[:scope]
  end

  it "aliases current_user to user" do
    serializer.user.should == serializer.current_user
  end

  [:stringify_json_ids?, :accepts_jsonapi?, :session, :context].each do |method|

    it "delegates #{method} to controller" do
      controller.send(method).should == serializer.send(method)
    end
  end

  it "creates an alias for object based on serializer class name" do
    class FooSerializer < Canvas::APISerializer
    end

    FooSerializer.new({}, options).foo.should == {}

    Object.send(:remove_const, :FooSerializer)
  end

  describe "#serializable object" do
    before do

      Foo = Struct.new(:id, :name) do
        def read_attribute_for_serialization(attr)
          send(attr)
        end
      end

      class FooSerializer < Canvas::APISerializer
        attributes :id, :name
      end
    end

    after do
      Object.send(:remove_const, :Foo)
      Object.send(:remove_const, :FooSerializer)
    end

    it "uses ActiveModel::serializer's implementation if not stringify_ids? returns false" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: false, stringify_json_ids: false)
      object = Foo.new(1, 'Alice')
      serializer = FooSerializer.new(object, {root: nil, controller: con})
      serializer.expects(:stringify_ids?).returns false
      serializer.as_json(root: nil).should == {
        id: 1,
        name: 'Alice'
      }
    end

    it "stringifies ids if jsonapi or stringids requested" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: true, stringify_json_ids: true)
      object = Foo.new(1, 'Alice')
      serializer = FooSerializer.new(object, {root: nil, controller: con})
      serializer.as_json(root: nil).should == {
        id: '1',
        name: 'Alice'
      }
    end

    it "uses urls for embed: :ids, include: false" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: true, stringify_json_ids: true)
      class FooSerializer
        has_one :bar, embed: :ids
      end
      object = Foo.new(1, 'Bob')
      object.expects(:bar).returns stub()
      url = "http://example.com/api/v1/bar/1"
      serializer = FooSerializer.new(object, {root: nil, controller: con})
      serializer.expects(:bar_url).returns(url)
      serializer.as_json(root: nil)['links']['bar'].should == url
    end

    it "uses ids for embed: :ids, embed_in_root: true" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: true, stringify_json_ids: true)
      class FooSerializer
        has_one :bar, embed: :ids, embed_in_root: true
      end
      class BarSerializer < Canvas::APISerializer
        attributes :id
      end
      object = Foo.new(1, 'Bob')
      object.expects(:bar).returns Foo.new(1, 'Alice')
      url = "http://example.com/api/v1/bar/1"
      serializer = FooSerializer.new(object, {root: nil, controller: con})
      serializer.as_json(root: nil)['links']['bar'].should == "1"
      Object.send(:remove_const, :BarSerializer)
    end
  end

end
