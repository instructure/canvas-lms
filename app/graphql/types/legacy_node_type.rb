Types::LegacyNodeType = GraphQL::EnumType.define do
  name "NodeType"

  value "Assignment"
  value "Course"
  value "Section"
  value "User"
  value "Enrollment"
  value "GradingPeriod"

=begin
  # TODO: seems like we should be able to dynamically generate the types that
  # go here (but i'm getting a circular dep. error when i try)
    CanvasSchema.types.values.select { |t|
      t.respond_to?(:interfaces) && t.interfaces.include?(CanvasSchema.types["Node"])
    }.each { |t|
      value t
    }
=end
end
