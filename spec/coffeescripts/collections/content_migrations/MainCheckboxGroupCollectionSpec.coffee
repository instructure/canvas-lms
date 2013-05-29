define [
  'Backbone'
  'compiled/collections/content_migrations/MainCheckboxGroupCollection'
  'compiled/models/content_migrations/MainCheckboxGroupModel'
  'compiled/models/ProgressingContentMigration'
  'compiled/models/ContentMigration'
], (Backbone, MainCheckboxGroupCollection, MainCheckboxGroupModel, ProgressingContentMigration, MigrationModel) -> 
  
  module 'MainCheckboxGroupCollectionSpec',
    setup: -> 
      @courseID = 15
      @migration = new MigrationModel id: 42
      @mainCheckboxGroupCollection = new MainCheckboxGroupCollection null,
                                     courseID: "15"
                                     migrationModel: @migration

  test 'contains MainCheckboxGroupModel\'s ', -> 
    model = @mainCheckboxGroupCollection.model 
    modelInstance = new model(migrationModel: new ProgressingContentMigration)

    ok modelInstance instanceof MainCheckboxGroupModel, "Collection contains instances of MainCheckboxGroupsModels"

  test 'has a courseID', -> 
    ok isFinite(Number(@mainCheckboxGroupCollection.courseID)), "Has a courseID number"

  test 'has a migrationModel', -> 
    ok @mainCheckboxGroupCollection.migrationModel instanceof MigrationModel, "Has a migration model"

  test 'endpoints set to the correct url', -> 
    endpointURL = "/api/v1/courses/#{@courseID}/content_migrations/#{@migration.id}/selective_data"
    equal @mainCheckboxGroupCollection.url(), endpointURL, "Endpoint url is correct"
