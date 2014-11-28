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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe StreamItemCache do
  describe "#invalidate_recent_stream_items" do
    it "deletes both the dashboard and context specific keys" do
      enable_cache do
        # GIVEN: I have an existing stream item and cache it
        # by calling cached_recent_stream_items
        course_with_teacher(:active_all => true)
        discussion_topic_model(:context => @course) # stream item
        @teacher.cached_recent_stream_items # cache the dashboard items
        @teacher.cached_recent_stream_items(:contexts => [@course]) # cache the context items
        dashboard_key = StreamItemCache.recent_stream_items_key(@teacher)
        context_key   = StreamItemCache.recent_stream_items_key(@teacher, 'Course', @course.id)
        expect(Rails.cache.read(dashboard_key)).not_to be_blank
        expect(Rails.cache.read(context_key)).not_to be_blank

        # WHEN: I create another stream item
        discussion_topic_model(:context => @course) # observer fires

        # EXPEXT: the cache to be cleared
        expect(Rails.cache.read(dashboard_key)).to be_blank
        expect(Rails.cache.read(context_key)).to be_blank
      end
    end
  end
end
