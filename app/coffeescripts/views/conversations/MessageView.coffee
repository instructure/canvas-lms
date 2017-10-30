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
  'i18n!conversations'
  'Backbone'
  'underscore'
  'jst/conversations/message'
  'react'
  'react-dom'
  'instructure-ui/lib/components/Checkbox'
  'instructure-ui/lib/components/ScreenReaderContent'
], (I18n, {View}, _, template, React, ReactDOM, {default: Checkbox}, {default: ScreenReaderContent}) ->

  class MessageView extends View

    tagName: 'li'

    template: template

    els:
      '.star-btn': '$starBtn'
      '.StarButton-LabelContainer': '$starBtnScreenReaderMessage'
      '.read-state': '$readBtn'
      '.select-checkbox': '$selectCheckbox'

    events:
      'click': 'onSelect'
      'click .open-message': 'onSelect'
      'click .star-btn':   'toggleStar'
      'click .read-state': 'toggleRead'
      'mousedown': 'onMouseDown'

    messages:
      read:     I18n.t('Mark as read')
      unread:   I18n.t('Mark as unread')
      star:     I18n.t('Star conversation')
      unstar:   I18n.t('Unstar conversation')

    initialize: ->
      super
      @attachModel()

    attachModel: ->
      @model.on('change:starred', @setStarBtnChecked)
      @model.on('change:workflow_state', => @$readBtn.toggleClass('read', @model.get('workflow_state') isnt 'unread'))
      @model.on('change:selected', @setSelected)

    renderSelectCheckbox: ->
      subject = @model.get('subject') || I18n.t('No Subject')
      ReactDOM.render(
        React.createElement(Checkbox,
          label: React.createElement(ScreenReaderContent, {}, I18n.t('Select Conversation %{subject}', subject: subject ))
          checked: !!@model.get('selected')
          onChange: => @model.set('selected', !@model.get('selected'))
        ), @$selectCheckbox[0])

    setSelected: (m) =>
      selected = m.get('selected')
      @$el.toggleClass('active', selected)
      @renderSelectCheckbox()

    onSelect: (e) ->
      return if e and e.target.className.match(/star|read-state/) or @$selectCheckbox[0].contains(e.target)
      if e.shiftKey
        return @model.collection.selectRange(@model)
      modifier = e.metaKey or e.ctrlKey
      if @model.get('selected') and modifier then @deselect(modifier) else @select(modifier)

    select: (modifier) ->
      _.each(@model.collection.without(@model), (m) -> m.set('selected', false)) unless modifier
      @model.set('selected', true)
      if @model.unread()
        @model.set('workflow_state', 'read')
        @model.save() if @model.get('for_submission')

    deselect: (modifier) ->
      @model.set('selected', false) if modifier

    setStarBtnCheckedScreenReaderMessage: ->
      text = if @model.starred()
               if @model.get('subject')
                 I18n.t('Starred "%{subject}", Click to unstar.', subject: @model.get('subject'))
               else
                 I18n.t('Starred "(No Subject)", Click to unstar.')
             else
               if @model.get('subject')
                 I18n.t('Not starred "%{subject}", Click to star.', subject: @model.get('subject'))
               else
                 I18n.t('Not starred "(No Subject)", Click to star.')
      @$starBtnScreenReaderMessage.text(text)

    setStarBtnChecked: =>
      @$starBtn.attr
        'aria-checked': @model.starred()
        title: if @model.starred() then @messages.unstar else @messages.star
      @$starBtn.toggleClass('active', @model.starred())
      @setStarBtnCheckedScreenReaderMessage()

    toggleStar: (e) ->
      e.preventDefault()
      @model.toggleStarred()
      @model.save()
      @setStarBtnChecked()

    toggleRead: (e) ->
      e.preventDefault()
      @model.toggleReadState()
      @model.save()
      @$readBtn.attr
        'aria-checked': @model.unread()
        title: if @model.unread() then @messages.read else @messages.unread

    onMouseDown: (e) ->
      if e.shiftKey
        e.preventDefault()
        setTimeout ->
          window.getSelection().removeAllRanges() # IE
        , 0

    afterRender: () ->
      @renderSelectCheckbox()

    remove: () ->
      ReactDOM.unmountComponentAtNode(@$selectCheckbox[0])
      View.prototype.remove.apply(this, arguments)

    toJSON: ->
      @model.toJSON().conversation
