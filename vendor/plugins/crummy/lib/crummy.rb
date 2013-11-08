module Crummy
  module ControllerMethods
    module ClassMethods
      # Add a crumb to the crumbs array.
      #
      #   add_crumb("Home", "/")
      #   add_crumb("Business") { |instance| instance.business_path }
      #
      # Works like a before_filter so +:only+ and +except+ both work.
      def add_crumb(name, *args)
        options = args.extract_options!
        url = args.first
        # I wanted this next line to look more like:
        # html_options = options.pluck { |k,v| %w{class id}.include? k.to_s  }
        # but couldn't figure out how
        html_options = options[:class] ? {:class => options[:class]} : {} 
        html_options[:id] = options[:id] if options[:id]
        raise ArgumentError, "Need more arguments" unless name or options[:record] or block_given?
        raise ArgumentError, "Cannot pass url and use block" if url && block_given?
        before_filter(options) do |instance|
          url_value = url
          url_value = yield instance if block_given?
          url_value = instance.send url_value if url_value.is_a? Symbol
          name_value = name
          name_value = instance.instance_eval(&name_value) if name_value.is_a? Proc
          name_value = instance.instance_variable_get("@#{name_value}") if name_value.is_a? Symbol
          record = instance.instance_variable_get("@#{name_value}") unless url_value or block_given?
          if record and record.respond_to? :to_param
            name_value, url_value = record.to_s, instance.url_for(record)
          end
        
          # FIXME: url_value = instance.url_for(name_value) if name_value.respond_to?("to_param") && url_value.nil?
          # FIXME: Add ||= for the name_value, url_value above
          instance.add_crumb(name_value, url_value, html_options)
        end
      end
    end

    module InstanceMethods
      # Add a crumb to the crumbs array.
      #
      #   add_crumb("Home", "/")
      #   add_crumb("Business") { |instance| instance.business_path }
      #
      def add_crumb(name, url=nil, options = {})
        crumbs.push [name, url, options]
      end
      
      def clear_crumbs
        crumbs.clear
      end

      # Lists the crumbs as an array
      def crumbs
        get_or_set_ivar "@_crumbs", []
      end

      def get_or_set_ivar(var, value) # :nodoc:
        instance_variable_set var, instance_variable_get(var) || value
      end
      private :get_or_set_ivar
    end

    def self.included(receiver) # :nodoc:
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
  
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
        if CANVAS_RAILS2
          content_tag_without_nil_return(:nav, :id => "breadcrumbs", :role => "navigation", 'aria-label' => 'breadcrumbs') do
            content_tag_without_nil_return(:ul, nil, nil, false) do
              crumbs.collect do |crumb|
                content_tag(:li, crumb_to_html(crumb), crumb[2])
              end.join
            end
          end
        else
          content_tag(:nav, :id => "breadcrumbs", :role => "navigation", 'aria-label' => 'breadcrumbs') do
            content_tag(:ul, nil, nil, false) do
              crumbs.collect do |crumb|
                content_tag(:li, crumb_to_html(crumb), crumb[2])
              end.join
            end
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
