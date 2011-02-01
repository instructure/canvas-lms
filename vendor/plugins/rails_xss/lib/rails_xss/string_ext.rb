require 'active_support/deprecation'

ActiveSupport::SafeBuffer.class_eval do
  def concat(value)
    if value.html_safe?
      super(value)
    else
      super(ERB::Util.h(value))
    end
  end
  alias << concat
end

class String
  def html_safe?
    defined?(@_rails_html_safe)
  end

  def html_safe!
    ActiveSupport::Deprecation.warn("Use html_safe with your strings instead of html_safe! See http://yehudakatz.com/2010/02/01/safebuffers-and-rails-3-0/ for the full story.", caller)
    @_rails_html_safe = true
    self
  end

  def add_with_safety(other)
    result = add_without_safety(other)
    if html_safe? && also_html_safe?(other)
      result.html_safe!
    else
      result
    end
  end
  alias_method :add_without_safety, :+
  alias_method :+, :add_with_safety

  def concat_with_safety(other_or_fixnum)
    result = concat_without_safety(other_or_fixnum)
    unless html_safe? && also_html_safe?(other_or_fixnum)
      remove_instance_variable(:@_rails_html_safe) if defined?(@_rails_html_safe)
    end
    result
  end

  alias_method_chain :concat, :safety
  undef_method :<<
  alias_method :<<, :concat_with_safety

  private
    def also_html_safe?(other)
      other.respond_to?(:html_safe?) && other.html_safe?
    end
end
