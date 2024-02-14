# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Canvas::APISerializer do
  let(:controller) { ActiveModel::FakeController.new }
  let(:options) { { scope: {}, controller: } }
  let(:serializer) { Canvas::APISerializer.new({}, options) }

  it "aliases user to options[:scope]" do
    expect(serializer.user).to eq options[:scope]
  end

  it "aliases current_user to user" do
    expect(serializer.user).to eq serializer.current_user
  end

  %i[stringify_json_ids? accepts_jsonapi? session context].each do |method|
    it "delegates #{method} to controller" do
      expect(controller.send(method)).to eq serializer.send(method)
    end
  end

  # rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
  # Canvas::APISerializer accesses klass.name in it's inherited hook,
  # so we can't use stub_const
  it "creates an alias for object based on serializer class name" do
    class FooSerializer < Canvas::APISerializer
    end

    expect(FooSerializer.new({}, options).foo).to eq({})
  ensure
    Object.send(:remove_const, :FooSerializer) # rubocop:disable RSpec/RemoveConst
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
      # rubocop:disable RSpec/RemoveConst
      Object.send(:remove_const, :Foo)
      Object.send(:remove_const, :FooSerializer)
      # rubocop:enable RSpec/RemoveConst
    end

    it "uses ActiveModel::serializer's implementation if not stringify_ids? returns false" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: false, stringify_json_ids: false)
      object = Foo.new(1, "Alice")
      serializer = FooSerializer.new(object, { root: nil, controller: con })
      expect(serializer).to receive(:stringify_ids?).and_return false
      expect(serializer.as_json(root: nil)).to eq({
                                                    id: 1,
                                                    name: "Alice"
                                                  })
    end

    it "stringifies ids if jsonapi or stringids requested" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: true, stringify_json_ids: true)
      object = Foo.new(1, "Alice")
      serializer = FooSerializer.new(object, { root: nil, controller: con })
      expect(serializer.as_json(root: nil)).to eq({
                                                    id: "1",
                                                    name: "Alice"
                                                  })
    end

    it "uses urls for embed: :ids, include: false" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: true, stringify_json_ids: true)
      class FooSerializer
        has_one :bar, embed: :ids
      end
      object = Foo.new(1, "Bob")
      expect(object).to receive(:bar).and_return double
      url = "http://example.com/api/v1/bar/1"
      serializer = FooSerializer.new(object, { root: nil, controller: con })
      expect(serializer).to receive(:bar_url).and_return(url)
      expect(serializer.as_json(root: nil)["links"]["bar"]).to eq url
    end

    it "uses ids for embed: :ids, embed_in_root: true" do
      con = ActiveModel::FakeController.new(accepts_jsonapi: true, stringify_json_ids: true)
      class FooSerializer
        has_one :bar, embed: :ids, embed_in_root: true
      end

      class BarSerializer < Canvas::APISerializer
        attributes :id
      end
      object = Foo.new(1, "Bob")
      expect(object).to receive(:bar).and_return Foo.new(1, "Alice")
      serializer = FooSerializer.new(object, { root: nil, controller: con })
      expect(serializer.as_json(root: nil)["links"]["bar"]).to eq "1"
    ensure
      Object.send(:remove_const, :BarSerializer) # rubocop:disable RSpec/RemoveConst
    end

    context "embedding objects in root" do
      subject do
        FooSerializer.new(object, {
                            controller:,
                            root: nil
                          })
      end

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
        # rubocop:disable RSpec/RemoveConst
        Object.send(:remove_const, :Bar)
        Object.send(:remove_const, :BarSerializer)
        # rubocop:enable RSpec/RemoveConst
      end

      let :object do
        Foo.new(1, "Bob").tap do |object|
          expect(object).to receive(:bar).and_return Bar.new(1, "Alice")
        end
      end

      let :controller do
        ActiveModel::FakeController.new({
                                          accepts_jsonapi: true,
                                          stringify_json_ids: true
                                        })
      end

      it "uses objects for embed: :object, embed_in_root: true" do
        class FooSerializer
          has_one :bar, embed: :object, embed_in_root: true
        end

        subject.as_json(root: nil).stringify_keys.tap do |json|
          expect(json["links"]).not_to be_present
          expect(json["bar"]).to be_present
          expect(json["bar"]).to eq [{ id: 1, name: "Alice" }]
        end
      end

      it "uses objects for embed: :object, embed_in_root: true and uses a custom key" do
        class FooSerializer
          has_one :bar, embed: :object, embed_in_root: true, root: "adooken"
        end

        subject.as_json(root: nil).stringify_keys.tap do |json|
          expect(json["links"]).not_to be_present
          expect(json["bar"]).not_to be_present
          expect(json["adooken"]).to be_present
          expect(json["adooken"]).to eq [{ id: 1, name: "Alice" }]
        end
      end

      it "respects the :wrap_in_array custom option" do
        class FooSerializer
          has_one :bar, embed: :object, embed_in_root: true, wrap_in_array: false
        end

        subject.as_json(root: nil).stringify_keys.tap do |json|
          expect(json["links"]).not_to be_present
          expect(json["bar"]).to be_present
          expect(json["bar"]).to eq({ id: 1, name: "Alice" })
        end
      end
    end
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
