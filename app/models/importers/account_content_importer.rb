module Importers
  class AccountContentImporter < Importer

    self.item_class = Account

    def self.import_content(account, data, params, migration)
      Importers::LearningOutcomeImporter.process_migration(data, migration)

      migration.progress = 100
      migration.workflow_state = :imported
      migration.save
    end
  end
end