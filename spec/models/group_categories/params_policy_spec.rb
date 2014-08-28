require_relative '../../support/boolean_translator'
require_relative '../../../app/models/group_categories/params'
require_relative '../../../app/models/group_categories/params_policy'

class Course; end

module GroupCategories

  MockGroupCategory = Struct.new(:name, :self_signup,
    :auto_leader, :group_limit, :create_group_count, :assign_unassigned_members)

  describe ParamsPolicy do

    let(:populate_options){
      { boolean_translator: BooleanTranslator }
    }

    describe 'intializer' do
      it 'accepts a category and context' do
        category = stub('group_category')
        context = stub('course')
        policy = ParamsPolicy.new(category, context)
        policy.group_category.should == category
        policy.context.should == context
      end
    end

    describe '#populate_with' do
      let(:category){ MockGroupCategory.new() }
      let(:context){ stub('course') }
      let(:policy){ ParamsPolicy.new(category, context) }

      it 'configures the self_signup accoring to the params' do
        policy.populate_with({enable_self_signup: true}, populate_options)
        category.self_signup.should == 'enabled'
      end

      it 'sets up the autoleader value' do
        policy.populate_with({enable_auto_leader: "1", auto_leader_type: 'RANDOM'}, populate_options)
        category.auto_leader.should == 'random'
      end

      it 'lets you override the name' do
        policy.populate_with({name: "SomeGroupCategory"}, populate_options)
        category.name.should == 'SomeGroupCategory'
      end

      it 'passes through group limit' do
        policy.populate_with({group_limit: 3}, populate_options)
        category.group_limit.should == 3
      end

      describe 'when context is a course' do
        let(:context){ Course.new }

        it 'populates group count' do
          policy.populate_with({enable_self_signup: "1", create_group_count: 2}, populate_options)
          category.create_group_count.should == 2
        end
      end
    end
  end

end
