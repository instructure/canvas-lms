ActiveSupport::TimeWithZone.delegate :to_yaml, :to => :utc
ActiveSupport::SafeBuffer.class_eval do
  def encode_with(coder)
    coder.scalar("!str", self.to_str)
  end
end

module ActiveSupport::Cache
  module RailsCacheShim
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{CANVAS_RAILS4_2 ? 'namespaced_key' : 'normalize_key'}(key, options)
        result = super
        if options && options.has_key?(:use_new_rails) ? options[:use_new_rails] : !CANVAS_RAILS4_2
          result = "rails5:\#{result}"
        end
        result
      end
RUBY

    def delete(key, options = nil)
      r1 = super(key, (options || {}).merge(use_new_rails: !CANVAS_RAILS4_2)) # prefer rails 3 if on rails 3 and vis versa
      r2 = super(key, (options || {}).merge(use_new_rails: CANVAS_RAILS4_2))
      r1 || r2
    end
  end
  Store.prepend(RailsCacheShim)
end

module IgnoreMonkeyPatchesInDeprecations
  def extract_callstack(callstack)
    return _extract_callstack(callstack) if !CANVAS_RAILS4_2 && callstack.first.is_a?(String)

    offending_line = callstack.find { |frame|
      # pass the whole frame to the filter function, so we can ignore specific methods
      !ignored_callstack(frame)
    } || callstack.first

    if CANVAS_RAILS4_2
      if offending_line
        if md = offending_line.match(/^(.+?):(\d+)(?::in `(.*?)')?/)
          md.captures
        else
          offending_line
        end
      end
    else
      [offending_line.path, offending_line.lineno, offending_line.label]
    end
  end

  def ignored_callstack(frame)
    if frame.is_a?(String)
        if md = frame.match(/^(.+?):(\d+)(?::in `(.*?)')?/)
          path, _, label = md.captures
        else
          return false
        end
    else
      path, _, label = frame.absolute_path, frame.lineno, frame.label
    end
    return true if path&.start_with?(File.dirname(__FILE__) + "/active_record.rb")
    return true if path&.start_with?(File.expand_path(File.dirname(__FILE__) + "/../../gems/activesupport-suspend_callbacks"))
    return true if path == File.expand_path(File.dirname(__FILE__) + "/../../spec/support/blank_slate_protection.rb")
    @switchman ||= File.expand_path('..', Gem.loaded_specs['switchman'].full_gem_path) + "/"
    return true if path&.start_with?(@switchman)
    return true if label == 'render' && path&.end_with?("application_controller.rb")
    return true if label == 'named_context_url' && path&.end_with?("application_controller.rb")
    return true if label == 'redirect_to' && path&.end_with?("application_controller.rb")

    return false unless path
    if CANVAS_RAILS4_2
      rails_gem_root = File.expand_path('..', Gem.loaded_specs['activesupport'].full_gem_path) + "/"
      path.start_with?(rails_gem_root)
    else
      puts ActiveSupport::Deprecation::Reporting::RAILS_GEM_ROOT
      super(path)
    end
  end
end
ActiveSupport::Deprecation.prepend(IgnoreMonkeyPatchesInDeprecations)
