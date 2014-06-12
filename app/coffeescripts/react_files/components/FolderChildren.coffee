define [
  'jquery'
  'underscore'
  'react'
  '../mixins/BackboneMixin'
  '../utils/withGlobalDom'
  'compiled/util/deparam'
  './ColumnHeaders'
  './LoadingIndicator'
  './FolderChild'
  '../mixins/SortableMixin'
], ($, _, React, BackboneMixin, withGlobalDom, deparam, ColumnHeaders, LoadingIndicator, FolderChild, SortableMixin) ->

  FolderChildren = React.createClass

    mixins: [BackboneMixin('model'), SortableMixin],

    registerListeners: ->
      debouncedForceUpdate = _.debounce @forceUpdate.bind(this, null), 0
      @props.model.folders.on('all', debouncedForceUpdate, this)
      @props.model.files.on('all', debouncedForceUpdate, this)

    componentWillReceiveProps: ->
      @registerListeners()

    componentWillMount: ->
      @registerListeners()
      @props.model.loadAll()

    render: withGlobalDom ->
      div className:'ef-directory',
        ColumnHeaders(subject: @props.model)
        @props.model.children().map (child) =>
          FolderChild key:child.cid, model: child, baseUrl: @props.baseUrl
        LoadingIndicator isLoading: @props.model.folders.fetchingNextPage || @props.model.files.fetchingNextPage




