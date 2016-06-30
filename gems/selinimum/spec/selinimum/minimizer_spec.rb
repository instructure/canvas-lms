require "selinimum/minimizer"

describe Selinimum::Minimizer do
  describe "#filter" do
    class NopeDetector
      def can_process?(_, _)
        true
      end

      def dependents_for(file)
        raise Selinimum::TooManyDependentsError, file
      end

      def commit_files=(*); end
    end

    class FooDetector
      def can_process?(file, _)
        file =~ /foo/
      end

      def dependents_for(file)
        ["file:#{file}"]
      end

      def commit_files=(*); end
    end

    let(:spec_dependency_map) { { "spec/selenium/foo_spec.rb" => ["file:app/views/foos/show.html.erb"] } }
    let(:spec_files) do
      [
        "spec/selenium/foo_spec.rb",
        "spec/selenium/bar_spec.rb"
      ]
    end

    it "returns the spec_files if there is no corresponding dependent detector" do
      minimizer = Selinimum::Minimizer.new(spec_dependency_map, [])

      expect(minimizer.filter(["app/views/foos/show.html.erb"], spec_files)).to eql(spec_files)
    end

    it "returns the spec_files if a file's dependents can't be inferred" do
      minimizer = Selinimum::Minimizer.new(spec_dependency_map, [NopeDetector.new])

      expect(minimizer.filter(["app/views/foos/show.html.erb"], spec_files)).to eql(spec_files)
    end

    it "returns the filtered spec_files if every file's dependents can be inferred" do
      minimizer = Selinimum::Minimizer.new(spec_dependency_map, [FooDetector.new])

      expect(minimizer.filter(["app/views/foos/show.html.erb"], spec_files)).to eql(["spec/selenium/foo_spec.rb"])
    end
  end
end
