# frozen_string_literal: true

namespace :graphql do
  desc "Dump GraphQL schema and fragment types"
  task schema: :environment do
    Rails.root.join("schema.graphql").open("w") do |f|
      f.puts CanvasSchema.to_definition
    end

    Rails.root.join("ui/shared/apollo/fragmentTypes.json").open("w") do |f|
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
    end
  end

  namespace :subgraph do
    def load_config(require_keys:)
      config = Rails.application.credentials.subgraph_registry&.with_indifferent_access || {}
      abort "Canvas is not configured to publish its subgraph schema" if config.blank?

      require_keys.each do |config_key|
        abort "Config is missing #{config_key}" if config[config_key].blank?
      end
      config
    end

    desc "Publish the subgraph schema to the schema registry as configured by the given VARIANT_KEY"
    task publish: :environment do
      unless system("command -v rover &> /dev/null")
        abort "Requires `rover` CLI, see: https://www.apollographql.com/docs/rover/getting-started"
      end
      abort "VARIANT_KEY env var must be set" if ENV["VARIANT_KEY"].blank?

      variant_key = :"#{ENV["VARIANT_KEY"]}_variant"
      config = load_config(require_keys: [variant_key, :graph_name, :registry_key])

      graph_ref = "#{config[:graph_name]}@#{config[variant_key]}"
      cmd = "APOLLO_KEY=#{config[:registry_key]} rover subgraph publish #{graph_ref} --client-timeout 60 --name canvas --schema -"

      Tempfile.create("subgraph_schema") do |schema|
        schema.write(CanvasSchema.for_federation.federation_sdl)
        # use `spawn` so stdout and stderr of the child process get attached to
        # this process, i.e. the caller sees all the output from the cmd
        Process.wait(spawn(cmd, in: schema.path))
      end
      exit($?.exitstatus)
    end
  end
end
