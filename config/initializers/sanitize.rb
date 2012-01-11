require 'sanitize'
class Sanitize
  # modified from sanitize.rb to support mid-value matching
  REGEX_STYLE_PROTOCOL = /([A-Za-z0-9\+\-\.\&\;\#\s]*?)(?:\:|&#0*58|&#x0*3a)/i
  REGEX_STYLE_METHOD = /([A-Za-z0-9\+\-\.\&\;\#\s]*?)(?:\(|&#0*40|&#x0*28)/i
  
  alias :original_clean_element! :clean_element!
  def clean_element!(node)
    res = original_clean_element!(node)
    if node['style']
      styles = []
      style = node['style']
      # taken from https://github.com/flavorjones/loofah/blob/master/lib/loofah/html5/scrub.rb
      # the gauntlet
      style = '' unless style =~ /\A([:,\;#%.\(\)\/\sa-zA-Z0-9!]|\w-\w|\'[\s\w]+\'|\"[\s\w]+\"|\([\d,\s]+\))*\z/
      style = '' unless style =~ /\A\s*([-\w]+\s*:[^\;]*(\;\s*|$))*\z/
      
      style.scan(/([-\w]+)\s*:\s*([^;]*)/) do |property, value|
        property = property.downcase
        valid = (@config[:style_properties] || []).include?(property)
        valid ||= (@config[:style_expressions] || []).any?{|e| property.match(e) }
        if valid
          styles << [property, clean_style_value(value)]
        end
      end
      node['style'] = styles.select { |k,v| v }.map{|k,v| "#{k}: #{v}"}.join('; ') + ";"
    end
    res
  end
  
  def clean_style_value(value)
    # checks for any colons anywhere in the string
    # to make sure they're preceded by a valid protocol
    protocols = @config[:protocols]['style']['any']
    
    # no idea what these are called in css, but it's
    # a name followed by open-paren 
    # (i.e. url(...) or expression(...))
    methods = @config[:style_methods]
    
    if methods
      value.to_s.downcase.scan(REGEX_STYLE_METHOD) do |match|
        return nil if !methods.include?(match[0].downcase)
      end
    end
    if protocols
      value.to_s.downcase.scan(REGEX_STYLE_PROTOCOL) do |match|
        return nil if !protocols.include?(match[0].downcase)
      end
    end
    value
  end
end
