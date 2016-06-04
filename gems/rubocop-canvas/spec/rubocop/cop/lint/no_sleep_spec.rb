describe RuboCop::Cop::Lint::NoSleep do
  subject(:cop) { described_class.new }

  context "controller" do
    before(:each) do
      allow(cop).to receive(:file_name).and_return("knights_controller.rb")
    end

    it 'disallows sleep' do
      inspect_source(cop, %{
        class KnightsController < ApplicationController
          def find_sword
            sleep 999
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to match(/tie up this process/)
      expect(cop.offenses.first.severity.name).to eq(:error)
    end
  end

  context "spec" do
    before(:each) do
      allow(cop).to receive(:file_name).and_return("alerts_spec.rb")
    end

    it 'disallows sleep' do
      inspect_source(cop, %{
        describe "Alerts" do
          it "should validate the form" do
            sleep 2
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to match(/consider: Timecop/)
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end
  end

  context "other" do
    before(:each) do
      allow(cop).to receive(:file_name).and_return("bookmark_service.rb")
    end

    it 'disallows sleep' do
      inspect_source(cop, %{
        class BookmarkService < UserService
          def find_bookmarks(query)
            sleep Time.now - last_get
          end
        end
      })
      expect(cop.offenses.size).to eq(1)
      expect(cop.messages.first).to eq("Avoid using sleep.")
      expect(cop.offenses.first.severity.name).to eq(:warning)
    end
  end
end
