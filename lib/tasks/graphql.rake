dependent_files = []
dependent_files += Dir.glob "app/graphql/types/**/*.rb"
dependent_files += Dir.glob "gems/plugins/*/app/graphql/types/**/*.rb"
dependent_files += Dir.glob "gems/plugins/*/lib/*/extensions/graphql/**/*.rb"

file "app/jsx/fragmentTypes.json" => dependent_files do
  Rake::Task['graphql:schema'].invoke
  Rake::Task['graphql:schema'].reenable
end

namespace :graphql do
  desc "Dump GraphQL schema and fragment types"
  task schema: :environment do
    GraphQLPostgresTimeout.do_not_wrap = true

    File.atomic_write("#{Rails.root}/schema.graphql") do |f|
      f.write CanvasSchema.to_definition
    end

    File.atomic_write("#{Rails.root}/app/jsx/fragmentTypes.json") do |f|
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
      f.write JSON.pretty_generate(types["data"])
    end
  end
end
