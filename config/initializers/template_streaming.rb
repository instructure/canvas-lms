module StreamingViewExtensions

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
