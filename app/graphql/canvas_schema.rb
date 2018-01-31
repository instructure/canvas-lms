CanvasSchema = GraphQL::Schema.define do
  query(Types::QueryType)
  mutation(Types::MutationType)

  use GraphQL::Batch

  id_from_object ->(obj, type_def, _) {
    GraphQL::Schema::UniqueWithinType.encode(type_def.name, obj.id)
  }

  object_from_id ->(relay_id, ctx) {
    type, id = GraphQL::Schema::UniqueWithinType.decode(relay_id)

    GraphQLNodeLoader.load(type, id, ctx)
  }

  resolve_type ->(_type, obj, ctx) {
    case obj
    when Course then Types::CourseType
    when Assignment then Types::AssignmentType
    when CourseSection then Types::SectionType
    when User then Types::UserType
    when Enrollment then Types::EnrollmentType
    when GradingPeriod then Types::GradingPeriodType
    end
  }

  instrument :field, AssignmentOverrideInstrumenter.new
end
