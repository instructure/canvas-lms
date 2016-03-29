require_dependency 'importers'

module Importers
  class AccountContentImporter < Importer

    self.item_class = Account
    Importers.register_content_importer(self)

    def self.import_content(account, data, params, migration)
      Importers::ContentImporterHelper.add_assessment_id_prepend(account, data, migration)

      Importers::AssessmentQuestionImporter.process_migration(data, migration)
      Importers::LearningOutcomeImporter.process_migration(data, migration)

      migration.resolve_content_links!

      migration.progress = 100
      migration.workflow_state = :imported
      migration.save
    end
  end
end