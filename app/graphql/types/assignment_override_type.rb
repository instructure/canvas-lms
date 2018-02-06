module Types
  AssignmentOverrideType = GraphQL::ObjectType.define do
    name "AssignmentOverride"

    interfaces [Interfaces::TimestampInterface]

    field :_id, !types.ID, "legacy canvas id", property: :id

    field :assignment, AssignmentType, resolve: ->(override, _, _) {
      Loaders::AssociationLoader.for(AssignmentOverride, :assignment)
        .load(override)
        .then { override.assignment }
    }

    field :title, types.String

    field :set, AssignmentOverrideSetUnion do
      description "This object specifies what students this override applies to"

      resolve ->(override, _, _) {
        if override.set_type == "ADHOC"
          # AdhocStudentsType will load the actual students
          override
        else
          Loaders::AssociationLoader.for(AssignmentOverride, :set)
            .load(override)
            .then { override.set }
        end
      }
    end

    field :dueAt, TimeType, property: :due_at
    field :lockAt, TimeType, property: :lock_at
    field :unlockAt, TimeType, property: :unlock_at
    field :allDay, types.Boolean, property: :all_day
  end

  AssignmentOverrideSetUnion = GraphQL::UnionType.define do
    name "AssignmentOverrideSet"

    description "Objects that can be assigned overridden dates"

    possible_types [SectionType, GroupType, AdhocStudentsType]

    resolve_type ->(obj, _) {
      case obj
      when CourseSection then SectionType
      when Group then GroupType
      when AssignmentOverride then AdhocStudentsType
      end
    }
  end

  AdhocStudentsType = GraphQL::ObjectType.define do
    name "AdhocStudents"

    description "A list of students that an `AssignmentOverride` applies to"

    field :students, types[UserType], resolve: ->(override, _, _) {
      Loaders::AssociationLoader.for(AssignmentOverride,
                                     assignment_override_students: :user)
      .load(override)
      .then { override.assignment_override_students.map(&:user) }
    }

  end
end
