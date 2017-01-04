require_relative '../../spec_helper'
require_relative '../../support/boolean_translator'
require_dependency "group_categories/params"

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
        expect(params.send(param)).to eq output_value
      end
    end

    it 'delegates through properties that need no transformation' do
      params = build_params(name: "SomeName", group_limit: 42)
      expect(params.name).to eq "SomeName"
      expect(params.group_limit).to eq 42
    end

    describe '#self_signup' do
      it 'is nil if signup is not enabled' do
        params = build_params(enable_self_signup: "no", restrict_self_signup: "yes")
        expect(params.self_signup).to be_nil
      end

      it 'is restricted if both parameters are set to true' do
        params = build_params(enable_self_signup: true, restrict_self_signup: true)
        expect(params.self_signup).to eq 'restricted'
      end

      it 'is enabled if restriction isnt set' do
        params = build_params(enable_self_signup: true, restrict_self_signup: false)
        expect(params.self_signup).to eq 'enabled'
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
        expect(params.auto_leader).to be_nil
      end

      it 'is nil with auto_leading disabled from form submission of an existing record' do
        raw_args = {auto_leader: "first", enable_auto_leader: "0"}
        params = build_params(raw_args)
        expect(params.auto_leader).to be(nil)
      end

      it 'passes through valid values when auto leading is enabled' do
        params = build_params(enable_auto_leader: true, auto_leader_type: "random")
        expect(params.auto_leader).to eq 'random'
      end

      it 'normalizes casing for valid values' do
        params = build_params(enable_auto_leader: true, auto_leader_type: "FIRST")
        expect(params.auto_leader).to eq 'first'
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

      describe "when there's a collision between raw and formbased" do

        #because this would indicate it's not actively trying to be deleted
        it 'uses the raw value if form value not from a checkbox form' do
          params = build_params(auto_leader_type: "FIRST", auto_leader: "random")
          expect(params.auto_leader).to eq("random")
        end

        it 'nils out the param if disabled from the form' do
          params = build_params(enable_auto_leader: false, auto_leader_type: "FIRST", auto_leader: "random")
          expect(params.auto_leader).to be(nil)
        end

        it 'uses the form value if form is enabled' do
          params = build_params(enable_auto_leader: true, auto_leader_type: "FIRST", auto_leader: "random")
          expect(params.auto_leader).to eq("first")
        end
      end
    end

    describe '#create_group_count' do
      it 'passes through the count param when self signup is enabled' do
        params = build_params(enable_self_signup: true,
          restrict_self_signup: false, create_group_count: "3")
        expect(params.create_group_count).to eq 3
      end

      it 'is nil if self-signup and split-groups are both disabled' do
        params = build_params(enable_self_signup: false, split_groups: '0')
        expect(params.create_group_count).to be_nil
      end

      it 'uses the split_group_count if self-signup isnt enabled and the split is set' do
        args = {
          enable_self_signup: false,
          split_groups: '1',
          split_group_count: '3',
          create_group_count: '2'
        }
        params = build_params(args)
        expect(params.create_group_count).to eq 3
      end

      it 'defaults to the create group count if the split group count isnt set' do
        args = {
          enable_self_signup: false,
          split_groups: '1',
          create_group_count: '2'
        }
        params = build_params(args)
        expect(params.create_group_count).to eq 2
      end
    end

    describe '#assign_unassigned_members' do
      it 'is false if self signup is on' do
        params = build_params(enable_self_signup: true)
        expect(params.assign_unassigned_members).to be(false)
      end

      it 'is false if split groups arent set' do
        params = build_params(enable_self_signup: false, split_groups: '0')
        expect(params.assign_unassigned_members).to be(false)
      end

      it 'is false if create_group_count is empty' do
        params = build_params(enable_self_signup: false,
          split_groups: '1', create_group_count: nil, split_group_count: nil)
        expect(params.assign_unassigned_members).to be(false)
      end

      it 'is true without self signup and with a split count' do
        params = build_params(enable_self_signup: false,
          split_groups: '1', create_group_count: nil, split_group_count: '3')
        expect(params.assign_unassigned_members).to be(true)
      end
    end

  end
end
