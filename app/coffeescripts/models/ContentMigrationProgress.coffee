define [
  'compiled/models/Progress'
], (ProgressModel) -> 
  class ContentMigrationProgress extends ProgressModel
    defaults: 
      timeout: 5000
