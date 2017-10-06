//
// mep-feature-speed.js with additional customizations
//
// to see the diff, run:
//
// upstream_url='https://raw.githubusercontent.com/instructure/mediaelement/1a177ed2cc3d51689a210d5c034c88112d5a2e42/src/js/mep-feature-speed.js'
// diff -bu \
//   <(curl -s "${upstream_url}") \
//   public/javascripts/mediaelement/mep-feature-speed-instructure.js
//
(function($) {

  // Speed
  $.extend(mejs.MepDefaults, {

    // We also support to pass object like this:
    // [{name: 'Slow', value: '0.75'}, {name: 'Normal', value: '1.00'}, ...]

    // INSTRUCTURE CUSTOMIZATION: remove 1.25 speed and add 0.50
    speeds: ['2.00', '1.50', '1.00', '0.75', '0.50'],

    defaultSpeed: '1.00',

    speedChar: 'x',

    speedLabel: 'Change playback speed'
  });

  $.extend(MediaElementPlayer.prototype, {

    buildspeed: function(player, controls, layers, media) {
      var t = this;
      var hoverTimeout;

      if (t.media.pluginType == 'native') {
        var
          speedButton = null,
          speedSelector = null,
          playbackSpeed = null,
          inputId = null,
          isCurrent = null;

        var speeds = [];
        var defaultInArray = false;
        for (var i=0, len=t.options.speeds.length; i < len; i++) {
          var s = t.options.speeds[i];
          if (typeof(s) === 'string'){
            speeds.push({
              name: s + t.options.speedChar,
              value: s
            });
            if(s === t.options.defaultSpeed) {
              defaultInArray = true;
            }
          }
          else {
            speeds.push(s);
            if(s.value === t.options.defaultSpeed) {
              defaultInArray = true;
            }
          }
        }

        if (!defaultInArray) {
          speeds.push({
            name: t.options.defaultSpeed + t.options.speedChar,
            value: t.options.defaultSpeed
          });
        }

        speeds.sort(function(a, b) {
          return parseFloat(b.value) - parseFloat(a.value);
        });

        var getSpeedNameFromValue = function(value) {
          for(i=0,len=speeds.length; i <len; i++) {
            if (speeds[i].value === value) {
              return speeds[i].name;
            }
          }
        };

        var speedLabel = function(speed) {
          return mejs.i18n.t(t.options.speedLabel + ': Current speed ' + getSpeedNameFromValue(speed));
        }

        var html = '<div class="mejs-button mejs-speed-button">' +
              '<button role="button" aria-haspopup="true" aria-controls="' + t.id + '" type="button" aria-label="' + speedLabel(t.options.defaultSpeed) + '" aria-live="assertive">' + getSpeedNameFromValue(t.options.defaultSpeed) + '</button>' +
              '<div class="mejs-speed-selector mejs-offscreen" role="menu" aria-expanded="false" aria-hidden="true">' +
              '<ul>';

        for (i = 0, il = speeds.length; i<il; i++) {
          inputId = t.id + '-speed-' + speeds[i].value;
          isCurrent = (speeds[i].value === t.options.defaultSpeed);
          html += '<li>' +
                '<input type="radio" name="speed" role="menuitemradio"' +
                      'value="' + speeds[i].value + '" ' +
                      'id="' + inputId + '" ' +
                      (isCurrent ? ' checked="checked"' : '') +
                      ' aria-selected="' + isCurrent + '"' +
                      ' aria-label="' + getSpeedNameFromValue(speeds[i].value) + '"' +
                      ' tabindex=-1' +
                      ' />' +
                '<label for="' + inputId + '" ' + 'aria-hidden="true"' +
                      (isCurrent ? ' class="mejs-selected"' : '') +
                      '>' + speeds[i].name + '</label>' +
              '</li>';
        }
        html += '</ul></div></div>';

        player.speedButton = speedButton = $(html).appendTo(controls);
        speedSelector = speedButton.find('.mejs-speed-selector');

        playbackSpeed = t.options.defaultSpeed;

        media.addEventListener('loadedmetadata', function(e) {
          if (playbackSpeed) {
            media.playbackRate = parseFloat(playbackSpeed);
          }
        }, true);

        speedSelector
          .on('click', 'input[type="radio"]', function() {
            // set aria states
            $(this).attr('aria-selected', true).attr('checked', 'checked');
            $(this).closest('.mejs-speed-selector').find('input[type=radio]').not(this).attr('aria-selected', 'false').removeAttr('checked');

            var newSpeed = $(this).attr('value');
            playbackSpeed = newSpeed;
            media.playbackRate = parseFloat(newSpeed);
            speedButton.find('button')
              .html(getSpeedNameFromValue(newSpeed))
              .attr('aria-label', speedLabel(newSpeed));
            speedButton.find('.mejs-selected').removeClass('mejs-selected');
            speedButton.find('input[type="radio"]:checked').next().addClass('mejs-selected');
          });
        speedButton
        // set size on demand
          .one( 'mouseenter focusin', function() {
            speedSelector
              .height(
                speedButton.find('.mejs-speed-selector ul').outerHeight(true) +
                speedButton.find('.mejs-speed-translations').outerHeight(true))
              .css('top', (-1 * speedSelector.height()) + 'px');
            })

            // hover
            .hover(function() {
              clearTimeout(hoverTimeout);
              player.showSpeedSelector();
            }, function() {
              hoverTimeout = setTimeout(function () {
                player.hideSpeedSelector();
              }, t.options.menuTimeoutMouseLeave);
            })

            // keyboard menu activation
            .on('keydown', function (e) {
              var keyCode = e.keyCode;

              switch (keyCode) {
              case 32: // space
                if (!mejs.MediaFeatures.isFirefox) { // space sends the click event in Firefox
                  player.showSpeedSelector();
                }
                $(this).find('.mejs-speed-selector')
                  .find('input[type=radio]:checked').first().focus();
                break;
              case 13: // enter
                player.showSpeedSelector();
                $(this).find('.mejs-speed-selector')
                  .find('input[type=radio]:checked').first().focus();
                break;
              case 27: // esc
                player.hideSpeedSelector();
                $(this).find('button').focus();
                break;
              default:
                return true;
            }
          })

          // close menu when tabbing away
          .on('focusout', mejs.Utility.debounce(function (e) { // Safari triggers focusout multiple times
            // Firefox does NOT support e.relatedTarget to see which element
            // just lost focus, so wait to find the next focused element
            setTimeout(function () {
              var parent = $(document.activeElement).closest('.mejs-speed-selector');
              if (!parent.length) {
                // focus is outside the control; close menu
                player.hideSpeedSelector();
              }
            }, 0);
          }, 100))

          // Handle click so that screen readers can toggle the menu
          .on('click', 'button', function (e) {
            if ($(this).siblings('.mejs-speed-selector').hasClass('mejs-offscreen')) {
              player.showSpeedSelector();
              $(this).siblings('.mejs-speed-selector').find('input[type=radio]:checked').first().focus();
            } else {
              player.hideSpeedSelector();
            }
          });
      }
    },

    hideSpeedSelector: function () {
      this.speedButton.find('.mejs-speed-selector')
        .addClass('mejs-offscreen')
        .attr('aria-expanded', 'false')
        .attr('aria-hidden', 'true')
        .find('input[type=radio]') // make radios not focusable
        .attr('tabindex', '-1');
    },

    showSpeedSelector: function () {
      this.speedButton.find('.mejs-speed-selector')
        .removeClass('mejs-offscreen')
        .attr('aria-expanded', 'true')
        .attr('aria-hidden', 'false')
        .find('input[type=radio]')
        .attr('tabindex', '0');
    }
  });

})(mejs.$);
