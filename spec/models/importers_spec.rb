#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe Importers do
  describe 'disable_live_events!' do
    it 'disables the live event observer' do
      Importers.disable_live_events! do
        expect(Canvas::LiveEvents).not_to receive(:assignment_created)
        assignment_model
      end
    end

    it 'ensures live events are re-enabled' do
      expect do
        Importers.disable_live_events! { raise 'an error' }
      end.to raise_error 'an error'
      expect(Canvas::LiveEvents).to receive(:assignment_created)
      assignment_model
    end
  end

  describe 'enable_live_events!' do
    it 'enables live events' do
      Importers.disable_live_events! do
        Importers.enable_live_events!
        expect(Canvas::LiveEvents).to receive(:assignment_created)
        assignment_model
      end
    end
  end
end
