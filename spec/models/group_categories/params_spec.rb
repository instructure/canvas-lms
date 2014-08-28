require_relative '../../support/boolean_translator'
require_relative '../../../app/models/group_categories/params'


module GroupCategories


  describe Params do

    let(:param_options){
      { boolean_translator: BooleanTranslator }
    }

    def build_params(args)
      Params.new(args, param_options)
    end

    def check_passthrough_raw_param(inputs, param, output_value)
      inputs.each do |val|
        params = build_params(param => val)
        params.send(param).should == output_value
      end
    end

    it 'delegates through properties that need no transformation' do
      params = build_params(name: "SomeName", group_limit: 42)
      params.name.should == "SomeName"
      params.group_limit.should == 42
    end

    describe '#self_signup' do
      it 'is nil if signup is not enabled' do
        params = build_params(enable_self_signup: "no", restrict_self_signup: "yes")
        params.self_signup.should be_nil
      end

      it 'is restricted if both parameters are set to true' do
        params = build_params(enable_self_signup: true, restrict_self_signup: true)
        params.self_signup.should == 'restricted'
      end

      it 'is enabled if restriction isnt set' do
        params = build_params(enable_self_signup: true, restrict_self_signup: false)
        params.self_signup.should == 'enabled'
      end

      it 'is enabled if enabled is passed in raw' do
        valid_inputs = ['enabled', :enabled, "ENABLED"]
        check_passthrough_raw_param(valid_inputs, :self_signup, 'enabled')
      end

      it 'is restricted if restricted is passed in raw' do
        valid_inputs = ['restricted', :restricted, "RESTRICTED"]
        check_passthrough_raw_param(valid_inputs, :self_signup, 'restricted')
      end
    end

    describe "#auto_leader" do
      it 'is nil if auto leading is disabled' do
        params = build_params(enable_auto_leader: false, auto_leader_type: "first")
        params.auto_leader.should be_nil
      end

      it 'passes through valid values when auto leading is enabled' do
        params = build_params(enable_auto_leader: true, auto_leader_type: "random")
        params.auto_leader.should == 'random'
      end

      it 'normalizes casing for valid values' do
        params = build_params(enable_auto_leader: true, auto_leader_type: "FIRST")
        params.auto_leader.should == 'first'
      end

      it 'errors on a bad assignment' do
        params = build_params(enable_auto_leader: true, auto_leader_type: "nonsense")
        expect{ params.auto_leader }.to raise_error(ArgumentError)
      end

      it 'is random if random is passed in raw' do
        valid_inputs = ['random', :random, "RANDOM"]
        check_passthrough_raw_param(valid_inputs, :auto_leader, 'random')
      end

      it 'is first if first is passed in raw' do
        valid_inputs = ['first', :first, "FIRST"]
        check_passthrough_raw_param(valid_inputs, :auto_leader, 'first')
      end
    end

    describe '#create_group_count' do
      it 'passes through the count param when self signup is enabled' do
        params = build_params(enable_self_signup: true,
          restrict_self_signup: false, create_group_count: "3")
        params.create_group_count.should == 3
      end

      it 'is nil if self-signup and split-groups are both disabled' do
        params = build_params(enable_self_signup: false, split_groups: '0')
        params.create_group_count.should be_nil
      end

      it 'uses the split_group_count if self-signup isnt enabled and the split is set' do
        args = {
          enable_self_signup: false,
          split_groups: '1',
          split_group_count: '3',
          create_group_count: '2'
        }
        params = build_params(args)
        params.create_group_count.should == 3
      end

      it 'defaults to the create group count if the split group count isnt set' do
        args = {
          enable_self_signup: false,
          split_groups: '1',
          create_group_count: '2'
        }
        params = build_params(args)
        params.create_group_count.should == 2
      end
    end

    describe '#assign_unassigned_members' do
      it 'is false if self signup is on' do
        params = build_params(enable_self_signup: true)
        params.assign_unassigned_members.should be_false
      end

      it 'is false if split groups arent set' do
        params = build_params(enable_self_signup: false, split_groups: '0')
        params.assign_unassigned_members.should be_false
      end

      it 'is false if create_group_count is empty' do
        params = build_params(enable_self_signup: false,
          split_groups: '1', create_group_count: nil, split_group_count: nil)
        params.assign_unassigned_members.should be_false
      end

      it 'is true without self signup and with a split count' do
        params = build_params(enable_self_signup: false,
          split_groups: '1', create_group_count: nil, split_group_count: '3')
        params.assign_unassigned_members.should be_true
      end
    end

  end
end
