module PolymorphicTypeOverride
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def override_polymorphic_types(polymorphic_type_mappings)
      validate_classes!(polymorphic_type_mappings.map { |mapping| mapping[:to] })

      read_attribute_override = Proc.new do |instance, attr|
        matched = nil
        polymorphic_type_mappings.each do |mapping|
          original_class_name = mapping.fetch(:from)
          new_class_name = mapping.fetch(:to)
          attribute_to_override = "#{mapping.fetch(:type)}_type"

          if attr == attribute_to_override && instance.instance_variable_get(:@attributes)[attribute_to_override] == original_class_name
            matched = new_class_name
          end
        end
        matched
      end

      define_method :read_attribute do |attr|
        overriding = read_attribute_override.call(self, attr)
        return overriding if overriding
        super attr
      end
    end

    private

    def validate_classes!(klasses)
      klasses.map(&:constantize)
    end
  end
end