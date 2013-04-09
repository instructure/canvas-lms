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

  test 'adds errors', 6, ->
    @view.addError(@view.$('input').first(), 'Wrong!')
    equal $('.help-inline').size(), 1
    equal $('.error').size(), 1
    ok $(".help-inline:contains('Wrong!')").is ':visible'
    @view.addError(@view.$('input').last(), 'Also Wrong...')
    equal $('.help-inline').size(), 2
    equal $('.error').size(), 2
    ok $(".help-inline:contains('Also Wrong...')").is ':visible'

  test 'removes all errors', 2, ->
    @view.addError(@view.$('input').first(), 'Wrong!')
    @view.addError(@view.$('input').last(), 'Also Wrong...')
    equal $('.help-inline').size(), 2
    @view.removeErrors()
    equal $('.help-inline').size(), 0