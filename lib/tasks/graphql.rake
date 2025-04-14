# frozen_string_literal: true

namespace :graphql do
  desc "Dump GraphQL schema and fragment types"
  task schema: :environment do
    Rails.root.join("schema.graphql").open("w") do |f|
      # The front-end library in use doesn't support @specifiedBy until v15.1.0 - remove it for now
      # and match the behaviour of the previous schema dump
      f.puts CanvasSchema.to_definition
    end

    types = CanvasSchema.execute(<<~GQL)
      {
        __schema {
          types {
            kind
            name
            possibleTypes {
              name
            }
          }
        }
      }
    GQL
    types["data"]["__schema"]["types"].reject! { |t| t["possibleTypes"].nil? }

    Rails.root.join("ui/shared/apollo-v3/possibleTypes.json").open("w") do |f|
      possible_types = {}

      types["data"]["__schema"]["types"].each do |type|
        possible_types[type["name"]] = type["possibleTypes"].pluck("name")
      end

      f.puts JSON.pretty_generate(possible_types)
    end
  end
end
