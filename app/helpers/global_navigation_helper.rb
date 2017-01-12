module GlobalNavigationHelper
  # When k12 flag is on, replaces global navigation icon with a different one
  def svg_icon(icon)
    base = k12? ? 'k12/' : ''
    begin
      render_icon_partial(base, icon)
    rescue ActionView::MissingTemplate => e
      logger.warn "Global nav icon does not exist: #{e}"
      render_icon_partial('', icon) rescue nil # worst case we don't render anything
    end
  end

  private

  def render_icon_partial(base, icon)
    render "shared/svg/#{base}svg_icon_#{icon}.svg"
  end
end
