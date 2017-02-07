require 'spec_helper'

module DrDiff
  describe GitProxy do
    describe ".files" do
      context "no sha is given during creation, and directory is dirty" do
        it "calls outstanding_change_files" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(true)
          expect(subject).to receive(:outstanding_change_files)
          subject.files
        end
      end

      context "no sha is given during creation, and directory is clean" do
        it "calls change_files" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(false)
          expect(subject).to receive(:change_files)
          subject.files
        end
      end

      context "a sha is given during creation" do
        it "calls change_files" do
          subject = described_class.new(sha: "12345")
          expect(subject).to receive(:change_files)
          subject.files
        end
      end
    end

    describe ".diff" do
      context "no sha is given during creation, and directory is dirty" do
        it "calls outstanding_change_diff" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(true)
          expect(subject).to receive(:outstanding_change_diff)
          subject.diff
        end
      end

      context "no sha is given during creation, and directory is clean" do
        it "calls outstanding_change_diff" do
          expect_any_instance_of(GitProxy).to receive(:dirty?).and_return(false)
          expect(subject).to receive(:change_diff)
          subject.diff
        end
      end

      context "a sha is given during creation" do
        it "calls change_diff" do
          subject = described_class.new(sha: "12345")
          expect(subject).to receive(:change_diff)
          subject.diff
        end
      end
    end
  end
end
