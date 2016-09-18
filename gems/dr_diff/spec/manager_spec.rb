require 'spec_helper'

module DrDiff
  describe Manager do
    describe ".files" do
      let(:git_files_output) do
%{lib/dr_diff.rb
spec/dr_diff_spec.rb}
      end

      let(:file_list) { git_files_output.split("\n") }

      before :each do
        allow(File).to receive(:exist?).and_return(true)
      end

      it "excludes files that do not exist" do
        git = double('git', files: git_files_output + "\nREADME.md")
        subject = described_class.new(git: git)
        allow(File).to receive(:exist?).with("README.md").and_return(false)
        expect(subject.files).to eq(file_list)
      end

      context "regex is given" do
        let(:git) { double('git', files: git_files_output + "\nbuild.js") }
        let(:subject) { described_class.new(git: git) }
        let(:ruby_regex) { /\.rb$/ }

        it "excludes files do not match the regex" do
          expect(subject.files(ruby_regex)).to eq(file_list)
        end
      end

      context "git_dir is given" do
        let(:git_dir) { "some/path/" }
        let(:git) { double('git', files: git_files_output) }
        let(:subject) { described_class.new(git: git, git_dir: git_dir) }

        it "prepends the results with the git_dir" do
          expect(subject.files(/\.rb$/)).to eq(file_list.map { |f| git_dir + f })
        end
      end
    end

    describe ".comments" do
      let(:format) { "rubocop" }
      let(:command) { "rubocop" }
      let(:diff_parser) { double("diff parser") }
      let(:command_capture) { double("command capture") }
      let(:git) { double('git', diff: "diff") }
      let(:subject) { described_class.new(git: git) }

      let(:command_capture_comments) do
        [
          {:path=>"gems/plugins/custom_reports/lib/custom_reports.rb",
           :message=>
             "[rubocop] Avoid using sleep.\n\n       sleep 1\n       ^^^^^^^\n",
           :position=>5,
           :severity=>"warn"}
        ]
      end

      before :each do
        expect(DiffParser).to receive(:new).with(git.diff).and_return(diff_parser)
        expect(CommandCapture).to receive(:run).with(format, command).and_return(command_capture_comments)
        allow(diff_parser).to receive(:relevant?).and_return(true)
      end

      it "returns all relevant comments" do
        result = subject.comments(format: format, command: command)
        expect(result.length).to eq(1)
      end

      it "does not return irrelevant comments" do
        allow(diff_parser).to receive(:relevant?).and_return(false)
        result = subject.comments(format: format, command: command)
        expect(result.length).to eq(0)
      end

      context "git_dir exists" do
        let(:git_dir) { "gems/plugins/custom_reports/" }
        let(:subject) { described_class.new(git: git, git_dir: git_dir) }

        it "removes git_dir from path when determining if relevant" do
          comment = command_capture_comments.first
          path_without_git_dir = comment[:path][git_dir.length..-1]
          expect(diff_parser).to receive(:relevant?).with(path_without_git_dir,
                                                          comment[:position],
                                                          true)
          subject.comments(format: format, command: command)
        end

        context "include_git_dir_in_output is true" do
          it "includes the git_dir in the output" do
            full_comment_path = command_capture_comments.first[:path]
            result = subject.comments(format: format, command: command, include_git_dir_in_output: true)
            expect(result.first[:path]).to eq(full_comment_path)
          end
        end

        context "include_git_dir_in_output is false" do
          it "does not include the git_dir in the output" do
            full_comment_path = command_capture_comments.first[:path]
            comment_path_without_git_dir = full_comment_path[git_dir.length..-1]
            result = subject.comments(format: format, command: command)
            expect(result.first[:path]).to eq(comment_path_without_git_dir)
          end
        end
      end

      context "git_dir does not exist" do
        let(:subject) { described_class.new(git: git) }

        it "passes the entire comment path in to determine if it is relevant" do
          comment = command_capture_comments.first
          expect(diff_parser).to receive(:relevant?).with(comment[:path],
                                                          comment[:position],
                                                          true)
          subject.comments(format: format, command: command)
        end
      end
    end
  end
end
