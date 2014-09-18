define [
  'i18n!react_files'
  'jquery'
  'underscore'
  'react'
  'react-router'
  './BreadcrumbCollapsedContainer'
  'compiled/react/shared/utils/withReactDOM'
], (I18n, $, _, React, {Link}, BreadcrumbCollapsedContainer, withReactDOM ) ->

  Breadcrumbs = React.createClass

    propTypes:
      rootTillCurrentFolder: React.PropTypes.array.isRequired
      contextType: React.PropTypes.oneOf(['users', 'groups', 'accounts', 'courses']).isRequired
      contextId: React.PropTypes.string.isRequired

    getInitialState: ->
      {
        minCrumbWidth: 40
        maxCrumbWidth: 500
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
        maxCrumbWidth: 500
      }, @checkIfCrumbsFit)

    componentWillReceiveProps: -> setTimeout(@startRecalculating)

    checkIfCrumbsFit: ->
      return unless @state.heightOfOneBreadcrumb
      breadcrumbHeight = $(@refs.breadcrumbs.getDOMNode()).height()
      if (breadcrumbHeight > @state.heightOfOneBreadcrumb) and (@state.maxCrumbWidth > @state.minCrumbWidth)
        maxCrumbWidth = Math.max(@state.minCrumbWidth, @state.maxCrumbWidth - 20)
        @setState({maxCrumbWidth}, @checkIfCrumbsFit)

    renderSingleCrumb: (folder, isLastCrumb, isRootCrumb) ->
      name = if isRootCrumb then I18n.t('files', 'Files') else folder.get('name')

      li {},
        Link {
          to: (if isRootCrumb then 'rootFolder' else 'folder')
          contextType: @props.contextType
          contextId: @props.contextId
          splat: (folder.urlPath() unless isRootCrumb)
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
              contextType: @props.contextType
              contextId: @props.contextId
              query: @props.query
            },
              span {
                className: 'ellipsis'
              },
                if @props.query.search_term
                  I18n.t('search_results_for', 'search results for "%{search_term}"', {search_term: @props.query.search_term})
        ]
      else
        return [] unless @props.rootTillCurrentFolder?.length
        [foldersInMiddle..., lastFolder] = @props.rootTillCurrentFolder
        if @state.maxCrumbWidth > @state.minCrumbWidth
          @props.rootTillCurrentFolder.map (folder, i) =>
            @renderSingleCrumb(folder, folder isnt lastFolder, i is 0)
        else
          [
            BreadcrumbCollapsedContainer({
              foldersToContain: foldersInMiddle
              contextType: @props.contextType,
              contextId: @props.contextId
            }),
            @renderSingleCrumb(lastFolder, false)
          ]

    render: withReactDOM ->
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


