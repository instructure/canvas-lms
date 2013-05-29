define [
  'compiled/views/content_migrations/MainCheckboxGroupView'
  'compiled/models/content_migrations/MainCheckboxGroupModel'
  'compiled/models/ProgressingContentMigration'
], (MainCheckboxGroupView, MainCheckboxGroupModel, ProgressingMigration) -> 
  module 'MainCheckboxGroupViewSpec',
    setup: -> 
      @model = new MainCheckboxGroupModel
                  property: "copy[all_course_settings]"
                  title: "Course Settings"
                  type: "course_settings"
                  migrationModel: new ProgressingMigration
                                    course_id: 5
                                    id: 42

      @view = new MainCheckboxGroupView model: @model

      $('#fixtures').html @view.render().el

    teardown: -> @view.remove()

  test 'renders a checkbox with a CheckboxGroupModels title as a label', -> 
    equal @view.$el.find('[data-bind="title"]').text(), @model.get('title'), "Renders title as checkbox label"
    equal @view.$el.find('[type="checkbox"]').length, 1, "Renders a checkbox"

  test 'clicking checkbox set model property from checkbox name', -> 
    @view.$el.find('[type="checkbox"]').click()
    ok @model.migrationModel.deepGet("copy.all_course_settings"), "all_course_settings is true"
