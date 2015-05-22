require 'spec_helper'

module Canvas
  class Errors
    describe JobInfo do
      let(:job) do
        stub(
          attempts: 1,
          strand: 'thing',
          priority: 1,
          handler: 'Something',
          run_at: Time.zone.now,
          max_attempts: 1,
          tag: "TAG"
        )
      end

      let(:worker){ stub(name: 'workername') }

      let(:info){ described_class.new(job, worker) }

      describe "#to_h" do
        subject(:hash){ info.to_h }

        it "tags all exceptions as 'BackgroundJob'" do
          expect(hash[:tags][:process_type]).to eq("BackgroundJob")
        end

        it "includes the tag from the job if there is one" do
          expect(hash[:tags][:job_tag]).to eq("TAG")
        end

        it "grabs some common attrs from jobs into extras" do
          expect(hash[:extra][:attempts]).to eq(1)
          expect(hash[:extra][:strand]).to eq('thing')
        end

        it "includes the worker name" do
          expect(hash[:extra][:worker_name]).to eq('workername')
        end
      end

    end
  end
end
