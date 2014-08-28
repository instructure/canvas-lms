module CanvasCrummy
  module ViewMethods
    # List the crumbs as an array
    def crumbs
      @_crumbs ||= [] # Give me something to push to
    end

    # Add a crumb to the +crumbs+ array
    def add_crumb(name, url=nil, options = {})
      crumbs.push [name, url, options]
    end

    # Render the list of crumbs
    def render_crumbs(options = {})
      if crumbs.length > 1
        content_tag(:nav, :id => "breadcrumbs", :role => "navigation", 'aria-label' => 'breadcrumbs') do
          content_tag(:ul, nil, nil, false) do
            crumbs.collect do |crumb|
              content_tag(:li, crumb_to_html(crumb), crumb[2])
            end.join.html_safe
          end
        end
      end
    end

    def crumb_to_html(crumb)
      name, url = crumb
      span = content_tag(:span, name, :class => 'ellipsible')
      url ? link_to(span, url) : span
    end

  end
end