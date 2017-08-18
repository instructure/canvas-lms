module Types
  StudentSummaryAnalyticsType = GraphQL::ObjectType.define do
    name "StudentSummaryAnalytics"
    description "basic information about a students activity in a course"

    field :pageViews, PageViewAnalysisType, property: :page_views
    field :participations, PageViewAnalysisType, property: :participations
    field :tardinessBreakdown, TardinessBreakdownType, property: :tardiness_breakdown
  end

  PageViewAnalysisType = GraphQL::ObjectType.define do
    name "PageViewAnalysis"

    field :total, types.Int do
      description "The number of views/participations this student has"
      hash_key :total
    end

    field :max, types.Int do
      description "The maximum number of views/participations in this course"
      hash_key :max
    end

    field :level, types.Int do
      description "This number (0-3) is intended to give an idea of how the student is doing relative to others in the course"
      hash_key :level
    end
  end

  TardinessBreakdownType = GraphQL::ObjectType.define do
    name "TardinessBreakdown"
    description "statistics based on timeliness of student submissions"

    field :total, types.Int, hash_key: :total
    field :late, types.Float, hash_key: :late
    field :missing, types.Float, hash_key: :missing
    field :onTime, types.Float, hash_key: :on_time
  end
end
