define [
  'jquery'
  'compiled/views/ExternalTools/EditView'
], ($, EditView) ->

  module 'ExternalTools',
    setup: ->
      @view = new EditView()
      @view.render()

    teardown: ->
      @view.$el.dialog 'close'

  test 'EditView: adds errors', 6, ->
    @view.addError(@view.$('input').first(), 'Wrong!')
    equal $('.help-inline').size(), 1,
      'Inline help text appears'
    equal $('.error').size(), 1,
      'Missing required field appear with red borders'
    ok $(".help-inline:contains('Wrong!')").is ':visible'

    @view.addError(@view.$('input').last(), 'Also Wrong...')
    equal $('.help-inline').size(), 2,
      'Inline help text appears'
    equal $('.error').size(), 2,
      'Missing required field appear with red borders'
    ok $(".help-inline:contains('Also Wrong...')").is ':visible'

  test 'EditView: removes all errors', 2, ->
    @view.addError(@view.$('input').first(), 'Wrong!')
    @view.addError(@view.$('input').last(), 'Also Wrong...')
    equal $('.help-inline').size(), 2,
      'Two errors are displayed'
    @view.removeErrors()
    equal $('.help-inline').size(), 0,
      'Zero errors are displayed (after "removeErrors()")'