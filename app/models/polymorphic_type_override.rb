module PolymorphicTypeOverride
  def self.included(base)
    base.extend PolymorphicTypeOverride::ClassMethods
  end

  module ClassMethods
    def override_polymorphic_types(polymorphic_type_mappings)
      # Rails likes to use both read_attribute and the cached attr_reader for attributes
      # We have to re-define both to completely override the stored constant.
      @@polymorphic_type_mappings ||= {}
      @@polymorphic_type_mappings[self.name] = OverrideMapper.new(polymorphic_type_mappings)

      @@polymorphic_type_mappings[self.name].each_with_mapping do |overridden, mapping|
        # define attr_reader for mapping[:type] e.g., ContentTag#content_type
        define_method overridden do
          current_type = self.instance_variable_get(:@attributes)[overridden.to_s]

          if mapping.keys.include? current_type
            return mapping[current_type]
          end

          super()
        end
      end

      # define read_attribute
      define_method :read_attribute do |attr|
        mapper = @@polymorphic_type_mappings[self.class.name]
        if mapper.overrides?(attr)
          overriding = mapper.override_from_attributes(attr, self.instance_variable_get(:@attributes))
          return overriding if overriding
        end

        super attr
      end
    end

    private

    class OverrideMapper
      attr_reader :mappings

      def initialize(mappings)
        @mappings = mappings.with_indifferent_access
      end

      def overrides?(type)
        mappings.key?(type)
      end

      def constants_mapping(type)
        mappings[type]
      end

      def override_from_attributes(attr, attributes)
        mapping = mappings[attr]
        attr = attr.to_s

        mapping.each do |original_class, new_class|
          if attributes[attr] == original_class
            return new_class
          end
        end

        false
      end

      def each_with_mapping
        mappings.each do |attr, mapping|
          yield attr, mapping
        end

      end
    end

  end
end
