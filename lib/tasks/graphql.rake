namespace :graphql do
  desc "Generate schema"
  task schema: :environment do
    File.open("#{Rails.root}/schema.graphql", "w") { |f|
      f.puts CanvasSchema.to_definition
    }
  end
end
