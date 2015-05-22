require 'spec_helper'

module RuboCop::Canvas
  describe FileSieve do
    describe "#files" do
      let(:file_list){ %w{lib/rubocop_canvas.rb spec/rubocop/canvas/comments_spec.rb} }
      let(:git_output) do
        %{
          lib/rubocop_canvas.rb
          spec/rubocop/canvas/comments_spec.rb
        }
      end

      context "with nil SHA" do
        context "with dirty git" do
          let(:git_output) do
            %{
              modified:   lib/rubocop_canvas.rb
              modified:   spec/rubocop/canvas/comments_spec.rb
            }
          end
          let(:git){ double('git', changes: git_output, dirty?: true) }
          let(:sieve){ described_class.new(git) }

          it "excludes non ruby files" do
            git_output << "\n   modified:   README.md"
            expect(sieve.files).to eq(file_list)
          end

          it "excludes files that dont exist" do
            git_output << "\n   modified:   not/a/file.rb"
            expect(sieve.files).to eq(file_list)
          end

          it "selects dirty files if git is dirty" do
            expect(sieve.files).to eq(file_list)
          end

        end

        it "gets file list from the head SHA if git is clean" do
          git = double('git', diff_files: git_output, dirty?: false, head_sha: '123')
          sieve = described_class.new(git)
          expect(sieve.files).to eq(file_list)
        end
      end

      it "gets file list from git diff of an explicit sha" do
        git = double('git')
        allow(git).to receive(:diff_files).with('MYSHA').and_return(git_output)
        sieve = described_class.new(git)
        expect(sieve.files('MYSHA')).to eq(file_list)
      end

    end
  end
end
