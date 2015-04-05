require 'spec_helper'

describe RuboCop::Canvas::DiffParser do
  describe "#relevant?" do
    let(:parser){ described_class.new(raw_diff) }

    context "diff with new code" do
      let(:raw_diff) do
          %{
            commit 5f073b464f0274b3035039b74c8dee84c21835dc
      Author: Ethan Vizitei <ethan.vizitei@gmail.com>
      Date:   Mon Apr 6 15:31:52 2015 -0600

          first commit

      diff --git a/some_file.rb b/some_file.rb
      index eede799..c949884 100644
      --- a/some_file.rb
      +++ b/some_file.rb
      @@ -1,5 +1,6 @@
       # encoding: utf-8

      +puts "DIFF TWO"
       require 'spec_helper'

       describe RuboCop::Cop::Style::ConstantName do
      @@ -56,6 +57,9 @@ describe RuboCop::Cop::Style::ConstantName do
           expect(cop.offenses).to be_empty
         end

      +
      +  puts "DIFF ONE"
      +
         it 'checks qualified const names' do
           inspect_source(cop,
                          ['::AnythingGoes = 30',

          }
        end

      it "is true for same file with a line number in the range" do
        expect(parser.relevant?("some_file.rb", 3)).to be(true)
      end

      it "is false for a different file" do
        expect(parser.relevant?("some_other_file.rb", 3)).to be(false)
      end

      it "is false for a line number outside the change ranges" do
        expect(parser.relevant?("some_file.rb", 8)).to be(false)
      end

      it "is true at the boundary of a diff set" do
        expect(parser.relevant?("some_file.rb", 56)).to be(false)
        expect(parser.relevant?("some_file.rb", 57)).to be(true)
        expect(parser.relevant?("some_file.rb", 66)).to be(true)
        expect(parser.relevant?("some_file.rb", 67)).to be(false)
      end
    end

    context "for diffs with deletions" do
      let(:raw_diff) do
        %{commit 6321b044912b5162a07c2f4f88c335ee1d781d1e
        Author: Ethan Vizitei <ethan.vizitei@gmail.com>
        Date:   Wed Apr 8 14:23:26 2015 -0600
        
            remove something
        
        diff --git a/some_file.rb b/some_file.rb
        index c949884..150ed80 100644
        --- a/some_file.rb
        +++ b/some_file.rb
        @@ -56,14 +56,4 @@ describe RuboCop::Cop::Style::ConstantName do
                            'Parser::CurrentRuby = Parser::Ruby20')
             expect(cop.offenses).to be_empty
           end
        -
        -
        -  puts "DIFF ONE"
        -
        -  it 'checks qualified const names' do
        -    inspect_source(cop,
                           -                   ['::AnythingGoes = 30',
        -                    'a::Bar_foo = 10'])
        -    expect(cop.offenses.size).to eq(2)
        -  end
         end
        }
      end

      it 'respects the boundary of a removed diff set' do
        expect(parser.relevant?("some_file.rb", 55)).to be(false)
        expect(parser.relevant?("some_file.rb", 56)).to be(true)
        expect(parser.relevant?("some_file.rb", 60)).to be(true)
        expect(parser.relevant?("some_file.rb", 61)).to be(false)
      end
    end
  end
end
