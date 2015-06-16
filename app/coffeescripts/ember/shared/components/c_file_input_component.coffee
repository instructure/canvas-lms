define [
  'ember'
  '../register'
], (Ember, register) ->

  register 'component', 'c-file-input', Ember.TextField.extend

    type: 'file'

    setFiles: ((event)->
      @set('files', [].slice.call(event.target.files, 0))
    ).on('change')

