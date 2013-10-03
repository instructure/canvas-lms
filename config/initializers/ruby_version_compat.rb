# ruby 1.9 compatibility fixes for Rails 2.3

if RUBY_VERSION < '2.0'
  # see https://bugs.ruby-lang.org/issues/7547
  # the fix was only applied in 2.0
  module Dir::Tmpname
    def create(basename, *rest)
      if opts = Hash.try_convert(rest[-1])
        opts = opts.dup if rest.pop.equal?(opts)
        max_try = opts.delete(:max_try)
        opts = [opts]
      else
        opts = []
      end
      tmpdir, = *rest
      if $SAFE > 0 and tmpdir.tainted?
        tmpdir = '/tmp'
      else
        tmpdir ||= tmpdir()
      end
      n = nil
      begin
        path = File.join(tmpdir, make_tmpname(basename, n))
        yield(path, n, *opts)
      rescue Errno::EEXIST
        n ||= 0
        n += 1
        retry if !max_try or n < max_try
        raise "cannot generate temporary name using `#{basename}' under `#{tmpdir}'"
      end
      path
    end
  end
end

# See http://developer.uservoice.com/entries/how-to-upgrade-a-rails-2.3.14-app-to-ruby-1.9.3/
# TZInfo needs to be patched.  In particular, you'll need to re-implement the datetime_new! method:
require 'tzinfo'

module TZInfo
  # Methods to support different versions of Ruby.
  module RubyCoreSupport #:nodoc:
    HALF_DAYS_IN_DAY = rational_new!(1, 2)

    # Rails 2.3 defines datetime_new! in terms of methods that don't exist in
    # Ruby 1.9.3, so we have to redefine it here
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

if CANVAS_RAILS2

  require "active_support/core_ext/string/output_safety"
  class ERB
    module Util
      # see https://github.com/rails/rails/issues/7430
      def html_escape(s)
        s = s.to_s
        if s.html_safe?
          s
        else
          s.gsub(/[&"'><]/, HTML_ESCAPE).html_safe
        end
      end
 
      alias h html_escape
 
      singleton_class.send(:remove_method, :html_escape)
      module_function :html_escape, :h
    end
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

  # ActiveSupport::SafeBuffer is a subclass of String, and while string
  # literals get the encoding of the source file,
  #
  # String.new always gets ascii-8bit encoding. This means that depending on
  # the contents of a template and the data interpolated into the template,
  # things either work great or you get an incompatible encoding error.
  #
  # This patch fixes the problem by giving new SafeBuffers the default encoding
  # (which in canvas is utf-8)
  class ActiveSupport::SafeBuffer
    def initialize(*a)
      super.force_encoding('utf-8')
    end
  end

  # Get rid of the warnings in Rails 2.3 + Ruby 1.9 about unicode
  # normalization not being supported.
  module ActiveSupport::Inflector
    def transliterate(string)
      I18n.transliterate(string)
    end
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
      if o.respond_to?(:original_filename) && o.original_filename
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

class ActiveRecord::Base
  # this is basically all potentially affected AR serialized columns that
  # existed in the DB before Canvas was Ruby 1.9 only. We've verified that
  # none of these columns should legitimately contain binary data, only text.
  SERIALIZED_COLUMNS_WITH_POTENTIALLY_INVALID_UTF8 = {
    'AssessmentQuestion'       => %w[question_data],
    'ContextExternalTool'      => %w[settings],
    'EportfolioEntry'          => %w[content],
    'ErrorReport'              => %w[http_env data],
    'LearningOutcome'          => %w[data],
    'Profile'                  => %w[data],
    'Quiz'                     => %w[quiz_data],
    'QuizQuestion'             => %w[question_data],
    'QuizSubmission'           => %w[quiz_data submission_data],
    'QuizSubmissionSnapshot'   => %w[data],
    'Rubric'                   => %w[data],
    'RubricAssessment'         => %w[data],
    'SisBatch'                 => %w[processing_errors processing_warnings],
    'StreamItem'               => %w[data]
  }

  def unserialize_attribute_with_utf8_check(attr_name)
    value = unserialize_attribute_without_utf8_check(attr_name)
    if SERIALIZED_COLUMNS_WITH_POTENTIALLY_INVALID_UTF8[self.class.name].try(:include?, attr_name.to_s)
      TextHelper.recursively_strip_invalid_utf8!(value, true)
    end
    value
  end
  alias_method_chain :unserialize_attribute, :utf8_check
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

# Fix for https://bugs.ruby-lang.org/issues/7278 , which was filling up our logs with these warnings
if RUBY_VERSION < "2."
  require 'net/protocol'
  class Net::InternetMessageIO
    def each_crlf_line(src)
      buffer_filling(@wbuf, src) do
        while line = @wbuf.slice!(/\A[^\r\n]*(?:\n|\r(?:\n|(?!\z)))/)
          yield line.chomp("\n") + "\r\n"
        end
      end
    end
  end
end
