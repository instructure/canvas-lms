require 'spec_helper'

module DrDiff
  describe DiffParser do
    let(:add_diff) do
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

    let(:subtractive_diff) do
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

    let(:combination_diff) do
      %{
        commit 1209c53bf6c3f7b2a3a762c7ac0d52a824f51399
  Author: Ethan Vizitei <evizitei@instructure.com>
  Date:   Fri Apr 10 08:31:53 2015 -0600

    add heavy mode

    lets rlint only run with local changeset unless you specify "--heavy"

    Change-Id: I4a960c72644dfc46aca7a51d04321711cef0850c

  diff --git a/Gemfile.d/development.rb b/Gemfile.d/development.rb
  index 4089f23..7dfcd30 100644
  --- a/Gemfile.d/development.rb
  +++ b/Gemfile.d/development.rb
  @@ -4,6 +4,7 @@ group :development do
   gem 'rb-inotify', '~>0.9.0', require: false
   gem 'rb-fsevent', require: false
   gem 'rb-fchange', require: false
  +  gem 'rainbow', require: false

   gem "letter_opener"
   gem 'spring', '>= 1.3.0'
  diff --git a/script/rlint b/script/rlint
  index de9af40..fc31c9d 100755
  --- a/script/rlint
  +++ b/script/rlint
  @@ -61,8 +61,20 @@ if ENV['GERRIT_REFSPEC']
     `gergich comment \#{Shellwords.escape(comments.to_json)}`
   end
  else
  +  heavy_mode = ARGV.include?("--heavy")
   #local run, just spit out everything wrong with these files to output
   env_sha = ENV['SHA']
   ruby_files = pick_ruby_files(env_sha)
  -  cli.run(ruby_files)
  +  if heavy_mode
  +    cli.run(ruby_files)
  +  else
  +    require 'rainbow'
  +    cli.run(ruby_files + ["--format", "json", "--out", ".rubocop-output.json"])
  +    results_json = JSON.parse(File.read(".rubocop-output.json"))
  +    diff = git_diff(env_sha)
  +    comments = RuboCop::Canvas::Comments.build(diff, results_json)
  +    comments.each do |comment|
  +      $stdout.printf("[%s]", comment)
  +    end
  +  end
  end
      }
    end


    describe "#relevant?" do
      context "diff with new code" do
        let(:parser){ described_class.new(add_diff) }

        it "is true for same file with a line number in the range" do
          expect(parser.relevant?("some_file.rb", 3)).to be(true)
        end

        it "is false for a different file" do
          expect(parser.relevant?("some_other_file.rb", 3)).to be(false)
        end

        it "is false for a line number outside the change ranges" do
          expect(parser.relevant?("some_file.rb", 8)).to be(false)
        end

        it "is only true for touched lines" do
          expect(parser.relevant?("some_file.rb", 56)).to be(false)
          expect(parser.relevant?("some_file.rb", 57)).to be(false)
          expect(parser.relevant?("some_file.rb", 60)).to be(true)
          expect(parser.relevant?("some_file.rb", 66)).to be(false)
          expect(parser.relevant?("some_file.rb", 67)).to be(false)
        end

        it "is relevant anywhere in ranges if severe" do
          expect(parser.relevant?("some_file.rb", 56, true)).to be(false)
          expect(parser.relevant?("some_file.rb", 57, true)).to be(true)
          expect(parser.relevant?("some_file.rb", 66, true)).to be(true)
          expect(parser.relevant?("some_file.rb", 67, true)).to be(false)
        end
      end

      context "for diffs with deletions" do
        let(:parser){ described_class.new(subtractive_diff) }

        it 'respects the boundary of a removed diff set' do
          expect(parser.relevant?("some_file.rb", 55, true)).to be(false)
          expect(parser.relevant?("some_file.rb", 56, true)).to be(true)
          expect(parser.relevant?("some_file.rb", 60, true)).to be(true)
          expect(parser.relevant?("some_file.rb", 61, true)).to be(false)
        end
      end
    end

    describe "raw parsing" do
      it "parses combination diffs correctly" do
        parser = described_class.new(combination_diff)
        diff = parser.diff
        expect(diff['Gemfile.d/development.rb'][:change]).to eq([7])
        expect(diff['script/rlint'][:change]).to eq([64]+(68..79).to_a)
      end

      it "parses additive diffs correctly" do
        parser = described_class.new(add_diff)
        diff = parser.diff
        expect(diff['some_file.rb'][:change]).to eq([3, 60, 61, 62])
      end

      it "parses subtractive diffs correctly" do
        parser = described_class.new(subtractive_diff)
        diff = parser.diff
        expect(diff['some_file.rb'][:change]).to eq([])
      end
    end
  end
end
