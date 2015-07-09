require "spec_helper"

describe Selinimum::Detectors::RubyDetector do
  describe "#can_process?" do
    it "processes ruby files in the right path" do
      expect(subject.can_process?("app/views/users/user.html.erb")).to be_truthy
      expect(subject.can_process?("app/views/users/_partial.html.erb")).to be_truthy
      expect(subject.can_process?("app/controllers/users_controller.rb")).to be_truthy
      expect(subject.can_process?("spec/selenium/users_spec.rb")).to be_truthy
    end

    it "doesn't process global-y files" do
      expect(subject.can_process?("app/views/layouts/application.html.erb")).to be_falsy
      expect(subject.can_process?("app/views/shared/_foo.html.erb")).to be_falsy
      expect(subject.can_process?("app/controllers/application_controller.rb")).to be_falsy
    end

    it "doesn't process other ruby files" do
      expect(subject.can_process?("app/models/user.rb")).to be_falsy
      expect(subject.can_process?("lib/foo.rb")).to be_falsy
    end
  end

  describe "#dependents_for" do
    it "returns the file itself" do
      expect(subject.dependents_for("app/views/users/user.html.erb")).to eql(["file:app/views/users/user.html.erb"])
    end
  end
end

