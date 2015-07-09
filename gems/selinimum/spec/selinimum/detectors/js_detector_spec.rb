require "spec_helper"

describe Selinimum::Detectors::JsDetector do
  before do
    allow(Selinimum::RequireJSLite).to receive(:find_bundles_for).and_return(["app/coffeescripts/bundles/bar.coffee"])
  end

  describe "#can_process?" do
    it "processes js files in the right path" do
      expect(subject.can_process?("public/javascripts/quizzes.js")).to be_truthy
    end
  end

  describe "#bundles_for" do
    it "finds top-level bundle(s)" do
      expect(Selinimum::RequireJSLite)
        .to receive(:find_bundles_for).with("foo").and_return(["app/coffeescripts/bundles/bar.coffee"])
      expect(subject.bundles_for("public/javascripts/foo.js")).to eql(["bar"])
    end

    it "raises on no bundle" do
      allow(Selinimum::RequireJSLite).to receive(:find_bundles_for).with("foo").and_return([])
      expect { subject.bundles_for("public/javascripts/foo.js") }.to raise_error(Selinimum::UnknownDependenciesError)
    end

    it "raises on the common bundle" do
      allow(Selinimum::RequireJSLite)
        .to receive(:find_bundles_for).with("foo").and_return(["app/coffeescripts/bundles/common.coffee"])
      expect { subject.bundles_for("public/javascripts/foo.js") }.to raise_error(Selinimum::TooManyDependenciesError)
    end
  end

  describe "#dependents_for" do
    it "formats the bundle dependency" do
      expect(subject.dependents_for("public/javascripts/foo.js")).to eql(["js:bar"])
    end
  end
end
