#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'spec_helper'

describe LiveEvents::AsyncWorker do
  before(:each) do
    LiveEvents.max_queue_size = -> { 100 }
    @worker = LiveEvents::AsyncWorker.new(false)
    allow(LiveEvents.logger).to receive(:info)
    allow(@worker).to receive(:at_exit)
  end

  describe "push" do
    it "should execute stuff pushed on the queue" do
      fired = false

      @worker.push -> { fired = true }

      @worker.start!
      @worker.stop!

      expect(fired).to be true
    end

    it "should reject items when queue is full" do
      LiveEvents.max_queue_size = -> { 5 }
      5.times { expect(@worker.push -> {}).to be_truthy }

      expect(@worker.push -> {}).to be false
    end
  end

  describe "exit handling" do

    it "should drain the queue" do
      fired = false
      @worker.push -> { fired = true }
      expect(@worker).to receive(:at_exit).and_yield
      @worker.start!
      expect(fired).to be true
    end
  end
end

