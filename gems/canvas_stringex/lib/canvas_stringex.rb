module CanvasStringex
  require "lucky_sneaks/string_extensions"
  require "lucky_sneaks/unidecoder"
  require "lucky_sneaks/acts_as_url"

  String.send :include, LuckySneaks::StringExtensions

  if defined?(ActiveRecord)
    ActiveRecord::Base.send :include, LuckySneaks::ActsAsUrl
  end
end
