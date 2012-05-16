if RUBY_VERSION < "1.9."
  require 'fastercsv'
else
  # ruby 1.9 compatibility fixes

  # 1.9 has a built-in equivalent to fastercsv
  # make an alias for CSV, which has replaced FasterCSV
  require 'csv'
  FasterCSV = CSV

  # See http://developer.uservoice.com/entries/how-to-upgrade-a-rails-2.3.14-app-to-ruby-1.9.3/
  # TZInfo needs to be patched.  In particular, you'll need to re-implement the datetime_new! method:
  require 'tzinfo'

  module TZInfo
    # Methods to support different versions of Ruby.
    module RubyCoreSupport #:nodoc:
      # Ruby 1.8.6 introduced new! and deprecated new0.
      # Ruby 1.9.0 removed new0.
      # Ruby trunk revision 31668 removed the new! method.
      # Still support new0 for better performance on older versions of Ruby (new0 indicates
      # that the rational has already been reduced to its lowest terms).
      # Fallback to jd with conversion from ajd if new! and new0 are unavailable.
      if DateTime.respond_to? :new!
        def self.datetime_new!(ajd = 0, of = 0, sg = Date::ITALY)
          DateTime.new!(ajd, of, sg)
        end
      elsif DateTime.respond_to? :new0
        def self.datetime_new!(ajd = 0, of = 0, sg = Date::ITALY)
          DateTime.new0(ajd, of, sg)
        end
      else
        HALF_DAYS_IN_DAY = rational_new!(1, 2)

        def self.datetime_new!(ajd = 0, of = 0, sg = Date::ITALY)
          # Convert from an Astronomical Julian Day number to a civil Julian Day number.
          jd = ajd + of + HALF_DAYS_IN_DAY

          # Ruby trunk revision 31862 changed the behaviour of DateTime.jd so that it will no
          # longer accept a fractional civil Julian Day number if further arguments are specified.
          # Calculate the hours, minutes and seconds to pass to jd.

          jd_i = jd.to_i
          jd_i -= 1 if jd < 0
          hours = (jd - jd_i) * 24
          hours_i = hours.to_i
          minutes = (hours - hours_i) * 60
          minutes_i = minutes.to_i
          seconds = (minutes - minutes_i) * 60

          DateTime.jd(jd_i, hours_i, minutes_i, seconds, of, sg)
        end
      end
    end
  end

  if Rails.version > "3."
    raise "These following patches shouldn't be necessary in Rails 3.x"
  end

  # also https://groups.google.com/forum/#!msg/rubyonrails-core/gb5woRkmDlk/iQ2G7jjNWKkJ
  MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]

  # In Ruby 1.9, respond_to? (which is what proxy_respond_to? REALLY is), chains to
  # respond_to_missing?.  However, respond_to_missing? is *not* defined on
  # AssociationProxy because Rails removes *all* methods besides __*, send,
  # nil?, and object_id, so it hits method_missing, and tries to load the
  # target.
  # See https://rails.lighthouseapp.com/projects/8994/tickets/5410-multiple-database-queries-when-chaining-named-scopes-with-rails-238-and-ruby-192
  # (The patch in that lighthouse bug was not, in fact, merged in).
  class ActiveRecord::Associations::AssociationProxy
    def respond_to_missing?(meth, incl_priv)
      false
    end
  end

  # This makes it so all parameters get converted to UTF-8 before they hit your
  # app.  If someone sends invalid UTF-8 to your server, raise an exception.
  class ActionController::InvalidByteSequenceErrorFromParams < Encoding::InvalidByteSequenceError; end
  class ActionController::Base
    def force_utf8_params
      traverse = lambda do |object, block|
        if object.kind_of?(Hash)
          object.each_value { |o| traverse.call(o, block) }
        elsif object.kind_of?(Array)
          object.each { |o| traverse.call(o, block) }
        else
          block.call(object)
        end
        object
      end
      force_encoding = lambda do |o|
        if o.respond_to?(:force_encoding)
          o.force_encoding(Encoding::UTF_8)
          raise ActionController::InvalidByteSequenceErrorFromParams unless o.valid_encoding?
        end
        if o.respond_to?(:original_filename)
          o.original_filename.force_encoding(Encoding::UTF_8)
          raise ActionController::InvalidByteSequenceErrorFromParams unless o.original_filename.valid_encoding?
        end
      end
      traverse.call(params, force_encoding)
      path_str = request.path.to_s
      if path_str.respond_to?(:force_encoding)
        path_str.force_encoding(Encoding::UTF_8)
        raise ActionController::InvalidByteSequenceErrorFromParams unless path_str.valid_encoding?
      end
    end
    before_filter :force_utf8_params
  end

  # Make sure the flash sets the encoding to UTF-8 as well.
  module ActionController
    module Flash
      class FlashHash
        def [](k)
          v = super
          v.is_a?(String) ? v.force_encoding("UTF-8") : v
        end
      end
    end
  end

end
