#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "SummaryMessageConsolidator" do
  it "should process in batches" do
    Setting.set('summary_message_consolidator_batch_size', '2')
    users = (0..3).map { user_with_communication_channel }
    messages = []
    users.each { |u| 3.times { messages << delayed_message_model(:cc => u.communication_channels.first, :send_at => 1.day.ago) } }

    expects_job_with_tag('Delayed::Batch.serial', 2) do
      SummaryMessageConsolidator.process
    end
    messages.each { |m| expect(m.reload.workflow_state).to eq 'sent'; expect(m.batched_at).to be_present }
    queued = created_jobs.map { |j| j.payload_object.jobs.map { |j| j.payload_object.args } }.flatten
    expect(queued.map(&:to_i).sort).to eq messages.map(&:id).sort
  end

  it "should send summaries from different accounts in separate messages" do
    users = (0..3).map { user_with_communication_channel }
    dms = []
    account_ids = [1, 2, 3]
    delayed_messages_per_account = 2
    account_id_iter = (account_ids * delayed_messages_per_account).sort
    users.each do |u|
      account_id_iter.each do |rai|
        dms << delayed_message_model(
          :cc => u.communication_channels.first,
          :root_account_id => rai,
          :send_at => 1.day.ago)
      end
    end

    SummaryMessageConsolidator.process
    dm_summarize_expectation = DelayedMessage.expects(:summarize)
    dms.each_slice(delayed_messages_per_account) do |dms|
      dm_summarize_expectation.with(dms.map(&:id))
    end
    run_jobs
  end
end
