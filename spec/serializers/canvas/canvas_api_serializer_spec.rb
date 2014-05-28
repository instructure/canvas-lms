require 'spec_helper'

describe Canvas::APISerializer do

  let(:controller) { ActiveModel::FakeController.new }
  let(:options) { { scope: {}, controller: controller } }
  let(:serializer) { Canvas::APISerializer.new({}, options) }

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

    context 'embedding objects in root' do
      before do
        Bar = Struct.new(:id, :name) do
          def read_attribute_for_serialization(attr)
            send(attr)
          end
        end

        class BarSerializer < Canvas::APISerializer
          attributes :id, :name
        end
      end

      after do
        Object.send(:remove_const, :Bar)
        Object.send(:remove_const, :BarSerializer)
      end

      let :object do
        Foo.new(1, 'Bob').tap do |object|
          object.expects(:bar).returns Bar.new(1, 'Alice')
        end
      end

      let :controller do
        ActiveModel::FakeController.new({
          accepts_jsonapi: true,
          stringify_json_ids: true
        })
      end

      subject do
        FooSerializer.new(object, {
          controller: controller,
          root: nil
        })
      end

      it "uses objects for embed: :object, embed_in_root: true" do
        class FooSerializer
          has_one :bar, embed: :object, embed_in_root: true
        end

        subject.as_json(root: nil).stringify_keys.tap do |json|
          json['links'].should_not be_present
          json['bar'].should be_present
          json['bar'].should == [{ id: 1, name: 'Alice' }]
        end
      end

      it "uses objects for embed: :object, embed_in_root: true and uses a custom key" do
        class FooSerializer
          has_one :bar, embed: :object, embed_in_root: true, root: 'adooken'
        end

        subject.as_json(root: nil).stringify_keys.tap do |json|
          json['links'].should_not be_present
          json['bar'].should_not be_present
          json['adooken'].should be_present
          json['adooken'].should == [{ id: 1, name: 'Alice' }]
        end
      end

      it "respects the :wrap_in_array custom option" do
        class FooSerializer
          has_one :bar, embed: :object, embed_in_root: true, wrap_in_array: false
        end

        subject.as_json(root: nil).stringify_keys.tap do |json|
          json['links'].should_not be_present
          json['bar'].should be_present
          json['bar'].should == { id: 1, name: 'Alice' }
        end
      end
    end
  end
end
