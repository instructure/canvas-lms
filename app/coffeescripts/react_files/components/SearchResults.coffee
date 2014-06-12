define [
  'jquery'
  'underscore'
  'react'
  '../mixins/BackboneMixin'
  'compiled/models/Folder'
  '../utils/withGlobalDom'
  'compiled/util/deparam'
  './ColumnHeaders'
  './LoadingIndicator'
  './FolderChild'
  '../mixins/SortableMixin'
], ($, _, React, BackboneMixin, Folder, withGlobalDom, deparam, ColumnHeaders, LoadingIndicator, FolderChild, SortableMixin) ->

  FolderChildren = React.createClass

    mixins: [BackboneMixin('collection'), SortableMixin],

    componentWillMount: ->
      @props.collection.loadAll = true #TODO: remove this and use scroll
      @props.collection.fetch(data: search_term: '.js')


    render: withGlobalDom ->
      div className:'ef-directory',
        ColumnHeaders(subject: @props.collection)
        @props.collection.models.sort(Folder::childrenSorter.bind(@props.collection)).map (child) =>
          FolderChild key:child.cid, model: child, baseUrl: @props.baseUrl
        LoadingIndicator isLoading: @props.collection.fetchingNextPage




