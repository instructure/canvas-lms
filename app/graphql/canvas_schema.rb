CanvasSchema = GraphQL::Schema.define do
  query(Types::QueryType)
  mutation(Types::MutationType)

  # GraphQL::Batch setup:
  lazy_resolve(Promise, :sync)
  instrument(:query, GraphQL::Batch::Setup)

  id_from_object ->(obj, type_def, _) {
    GraphQL::Schema::UniqueWithinType.encode(type_def.name, obj.id)
  }

  object_from_id ->(relay_id, ctx) {
    type, id = GraphQL::Schema::UniqueWithinType.decode(relay_id)

    GqlNodeLoader.load(type, id, ctx)
  }

  resolve_type ->(obj, ctx) {
    case obj
    when Course then Types::CourseType
    when Assignment then Types::AssignmentType
    else raise "I don't know how to resolve #{obj.inspect}"
    end
  }

  instrument :field, AssignmentOverrideInstrumenter.new
end
