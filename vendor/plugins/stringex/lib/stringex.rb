require 'lucky_sneaks/string_extensions'
require 'lucky_sneaks/unidecoder'

String.send :include, LuckySneaks::StringExtensions

if defined?(ActiveRecord)
  require 'lucky_sneaks/acts_as_url'
  ActiveRecord::Base.send :include, LuckySneaks::ActsAsUrl
end
