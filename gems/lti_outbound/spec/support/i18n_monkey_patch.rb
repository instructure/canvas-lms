#Any including Application will need to perform the override in order for this gem to function as expected.

module I18n
  class << self
    attr_accessor :localizer

    # Public: If a localizer has been set, use it to set the locale and then
    # delete it.
    #
    # Returns nothing.
    def set_locale_with_localizer
      if localizer
        self.locale = localizer.call
        self.localizer = nil
      end
    end
  end
end