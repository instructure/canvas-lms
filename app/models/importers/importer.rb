module Importers
  class Importer
    class << self
      attr_accessor :item_class

      # forward translations to CalendarEvent; they used to live there.
      def translate(key, default, options = {})
        raise "Needs self.item_class to be set in #{self}" unless self.item_class
        self.item_class.translate(key, default, options)
      end
      alias :t :translate

      def logger(*args)
        raise "Needs self.item_class to be set in #{self}" unless self.item_class
        self.item_class.logger(*args)
      end
    end
  end
end