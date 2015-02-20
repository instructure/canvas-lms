define [
  'underscore'
  'compiled/models/Folder'
  'compiled/models/File'
  'compiled/models/ModuleFile'
], (_, Folder, File, ModuleFile) ->

  ###
  # Sets usage rights on the models in memory based on the response from the
  # API.
  #    apiData - the response from the API
  #    models - an array containing the files/folders to update
  ###
  updateModelsUsageRights = (apiData, models) ->
    # Grab the ids affected from the apiData
    affectedIds = apiData?.file_ids
    # Seperate the models array into a file group and a folder group.
    {files, folders} = _.groupBy models, (item) ->
      return 'files' if item instanceof File
      return 'files' if item instanceof ModuleFile
      return 'folders' if item instanceof Folder
    # We'll go ahead and update the files and remove the id from our list.
    if files
      files.map (file, index) ->
        id  = parseInt(file[file.idAttribute], 10)
        idx = affectedIds.indexOf(id)

        if id in affectedIds
          file.set
            usage_rights:
              legal_copyright: apiData?.legal_copyright
              license: apiData?.license
              use_justification: apiData?.use_justification
              own_copyright: apiData?.own_copyright
              license_name:apiData?.license_name

          affectedIds.splice(idx, 1)

    return if affectedIds.length == 0
    # Now that we have the files out of the way we can continue to the folders
    if folders
      for folder in folders
        # Combine the models from the files and folders collection
        combinedCollection = folder.files.models.concat(folder.folders.models)
        # The function expects us to give it apiData with file ids, so we
        # update it then give it back to the function recursively.
        apiData.file_ids = affectedIds
        updateModelsUsageRights apiData, combinedCollection
