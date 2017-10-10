module Types
  GradingPeriodType = GraphQL::ObjectType.define do
    name "GradingPeriod"

    implements GraphQL::Relay::Node.interface
    interfaces [Interfaces::TimestampInterface]

    global_id_field :id
    field :_id, !types.ID, "legacy canvas id", property: :id

    field :title, types.String

    field :startDate, TimeType, property: :start_date
    field :endDate, TimeType, property: :end_date
    field :closeDate, TimeType, <<-DOC, property: :close_date
    assignments can only be graded before the grading period closes
    DOC

    field :weight, types.Float, <<-DOC
    used to calculate how much the assignments in this grading period
    contribute to the overall grade
    DOC
  end
end
