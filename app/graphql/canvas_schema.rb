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

    check_read_permission = ->(o) {
      o.grants_right?(ctx[:current_user], ctx[:session], :read) ? o : nil
    }

    case type
    when "Course"
      Loaders::IDLoader.for(Course).load(id).then(check_read_permission)
    when "Assignment"
      Loaders::IDLoader.for(Assignment).load(id).then(check_read_permission)
    end
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
