require "selinimum/detectors/handlebars_detector"

describe Selinimum::Detectors::HandlebarsDetector do
  before do
    allow_any_instance_of(Selinimum::Detectors::HandlebarsDetector)
      .to receive(:template_graph).and_return({
        "app/views/jst/foo/_item.handlebars" => ["app/views/jst/foo/_items.handlebars"],
        "app/views/jst/foo/_items.handlebars" => ["app/views/jst/foo/template.handlebars"]
      })
  end

  describe "#can_process?" do
    it "process handlebars files in the right path" do
      expect(subject.can_process?("app/views/jst/foo/_item.handlebars", {})).to be_truthy
    end
  end
end
