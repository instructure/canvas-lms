define [
  'jquery'
  'wikiSidebar'
  'compiled/models/WikiPage'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/wiki/WikiPageEditView'
  'compiled/views/wiki/WikiPageIndexItemView'
  'jst/wiki/WikiPageIndex'
  'compiled/views/StickyHeaderMixin'
  'compiled/str/splitAssetString'
  'jquery.disableWhileLoading'
], ($, wikiSidebar, WikiPage, PaginatedCollectionView, WikiPageEditView, itemView, template, StickyHeaderMixin, splitAssetString) ->

  class WikiPageIndexView extends PaginatedCollectionView
    @mixin StickyHeaderMixin
    @mixin
      template: template
      itemView: itemView

      events:
        'click .new_page': 'createNewPage'
        'click .canvas-sortable-header-row a[data-sort-field]': 'sort'

      els:
        '.no-pages': '$noPages'
        '.no-pages a:first-child': '$noPagesLink'

    @optionProperty 'default_editing_roles'
    @optionProperty 'WIKI_RIGHTS'

    initialize: (options) ->
      super
      @sortOrders =
        title: 'asc'
        created_at: 'desc'
        updated_at: 'desc'

      # Next sort order to use when column is clicked
      @nextSortOrders =
        title: 'desc'
        created_at: 'desc'
        updated_at: 'desc'

      @itemViewOptions ||= {}
      @itemViewOptions.WIKI_RIGHTS = @WIKI_RIGHTS

      @contextAssetString = options?.contextAssetString
      [@contextName, @contextId] = splitAssetString(@contextAssetString) if @contextAssetString
      @itemViewOptions.contextName = @contextName

    afterRender: ->
      super
      @$noPages.redirectClickTo(@$noPagesLink)

    sort: (event) ->
      currentTarget = $(event.currentTarget)
      currentSortField = @collection.options.params?.sort or "title"
      newSortField = $(event.currentTarget).data 'sort-field'

      if currentSortField is newSortField
        @sortOrders[newSortField] = if @sortOrders[newSortField] is 'asc' then 'desc' else 'asc'
        @nextSortOrders[newSortField] = if @sortOrders[newSortField] is 'asc' then 'desc' else 'asc'
        currentTarget.data 'sort-order',@sortOrders[newSortField]

      @collection.setParam 'sort',newSortField
      @collection.setParam 'order',@sortOrders[newSortField]
      @$el.disableWhileLoading @collection.fetch().then ->
        $('.canvas-sortable-header-row a[data-sort-field="' + newSortField + '"]').focus()

    createNewPage: (ev) ->
      ev?.preventDefault()

      @$el.hide()
      $('body').removeClass('index')
      $('body').addClass('edit')

      @editModel = new WikiPage {editing_roles: @default_editing_roles}, contextAssetString: @contextAssetString
      @editView = new WikiPageEditView
        model: @editModel
        wiki_pages_path: ENV.WIKI_PAGES_PATH
        WIKI_RIGHTS: ENV.WIKI_RIGHTS
        PAGE_RIGHTS:
          update: ENV.WIKI_RIGHTS.update_page
          update_content: ENV.WIKI_RIGHTS.update_page_content
      @$el.parent().append(@editView.$el)

      @editView.render()

      # override the cancel behavior
      @editView.on 'cancel', =>
        @editView.$el.remove()
        wikiSidebar.hide()

        $('body').removeClass('edit')
        $('body').addClass('index')
        @$el.show()

    toJSON: ->
      json = super
      json.WIKI_RIGHTS = @WIKI_RIGHTS
      json.contextName = @contextName
      json.fetched = @fetched
      json.sortField = @collection.options.params?.sort or "title"
      json.sortOrders = @sortOrders
      json.nextSortOrders = @nextSortOrders
      json
