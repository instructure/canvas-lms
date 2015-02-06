require_relative '../../../spec_helper'

class CategoryHarness
  include Api::V1::GroupCategory

  def polymorphic_url(data)
    "http://www.example.com/api/#{data.join('/')}"
  end
end

describe "Api::V1::GroupCategory" do
  describe "#group_category_json" do
    let(:category){ GroupCategory.new(name: "mygroup") }

    it "includes the auto_leader value" do
      category.auto_leader = 'random'
      json = CategoryHarness.new.group_category_json(category, nil, nil)
      expect(json['auto_leader']).to eq('random')
    end

    describe 'groups_count' do
      it 'is absent without the includes' do
        json = CategoryHarness.new.group_category_json(category, nil, nil, {})
        expect(json.keys.include?("groups_count")).to be(false)
      end

      it 'is present with the includes' do
        category.stubs(:groups => stub(active: stub(size: 3)), :is_member? => false)
        json = CategoryHarness.new.group_category_json(category, nil, nil, {:include => ['groups_count']})
        expect(json["groups_count"]).to eq(3)
      end
    end

    describe 'progress_url' do
      it 'is absent without the includes' do
        json = CategoryHarness.new.group_category_json(category, nil, nil, {})
        expect(json.keys.include?("progress")).to be(false)
      end

      it 'is present with the includes' do
        category.stubs(current_progress: stub(:pending? => true))
        json = CategoryHarness.new.group_category_json(category, nil, nil, {:include => ['progress_url']})
        expect(json["progress"]['url']).to match(/example.com\/api\/api_v1/)
      end
    end

    describe 'group_category_data' do
      it 'sets protected with the category value' do
        category.stubs(:protected? => true)
        json = CategoryHarness.new.group_category_json(category, nil, nil)
        expect(json["protected"]).to eq(true)
      end

      it 'passes through "allows_multiple_memberships"' do
        category.stubs(:allows_multiple_memberships? => false)
        json = CategoryHarness.new.group_category_json(category, nil, nil)
        expect(json["allows_multiple_memberships"]).to eq(false)
      end

      it 'checks the user against the category to set "is_member"' do
        user = stub
        category.expects(:is_member?).with(user).returns(true)
        json = CategoryHarness.new.group_category_json(category, user, nil)
        expect(json["is_member"]).to eq(true)
      end
    end

  end
end
