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

  create: ->
    window.ENV =
      {
        submission_zip_url: '/courses/1/assignments/1/submissions?zip=1'
      }

    ajax.defineFixture window.ENV.submission_zip_url,
      response: clone data
      jqXHR: { getResponseHeader: -> {} }
      textStatus: ''

  makeAvailable: ->
    data.attachment.file_state = 100
    data.attachment.workflow_state = 'available'
