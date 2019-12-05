namespace :graphql do
  desc "Dump GraphQL schema and fragment types"
  task schema: :environment do
    GraphQLPostgresTimeout.do_not_wrap = true

    filter = ->(schema_member, ctx) do
      # We can't call visible? on interfaces here because of missing data in
      # the context. Instead, manually mark of an interface should be hidden
      # from the graphql.schema file by setting a flag in the metadata. See:
      # https://github.com/rmosolgo/graphql-ruby/blob/master/guides/schema/limiting_visibility.md
      if schema_member.is_a? GraphQL::InterfaceType
        return !schema_member.metadata[:hide_from_schema]
      end

      # Some type classes don't have a visible? method (such as Boolean), and
      # should always be in the schema
      type_class = schema_member.metadata[:type_class]
      return true unless type_class.respond_to?(:visible?)

      type_class.visible?(ctx)
    end

    File.open("#{Rails.root}/schema.graphql", "w") { |f|
      f.puts CanvasSchema.to_definition(only: filter)
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
