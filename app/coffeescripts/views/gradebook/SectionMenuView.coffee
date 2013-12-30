define [
  'i18n!gradebook2'
  'underscore'
  'Backbone'
  'jst/gradebook2/section_to_show_menu'

  'compiled/jquery.kylemenu'
  'vendor/jquery.ba-tinypubsub'
], (I18n, _, {View}, template) ->

  class SectionMenuView extends View

    @optionProperty 'sections'

    @optionProperty 'currentSection'

    template: template

    defaultSection: I18n.t('all_sections', 'All Sections')

    constructor: (options) ->
      super
      @sections.unshift(name: @defaultSection, checked: !options.currentSection)

    render: ->
      @detachEvents()
      super
      @$('button').kyleMenu()
      @attachEvents()

    detachEvents: ->
      $.unsubscribe('currentSection/change', @onSectionChange)
      @$('.section-select-menu').off('menuselect')

    attachEvents: ->
      $.subscribe('currentSection/change', @onSectionChange)
      @$('.section-select-menu').on('menuselect', (event, ui) =>
        section = @$('[aria-checked=true] input[name=section_to_show_radio]').val() || undefined
        $.publish('currentSection/change', [section, @cid])
        @trigger('menuselect', event, ui, @currentSection)
      )

    onSectionChange: (section, author) =>
      @currentSection = section
      @updateSections()
      @render()

    updateSections: ->
      _.map(@sections, (section) =>
        section.checked = section.id == @currentSection
        section
      )

    toJSON: ->
      {
        sections: @sections,
        currentSection: _.findWhere(@sections, id: @currentSection)?.name or @defaultSection
      }
