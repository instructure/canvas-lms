# frozen_string_literal: true

shared_examples "comments" do |raw_changes|
  let(:changes) { raw_changes.map { |c| double(c) } }
  let(:linter) { described_class.new(changes:, config:) }

  it "comments" do
    expect(linter.run).to match(hash_including(linter.comment))
  end
end

shared_examples "comments with msg key" do |raw_changes, msg_key|
  let(:changes) { raw_changes.map { |c| double(c) } }
  let(:linter) { described_class.new(changes:, config:) }

  it "comments" do
    result = linter.run
    expect(result).to match(hash_including(linter.comment))
    expect(result[:message]).to eq(config[:messages][msg_key])
  end
end

shared_examples "does not comment" do |raw_changes|
  let(:changes) { raw_changes.map { |c| double(c) } }
  let(:linter) { described_class.new(changes:, config:) }

  it "does not comment" do
    expect(linter.run).to be_nil
  end
end

shared_examples "change combos" do |change_path, spec_path|
  context "not deletion" do
    context "no spec changes" do
      include_examples "comments",
                       [{ path: change_path, status: "added" }]
    end

    context "has spec non deletions" do
      include_examples "does not comment",
                       [{ path: change_path, status: "modified" },
                        { path: spec_path, status: "added" }]
    end

    context "has spec deletions" do
      include_examples "comments",
                       [{ path: change_path, status: "added" },
                        { path: spec_path, status: "deleted" }]
    end
  end

  context "deletion" do
    include_examples "does not comment",
                     [{ path: change_path, status: "deleted" }]
  end
end

shared_examples "change combos with msg key" do |change_path, spec_path, msg_key|
  context "not deletion" do
    context "no spec changes" do
      include_examples "comments with msg key",
                       [{ path: change_path, status: "added" }],
                       msg_key
    end

    context "has spec non deletions" do
      include_examples "does not comment",
                       [{ path: change_path, status: "modified" },
                        { path: spec_path, status: "added" }]
    end

    context "has spec deletions" do
      include_examples "comments with msg key",
                       [{ path: change_path, status: "added" },
                        { path: spec_path, status: "deleted" }],
                       msg_key
    end
  end

  context "deletion" do
    include_examples "does not comment",
                     [{ path: change_path, status: "deleted" }]
  end
end
