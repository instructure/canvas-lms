define [
  'jquery'
  'i18n!pages'
  'wikiSidebar'
  'compiled/models/WikiPage'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/wiki/WikiPageEditView'
  'compiled/views/wiki/WikiPageIndexItemView'
  'jst/wiki/WikiPageIndex'
  'compiled/views/StickyHeaderMixin'
  'compiled/str/splitAssetString'
  'jquery.disableWhileLoading'
], ($, I18n, wikiSidebar, WikiPage, PaginatedCollectionView, WikiPageEditView, itemView, template, StickyHeaderMixin, splitAssetString) ->

  class WikiPageIndexView extends PaginatedCollectionView
    @mixin StickyHeaderMixin
    @mixin
      events:
        'click .new_page': 'createNewPage'
        'keyclick .new_page': 'createNewPage'
        'click .header-row a[data-sort-field]': 'sort'

      els:
        '.no-pages': '$noPages'
        '.no-pages a:first-child': '$noPagesLink'
        '.header-row a[data-sort-field]': '$sortHeaders'

    template: template
    itemView: itemView

    @optionProperty 'default_editing_roles'
    @optionProperty 'WIKI_RIGHTS'

    @lastFocusField: null

    initialize: (options) ->
      super
      @WIKI_RIGHTS ||= {}

      @itemViewOptions ||= {}
      @itemViewOptions.indexView = @
      @itemViewOptions.collection = @collection
      @itemViewOptions.WIKI_RIGHTS = @WIKI_RIGHTS
      @focusAfterRenderSelector = null

      @contextAssetString = options?.contextAssetString
      [@contextName, @contextId] = splitAssetString(@contextAssetString) if @contextAssetString
      @itemViewOptions.contextName = @contextName

      @collection.on 'fetch', =>
        unless @fetched
          @fetched = true
          @render()
      @collection.on 'fetched:last', =>
        @fetchedLast = true
        @render()

      @collection.on 'sortChanged', @sortChanged
      @currentSortField = @collection.currentSortField

    afterRender: ->
      super
      @$noPages.redirectClickTo(@$noPagesLink)
      @renderSortHeaders()
      if @focusAfterRenderSelector
        # We do a setTimeout here just to force it to the next tick.
        setTimeout =>
          $(@focusAfterRenderSelector).focus()
        , 1

    sort: (event = {}) ->
      event.preventDefault()
      @lastFocusField = sortField = $(event.currentTarget).data('sort-field')
      sortOrder = @collection.sortOrders[sortField] unless @currentSortField
      @$el.disableWhileLoading @collection.sortByField(sortField, sortOrder)

    sortChanged: (currentSortField) =>
      @currentSortField = currentSortField
      @renderSortHeaders()

    renderSortHeaders: ->
      return unless @$sortHeaders

      sortOrders = @collection.sortOrders
      for sortHeader in @$sortHeaders
        $sortHeader = $(sortHeader)
        $i = $sortHeader.find('i')

        sortField = $sortHeader.data('sort-field')
        sortOrder = if sortOrders[sortField] == 'asc' then 'up' else 'down'

        if sortOrder == 'up'
          $sortHeader.attr('aria-label', I18n.t('headers.sort_ascending', '%{title}, Sort ascending', {title: $sortHeader.text()}))
        else
          $sortHeader.attr('aria-label', I18n.t('headers.sort_descending', '%{title}, Sort descending', {title: $sortHeader.text()}))

        $sortHeader.toggleClass 'sort-field-active', sortField == @currentSortField
        $i.removeClass('icon-mini-arrow-up icon-mini-arrow-down')
        $i.addClass("icon-mini-arrow-#{sortOrder}")

      if @lastFocusField
        $("[data-sort-field='#{@lastFocusField}']").focus()

    createNewPage: (ev) ->
      ev?.preventDefault()

      @$el.hide()
      $('body').removeClass('index')
      $('body').addClass('edit with-right-side')

      @editModel = new WikiPage {editing_roles: @default_editing_roles}, contextAssetString: @contextAssetString
      @editView = new WikiPageEditView
        model: @editModel
        wiki_pages_path: ENV.WIKI_PAGES_PATH
        WIKI_RIGHTS: ENV.WIKI_RIGHTS
        PAGE_RIGHTS:
          update: ENV.WIKI_RIGHTS.update_page
          update_content: ENV.WIKI_RIGHTS.update_page_content
          read_revisions: ENV.WIKI_RIGHTS.read_revisions
      @$el.parent().append(@editView.$el)

      @editView.render()

      # override the cancel behavior
      @editView.on 'cancel', =>
        @editView.$el.remove()
        wikiSidebar.hide()

        $('body').removeClass('edit with-right-side')
        $('body').addClass('index')
        @$el.show()

    toJSON: ->
      json = super
      json.CAN =
        CREATE: !!@WIKI_RIGHTS.create_page
        MANAGE: !!@WIKI_RIGHTS.manage
        PUBLISH: !!@WIKI_RIGHTS.manage && @contextName == 'courses'
      json.CAN.VIEW_TOOLBAR = json.CAN.CREATE
      json.fetched = !!@fetched
      json.fetchedLast = !!@fetchedLast
      json
