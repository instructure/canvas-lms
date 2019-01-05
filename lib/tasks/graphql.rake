namespace :graphql do
  desc "Dump GraphQL schema and fragment types"
  task schema: :environment do
    File.open("#{Rails.root}/schema.graphql", "w") { |f|
      f.puts CanvasSchema.to_definition
    }

    File.open("#{Rails.root}/app/jsx/fragmentTypes.json", "w") { |f|
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
      f.puts JSON.pretty_generate(types["data"])
    }
  end
end
