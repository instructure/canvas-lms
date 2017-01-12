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
