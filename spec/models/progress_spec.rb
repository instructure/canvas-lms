#
# Copyright (C) 2013 Instructure, Inc.
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

describe Progress do
  describe '#process_job' do
    class Jerbs
      cattr_accessor :flag
      extend RSpec::Matchers

      def self.succeed(progress, flag)
        expect(progress.state).to eq :running
        self.flag = flag
      end

      def self.fail(progress)
        raise "fail!"
      end
    end

    before { Jerbs.flag = nil }

    let(:progress) { Progress.create!(tag: "test", context: user_factory) }

    it "should update the progress while running the job" do
      progress.process_job(Jerbs, :succeed, {}, :flag)
      expect(progress).to be_queued
      run_jobs
      expect(progress.reload).to be_completed
      expect(progress.completion).to eq 100
      expect(Jerbs.flag).to eq :flag
    end

    it "should fail the progress if the job fails" do
      progress.process_job(Jerbs, :fail)
      run_jobs
      expect(progress.reload).to be_failed
    end
  end
end
