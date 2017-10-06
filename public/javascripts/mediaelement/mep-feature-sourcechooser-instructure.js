//
// mep-feature-tracks.js with additional customizations
//
// to see the diff, run:
//
// upstream_url='https://raw.githubusercontent.com/instructure/mediaelement/1a177ed2cc3d51689a210d5c034c88112d5a2e42/src/js/mep-feature-sourcechooser.js'
// diff -bu \
//   <(curl -s "${upstream_url}") \
//   public/javascripts/mediaelement/mep-feature-sourcechooser-instructure.js
//
// Source Chooser Plugin
(function($) {

 $.extend(mejs.MepDefaults, {
   sourcechooserText: 'Source Chooser'
 });

 $.extend(MediaElementPlayer.prototype, {
   sources: [],

   buildsourcechooser: function(player, controls, layers, media) {
     // INSTRUCTURE ADDED
     if (!player.isVideo) { return; }

     var t = this;
     var hoverTimeout;

     player.sourcechooserButton =
       $('<div class="mejs-button mejs-sourcechooser-button">'+
           '<button type="button" role="button" aria-haspopup="true" aria-controls="' + t.id + '" title="' + t.options.sourcechooserText + '" aria-label="' + t.options.sourcechooserText + '" aria-live="assertive"></button>'+
           '<div class="mejs-sourcechooser-selector mejs-offscreen" role="menu" aria-expanded="false" aria-hidden="true">'+
             '<ul>'+
             '</ul>'+
           '</div>'+
         '</div>')
         .appendTo(controls)

         // hover
         .hover(function() {
           clearTimeout(hoverTimeout);
           player.showSourcechooserSelector();
         }, function() {
           hoverTimeout = setTimeout(function () {
           player.hideSourcechooserSelector();
           }, t.options.menuTimeoutMouseLeave);
         })

         // keyboard menu activation
         .on('keydown', function (e) {
           var keyCode = e.keyCode;

           switch (keyCode) {
             case 32: // space
               if (!mejs.MediaFeatures.isFirefox) { // space sends the click event in Firefox
                 player.showSourcechooserSelector();
               }
               $(this).find('.mejs-sourcechooser-selector')
                 .find('input[type=radio]:checked').first().focus();
               break;
             case 13: // enter
               player.showSourcechooserSelector();
               $(this).find('.mejs-sourcechooser-selector')
                 .find('input[type=radio]:checked').first().focus();
               break;
             case 27: // esc
               player.hideSourcechooserSelector();
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
             var parent = $(document.activeElement).closest('.mejs-sourcechooser-selector');
             if (!parent.length) {
               // focus is outside the control; close menu
               player.hideSourcechooserSelector();
             }
           }, 0);
         }, 100))

         // handle clicks to the source radio buttons
         .delegate('input[type=radio]', 'click', function() {
           // set aria states
           var selector = $(this).closest('.mejs-sourcechooser-selector');
           $(this).attr('aria-selected', true).attr('checked', 'checked');
           selector.find('input[type=radio]').not(this).attr('aria-selected', 'false').removeAttr('checked');
           selector.find('.mejs-selected').removeClass('mejs-selected')
           selector.find('input[type="radio"]:checked').next().addClass('mejs-selected');

           var src = this.value;

           if (media.currentSrc != src) {
             var currentTime = media.currentTime;
             var paused = media.paused;
             media.pause();
             media.setSrc(src);

             media.addEventListener('loadedmetadata', function(e) {
               media.currentTime = currentTime;
             }, true);

             var canPlayAfterSourceSwitchHandler = function(e) {
               if (!paused) {
                 media.play();
               }
               media.removeEventListener("canplay", canPlayAfterSourceSwitchHandler, true);
             };
             media.addEventListener('canplay', canPlayAfterSourceSwitchHandler, true);
             media.load();
           }

           t.setSourcechooserAriaLabel(media);
         })

         // Handle click so that screen readers can toggle the menu
         .delegate('button', 'click', function (e) {
           if ($(this).siblings('.mejs-sourcechooser-selector').hasClass('mejs-offscreen')) {
             player.showSourcechooserSelector();
             $(this).siblings('.mejs-sourcechooser-selector').find('input[type=radio]:checked').first().focus();
           } else {
             player.hideSourcechooserSelector();
           }
         });

     // add to list
     for (var i in this.node.children) {
       var src = this.node.children[i];
       if (src.nodeName === 'SOURCE' && (media.canPlayType(src.type) == 'probably' || media.canPlayType(src.type) == 'maybe')) {
         t.sources.push(src);
         player.addSourceButton(src.src, src.title, src.type, media.src == src.src);
       }
     }

     t.setSourcechooserAriaLabel(media);
   },

   setSourcechooserAriaLabel: function(media) {
     var label = mejs.i18n.t(this.options.sourcechooserText)
     var current = this.currentSource(media);

     if (current) {
       label += ': ' + mejs.i18n.t(current);
     }

     this.sourcechooserButton.find('button')
       .attr('aria-label', label)
       .attr('title', label);
   },

   addSourceButton: function(src, label, type, isCurrent) {
     var t = this;
     if (label === '' || label == undefined) {
       label = src;
     }
     type = type.split('/')[1];

     t.sourcechooserButton.find('ul').append(
       $('<li>'+
           '<input type="radio" name="' + t.id + '_sourcechooser" id="' + t.id + '_sourcechooser_' + label + type + '" role="menuitemradio" value="' + src + '" ' + (isCurrent ? 'checked="checked"' : '') + 'aria-selected="' + isCurrent + '" aria-label="' + label + '"' + ' tabindex=-1' + ' />'+
           '<label for="' + t.id + '_sourcechooser_' + label + type + '" aria-hidden="true"' + (isCurrent ? ' class="mejs-selected"' : '') + '>' + label + ' (' + type + ')</label>'+
         '</li>')
     );

     t.adjustSourcechooserBox();

   },

   currentSource: function(media) {
     var current = this.sources.filter(function(src) {
       return src.src == media.src;
     })[0];

     if (current) {
       return current.title || '';
     }

     return '';
   },

   adjustSourcechooserBox: function() {
     var t = this;
     // adjust the size of the outer box
     t.sourcechooserButton.find('.mejs-sourcechooser-selector').height(
       t.sourcechooserButton.find('.mejs-sourcechooser-selector ul').outerHeight(true)
     );
   },

   hideSourcechooserSelector: function () {
     this.sourcechooserButton.find('.mejs-sourcechooser-selector')
       .addClass('mejs-offscreen')
       .attr('aria-expanded', 'false')
       .attr('aria-hidden', 'true')
       .find('input[type=radio]') // make radios not focusable
       .attr('tabindex', '-1');
   },

   showSourcechooserSelector: function () {
     this.sourcechooserButton.find('.mejs-sourcechooser-selector')
       .removeClass('mejs-offscreen')
       .attr('aria-expanded', 'true')
       .attr('aria-hidden', 'false')
       .find('input[type=radio]')
       .attr('tabindex', '0');
   }
 });

})(mejs.$);
