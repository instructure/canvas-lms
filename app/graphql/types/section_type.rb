module Types
  SectionType = GraphQL::ObjectType.define do
    name "Section"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :name, !types.String
  end
end
