define [
  'ember'
  'compiled/str/splitAssetString'
], (Ember, splitAssetString) ->

  # hide the left nav when on small screen
  mq = window.matchMedia( "(max-width: 690px)" )
  toggleLeftSide = (mq) -> $('body').toggleClass('with-left-side', not mq.matches)
  mq.addListener(toggleLeftSide)
  toggleLeftSide(mq)


  FolderRoute = Ember.Route.extend

    serialize: (model, params) ->
      fullName = model.get('full_name').split('/')
      fullName.shift() # `full_name` includes the root folder (like 'course files' or 'group files'), we don't want that
      return { fullPath: 'folder/' + fullName.join('/')}

    # setupController: ->
      #do something to tell files controller what the current folder is

    beforeModel: (transition) ->
      if transition.params.folder.fullPath in ['folder/', 'folder']
        # TODO: this causes "Error while loading route: undefined" to log to the console, fix.
        @replaceWith('files')

    model: (params) ->
      realFullPath = decodeURIComponent(params.fullPath).replace(/^folder\//, '')
      [contextType, contextId] = splitAssetString ENV.context_asset_string

      # this will get the folder we want plus all parent folders
      @store.findQuery('folder', {fullName: realFullPath, contextId, contextType}).then (records) ->
        # the model for this route is just the folder we want, which will be the last in the array
        records.get('lastObject')
