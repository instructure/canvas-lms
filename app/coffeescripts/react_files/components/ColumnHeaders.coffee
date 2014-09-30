define [
  'underscore'
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
], (_, React, ReactRouter, withReactDOM, preventDefault) ->

  columns = [
    displayName: 'Name'
    property: 'name'
    className: 'ef-name-col'
  ,
    displayName: 'Date Created'
    property: 'created_at'
    className: 'ef-date-created-col'
  ,
    displayName: 'Date Modified'
    property: 'updated_at'
    className: 'ef-date-modified-col'
  ,
    displayName: 'Modified By'
    className: 'ef-modified-by-col'
    property: 'user'
  ,
    displayName: 'Size'
    property: 'size'
    className: 'ef-size-col'
  ]

  ColumnHeaders = React.createClass

    queryParamsFor: (property) ->
      order = if ((@props.query.sort || 'name') is property) and (@props.query.order is 'desc')
        'asc'
      else
        'desc'
      _.defaults({sort: property, order: order}, @props.query)

    render: withReactDOM ->
      sort = @props.query.sort or 'name'
      order = @props.query.order or 'asc'

      div className:'ef-directory',
        header className:'ef-directory-header',
          columns.map (column) =>
            isSortedCol = sort is column.property
            div key: column.property, className: "#{column.className} #{'current-filter' if isSortedCol}",
              ReactRouter.Link _.defaults({to: @props.to, query: @queryParamsFor(column.property)}, @props.params),
                column.displayName
                i className:'icon-arrow-up'   if isSortedCol and order is 'asc'
                i className:'icon-arrow-down' if isSortedCol and order is 'desc'
          div className:'ef-links-col'
