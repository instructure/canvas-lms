/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

//
// mep-feature-tracks.js with additional customizations
//
// to see the diff, run:
//
// upstream_url='https://raw.githubusercontent.com/instructure/mediaelement/e4e415b5093855eddbf310d07ddb3a12e81ae1d4/src/js/mep-feature-tracks.js'
// diff -bu \
//   <(curl -s "${upstream_url}") \
//   ui/shared/mediaelement/mep-feature-tracks-instructure.js
//

/* eslint-disable no-undef, eqeqeq, prefer-const, promise/catch-or-return */
/* eslint-disable import/no-cycle, @typescript-eslint/no-unused-vars, no-var, vars-on-top */

import React from 'react'
import ReactDOM from 'react-dom'
import InheritedCaptionTooltip from './InheritedCaptionTooltip'
import {useScope as useI18nScope} from '@canvas/i18n'
import {closedCaptionLanguages} from '@instructure/canvas-media'

const I18n = useI18nScope('mepfeaturetracksinstructure')

;(function ($) {
  // add extra default options
  $.extend(mejs.MepDefaults, {
    // this will automatically turn on a <track>
    startLanguage: '',

    tracksText: '',

    // By default, no WAI-ARIA live region - don't make a
    // screen reader speak captions over an audio track.
    tracksAriaLive: false,

    // option to remove the [cc] button when no <track kind="subtitles"> are present
    hideCaptionsButtonWhenEmpty: true,

    // If true and we only have one track, change captions to popup
    toggleCaptionsButtonWhenOnlyOne: false,

    // #id or .class
    slidesSelector: '',
  })

  $.extend(MediaElementPlayer.prototype, {
    hasChapters: false,

    cleartracks(player, controls, layers, media) {
      if (player) {
        if (player.captions) player.captions.remove()
        if (player.chapters) player.chapters.remove()
        if (player.captionsText) player.captionsText.remove()
        if (player.captionsButton) player.captionsButton.remove()
      }
    },
    buildtracks(player, controls, layers, media) {
      // INSTRUCTURE added code (the '&& !player.options.can_add_captions' part)
      if (
        player.tracks.length == 0 &&
        (!player.options.can_add_captions || this.options.lockedMediaAttachment)
      ) {
        return
      }

      let t = this,
        attr = t.options.tracksAriaLive
          ? 'role="log" aria-live="assertive" aria-atomic="false"'
          : '',
        tracksTitle = t.options.tracksText ? t.options.tracksText : I18n.t('Captions/Subtitles'),
        i,
        kind

      if (t.domNode.textTracks) {
        // if browser will do native captions, prefer mejs captions, loop through tracks and hide
        for (i = t.domNode.textTracks.length - 1; i >= 0; i--) {
          t.domNode.textTracks[i].mode = 'hidden'
        }
      }
      t.cleartracks(player, controls, layers, media)
      player.chapters = $('<div class="mejs-chapters mejs-layer"></div>').prependTo(layers).hide()
      player.captions = $(
        '<div class="mejs-captions-layer mejs-layer"><div class="mejs-captions-position mejs-captions-position-hover" ' +
          attr +
          '><span class="mejs-captions-text"></span></div></div>'
      )
        .prependTo(layers)
        .hide()
      player.captionsText = player.captions.find('.mejs-captions-text')
      player.captionsButton = $(
        '<div class="mejs-button mejs-captions-button">' +
          '<button type="button" aria-controls="' +
          t.id +
          '" title="' +
          tracksTitle +
          '" aria-label="' +
          tracksTitle +
          '"></button>' +
          '<div class="mejs-captions-selector mejs-offscreen" role="menu" aria-expanded="false" aria-hidden="true">' +
          '<ul>' +
          '<li>' +
          '<input type="radio" name="' +
          player.id +
          '_captions" id="' +
          player.id +
          '_captions_none" value="none" checked="checked" role="menuitemradio" aria-selected="true" aria-label="' +
          mejs.i18n.t('mejs.none') +
          '" tabindex="-1" />' +
          '<span for ="' +
          player.id +
          '_captions_none" aria-hidden="true">✓</span>' +
          '<label for="' +
          player.id +
          '_captions_none" aria-hidden="true">' +
          mejs.i18n.t('mejs.none') +
          '</label>' +
          '</li>' +
          '</ul>' +
          '</div>' +
          '</div>'
      ).appendTo(controls)

      let subtitleCount = 0
      for (i = 0; i < player.tracks.length; i++) {
        kind = player.tracks[i].kind
        if (kind === 'subtitles' || kind === 'captions') {
          subtitleCount++
        }
      }
      // if only one language then just make the button a toggle
      let lang = 'none'
      if (t.options.toggleCaptionsButtonWhenOnlyOne && subtitleCount == 1) {
        // click
        player.captionsButton.on('click', () => {
          if (player.selectedTrack === null) {
            lang = player.tracks[0].srclang
          }
          player.setTrack(lang)
        })
      } else {
        // hover
        let hoverTimeout
        player.captionsButton
          .hover(
            () => {
              clearTimeout(hoverTimeout)
              player.showCaptionsSelector()
            },
            () => {
              hoverTimeout = setTimeout(() => {
                player.hideCaptionsSelector()
              }, t.options.menuTimeoutMouseLeave)
            }
          )

          // handle clicks to the language radio buttons
          .on('keydown', function (e) {
            if (e.target.tagName.toLowerCase() === 'a') {
              // bypass for upload/delete links
              return true
            }

            const keyCode = e.keyCode

            switch (keyCode) {
              case 32: // space
                if (!mejs.MediaFeatures.isFirefox) {
                  // space sends the click event in Firefox
                  player.showCaptionsSelector()
                }
                $(this)
                  .find('.mejs-captions-selector')
                  .find('input[type=radio]:checked')
                  .first()
                  .focus()
                break
              case 13: // enter
                player.showCaptionsSelector()
                $(this)
                  .find('.mejs-captions-selector')
                  .find('input[type=radio]:checked')
                  .first()
                  .focus()
                break
              case 27: // esc
                player.hideCaptionsSelector()
                $(this).find('button').focus()
                break
              default:
                return true
            }
          })

          // close menu when tabbing away
          .on(
            'focusout',
            mejs.Utility.debounce(e => {
              // Safari triggers focusout multiple times
              // Firefox does NOT support e.relatedTarget to see which element
              // just lost focus, so wait to find the next focused element
              setTimeout(() => {
                const parent = $(document.activeElement).closest('.mejs-captions-selector')
                if (!parent.length) {
                  // focus is outside the control; close menu
                  player.hideCaptionsSelector()
                }
              }, 0)
            }, 100)
          )

          // handle clicks to the language radio buttons
          .on('click', 'input[type=radio]', function () {
            lang = this.value
            player.setTrack(lang)
          })

          .on('click', 'button', function () {
            if ($(this).siblings('.mejs-captions-selector').hasClass('mejs-offscreen')) {
              player.showCaptionsSelector()
              $(this)
                .siblings('.mejs-captions-selector')
                .find('input[type=radio]:checked')
                .first()
                .focus()
            } else {
              player.hideCaptionsSelector()
            }
          })
      }

      if (!player.options.alwaysShowControls) {
        // move with controls
        player.container
          .bind('controlsshown', () => {
            // push captions above controls
            player.container
              .find('.mejs-captions-position')
              .addClass('mejs-captions-position-hover')
          })
          .bind('controlshidden', () => {
            if (!media.paused) {
              // move back to normal place
              player.container
                .find('.mejs-captions-position')
                .removeClass('mejs-captions-position-hover')
            }
          })
      } else {
        player.container.find('.mejs-captions-position').addClass('mejs-captions-position-hover')
      }

      player.trackToLoad = -1
      player.selectedTrack = null
      player.isLoadingTrack = false

      // add to list
      for (i = 0; i < player.tracks.length; i++) {
        kind = player.tracks[i].kind
        if (kind === 'subtitles' || kind === 'captions') {
          // INSTRUCTURE added third src argument
          player.addTrackButton(
            player.tracks[i].srclang,
            player.tracks[i].label,
            player.tracks[i].src,
            player.container.find('track[label=' + player.tracks[i].label + ']')[0]
          )
        }
      }

      // INSTRUCTURE added code
      if (player.options.can_add_captions && !t.options.lockedMediaAttachment)
        player.addUploadTrackButton()

      // start loading tracks
      player.loadNextTrack()

      media.addEventListener(
        'timeupdate',
        () => {
          player.displayCaptions()
        },
        false
      )

      if (player.options.slidesSelector !== '') {
        player.slidesContainer = $(player.options.slidesSelector)

        media.addEventListener(
          'timeupdate',
          () => {
            player.displaySlides()
          },
          false
        )
      }

      media.addEventListener(
        'loadedmetadata',
        () => {
          player.displayChapters()
        },
        false
      )

      player.container.hover(
        () => {
          // chapters
          if (player.hasChapters) {
            player.chapters.removeClass('mejs-offscreen')
            player.chapters.fadeIn(200).height(player.chapters.find('.mejs-chapter').outerHeight())
          }
        },
        function () {
          if (player.hasChapters && !media.paused) {
            player.chapters.fadeOut(200, function () {
              $(this).addClass('mejs-offscreen')
              $(this).css('display', 'block')
            })
          }
        }
      )

      t.container.on('controlsresize', () => {
        t.adjustLanguageBox()
      })

      // check for autoplay
      if (player.node.getAttribute('autoplay') !== null) {
        player.chapters.addClass('mejs-offscreen')
      }
    },

    hideCaptionsSelector() {
      this.captionsButton
        .find('.mejs-captions-selector')
        .addClass('mejs-offscreen')
        .attr('aria-expanded', 'false')
        .attr('aria-hidden', 'true')
        .find('input[type=radio]') // make radios not focusable
        .attr('tabindex', '-1')
      this.captionsButton.find('.mejs-captions-selector a').attr('tabindex', '-1')
      this.captionsButton
        .find('svg[name="IconQuestion"]')
        .attr('tabindex', '-1')
        .attr('aria-hidden', 'true')
    },

    showCaptionsSelector() {
      this.captionsButton
        .find('.mejs-captions-selector')
        .removeClass('mejs-offscreen')
        .attr('aria-expanded', 'true')
        .attr('aria-hidden', 'false')
        .find('input[type=radio]')
        .attr('tabindex', '0')
      this.captionsButton.find('.mejs-captions-selector a').attr('tabindex', '0')
      this.captionsButton
        .find('svg[name="IconQuestion"]')
        .attr('tabindex', '0')
        .attr('aria-hidden', 'false')
        .removeAttr('focusable')
        .removeAttr('role')
    },

    setTrackAriaLabel() {
      let label = this.options.tracksText
      const current = this.selectedTrack

      if (current) {
        label += ': ' + current.label
      }

      this.captionsButton.find('button').attr('aria-label', label).attr('title', label)
    },

    setTrack(lang) {
      let t = this,
        i

      $(this).attr('aria-selected', true).prop('checked', true)
      $(this)
        .closest('.mejs-captions-selector')
        .find('input[type=radio]')
        .not(this)
        .attr('aria-selected', 'false')
        .removeAttr('checked')
      if (lang === 'none') {
        t.selectedTrack = null
        t.captionsButton.removeClass('mejs-captions-enabled')
      } else {
        for (i = 0; i < t.tracks.length; i++) {
          if (t.tracks[i].srclang == lang) {
            if (t.selectedTrack === null) t.captionsButton.addClass('mejs-captions-enabled')
            t.selectedTrack = t.tracks[i]
            t.captions.attr('lang', t.selectedTrack.srclang)
            t.displayCaptions()
            break
          }
        }
      }

      t.setTrackAriaLabel()
    },

    loadNextTrack() {
      const t = this

      t.trackToLoad++
      if (t.trackToLoad < t.tracks.length) {
        t.isLoadingTrack = true
        t.loadTrack(t.trackToLoad)
      } else {
        // add done?
        t.isLoadingTrack = false

        t.checkForTracks()
      }
    },

    loadTrack(index) {
      const t = this,
        track = t.tracks[index],
        after = function () {
          track.isLoaded = true

          t.enableTrackButton(track.srclang, track.label)

          t.loadNextTrack()
        }

      if (track.src !== undefined || track.src !== '') {
        $.ajax({
          url: track.src,
          dataType: 'text',
          success(d) {
            // parse the loaded file
            if (typeof d === 'string' && /<tt\s+xml/gi.exec(d)) {
              track.entries = mejs.TrackFormatParser.dfxp.parse(d)
            } else {
              track.entries = mejs.TrackFormatParser.webvtt.parse(d)
            }

            after()

            if (track.kind === 'chapters') {
              t.media.addEventListener(
                'play',
                () => {
                  if (t.media.duration > 0) {
                    t.displayChapters(track)
                  }
                },
                false
              )
            }

            if (track.kind === 'slides') {
              t.setupSlides(track)
            }
          },
          error() {
            t.removeTrackButton(track.srclang)
            t.loadNextTrack()
          },
        })
      }
    },

    enableTrackButton(lang, label) {
      const t = this

      if (label === '') {
        label = mejs.language.codes[lang] || lang
      }

      t.captionsButton
        .find('input[value=' + lang + ']')
        .prop('disabled', false)
        .attr('aria-label', label)
        .siblings('label')
        .text(label)

      // auto select
      if (t.options.startLanguage == lang) {
        $('#' + t.id + '_captions_' + lang)
          .prop('checked', true)
          .trigger('click')
      }

      t.adjustLanguageBox()
    },

    removeTrackButton(lang) {
      const t = this

      t.captionsButton
        .find('input[value=' + lang + ']')
        .closest('li')
        .remove()

      t.adjustLanguageBox()
    },

    // INSTRUCTURE added code
    addUploadTrackButton() {
      const t = this

      $('<a href="#" role="button" class="upload-track" tabindex="-1">Upload subtitles</a>')
        .appendTo(t.captionsButton.find('ul'))
        .wrap('<li>')
        .click(e => {
          e.preventDefault()
          import('./UploadMediaTrackForm').then(({default: UploadMediaTrackForm}) => {
            new UploadMediaTrackForm(t.options.mediaCommentId, t.media.src, t.options.attachmentId)
          })
        })
      t.adjustLanguageBox()
    },

    addTrackButton(lang, label, src, track_el) {
      const t = this
      const id = `${t.id}_captions_${lang}`
      if (label === '') {
        label = mejs.language.codes[lang] || lang
      }

      const $li = $('<li>')
      $li
        .append(
          $('<input type="radio" disabled="disabled" aria-selected="false" tabindex="-1">')
            .attr('name', `${t.id}_captions`)
            .attr('id', id)
            .attr('aria-label', label)
            .val(lang)
        )
        .append($('<span aria-hidden="true">').attr('for', id).text('✓'))
        .append($('<label aria-hidden="true">').attr('for', id).text(label))

      if (
        t.options.can_add_captions &&
        !(track_el && track_el.getAttribute('data-inherited-track') == 'true')
      ) {
        $li.append(
          $('<a href="#" role="button" data-remove="li" tabindex="-1">')
            .attr('data-confirm', I18n.t('Are you sure you want to delete this track?'))
            .attr('data-url', src)
            .attr('aria-label', I18n.t('Delete track'))
            .append($('<span aria-hidden="true">').text('x'))
        )
      }

      t.captionsButton.find('ul').append($li)
      t.adjustLanguageBox()

      if (track_el && track_el.getAttribute('data-inherited-track') == 'true') {
        const tooltip_container = $li
          .append('<span class="track-tip-container"></span>')
          .find('.track-tip-container')
        ReactDOM.render(<InheritedCaptionTooltip />, tooltip_container[0])
      }

      // remove this from the dropdownlist (if it exists)
      t.container.find('.mejs-captions-translations option[value=' + lang + ']').remove()
    },

    adjustLanguageBox() {
      const t = this
      // adjust the size of the outer box
      t.captionsButton
        .find('.mejs-captions-selector')
        .height(
          t.captionsButton.find('.mejs-captions-selector ul').outerHeight(true) +
            t.captionsButton.find('.mejs-captions-translations').outerHeight(true)
        )
    },

    checkForTracks() {
      let t = this,
        hasSubtitles = false

      // check if any subtitles
      if (t.options.hideCaptionsButtonWhenEmpty) {
        for (let i = 0; i < t.tracks.length; i++) {
          const kind = t.tracks[i].kind
          if ((kind === 'subtitles' || kind === 'captions') && t.tracks[i].isLoaded) {
            hasSubtitles = true
            break
          }
        }

        // INSTRUCTURE added code (second half of conditional)
        if (!hasSubtitles && !t.options.can_add_captions) {
          t.captionsButton.hide()
          t.setControlsSize()
        }
      }
    },
    sanitize(html) {
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')

      // Remove all nodes except those that are whitelisted
      const elementWhitelist = ['i', 'b', 'u', 'v', 'c', 'ruby', 'rt', 'lang', 'link']
      let elements = Array.from(doc.body.children || [])
      while (elements.length) {
        const node = elements.shift()
        if (elementWhitelist.includes(node.tagName.toLowerCase())) {
          elements = elements.concat(Array.from(node.children || []))
        } else {
          node.parentNode.removeChild(node)
        }
      }

      // Loop the elements and remove anything that contains value="javascript:" or an `on*` attribute
      // (`onerror`, `onclick`, etc.)
      // also remove any style or data-* attributes
      const allElements = doc.body.getElementsByTagName('*')
      for (let i = 0, n = allElements.length; i < n; i++) {
        const attributesObj = allElements[i].attributes,
          attributes = Array.prototype.slice.call(attributesObj)
        for (let j = 0, total = attributes.length; j < total; j++) {
          if (attributes[j].name.startsWith('on') || attributes[j].value.startsWith('javascript')) {
            allElements[i].parentNode.removeChild(allElements[i])
          } else if (attributes[j].name === 'style' || attributes[j].name.startsWith('data-')) {
            allElements[i].removeAttribute(attributes[j].name)
          }
        }
      }

      return doc.body.innerHTML
    },
    displayCaptions() {
      if (typeof this.tracks === 'undefined') return

      let t = this,
        track = t.selectedTrack,
        i

      if (track !== null && track.isLoaded) {
        for (i = 0; i < track.entries.times.length; i++) {
          if (
            t.media.currentTime >= track.entries.times[i].start &&
            t.media.currentTime <= track.entries.times[i].stop
          ) {
            // Set the line before the timecode as a class so the cue can be targeted if needed
            t.captionsText
              .html(t.sanitize(track.entries.text[i]))
              .attr('class', 'mejs-captions-text ' + (track.entries.times[i].identifier || ''))
            t.captions.show().height(0)
            return // exit out if one is visible;
          }
        }
        t.captions.hide()
      } else {
        t.captions.hide()
      }
    },

    setupSlides(track) {
      const t = this

      t.slides = track
      t.slides.entries.imgs = [t.slides.entries.text.length]
      t.showSlide(0)
    },

    showSlide(index) {
      if (typeof this.tracks === 'undefined' || typeof this.slidesContainer === 'undefined') {
        return
      }

      let t = this,
        url = t.slides.entries.text[index],
        img = t.slides.entries.imgs[index]

      if (typeof img === 'undefined' || typeof img.fadeIn === 'undefined') {
        t.slides.entries.imgs[index] = img = $('<img src="' + url + '">').on('load', () => {
          img.appendTo(t.slidesContainer).hide().fadeIn().siblings(':visible').fadeOut()
        })
      } else if (!img.is(':visible') && !img.is(':animated')) {
        // console.log('showing existing slide');

        img.fadeIn().siblings(':visible').fadeOut()
      }
    },

    displaySlides() {
      if (typeof this.slides === 'undefined') return

      let t = this,
        slides = t.slides,
        i

      for (i = 0; i < slides.entries.times.length; i++) {
        if (
          t.media.currentTime >= slides.entries.times[i].start &&
          t.media.currentTime <= slides.entries.times[i].stop
        ) {
          t.showSlide(i)

          return // exit out if one is visible;
        }
      }
    },

    displayChapters() {
      let t = this,
        i

      for (i = 0; i < t.tracks.length; i++) {
        if (t.tracks[i].kind === 'chapters' && t.tracks[i].isLoaded) {
          t.drawChapters(t.tracks[i])
          t.hasChapters = true
          break
        }
      }
    },

    drawChapters(chapters) {
      let t = this,
        i,
        dur,
        // width,
        // left,
        percent = 0,
        usedPercent = 0

      t.chapters.empty()

      for (i = 0; i < chapters.entries.times.length; i++) {
        dur = chapters.entries.times[i].stop - chapters.entries.times[i].start
        percent = Math.floor((dur / t.media.duration) * 100)
        if (
          percent + usedPercent > 100 || // too large
          (i == chapters.entries.times.length - 1 && percent + usedPercent < 100)
        ) {
          // not going to fill it in
          percent = 100 - usedPercent
        }
        // width = Math.floor(t.width * dur / t.media.duration);
        // left = Math.floor(t.width * chapters.entries.times[i].start / t.media.duration);
        // if (left + width > t.width) {
        //	width = t.width - left;
        // }

        t.chapters.append(
          $(
            '<div class="mejs-chapter" rel="' +
              chapters.entries.times[i].start +
              '" style="left: ' +
              usedPercent.toString() +
              '%;width: ' +
              percent.toString() +
              '%;">' +
              '<div class="mejs-chapter-block' +
              (i == chapters.entries.times.length - 1 ? ' mejs-chapter-block-last' : '') +
              '">' +
              '<span class="ch-title">' +
              t.sanitize(chapters.entries.text[i]) +
              '</span>' +
              '<span class="ch-time">' +
              mejs.Utility.secondsToTimeCode(chapters.entries.times[i].start, t.options) +
              '&ndash;' +
              mejs.Utility.secondsToTimeCode(chapters.entries.times[i].stop, t.options) +
              '</span>' +
              '</div>' +
              '</div>'
          )
        )
        usedPercent += percent
      }

      t.chapters.find('div.mejs-chapter').click(function () {
        t.media.setCurrentTime(parseFloat($(this).attr('rel')))
        if (t.media.paused) {
          t.media.play()
        }
      })

      t.chapters.show()
    },
  })

  mejs.language = {
    codes: closedCaptionLanguages.reduce((result, {id, label}) => ({...result, [id]: label}), {}),
  }

  /*
	Parses WebVTT format which should be formatted as
	================================
	WEBVTT
	1
	00:00:01,1 --> 00:00:05,000
	A line of text
	2
	00:01:15,1 --> 00:02:05,000
	A second line of text
	===============================
	Adapted from: http://www.delphiki.com/html5/playr
	*/
  mejs.TrackFormatParser = {
    webvtt: {
      pattern_timecode:
        /^((?:[0-9]{1,2}:)?[0-9]{2}:[0-9]{2}([,.][0-9]{1,3})?) --\> ((?:[0-9]{1,2}:)?[0-9]{2}:[0-9]{2}([,.][0-9]{3})?)(.*)$/,

      parse(trackText) {
        let i = 0,
          lines = mejs.TrackFormatParser.split2(trackText, /\r?\n/),
          entries = {text: [], times: []},
          timecode,
          text,
          identifier
        for (; i < lines.length; i++) {
          timecode = this.pattern_timecode.exec(lines[i])

          if (timecode && i < lines.length) {
            if (i - 1 >= 0 && lines[i - 1] !== '') {
              identifier = lines[i - 1]
            }
            i++
            // grab all the (possibly multi-line) text that follows
            text = lines[i]
            i++
            while (lines[i] !== '' && i < lines.length) {
              text = text + '\n' + lines[i]
              i++
            }
            text = $.trim(text).replace(
              /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gi,
              "<a href='$1' target='_blank'>$1</a>"
            )
            // Text is in a different array so I can use .join
            entries.text.push(text)
            entries.times.push({
              identifier,
              start:
                mejs.Utility.convertSMPTEtoSeconds(timecode[1]) === 0
                  ? 0.2
                  : mejs.Utility.convertSMPTEtoSeconds(timecode[1]),
              stop: mejs.Utility.convertSMPTEtoSeconds(timecode[3]),
              settings: timecode[5],
            })
          }
          identifier = ''
        }
        return entries
      },
    },
    // Thanks to Justin Capella: https://github.com/johndyer/mediaelement/pull/420
    dfxp: {
      parse(trackText) {
        trackText = $(trackText).filter('tt')
        let i = 0,
          container = trackText.children('div').eq(0),
          lines = container.find('p'),
          styleNode = trackText.find('#' + container.attr('style')),
          styles,
          text,
          entries = {text: [], times: []}

        if (styleNode.length) {
          const attributes = styleNode.removeAttr('id').get(0).attributes
          if (attributes.length) {
            styles = {}
            for (i = 0; i < attributes.length; i++) {
              styles[attributes[i].name.split(':')[1]] = attributes[i].value
            }
          }
        }

        for (i = 0; i < lines.length; i++) {
          var style
          const _temp_times = {
            start: null,
            stop: null,
            style: null,
          }
          if (lines.eq(i).attr('begin'))
            _temp_times.start = mejs.Utility.convertSMPTEtoSeconds(lines.eq(i).attr('begin'))
          if (!_temp_times.start && lines.eq(i - 1).attr('end'))
            _temp_times.start = mejs.Utility.convertSMPTEtoSeconds(lines.eq(i - 1).attr('end'))
          if (lines.eq(i).attr('end'))
            _temp_times.stop = mejs.Utility.convertSMPTEtoSeconds(lines.eq(i).attr('end'))
          if (!_temp_times.stop && lines.eq(i + 1).attr('begin'))
            _temp_times.stop = mejs.Utility.convertSMPTEtoSeconds(lines.eq(i + 1).attr('begin'))
          if (styles) {
            style = ''
            for (const _style in styles) {
              style += _style + ':' + styles[_style] + ';'
            }
          }
          if (style) _temp_times.style = style
          if (_temp_times.start === 0) _temp_times.start = 0.2
          entries.times.push(_temp_times)
          text = $.trim(lines.eq(i).html()).replace(
            /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/gi,
            "<a href='$1' target='_blank'>$1</a>"
          )
          entries.text.push(text)
        }
        return entries
      },
    },
    split2(text, regex) {
      // normal version for compliant browsers
      // see below for IE fix
      return text.split(regex)
    },
  }

  // test for browsers with bad String.split method.
  if ('x\n\ny'.split(/\n/gi).length != 3) {
    // add super slow IE8 and below version
    mejs.TrackFormatParser.split2 = function (text, regex) {
      let parts = [],
        chunk = '',
        i

      for (i = 0; i < text.length; i++) {
        chunk += text.substring(i, i + 1)
        if (regex.test(chunk)) {
          parts.push(chunk.replace(regex, ''))
          chunk = ''
        }
      }
      parts.push(chunk)
      return parts
    }
  }
})(mejs.$)
