//
// Playback speed control is based on code from an as-yet-unmerged pull request to mediaelement.js
// See: https://github.com/matthillman/mediaelement/commit/e9efc9473ca38c240b712a11ba4c035651c204d4
// And: https://github.com/johndyer/mediaelement/pull/1249
//
(function($) {

  // Speed
  $.extend(mejs.MepDefaults, {

    // INSTRUCTURE CUSTOMIZATION: adjust default available speeds
    speeds: ['2.00', '1.50', '1.00', '0.75', '0.50'],

    defaultSpeed: '1.00'

  });

  $.extend(MediaElementPlayer.prototype, {

    // INSTRUCTURE CUSTOMIZATION - pulling latest definition of isIE from ME.js master with IE11 fixes
    isIE: function() {
      return (window.navigator.appName.match(/microsoft/gi) !== null) || (window.navigator.userAgent.match(/trident/gi) !== null);
    },

    buildspeed: function(player, controls, layers, media) {
      // INSTRUCTURE CUSTOMIZATION: enable playback speed controls for both audio and video
      // if (!player.isVideo)
      //   return;

      var t = this;

      if (t.media.pluginType !== 'native') { return; }

      var s = '<div class="mejs-button mejs-speed-button"><button type="button">'+t.options.defaultSpeed+'x</button><div class="mejs-speed-selector"><ul>';
      var i, ss;

      if ($.inArray(t.options.defaultSpeed, t.options.speeds) === -1) {
        t.options.speeds.push(t.options.defaultSpeed);
      }

      t.options.speeds.sort(function(a, b) {
        return parseFloat(b) - parseFloat(a);
      });

      for (i = 0; i < t.options.speeds.length; i++) {
        s += '<li>';
        if (t.options.speeds[i] === t.options.defaultSpeed) {
          s += '<label class="mejs-speed-selected">'+ t.options.speeds[i] + 'x';
          s += '<input type="radio" name="speed" value="' + t.options.speeds[i] + '" checked=true />';
        } else {
          s += '<label>'+ t.options.speeds[i] + 'x';
          s += '<input type="radio" name="speed" value="' + t.options.speeds[i] + '" />';
        }
        s += '</label></li>';
      }
      s += '</ul></div></div>';

      player.speedButton = $(s).appendTo(controls);

      player.playbackspeed = t.options.defaultSpeed;

      player.$media.on('loadedmetadata', function() {
        media.playbackRate = parseFloat(player.playbackspeed);
      });

      player.speedButton.on('click', 'input[type=radio]', function() {
        player.playbackspeed = $(this).attr('value');
        media.playbackRate = parseFloat(player.playbackspeed);
        player.speedButton.find('button').text(player.playbackspeed + 'x');
        player.speedButton.find('.mejs-speed-selected').removeClass('mejs-speed-selected');
        player.speedButton.find('input[type=radio]:checked').parent().addClass('mejs-speed-selected');

        //
        // INSTRUCTURE CUSTOMIZATION - IE fixes
        //
        if (t.isIE()) {
          // After playback completes, IE will reset the rate to the
          // defaultPlaybackRate of 1.00 (with the UI still reflecting the
          // selected value) unless we set defaultPlaybackRate as well.
          media.defaultPlaybackRate = media.playbackRate;

          // Internet Explorer fires a 'waiting' event in addition to the
          // 'ratechange' event when the playback speed is changed, even though
          // the HTML5 standard says not to. >_<
          //
          // Even worse, the 'waiting' state does not resolve with any other
          // event that would indicate that we are done waiting, like 'playing'
          // or 'seeked', so we are left with nothing to hook on but ye olde
          // arbitrary point in the future.
          $(media).one('waiting', function() {
            setTimeout(function() {
              layers.find('.mejs-overlay-loading').parent().hide();
              controls.find('.mejs-time-buffering').hide();
            }, 500);
          });
        }
      });

      ss = player.speedButton.find('.mejs-speed-selector');
      ss.height(this.speedButton.find('.mejs-speed-selector ul').outerHeight(true) + player.speedButton.find('.mejs-speed-translations').outerHeight(true));
      ss.css('top', (-1 * ss.height()) + 'px');
    }
  });

})(mejs.$);
