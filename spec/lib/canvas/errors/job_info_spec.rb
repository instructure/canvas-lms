require 'spec_helper'

module Canvas
  class Errors
    describe JobInfo do
      let(:job) do
        stub(
          id: 42,
          source: "controller:discussion_topics_api,action:add_entry,"\
                  "hostname:app010001063068-vpc.us-east-1.canvas.insops.net,"\
                  "pid:8949,context_id:c5ec694d-1c0d-4744-a97a-cae44c477837",
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

        it "includes the job id in the extras hash" do
          expect(hash[:extra][:id]).to eq(42)
        end

        it 'includes the source, which has the request context id' do
          expect(hash[:extra][:source]).
            to match(/c5ec694d-1c0d-4744-a97a-cae44c477837/)
        end
      end

    end
  end
end
