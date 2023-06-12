# frozen_string_literal: true

module MarkTemplateStreaming
  def render_to_body(options = {})
    @streaming_template = true if options[:stream]
    super
  end

  # credit to https://stackoverflow.com/questions/7986150/http-streaming-in-rails-not-working-when-using-rackdeflater/10596123#10596123
  def _process_options(options)
    stream = options.delete(:stream)
    super
    if stream && request.version != "HTTP/1.0"
      # Same as org implmenation except don't set the transfer-encoding header
      # The Rack::Chunked middleware will handle it
      headers["Cache-Control"] ||= "no-cache"
      headers["Last-Modified"] ||= Time.now.httpdate
      headers.delete("Content-Length")
      options[:stream] = stream
    end
  end

  def _render_template(options)
    if options.delete(:stream)
      # Just render, don't wrap in a Chunked::Body, let
      # Rack::Chunked middleware handle it
      view_renderer.render_body(view_context, options)
    else
      super
    end
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
    if block
      content = capture(&block) || "" # still carry on even if the block doesn't return anything
      provide(name, content)
    else
      super
    end
  end

  # short-hand to provide blank content for multiple keys at once
  def provide_blank(*keys)
    keys.each do |key|
      provide(key, "")
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

  def append(key, _value)
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
ActionView::StreamingFlow.prepend(StreamingContentChecks) unless Rails.env.production?

module SkipEmptyTemplateConcats
  def initialize(original_block)
    new_block = ->(value) { original_block.call(value) unless value.empty? }
    super(new_block)
  end
end
ActionView::StreamingBuffer.prepend(SkipEmptyTemplateConcats)

module ActivateShardsOnRender
  def render(view, *, **)
    if (active_shard = view.request&.env&.[]("canvas.active_shard"))
      active_shard.activate do
        super
      end
    else
      super
    end
  end
end
ActionView::Template.prepend(ActivateShardsOnRender)
