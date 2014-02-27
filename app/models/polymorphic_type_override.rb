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

      @@polymorphic_type_mappings[self.name].each_with_mapping do |overridden, old_class, new_class|
        # define attr_reader for mapping[:type] e.g., ContentTag#content_type
        define_method overridden do
          if self.instance_variable_get(:@attributes)[overridden.to_s] == old_class
            return new_class
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

    # override .shard_category_code_for_reflection here
    def shard_category_code_for_reflection(reflection)
      mapper = @@polymorphic_type_mappings[self.name]

      if mapper && reflection && reflection.options && reflection.options[:foreign_type]
        if mapper.overrides?(reflection.options[:foreign_type])
          const_hash = mapper.constants_mapping(reflection.options[:foreign_type])
          return "#{const_hash}[self[:#{reflection.options[:foreign_type]}]].try(:constantize).try(:shard_category) || :default"
        end
      end
      super reflection
    end

    private

    class OverrideMapper
      attr_reader :mappings

      def initialize(mappings)
        @mappings = mappings.symbolize_keys
      end

      def overrides?(type)
        mappings.key?(type.to_sym)
      end

      def constants_mapping(type)
        mappings[type.to_sym]
      end

      def override_from_attributes(attr, attributes)
        mapping = mappings[attr.to_sym]
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
          mapping.each do |original_class, new_class|
            yield attr, original_class, new_class
          end
        end

      end
    end

  end
end
