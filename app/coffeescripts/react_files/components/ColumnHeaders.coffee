define [
  'i18n!react_files'
  'underscore'
  'react'
  'compiled/fn/preventDefault'
], (I18n, _, React, preventDefault) ->

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
    property: 'modified_at'
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

  ColumnHeaders =
    displayName: 'ColumnHeaders'

    columns: columns

    propTypes:
      query: React.PropTypes.object.isRequired
      toggleAllSelected: React.PropTypes.func.isRequired
      areAllItemsSelected: React.PropTypes.func.isRequired

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

