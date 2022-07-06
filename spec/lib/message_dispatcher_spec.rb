# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

describe "MessageDispatcher" do
  describe ".dispatch" do
    before do
      allow(InstStatsd::Statsd).to receive(:increment)
      message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email")
    end

    it "reschedules on Mailer delivery error" do
      track_jobs { MessageDispatcher.dispatch(@message) }
      expect(created_jobs.size).to eq 1
      job = created_jobs.first
      expect(Mailer).to receive(:create_message).and_raise(Timeout::Error)
      run_jobs
      expect(@message.reload.dispatch_at).to be > Time.now.utc + 4.minutes
      expect(job.reload.attempts).to eq 1
      expect(job.run_at).to be > @message.dispatch_at - 5.minutes
    end

    it "does not reschedule on canceled Message" do
      track_jobs { MessageDispatcher.dispatch(@message) }
      expect(created_jobs.size).to eq 1
      job = created_jobs.first
      @message.cancel
      run_jobs
      expect(@message.reload.state).to eq :cancelled
      expect { job.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "increments MessageDispatcher.dispatch.failed after Delayed::RetriableError" do
      message = Message.new(id: -1, created_at: Time.zone.now)
      worker = MessageDispatcher::DeliverWorker.new(message)
      expect { worker.perform }.to raise_error(Delayed::RetriableError)

      expect(InstStatsd::Statsd).to have_received(:increment).with("MessageDispatcher.dispatch.failed")
    end
  end

  describe ".batch_dispatch" do
    before do
      @messages = (0...3).map { message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email") }
    end

    it "shows message ids not found in batch process" do
      messages = @messages
      messages.push(Message.new(id: -1, created_at: Time.zone.now))
      track_jobs { MessageDispatcher.batch_dispatch(messages) }
      expect(created_jobs.size).to eq 1
      job = created_jobs.first
      run_jobs
      job.reload
      expect(job.last_error).to include("IDs not found: [-1]")
    end

    it "reschedules on Mailer delivery error, but not on canceled Message" do
      track_jobs { MessageDispatcher.batch_dispatch(@messages) }
      expect(created_jobs.size).to eq 1
      job = created_jobs.first
      @messages[0].cancel

      am_message = double
      expect(am_message).to receive(:deliver_now).and_return(true)
      expect(Mailer).to receive(:create_message).and_raise(Timeout::Error).ordered
      expect(Mailer).to receive(:create_message).and_raise(Timeout::Error).and_return(am_message).ordered

      track_jobs { Delayed::Worker.new.perform(job) }
      expect(created_jobs.size).to eq 1
      job2 = created_jobs.first
      @messages.each(&:reload)
      expect(@messages.map(&:state)).to eq %i[cancelled staged sent]
      expect(@messages[1].dispatch_at).to be > Time.now.utc + 4.minutes
      # the original job is complete, but the individual message gets re-scheduled in its own job
      expect { job.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect(job2.tag).to eq "MessageDispatcher::DeliverWorker#perform"
      expect(job2.payload_object.message).to eq @messages[1]
      expect(job2.run_at.to_i).to eq @messages[1].dispatch_at.to_i
    end

    describe "cross_shard" do
      specs_require_sharding

      before do
        @shard1.activate do
          @messages += (0...3).map { message_model(dispatch_at: Time.now, workflow_state: "staged", to: "somebody", updated_at: Time.now.utc - 11.minutes, user: user_factory, path_type: "email") }
        end
      end

      it "loads all the matches" do
        track_jobs { MessageDispatcher.batch_dispatch(@messages) }
        expect(created_jobs.size).to eq 1
        job = created_jobs.first

        am_message = double
        allow(am_message).to receive(:deliver_now).and_return(true)
        allow(Mailer).to receive(:create_message).and_return(am_message)

        track_jobs { Delayed::Worker.new.perform(job) }
        @messages.each(&:reload)
        expect(@messages.map(&:state)).to eq %i[sent sent sent sent sent sent]
      end
    end
  end
end
