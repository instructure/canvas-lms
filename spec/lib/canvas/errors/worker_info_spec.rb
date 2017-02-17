require 'spec_helper'
require_dependency "canvas/errors/worker_info"

module Canvas
  class Errors
    describe WorkerInfo do
      let(:worker){ stub(name: 'workername') }
      let(:info){ described_class.new(worker) }

      subject(:hash){ info.to_h }

      it "tags all exceptions as 'BackgroundJob'" do
        expect(hash[:tags][:process_type]).to eq("BackgroundJob")
      end

      it "includes the worker name as a tag" do
        expect(hash[:tags][:worker_name]).to eq("workername")
      end

    end
  end
end
