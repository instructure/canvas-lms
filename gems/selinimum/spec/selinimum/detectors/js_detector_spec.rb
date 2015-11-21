require "selinimum/detectors/js_detector"

describe Selinimum::Detectors::JSDetector do
  describe "#can_process?" do
    it "processes js files in the right path" do
      expect(subject.can_process?("public/javascripts/quizzes.js")).to be_truthy
    end
  end

  describe "#dependents_for" do
    it "finds top-level bundle(s)" do
      expect(subject)
        .to receive(:graph).and_return({"foo.js" => ["compiled/bundles/bar.js"]})
      expect(subject.dependents_for("public/javascripts/foo.js")).to eql(["js:bar"])
    end

    it "raises on no bundle" do
      expect(subject)
        .to receive(:graph).and_return({})
      expect { subject.dependents_for("public/javascripts/foo.js") }.to raise_error(Selinimum::UnknownDependentsError)
    end

    it "raises on the common bundle" do
      expect(subject)
        .to receive(:graph).and_return({"foo.js" => ["compiled/bundles/common.js"]})
      expect { subject.dependents_for("public/javascripts/foo.js") }.to raise_error(Selinimum::TooManyDependentsError)
    end
  end
end
