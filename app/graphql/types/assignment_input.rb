module Types
  AssignmentInput = GraphQL::InputObjectType.define do
    name "AssignmentInput"
    argument :name, !types.String
    argument :courseId, !types.ID
  end
end
