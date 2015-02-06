define [
  'jquery'
  'compiled/models/Folder'
  '../modules/filesEnv'
], ($, Folder, filesEnv) ->

  ####
  # Sets the usage rights for the given items.
  # - items should be an array of Files/Folders models
  # - usageRights should be an object of this form:
  #   {
  #      use_justification: fair_use, etc.
  #      legal_copyright: "(C) 2014 Instructure"
  #      license: creative_commons, etc.
  #   }
  #
  # - callback should be a function that handles what to do when complete
  #   It is called with these parameters (success, data)
  #     - success is a boolean indicating if the api call worked
  #     - data is the data returned from the api
  ####
  setUsageRights = (items, usageRights, callback) ->

    apiUrl = "/api/v1/#{filesEnv.contextType}/#{filesEnv.contextId}/usage_rights"
    folder_ids = []
    file_ids = []

    items.forEach (item) ->
      if (item instanceof Folder)
        folder_ids.push(item.get 'id')
      else
        file_ids.push(item.get 'id')

    $.ajax(
      url: apiUrl
      type: 'PUT'
      data: {
        folder_ids: folder_ids
        file_ids: file_ids
        usage_rights: usageRights
      },
      success: (data) ->
        callback(true, data)
      error: ->
        callback(false, data)
    )
