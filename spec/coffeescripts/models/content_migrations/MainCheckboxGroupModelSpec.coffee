define [
  'compiled/models/content_migrations/MainCheckboxGroupModel'
  'compiled/models/ProgressingContentMigration'
], (MainCheckboxGroupModel, ProgressingMigration) -> 
  module 'MainCheckboxGroupModelSpec',
    setup: -> 
      @modelData = 
                property: "copy[all_course_settings]"
                title: "Course Settings"
                type: "course_settings"

  test 'has progressingMigration child', ->
    model = new MainCheckboxGroupModel(migrationModel: new ProgressingMigration)
    ok model.hasOwnProperty('migrationModel'), "Has a migrationModel"

  test 'raises and error if migrationModel option is not a progressingMigration', -> 
    runModel = -> new MainCheckboxGroupModel(migrationModel: {notA: "progressingMigration"})
    throws runModel, "Throws an error when not given the correct migration"

    
