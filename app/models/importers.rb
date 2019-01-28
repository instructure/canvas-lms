#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Importers
  def self.register_content_importer(klass)
    @content_importers ||= {}
    @content_importers[klass.item_class.to_s] = klass
  end

  def self.content_importer_for(context_type)
    klass = @content_importers[context_type]
    raise "No content importer registered for #{context_type}" unless klass
    klass
  end

  def self.disable_live_events!
    ActiveRecord::Base.observers.disable LiveEventsObserver
    yield
  ensure
    enable_live_events!
  end

  def self.enable_live_events!
    ActiveRecord::Base.observers.enable LiveEventsObserver
  end

  class Importer
    class << self
      attr_accessor :item_class

      # forward translations to CalendarEvent; they used to live there.
      def translate(*args)
        raise "Needs self.item_class to be set in #{self}" unless self.item_class
        self.item_class.translate(*args)
      end
      alias :t :translate

      def logger(*args)
        raise "Needs self.item_class to be set in #{self}" unless self.item_class
        self.item_class.logger(*args)
      end
    end
  end
end

require_dependency 'importers/account_content_importer'
require_dependency 'importers/course_content_importer'
