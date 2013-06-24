define [
  'compiled/views/content_migrations/SelectContentView'
  'compiled/models/ProgressingContentMigration'
], (SelectContentView, ProgressingMigration) -> 
  module 'SelectContentViewSpec',
    setup: -> 
      @model = new ProgressingMigration
                  id: 5
                  course_id: 42

      @selectContentView = new SelectContentView 
                              model: @model
                              el: $('#fixtures')
                              title: 'Select Content'
                              width: 600
                              height: 400

    teardown: -> @selectContentView.remove()

  #test 'Renders main checkbox groups after open', -> 
    #@selectContentView.open()
    ## Todo: * Create sinon server to return a list of main checkboxes
    #ok 1, 'test should pass'

  #test 'Only send checkbox values that have been checked on submit', -> 
  # Todo: Test that params are being filtered out if they are set to false
