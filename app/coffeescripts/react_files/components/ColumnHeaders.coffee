define [
  'react'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
], (React, withReactDOM, preventDefault) ->


  columns = [
    displayName: 'Name'
    property: 'name'
    className: 'ef-name-col'
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

    makeSorter: (property) ->
      preventDefault (event) =>
        @props.subject.set
          sort: property
          order: if (@props.subject.get('sort') is property) and (@props.subject.get('order') is 'asc')
            'desc'
          else
            'asc'

    render: withReactDOM ->
      div className:'ef-directory',
        header className:'ef-directory-header',
          columns.map (column) =>
            isSortedCol = @props.subject.get('sort') is column.property
            div key: column.property, className: "#{column.className} #{'current-filter' if isSortedCol}",
              a onClick: @makeSorter(column.property),
                column.displayName
                i className:'icon-arrow-up'   if isSortedCol and @props.subject.get('order') is 'asc'
                i className:'icon-arrow-down' if isSortedCol and @props.subject.get('order') is 'desc'
          div className:'ef-links-col'