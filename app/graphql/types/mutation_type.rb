module Types
  MutationType = GraphQL::ObjectType.define do
    name "Mutation"

    field :createAssignment, AssignmentType do
      argument :assignment, !AssignmentInput

      resolve -> (_, args, ctx) do
        CanvasSchema.object_from_id(args[:assignment][:courseId], ctx).then do |course|
          # NOTE: i guess i have to type check here since i'm using global ids?
          if course && course.is_a?(Course)
            assignment = course.assignments.new name: args[:assignment][:name]
            if assignment.grants_right? ctx[:current_user], ctx[:session], :create
              assignment.save!
            end
          end
          assignment
        end
      end
    end
  end
end
