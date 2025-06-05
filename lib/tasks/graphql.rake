# frozen_string_literal: true

namespace :graphql do
  desc "Dump GraphQL schema and fragment types"
  task schema: :environment do
    Rails.root.join("schema.graphql").write(CanvasSchema.to_definition)

    possible_types_map = CanvasSchema.possible_types.select { |k, _| k.kind.abstract? }
                                     .transform_keys(&:graphql_name)
                                     .transform_values { |x| x.map(&:graphql_name).sort }
                                     .sort_by { |k, _| k }.to_h

    Rails.root.join("ui/shared/apollo-v3/possibleTypes.json").write(JSON.pretty_generate(possible_types_map))
  end
end
