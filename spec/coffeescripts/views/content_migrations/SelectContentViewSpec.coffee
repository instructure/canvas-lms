define [
  'Backbone'
  'compiled/views/content_migrations/SelectContentView'
  'compiled/models/ProgressingContentMigration'
], (Backbone, SelectContentView, ProgressingMigration) -> 

  module 'SelectContentView: Main Behaviors',
    setup: -> 
      @$fixtures = $('#fixtures')
      @model = new ProgressingMigration
                  id: 5
                  course_id: 42

      @selectContentView = new SelectContentView 
                              model: @model
                              title: 'Select Content'
                              width: 600
                              height: 400
                              fixDialogButtons: false

      @server = sinon.fakeServer.create()
      @$fixtures.append @selectContentView.$el

    teardown: -> 
      @server.restore()
      @selectContentView.remove()

  test 'render top level checkboxes when opened', -> 
    @server.respondWith('GET', 
                        '/api/v1/courses/42/content_migrations/5/selective_data', 
                         [200, { "Content-Type": "application/json" }, JSON.stringify([
                              {
                                  "type": "course_settings",
                                  "property": "copy[all_course_settings]",
                                  "title": "Course Settings"
                              },
                              {
                                  "type": "syllabus_body",
                                  "property": "copy[all_syllabus_body]",
                                  "title": "Syllabus Body"
                              }
                          ])]
    )
    @selectContentView.open()
    @server.respond()

    $checkboxes = @selectContentView.$el.find('[type=checkbox]')
    equal $checkboxes.length, 2, "Renders all checkboxes"
