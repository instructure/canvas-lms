#
# Copyright (C) 2011 - present Instructure, Inc.
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
  'i18n!slideshow'
  'jquery'
  'str/htmlEscape'
  'jqueryui/dialog'
  'jquery.instructure_misc_helpers'
], (I18n, $, htmlEscape) ->

  class Slide
    constructor: (title, slideshow) ->
      @title = title
      @slideshow = slideshow
      @$body = $('<li/>').addClass('slide')
      @slideshow.slides.append(@$body)

      @prevSlide = @slideshow.slideObjects[@slideshow.slideObjects.length - 1]
      @prevSlide?.nextSlide = this
      @nextSlide = null

      @$indicator = $("<a/>").addClass('slide').attr('href', '#').attr('title', htmlEscape(@title)).html('&nbsp;')
      @$indicator.data('slide', this)
      @slideshow.navigation.append(@$indicator)
      slide = this
      @$indicator.click ->
        slideshow.showSlide(slide)
        return false

      @hide()

    addParagraph: (text, klass) ->
      $paragraph = $("<p/>")
      $paragraph.addClass(klass) if klass?
      $paragraph.html(htmlEscape(text))
      @$body.append($paragraph)

    addImage: (src, klass, url) ->
      $image = $("<img/>").attr('src', src)
      $image.addClass(klass) if klass?
      if url
        $link = $("<a/>").attr('href', url).attr('target', '_blank')
        $link.append($image)
        @$body.append($link)
      else
        @$body.append($image)

    show: ->
      @$body.show()
      @$indicator.addClass('current_slide')

    hide: ->
      @$indicator.removeClass('current_slide')
      @$body.hide()

  class Slideshow
    constructor: (id) ->
      slideshow = this
      @$dom = $('<div/>').attr('id', id)

      @$slides = $('<ul/>').addClass('slides')
      @$dom.append(@$slides)

      @$separator = $("<div/>").addClass('separator')
      @$dom.append(@$separator)

      @$navigation = $("<div/>").addClass('navigation')
      @$dom.append(@$navigation)

      @$backButton = $("<a/>").addClass('back').
        attr('href', '#').
        attr('title', I18n.t('titles.back', 'Back')).
        html('&nbsp;')
      @$navigation.append(@$backButton)
      @$backButton.click ->
        slideshow.showPrevSlide()
        return false

      @$forwardButton = $("<a/>").addClass('forward').
        attr('href', '#').
        attr('title', I18n.t('titles.forward', 'Forward')).
        html('&nbsp;')
      @$navigation.append(@$forwardButton)
      @$forwardButton.click ->
        slideshow.showNextSlide()
        return false

      @$closeButton = $("<a/>").addClass('close').
        attr('href', '#').
        attr('title', I18n.t('titles.close', 'Close')).
        html('&nbsp;')
      @$navigation.append(@$closeButton)
      @$closeButton.click ->
        slideshow.close()
        return false

      @slideObjects = []
      @slideShown = null

    addSlide: (name, callback) ->
      slide = new Slide(name, this)
      @slideObjects.push(slide)
      callback(slide)

    start: ->
      @showSlide(@slideObjects[0])
      @$dialog = @$dom.dialog
        dialogClass: 'slideshow_dialog'
        height: 529
        width: 700
        modal: true
        draggable: false
        resizable: false

    showSlide: (slide) ->
      if slide
        unless @slideShown and slide == @slideShown
          @slideShown?.hide()
          @slideShown = slide
          @slideShown.show()
        if @slideShown.prevSlide
          @$backButton.removeClass('inactive')
        else
          @$backButton.addClass('inactive')
        if @slideShown.nextSlide
          @$forwardButton.removeClass('inactive')
        else
          @$forwardButton.addClass('inactive')

    showPrevSlide: ->
      @showSlide(@slideShown?.prevSlide)

    showNextSlide: ->
      @showSlide(@slideShown?.nextSlide)

    close: ->
      @$dom.dialog('close')
      @$dom.hide()
      @slideShown?.hide()
      @slideShown = null

  Slideshow

