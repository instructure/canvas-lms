define [
  'jquery'
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactElement'
  '../modules/customPropTypes',
], ($, React, ReactRouter, withReactElement, customPropTypes) ->

  Link =   ReactRouter.Link

  BreadcrumbCollapsedContainer =
    displayName: 'BreadcrumbCollapsedContainer'


    propTypes:
      foldersToContain: React.PropTypes.arrayOf(customPropTypes.folder).isRequired

    getInitialState: ->
      open: false

    open: ->
      clearTimeout @timeout
      @setState open: true

    close: ->
      @timeout = setTimeout =>
        @setState open: false
      , 100
