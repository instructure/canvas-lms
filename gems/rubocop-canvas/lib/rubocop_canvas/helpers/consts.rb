module RuboCop
  module Cop
    module Consts
      module JQuerySelectors
        # https://api.jquery.com/category/selectors/jquery-selector-extensions/
        JQUERY_SELECTOR_EXTENSIONS = [
          /:animated/, # https://api.jquery.com/animated-selector/
          # Attribute Not Equal Selector [name!="value"]
          /\[\w+!=/,    # https://api.jquery.com/attribute-not-equal-selector/
          /:button/,    # https://api.jquery.com/button-selector/
          /:checkbox/,  # https://api.jquery.com/checkbox-selector/
          /:contains/,  # https://api.jquery.com/contains-selector/
          /:eq\(/,      # https://api.jquery.com/eq-selector/
          /:even/,      # https://api.jquery.com/even-selector/
          /:file/,      # https://api.jquery.com/file-selector/
          /:first/,     # https://api.jquery.com/first-selector/
          /:gt\(/,      # https://api.jquery.com/gt-selector/
          /:has\(/,     # https://api.jquery.com/has-selector/
          /:header/,    # https://api.jquery.com/header-selector/
          /:hidden/,    # https://api.jquery.com/hidden-selector/
          /:image/,     # https://api.jquery.com/image-selector/
          /:input/,     # https://api.jquery.com/input-selector/
          /:last/,      # https://api.jquery.com/last-selector/
          /:lt\(/,      # https://api.jquery.com/lt-selector/
          /:nth\(/,     # equivalent to :eq()
          /:odd/,       # https://api.jquery.com/odd-selector/
          /:parent/,    # https://api.jquery.com/parent-selector/
          /:password/,  # https://api.jquery.com/password-selector/
          /:radio/,     # https://api.jquery.com/radio-selector/
          /:reset/,     # https://api.jquery.com/reset-selector/
          /:selected/,  # https://api.jquery.com/selected-selector/
          /:submit/,    # https://api.jquery.com/submit-selector/
          /:text/,      # https://api.jquery.com/text-selector/
          /:visible/,   # https://api.jquery.com/visible-selector/
        ].freeze

        # https://api.jqueryui.com/category/selectors/
        JQUERY_UI_SELECTORS = [
          /:data\(/,    # https://api.jqueryui.com/data-selector/
          /:focusable/, # https://api.jqueryui.com/focusable-selector/
          /:tabbable/,  # https://api.jqueryui.com/tabbable-selector/
        ].freeze

        JQUERY_SELECTORS = JQUERY_SELECTOR_EXTENSIONS + JQUERY_UI_SELECTORS
        JQUERY_SELECTORS_REGEX = /#{JQUERY_SELECTORS.join("|")}/
      end
    end
  end
end
