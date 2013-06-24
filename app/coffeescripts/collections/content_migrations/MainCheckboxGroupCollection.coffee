define [
  'Backbone'
  'compiled/models/content_migrations/MainCheckboxGroupModel'
], (Backbone, MainCheckboxGroupModel) -> 
  class MainCheckboxGroupCollection extends Backbone.Collection
    @optionProperty 'courseID'
    @optionProperty 'migrationModel'
    model: MainCheckboxGroupModel
    url: -> "/api/v1/courses/#{@courseID}/content_migrations/#{@migrationModel.id}/selective_data"
