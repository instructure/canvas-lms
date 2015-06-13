// Source Chooser Plugin
(function($) {

  $.extend(mejs.MepDefaults, {
    sourcechooserText: 'Source Chooser'
  });

  $.extend(MediaElementPlayer.prototype, {
    buildsourcechooser: function(player, controls, layers, media) {
      if (!player.isVideo) { return; }

      var t = this;

      player.sourcechooserButton =
        $('<div class="mejs-button mejs-sourcechooser-button">'+
            '<button type="button" aria-controls="' + t.id + '" title="' + t.options.sourcechooserText + '" aria-label="' + t.options.sourcechooserText + '"></button>'+
            '<div class="mejs-sourcechooser-selector">'+
              '<ul>'+
              '</ul>'+
            '</div>'+
          '</div>')
          .appendTo(controls)

          // hover
          .hover(function() {
            $(this).find('.mejs-sourcechooser-selector').css('visibility','visible');
          }, function() {
            $(this).find('.mejs-sourcechooser-selector').css('visibility','hidden');
          })

          // handle clicks to the language radio buttons
          .on('click', 'input[type=radio]', function() {
            if (media.currentSrc === this.value) { return; }

            var src = this.value;
            var currentTime = media.currentTime;
            var wasPlaying = !media.paused;

            $(media).one('loadedmetadata', function() {
              media.setCurrentTime(currentTime);
            });

            $(media).one('canplay', function() {
              if (wasPlaying) {
                media.play();
              }
            });

            media.setSrc(src);
            media.load();
          });

      // add to list
      for (var i in this.node.children) {
        var src = this.node.children[i];
        if (src.nodeName === 'SOURCE' && (media.canPlayType(src.type) === 'probably' || media.canPlayType(src.type) === 'maybe')) {
          player.addSourceButton(src.src, src.title, src.type, media.src === src.src);
        }
      }
    },

    addSourceButton: function(src, label, type, isCurrent) {
      var t = this;
      if (label === '' || label === undefined) {
        label = src;
      }
      type = type.split('/')[1];

      t.sourcechooserButton.find('ul').append(
        $('<li>'+
          '<label>' +
          '<input type="radio" name="' + t.id + '_sourcechooser" value="' + src + '" ' + (isCurrent ? 'checked="checked"' : '') + ' />' +
          label + ' (' + type + ')</label>' +
        '</li>')
      );

      t.adjustSourcechooserBox();
    },

    adjustSourcechooserBox: function() {
      var t = this;
      // adjust the size of the outer box
      t.sourcechooserButton.find('.mejs-sourcechooser-selector').height(
        t.sourcechooserButton.find('.mejs-sourcechooser-selector ul').outerHeight(true)
      );
    }
  });

})(mejs.$);
