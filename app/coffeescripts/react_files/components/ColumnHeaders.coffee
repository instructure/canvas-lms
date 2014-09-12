define [
  'i18n!react_files'
  'underscore'
  'react'
  'react-router'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
], (I18n, _, React, ReactRouter, withReactDOM, preventDefault) ->

  columns = [
    displayName: I18n.t('name', 'Name')
    property: 'name'
    className: 'ef-name-col'
  ,
    displayNameShort: I18n.t('created_at_short', 'Created')
    displayName: I18n.t('created_at', 'Date Created')
    property: 'created_at'
    className: 'ef-date-created-col'
  ,
    displayNameShort: I18n.t('updated_at_short', 'Modified')
    displayName: I18n.t('updated_at', 'Date Modified')
    property: 'updated_at'
    className: 'ef-date-modified-col'
  ,
    displayName: I18n.t('modified_by', 'Modified By')
    className: 'ef-modified-by-col'
    property: 'user'
  ,
    displayName: I18n.t('size', 'Size')
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

      header className:'ef-directory-header',
        columns.map (column) =>
          isSortedCol = sort is column.property
          div key: column.property, className: "#{column.className} #{'current-filter' if isSortedCol}",
            ReactRouter.Link _.defaults({to: @props.to, query: @queryParamsFor(column.property), className: 'ef-plain-link'}, @props.params),

              span className: ('visible-desktop' if column.displayNameShort),
                column.displayName
              if column.displayNameShort
                span className: 'hidden-desktop',
                  column.displayNameShort

              i className:'icon-mini-arrow-up'   if isSortedCol and order is 'asc'
              i className:'icon-mini-arrow-down' if isSortedCol and order is 'desc'
        div className:'ef-links-col'
