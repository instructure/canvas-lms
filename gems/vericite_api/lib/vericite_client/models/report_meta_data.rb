=begin
VeriCiteV1
=end

require 'date'

module VeriCiteClient
  class ReportMetaData
    # Users First Name
    attr_accessor :user_first_name

    # Users Last Name
    attr_accessor :user_last_name

    # Users Email
    attr_accessor :user_email

    # User Role
    attr_accessor :user_role

    # Title of Assignment
    attr_accessor :assignment_title

    # Title of Context
    attr_accessor :context_title

    attr_accessor :external_content_data

    # Attribute mapping from ruby-style variable name to JSON key.
    def self.attribute_map
      {
        
        :'user_first_name' => :'userFirstName',
        
        :'user_last_name' => :'userLastName',
        
        :'user_email' => :'userEmail',
        
        :'user_role' => :'userRole',
        
        :'assignment_title' => :'assignmentTitle',
        
        :'context_title' => :'contextTitle',
        
        :'external_content_data' => :'externalContentData'
        
      }
    end

    # Attribute type mapping.
    def self.swagger_types
      {
        :'user_first_name' => :'String',
        :'user_last_name' => :'String',
        :'user_email' => :'String',
        :'user_role' => :'String',
        :'assignment_title' => :'String',
        :'context_title' => :'String',
        :'external_content_data' => :'Array<ExternalContentData>'
        
      }
    end

    def initialize(attributes = {})
      return unless attributes.is_a?(Hash)

      # convert string to symbol for hash key
      attributes = attributes.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

      
      if attributes[:'userFirstName']
        self.user_first_name = attributes[:'userFirstName']
      end
      
      if attributes[:'userLastName']
        self.user_last_name = attributes[:'userLastName']
      end
      
      if attributes[:'userEmail']
        self.user_email = attributes[:'userEmail']
      end
      
      if attributes[:'userRole']
        self.user_role = attributes[:'userRole']
      end
      
      if attributes[:'assignmentTitle']
        self.assignment_title = attributes[:'assignmentTitle']
      end
      
      if attributes[:'contextTitle']
        self.context_title = attributes[:'contextTitle']
      end
      
      if attributes[:'externalContentData']
        if (value = attributes[:'externalContentData']).is_a?(Array)
          self.external_content_data = value
        end
      end
      
    end

    # Check equality by comparing each attribute.
    def ==(o)
      return true if self.equal?(o)
      self.class == o.class &&
          user_first_name == o.user_first_name &&
          user_last_name == o.user_last_name &&
          user_email == o.user_email &&
          user_role == o.user_role &&
          assignment_title == o.assignment_title &&
          context_title == o.context_title &&
          external_content_data == o.external_content_data
    end

    # @see the `==` method
    def eql?(o)
      self == o
    end

    # Calculate hash code according to all attributes.
    def hash
      [user_first_name, user_last_name, user_email, user_role, assignment_title, context_title, external_content_data].hash
    end

    # build the object from hash
    def build_from_hash(attributes)
      return nil unless attributes.is_a?(Hash)
      self.class.swagger_types.each_pair do |key, type|
        if type =~ /^Array<(.*)>/i
          if attributes[self.class.attribute_map[key]].is_a?(Array)
            self.send("#{key}=", attributes[self.class.attribute_map[key]].map{ |v| _deserialize($1, v) } )
          else
            #TODO show warning in debug mode
          end
        elsif !attributes[self.class.attribute_map[key]].nil?
          self.send("#{key}=", _deserialize(type, attributes[self.class.attribute_map[key]]))
        else
          # data not found in attributes(hash), not an issue as the data can be optional
        end
      end

      self
    end

    def _deserialize(type, value)
      case type.to_sym
      when :DateTime
        DateTime.parse(value)
      when :Date
        Date.parse(value)
      when :String
        value.to_s
      when :Integer
        value.to_i
      when :Float
        value.to_f
      when :BOOLEAN
        if value.to_s =~ /^(true|t|yes|y|1)$/i
          true
        else
          false
        end
      when :Object
        # generic object (usually a Hash), return directly
        value
      when /\AArray<(?<inner_type>.+)>\z/
        inner_type = Regexp.last_match[:inner_type]
        value.map { |v| _deserialize(inner_type, v) }
      when /\AHash<(?<k_type>.+), (?<v_type>.+)>\z/
        k_type = Regexp.last_match[:k_type]
        v_type = Regexp.last_match[:v_type]
        {}.tap do |hash|
          value.each do |k, v|
            hash[_deserialize(k_type, k)] = _deserialize(v_type, v)
          end
        end
      else # model
        _model = VeriCiteClient.const_get(type).new
        _model.build_from_hash(value)
      end
    end

    def to_s
      to_hash.to_s
    end

    # to_body is an alias to to_body (backward compatibility))
    def to_body
      to_hash
    end

    # return the object in the form of hash
    def to_hash
      hash = {}
      self.class.attribute_map.each_pair do |attr, param|
        value = self.send(attr)
        next if value.nil?
        hash[param] = _to_hash(value)
      end
      hash
    end

    # Method to output non-array value in the form of hash
    # For object, use to_hash. Otherwise, just return the value
    def _to_hash(value)
      if value.is_a?(Array)
        value.compact.map{ |v| _to_hash(v) }
      elsif value.is_a?(Hash)
        {}.tap do |hash|
          value.each { |k, v| hash[k] = _to_hash(v) }
        end
      elsif value.respond_to? :to_hash
        value.to_hash
      else
        value
      end
    end

  end
end
