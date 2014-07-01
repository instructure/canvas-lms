# ruby pre-2.0 compatibility fixes

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
    'AssessmentQuestion'                => %w[question_data],
    'ContextExternalTool'               => %w[settings],
    'EportfolioEntry'                   => %w[content],
    'ErrorReport'                       => %w[http_env data],
    'LearningOutcome'                   => %w[data],
    'Profile'                           => %w[data],
    'Quizzes::Quiz'                     => %w[quiz_data],
    'Quizzes::QuizQuestion'             => %w[question_data],
    'Quizzes::QuizSubmission'           => %w[quiz_data submission_data],
    'Quizzes::QuizSubmissionSnapshot'   => %w[data],
    'Rubric'                            => %w[data],
    'RubricAssessment'                  => %w[data],
    'SisBatch'                          => %w[processing_errors processing_warnings],
    'StreamItem'                        => %w[data]
  }

  class << self
    def strip_invalid_utf8_from_attribute(attr_name, value)
      if SERIALIZED_COLUMNS_WITH_POTENTIALLY_INVALID_UTF8[self.name].try(:include?, attr_name.to_s)
        Utf8Cleaner.recursively_strip_invalid_utf8!(value, true)
      end
      value
    end

    if CANVAS_RAILS3
      def type_cast_attribute_with_utf8_check(attr_name, attributes, cache={})
        value = type_cast_attribute_without_utf8_check(attr_name, attributes, cache)
        strip_invalid_utf8_from_attribute(attr_name, value)
      end
      alias_method_chain :type_cast_attribute, :utf8_check
    end
  end
end

unless CANVAS_RAILS3
  module AttributeReadWithUtf8Check
    def read_attribute(attr_name, &block)
      self.class.strip_invalid_utf8_from_attribute(attr_name, super)
    end
  end
  ActiveRecord::AttributeMethods::Read.send(:prepend, AttributeReadWithUtf8Check)
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
