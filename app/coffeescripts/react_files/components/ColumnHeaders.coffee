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
    displayName: I18n.t('kind', 'Kind')
    property: 'content-type'
    className: 'screenreader-only'
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
    displayName: 'ColumnHeaders'

    propTypes:
      to: React.PropTypes.string.isRequired
      query: React.PropTypes.object.isRequired
      toggleAllSelected: React.PropTypes.func.isRequired
      areAllItemsSelected: React.PropTypes.func.isRequired
      splat: React.PropTypes.string

    queryParamsFor: (property) ->
      order = if ((@props.query.sort || 'name') is property) and (@props.query.order is 'desc')
        'asc'
      else
        'desc'
      _.defaults({sort: property, order: order}, @props.query)

    render: withReactDOM ->
      sort = @props.query.sort or 'name'
      order = @props.query.order or 'asc'

      header className:'ef-directory-header', role: 'row',
        label className: 'screenreader-only', role: 'columnheader',
          input {
            type: 'checkbox'
            checked: @props.areAllItemsSelected()
            onChange: (event) => @props.toggleAllSelected(event.target.checked)
          },
          I18n.t('select_all', 'Select All')
        columns.map (column) =>
          isSortedCol = sort is column.property
          div {
            key: column.property
            className: "#{column.className} #{'current-filter' if isSortedCol}"
            role: 'columnheader'
            'aria-sort': {asc: 'ascending', desc: 'descending'}[isSortedCol and order] or 'none'
          },
            ReactRouter.Link _.defaults({
              query: @queryParamsFor(column.property)
              className: 'ef-plain-link'
            }, @props),

              span className: ('visible-desktop' if column.displayNameShort),
                column.displayName
              if column.displayNameShort
                span className: 'hidden-desktop',
                  column.displayNameShort


              if isSortedCol and order is 'asc'
                i className:'icon-mini-arrow-up',
                  span className: 'screenreader-only',
                    I18n.t('sorted_ascending', "Sorted Ascending")
              if isSortedCol and order is 'desc'
                i className:'icon-mini-arrow-down',
                  span className: 'screenreader-only',
                    I18n.t('sorted_desending', "Sorted Descending")

        div className:'ef-links-col', role: 'columnheader'
