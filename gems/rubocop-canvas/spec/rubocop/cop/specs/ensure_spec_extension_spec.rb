describe RuboCop::Cop::Specs::EnsureSpecExtension do
  subject(:cop) { described_class.new }

  context "named as *_spec.rb" do
    before(:each) do
      allow(cop).to receive(:file_name).and_return("dragoon_spec.rb")
    end

    context "top level context" do
      it 'does not warn for *_spec.rb extension' do
        inspect_source(cop, %{
          context AccountAuthorizationConfig::BlueDragoon do
            describe '#fire' do
              it 'rains fire' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(0)
      end
    end

    context "top level describe" do
      it 'does not warn for *_spec.rb extension' do
        inspect_source(cop, %{
          describe AccountAuthorizationConfig::GreenDragoon do
            describe '#green' do
              it 'smells bad' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  context "not named as *_spec.rb" do
    before(:each) do
      allow(cop).to receive(:file_name).and_return("dragoon.rb")
    end

    context "top level context" do
      it 'warns for *_spec.rb extension' do
        inspect_source(cop, %{
          context AccountAuthorizationConfig::BlueDragoon do
            describe '#fire' do
              it 'rains fire' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(1)
        expect(cop.messages.first).to match(/Spec files need to end with "_spec.rb"/)
        expect(cop.offenses.first.severity.name).to eq(:convention)
      end
    end

    context "top level describe" do
      it 'warns for *_spec.rb extension' do
        inspect_source(cop, %{
          describe AccountAuthorizationConfig::GreenDragoon do
            describe '#green' do
              it 'smells bad' do
                expect(1).to eq(1)
              end
            end
          end
        })
        expect(cop.offenses.size).to eq(1)
        expect(cop.messages.first).to match(/Spec files need to end with "_spec.rb"/)
        expect(cop.offenses.first.severity.name).to eq(:convention)
      end
    end
  end
end
