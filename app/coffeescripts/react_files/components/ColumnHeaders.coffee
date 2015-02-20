define [
  'i18n!react_files'
  'underscore'
  'old_unsupported_dont_use_react'
  'old_unsupported_dont_use_react-router'
  'compiled/react/shared/utils/withReactDOM'
  'compiled/fn/preventDefault'
], (I18n, _, React, ReactRouter, withReactDOM, preventDefault) ->

  classSet = React.addons.classSet

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
  ,
    displayName: I18n.t('Usage Rights')
    property: 'usage_rights'
    className: 'ef-usage-rights-col'
  ]

  ColumnHeaders = React.createClass
    displayName: 'ColumnHeaders'

    propTypes:
      to: React.PropTypes.string.isRequired
      query: React.PropTypes.object.isRequired
      params: React.PropTypes.object.isRequired
      toggleAllSelected: React.PropTypes.func.isRequired
      areAllItemsSelected: React.PropTypes.func.isRequired
      splat: React.PropTypes.string

    getInitialState: ->
      return {
        hideToggleAll: true
      }

    queryParamsFor: (query, property) ->
      order = if ((query.sort || 'name') is property) and (query.order is 'desc')
        'asc'
      else
        'desc'
      _.defaults({sort: property, order: order}, query)

    render: withReactDOM ->
      sort = @props.query.sort or 'name'
      order = @props.query.order or 'asc'

      selectAllCheckboxClass = classSet({
        'screenreader-only': @state.hideToggleAll
      })

      selectAllLabelClass = classSet({
        'screenreader-only': !@state.hideToggleAll
      })

      header className:'ef-directory-header', role: 'row',
        div className: selectAllCheckboxClass, role: 'columnheader',
          span {className: selectAllLabelClass },
            I18n.t('select_all', 'Select All')
          input {
            className: selectAllCheckboxClass
            type: 'checkbox'
            onFocus: (event) => @setState({hideToggleAll: false})
            onBlur: (event) => @setState({hideToggleAll: true})
            checked: @props.areAllItemsSelected()
            onChange: (event) => @props.toggleAllSelected(event.target.checked)
          },

        columns.map (column) =>
          # don't show any usage rights related stuff to people that don't have the feature flag on
          return if (column.property is 'usage_rights') and !@props.usageRightsRequiredForContext

          isSortedCol = sort is column.property

          # This little bit is done so that we can get a dynamic key added into
          # the object since string interpolation in an object key is forbidden
          # by CoffeeScript... which makes a lot of sense.
          columnClassNameObj =
            "current-filter": isSortedCol
          columnClassNameObj[column.className] = true

          columnClassName = classSet(columnClassNameObj)

          linkClassName = classSet({
            'visible-desktop': column.displayNameShort
            'ef-usage-rights-col-offset': (column.property == 'usage_rights')
          })

          div {
            key: column.property
            className: columnClassName
            role: 'columnheader'
            'aria-sort': {asc: 'ascending', desc: 'descending'}[isSortedCol and order] or 'none'
          },
            ReactRouter.Link _.defaults({
              query: @queryParamsFor(@props.query, column.property)
              className: 'ef-plain-link'
            }, @props),

              span className: linkClassName,
                if (column.property == 'select')
                  span {className: 'screenreader-only'},
                    column.displayName
                else if (column.property == 'usage_rights')
                  i {className: 'icon-files-copyright'},
                    span {className: 'screenreader-only'},
                      column.displayName
                else
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

        div {
          className:'ef-links-col'
          role: 'columnheader'
        },
          span {className:'screenreader-only'},
            I18n.t('Links')

