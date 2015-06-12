define [
  'i18n!react_files'
  'jquery'
  'underscore'
  'react'
  'react-router'
  './BreadcrumbCollapsedContainer'
  'compiled/react/shared/utils/withReactElement'
  '../modules/customPropTypes'
], (I18n, $, _, React, ReactRouter, BreadcrumbCollapsedContainerComponent, withReactElement, customPropTypes) ->

  MAX_CRUMB_WIDTH = 500
  MIN_CRUMB_WIDTH = 40
  Link = React.createFactory ReactRouter.Link
  BreadcrumbCollapsedContainer = React.createFactory BreadcrumbCollapsedContainerComponent

  Breadcrumbs = React.createClass
    displayName: 'Breadcrumbs'

    propTypes:
      rootTillCurrentFolder: React.PropTypes.arrayOf(customPropTypes.folder)

    mixins: [ReactRouter.State]

    getInitialState: ->
      {
        maxCrumbWidth: MAX_CRUMB_WIDTH
        availableWidth: 200000
      }

    componentWillMount: ->
      # Get the existing Canvas breadcrumbs, store them, and remove them
      @fixOldCrumbs()

    componentDidMount: ->
      # Attach the resize listener to dynamically change the components
      # involved in the breadcrumb trail.
      $(window).on('resize', @handleResize)
      @handleResize()


    componentWillUnmount: ->
      $(window).off('resize', @handleResize)

    fixOldCrumbs: ->
      $oldCrumbs = $('#breadcrumbs')
      heightOfOneBreadcrumb = $oldCrumbs.find('li:visible:first').height() * 1.5
      homeName = $oldCrumbs.find('.home').text()
      $a = $oldCrumbs.find('li').eq(1).find('a')
      contextUrl = $a.attr('href')
      contextName = $a.text()
      $oldCrumbs.remove()

      @setState({homeName, contextUrl, contextName, heightOfOneBreadcrumb})

    handleResize: ->
      @startRecalculating(window.innerWidth)

    startRecalculating: (newAvailableWidth) ->
      @setState({
        availableWidth: newAvailableWidth
        maxCrumbWidth: MAX_CRUMB_WIDTH
      }, @checkIfCrumbsFit)

    componentWillReceiveProps: -> setTimeout(@startRecalculating)

    checkIfCrumbsFit: ->
      return unless @state.heightOfOneBreadcrumb
      breadcrumbHeight = $(@refs.breadcrumbs.getDOMNode()).height()
      if (breadcrumbHeight > @state.heightOfOneBreadcrumb) and (@state.maxCrumbWidth > MIN_CRUMB_WIDTH)
        maxCrumbWidth = Math.max(MIN_CRUMB_WIDTH, @state.maxCrumbWidth - 20)
        @setState({maxCrumbWidth}, @checkIfCrumbsFit)

    renderSingleCrumb: (folder, isLastCrumb, isRootCrumb) ->
      name = if isRootCrumb then I18n.t('files', 'Files') else folder.get('name')

      li {},
        Link {
          to: (if isRootCrumb then 'rootFolder' else 'folder')
          params: ({splat: folder.urlPath() unless isRootCrumb})
          # only add title tooltips if there's a chance they could be ellipsized
          title: (name if @state.maxCrumbWidth < 500)
        },
          span {
            className: 'ellipsis'
            style:
              maxWidth: (@state.maxCrumbWidth unless isLastCrumb)
          },
            name

    renderDynamicCrumbs: ->
      if @props.showingSearchResults
        [
          @renderSingleCrumb(null, !'isLastCrumb', !!'isRootCrumb'),
          li {},
            Link {
              to: 'search'
              query: @getQuery()
              params: {splat: ''}
            },
              span {
                className: 'ellipsis'
              },
                if @getQuery().search_term
                  I18n.t('search_results_for', 'search results for "%{search_term}"', {search_term: @getQuery().search_term})
        ]
      else
        return [] unless @props.rootTillCurrentFolder?.length
        [foldersInMiddle..., lastFolder] = @props.rootTillCurrentFolder
        if @state.maxCrumbWidth > MIN_CRUMB_WIDTH
          @props.rootTillCurrentFolder.map (folder, i) =>
            @renderSingleCrumb(folder, folder is lastFolder, i is 0)
        else
          [
            BreadcrumbCollapsedContainer({foldersToContain: foldersInMiddle}),
            @renderSingleCrumb(lastFolder, true)
          ]

    render: withReactElement ->
      nav {
        'aria-label':'breadcrumbs'
        role: 'navigation'
        id: 'breadcrumbs'
        ref: 'breadcrumbs'
      },
        ul {},
          # The first link (house icon)
          li className: 'home',
            a href: '/',
              i className: 'icon-home standalone-icon', title: @state.homeName,
                span className: 'screenreader-only',
                  @state.homeName
          # Context link
          li {},
            a href: @state.contextUrl,
              span className: 'ellipsible',
                @state.contextName
          @renderDynamicCrumbs()...


