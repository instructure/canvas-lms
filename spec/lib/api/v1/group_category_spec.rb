require_relative '../../../spec_helper'

class CategoryHarness
  include Api::V1::GroupCategory
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

      it 'is not present without the includes' do
        category.stubs(:groups => stub(active: stub(size: 3)), :is_member? => false)
        json = CategoryHarness.new.group_category_json(category, nil, nil, {:include => ['groups_count']})
        expect(json["groups_count"]).to eq(3)
      end
    end
  end
end
