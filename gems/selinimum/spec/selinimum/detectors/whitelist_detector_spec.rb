require "selinimum/detectors/whitelist_detector"

describe Selinimum::Detectors::WhitelistDetector do
  describe "#can_process?" do
    before do
      allow(Selinimum).to receive(:whitelist).and_return(%w[
        *.md
        *.png
        /bin
        /spec/*
        !/spec/fixtures/**
        !/spec/selenium
        !/spec/*.rb
      ])

      subject.commit_files = %w[
        app/models/user.rb
        bin/rails
        public/images/speedgrader_icon.png
        spec/models/user_spec.rb
        spec/fixtures/unsafe.png
        spec/selenium/foo_spec.rb
        spec/spec_helper.rb
        README.md
      ]
    end

    it "processes whitelisted files" do
      expect(subject.can_process?("README.md", {})).to be_truthy
      expect(subject.can_process?("bin/rails", {})).to be_truthy
      expect(subject.can_process?("public/images/speedgrader_icon.png", {})).to be_truthy
      expect(subject.can_process?("spec/models/user_spec.rb", {})).to be_truthy
    end

    it "doesn't process other files" do
      expect(subject.can_process?("app/models/user.rb", {})).to be_falsy
      expect(subject.can_process?("spec/selenium/foo_spec.rb", {})).to be_falsy
      expect(subject.can_process?("spec/spec_helper.rb", {})).to be_falsy
      expect(subject.can_process?("spec/fixtures/unsafe.png", {})).to be_falsy
    end
  end

  describe "#dependents_for" do
    it "returns nothing" do
      expect(subject.dependents_for("foo/bar/baz")).to eql([])
    end
  end
end


