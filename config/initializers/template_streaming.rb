module MarkTemplateStreaming
  def render_to_body(options={})
    @streaming_template = true if options[:stream]
    super
  end
end
ActionController::Base.include(MarkTemplateStreaming)

module StreamingViewExtensions
  # still have stuff like `provide :wizard_box` work in the handful of places we do it
  # but skip them for streaming templates (so we're not waiting for it)
  def self.prepended(klass)
    klass.send(:attr_reader, :skipped_keys)
  end

  # e.g. skip_for_streaming :wizard_box, except: "eportfolios/show"
  # will skip the block for all streaming template other than the eportfolios/show endpoint
  def skip_for_streaming(name, except: nil)
    if @streaming_template && !Array(except).include?("#{controller_name}/#{action_name}")
      @skipped_keys ||= []
      @skipped_keys << name
    else
      yield
    end
  end

  def provide(name, content = nil, &block)
    if block_given?
      content = capture(&block) || '' # still carry on even if the block doesn't return anything
      provide(name, content)
    else
      super
    end
  end

  # short-hand to provide blank content for multiple keys at once
  def provide_blank(*keys)
    keys.each do |key|
      provide(key, '')
    end
  end
end
ActionView::Base.prepend(StreamingViewExtensions)

module StreamingContentChecks
  # (for non-prod) force a check at the end of streaming templates to make sure we provide
  # content like `:page_title` (even if it's empty)
  # so we don't wait forever for it
  def append!(key, value)
    if @view.skipped_keys&.include?(key)
      raise "Streaming template tried to provide content for #{key.inspect} but it's currently being skipped -
        may need to render normally or add an exception to `skip_for_streaming`"
    end
    @provided_keys ||= [:wizard_box, :keyboard_navigation]
    @provided_keys << key
    super
  end

  def append(key, value)
    raise "Streaming template used `content_for` with #{key.inspect} instead of `provide`,
      which is preferred (`provide` unblocks the rendering)"
  end

  def get(key)
    val = super
    unless key == :layout || @provided_keys&.include?(key)
      raise "We tried to render this view with streaming but it got stuck waiting for content -
        add a `<% provide_blank #{key.inspect} %>` at the top of the template or consider using `skip_for_streaming`"
    end
    val
  end
end
ActionView::StreamingFlow.prepend(StreamingContentChecks) unless ::Rails.env.production?
