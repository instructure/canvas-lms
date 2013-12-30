require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe QuizQuestion::MatchGroup do
  describe '#add' do
    let(:properties) do
      { text: 'Arkansas', match_id: 177 }
    end

    it "adds to matches" do
      subject.add(properties)
      subject.matches.length.should == 1
      subject.matches.first.text.should == properties[:text]
      subject.matches.first.id.should == properties[:match_id]
    end

    it "does not add a duplicate match" do
      subject.add(properties)
      subject.matches.length.should == 1
      subject.add(properties)
      subject.matches.length.should == 1
    end

    context "when providing a match with only text" do
      it "generates a unique id" do
        subject.add(text: "Georgia")
        subject.matches.first.text.should == "Georgia"
        subject.matches.first.id.should_not be_nil
      end
    end

    context "when providing a match with the same text" do
      it "does not add a duplicate match" do
        subject.add(text: "California")
        subject.matches.length.should == 1
        subject.add(text: "California")
        subject.matches.length.should == 1
      end
    end
  end
end


