describe RuboCop::Cop::Specs::ScopeHelperModules do
  subject(:cop) { described_class.new }

  context "within class" do
    it 'allows defs' do
      inspect_source(cop, %{
        class CombatArmband
          def laserbeams
            "PEWPEWPEPWEPWPEW"
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within context" do
    it 'allows defs' do
      inspect_source(cop, %{
        context "Jumpity JumpStick" do
          def jump_and_jab
            puts "heeeeeya!"
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within describe" do
    it 'allows defs' do
      inspect_source(cop, %{
        describe JumpStick do
          def zappy_zap
            puts "yarrwafeiowhf"
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within module" do
    it 'allows defs' do
      inspect_source(cop, %{
        module JumpStick
          def jumpy
            puts "vroom"
            puts "vroom"
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within shared_context" do
    it 'allows defs' do
      inspect_source(cop, %{
        shared_context "in-process server selenium tests" do
          def bat_poo
            "splat!"
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "within shared_examples" do
    it 'allows defs' do
      inspect_source(cop, %{
        shared_examples '[:correct]' do
          def pirates
            "attaaaaaaaack!"
          end
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  it "disallows defs on Object" do
    inspect_source(cop, %{
      def crow_tornado_so_op
        puts "yoo"
      end
    })
    expect(cop.offenses.size).to eq(1)
    expect(cop.messages.first).to match(/Define all helper/)
    expect(cop.offenses.first.severity.name).to eq(:warning)
  end
end