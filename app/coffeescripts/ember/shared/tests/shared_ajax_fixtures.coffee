define [
  'ic-ajax'
  'ember'
], (ajax, Ember) ->

  clone = (obj) ->
    Ember.copy obj, true

  data = {
    attachment:
      file_state: '0'
      workflow_state: 'to_be_zipped'
      readable_size: '73 KB'
  }

  numbers = [1, 2, 3]

  create: ->
    window.ENV =
      {
        submission_zip_url: '/courses/1/assignments/1/submissions?zip=1'
        numbers_url: '/courses/1/numbers'
      }

    ajax.defineFixture window.ENV.submission_zip_url,
      response: clone data
      jqXHR: { getResponseHeader: -> {} }
      textStatus: 'success'

    ajax.defineFixture window.ENV.numbers_url,
      response: clone numbers
      jqXHR: { getResponseHeader: -> {} }
      textStatus: 'success'

  makeAvailable: ->
    data.attachment.file_state = 100
    data.attachment.workflow_state = 'available'
