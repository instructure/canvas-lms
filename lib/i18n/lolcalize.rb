module I18n
  module Lolcalize
    def translate_with_lols(key, options = {})
      if options[:default]
        key = :lols # so that it doesn't find a real translation
        options[:default] = let_there_be_lols(options[:default]) if options[:default].present?
      end
      translate_without_lols(key, options)
    end

    # see also app/coffeescripts/str/i18nLolcalize.coffee
    def let_there_be_lols(str)
      # don't want to mangle placeholders, wrappers, etc.
      pattern = /(\s*%h?\{[^\}]+\}\s*|\s*[\n\\`\*_\{\}\[\]\(\)\#\+\-!]+\s*|^\s+)/
      result = str.split(pattern).map do |token|
        if token =~ pattern
          token
        else
          s = ''
          token.chars.each_with_index do |c, i|
            s << (i % 2 == 1 ? c.upcase : c.downcase)
          end
          s.gsub!(/\.( |\z)/, '!!?! ')
          s.sub!(/\A(\w+)\z/, '\1!')
          s << " LOL!" if s.length > 2
          s
        end
      end
      result.join('')
    end

    def self.extended(klass)
      klass.class_eval do
        class << self
          alias_method_chain :translate, :lols
          alias_method :t, :translate
        end
      end
    end
  end
end
