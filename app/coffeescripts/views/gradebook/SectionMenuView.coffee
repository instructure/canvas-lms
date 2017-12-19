#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!gradebook'
  'jquery'
  'underscore'
  'Backbone'
  'jst/gradebook/section_to_show_menu'
  '../../jquery.kylemenu'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $, _, {View}, template) ->

  class SectionMenuView extends View

    @optionProperty 'sections'
    @optionProperty 'course'
    @optionProperty 'showSections'
    @optionProperty 'disabled'

    @optionProperty 'currentSection'

    template: template

    determineDefaultSection: ->
      if @showSections || !@course
        defaultSection = I18n.t('all_sections', 'All Sections')
      else
        defaultSection = @course.name
      defaultSection

    constructor: (options) ->
      super
      @defaultSection = @determineDefaultSection()
      if @sections.length > 1
        @sections.unshift(name: @defaultSection, checked: !options.currentSection)
      @updateSections()

    render: ->
      @detachEvents()
      super
      @$('button').prop('disabled', @disabled).kyleMenu()
      @attachEvents()

    detachEvents: ->
      $.unsubscribe('currentSection/change', @onSectionChange)
      @$('.section-select-menu').off('menuselect')

    attachEvents: ->
      $.subscribe('currentSection/change', @onSectionChange)
      @$('.section-select-menu').on('click', (e) -> e.preventDefault())
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

    showSections: ->
      @showSections

    toJSON: ->
      {
        sections: @sections,
        showSections: @showSections,
        currentSection: _.findWhere(@sections, id: @currentSection)?.name or @defaultSection
      }
