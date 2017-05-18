#
# Copyright (C) 2015 - present Instructure, Inc.
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
