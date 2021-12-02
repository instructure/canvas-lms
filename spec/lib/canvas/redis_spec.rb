# frozen_string_literal: true

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

if Canvas.redis_enabled?

  # TODO: When CanvasCache::Redis has replaced all callsites,
  # we won't need this shim anymore, and can drop this test verifying it.
  describe "Canvas::Redis" do
    it "doesn't marshall" do
      Canvas.redis.set('test', 1)
      expect(Canvas.redis.get('test')).to eq '1'
    end
  end

end
