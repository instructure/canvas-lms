define [
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/models/content_migrations/ContentCheckbox'
], (CheckboxCollection, CheckboxModel) -> 
  module 'ContentCheckboxCollectionSpec'

  createCheckboxCollection = (properties) -> 
    properties ||= {}
    models = properties.models || new CheckboxModel(id: 42)
    options = properties.options || {migrationID: 1, courseID: 2}

    new CheckboxCollection models, options

  test 'url is going to the correct api endpoint', -> 
    courseID = 10
    migrationID = 20

    checkboxCollection = createCheckboxCollection 
      options: 
        migrationID: migrationID
        courseID: courseID

    endpointURL = "/api/v1/courses/#{courseID}/content_migrations/#{migrationID}/selective_data"
    equal checkboxCollection.url(), endpointURL, "Endpoint url is correct"

  test 'contains ContentCheckboxModel\'s ', -> 
    model = createCheckboxCollection().model 
    modelInstance = new model()

    ok modelInstance instanceof CheckboxModel, "Collection contains instances of ContentCheckboxModels"

  test 'has a courseID', -> 
    ok isFinite(Number(createCheckboxCollection(options: courseID: "23").courseID)), "Has a courseID number"

  test 'has a migrationID', -> 
    ok isFinite(Number(createCheckboxCollection(options: migrationID: "13").migrationID)), "Has a migrationID number"
