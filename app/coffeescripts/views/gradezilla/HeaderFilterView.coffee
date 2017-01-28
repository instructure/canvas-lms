define [
  'i18n!gradezilla'
  'Backbone'
  'compiled/gradezilla/OutcomeGradebookGrid'
  'jst/gradezilla/header_filter'
], (I18n, {View}, Grid, template) ->

  class HeaderFilterView extends View

    className: 'text-right'

    template: template

    labels:
      average: I18n.t('course_average', 'Course average')
      median: I18n.t('course_median', 'Course median')
      mode: I18n.t('course_mode', 'Course mode')

    events:
      'click li a': 'onClick'

    @optionProperty 'grid'

    @optionProperty 'redrawFn'

    onClick: (e) ->
      e.preventDefault()
      e.stopPropagation()
      key = e.target.getAttribute('data-method')
      @closeMenu()
      @updateLabel(key)
      @recalculateHeader(key)

    closeMenu: ->
      @$el.find('.al-trigger')
        .data('kyleMenu')
        .close()

    updateLabel: (key) ->
      @$('.current-label').text(@labels[key])

    recalculateHeader: (key) ->
      key = 'mean' if key is 'average'
      @redrawFn(@grid, key)
