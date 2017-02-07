require_relative '../../spec_helper'
require_relative '../../support/boolean_translator'
require_dependency "group_categories/params_policy"

module GroupCategories

  MockGroupCategory = Struct.new(:name, :self_signup,
    :auto_leader, :group_limit, :create_group_count, :assign_unassigned_members, :group_by_section)

  describe ParamsPolicy do

    let(:populate_options){
      { boolean_translator: BooleanTranslator }
    }

    describe 'intializer' do
      it 'accepts a category and context' do
        category = stub('group_category')
        context = stub('course')
        policy = ParamsPolicy.new(category, context)
        expect(policy.group_category).to eq category
        expect(policy.context).to eq context
      end
    end

    describe '#populate_with' do
      let(:category){ MockGroupCategory.new() }
      let(:context){ stub('course') }
      let(:policy){ ParamsPolicy.new(category, context) }

      it 'configures the self_signup accoring to the params' do
        policy.populate_with({enable_self_signup: true}, populate_options)
        expect(category.self_signup).to eq 'enabled'
      end

      it 'sets up the autoleader value' do
        policy.populate_with({enable_auto_leader: "1", auto_leader_type: 'RANDOM'}, populate_options)
        expect(category.auto_leader).to eq('random')
      end

      it "can null out an existing autoleader value" do
        category.auto_leader = "FIRST"
        policy.populate_with({enable_auto_leader: "0", auto_leader_type: 'RANDOM'}, populate_options)
        expect(category.auto_leader).to be(nil)
      end

      it 'lets you override the name' do
        policy.populate_with({name: "SomeGroupCategory"}, populate_options)
        expect(category.name).to eq 'SomeGroupCategory'
      end

      it 'passes through group limit' do
        policy.populate_with({group_limit: 3}, populate_options)
        expect(category.group_limit).to eq 3
      end

      describe 'when context is a course' do
        let(:context){ Course.new }

        it 'populates group count' do
          policy.populate_with({enable_self_signup: "1", create_group_count: 2}, populate_options)
          expect(category.create_group_count).to eq 2
        end
      end
    end
  end

end
