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
    messages.each { |m| m.reload.workflow_state.should == 'sent'; m.batched_at.should be_present }
    queued = created_jobs.map { |j| j.payload_object.jobs.map { |j| j.payload_object.args } }.flatten
    queued.map(&:to_i).sort.should == messages.map(&:id).sort
  end
end
