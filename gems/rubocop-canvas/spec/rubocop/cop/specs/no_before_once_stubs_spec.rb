describe RuboCop::Cop::Specs::NoBeforeOnceStubs do
  subject(:cop) { described_class.new }

  context "before(:all)" do
    it "allows all kinds of stubs" do
      inspect_source(cop, %{
        before(:all) do
          stub_file_data
          stub_kaltura
          stub_png_data
          collection = mock()
          collection.stubs(:table_name).returns("courses")
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "before(:each)" do
    it "allows all kinds of stubs" do
      inspect_source(cop, %{
        before(:each) do
          stub_file_data
          stub_kaltura
          stub_png_data
          collection = mock()
          collection.stubs(:table_name).returns("courses")
        end
      })
      expect(cop.offenses.size).to eq(0)
    end
  end

  context "before(:once)" do
    it "disallows all kinds of stubs" do
      inspect_source(cop, %{
        before(:once) do
          stub_file_data
          stub_kaltura
          stub_png_data
          collection = mock()
          collection.stubs(:table_name).returns("courses")
        end
      })
      expect(cop.offenses.size).to eq(5)
      expect(cop.messages.all? { |msg| msg =~ /Use `before\(:once\)`/ })
      expect(cop.offenses.all? { |off| off.severity.name == :warning })
    end
  end
end
