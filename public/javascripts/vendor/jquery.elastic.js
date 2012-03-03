/**
* @name             Elastic
* @descripton           Elastic is Jquery plugin that grow and shrink your textareas automaticliy
* @version            1.6.4
* @requires           Jquery 1.2.6+
*
* @author             Jan Jarfalk
* @author-email         jan.jarfalk@unwrongest.com
* @author-website         http://www.unwrongest.com
*
* @licens             MIT License - http://www.opensource.org/licenses/mit-license.php
*/

define(['jquery'], function($){
  $.fn.extend({
    elastic: function(options) {
      var opts = $.extend({}, options),
          //  We will create a div clone of the textarea
          //  by copying these attributes from the textarea to the div.
          mimics = [
            'paddingTop',
            'paddingRight',
            'paddingBottom',
            'paddingLeft',
            'borderLeftWidth',
            'borderLeftStyle',
            'borderRightWidth',
            'borderRightStyle',
            'fontSize',
            'lineHeight',
            'fontFamily',
            'width',
            'fontWeight'
          ];

      return this.each( function() {

        // Elastic only works on textareas
        if ( this.type != 'textarea' ) { return false; }

        var $textarea  = $(this),
            // Append the twin to the DOM
            // We are going to meassure the height of this, not the textarea.
            $twin      = $('<div />').css({ 'position': 'absolute', 'display':'none', 'word-wrap':'break-word' }).prependTo($textarea.parent()),
            lineHeight = parseInt($textarea.css('line-height'),10) || parseInt($textarea.css('font-size'),'10'),
            minheight  = parseInt($textarea.css('height'),10) || lineHeight*3,
            maxheight  = parseInt($textarea.css('max-height'),10) || Number.MAX_VALUE,
            goalheight = 0;

        // Opera returns max-height of -1 if not set
        if (maxheight < 0) { maxheight = Number.MAX_VALUE; }

        // Copy the essential styles (mimics) from the textarea to the twin
        $.each(mimics, function(i, val) {
          $twin.css( val, $textarea.css(val) );
        });

        // Sets a given height and overflow state on the textarea
        function setHeightAndOverflow(height, overflow){
          var curratedHeight = Math.floor(parseInt(height,10));
          if($textarea.height() != curratedHeight){
            $textarea.css({'height': curratedHeight + 'px','overflow':overflow});
          }
        }


        // This function will update the height of the textarea if necessary
        function update() {
          // Get curated content from the textarea.
          var textareaContent = $textarea.val().replace(/&/g,'&amp;').replace(/  /g, '&nbsp;').replace(/<|>/g, '&gt;').replace(/\n/g, '<br />'),
              twinContent     = $twin.html().replace(/<br>/ig,'<br />');

          if(textareaContent+'&nbsp;' != twinContent){

            // Add an extra white space so new rows are added when you are at the end of a row.
            // using .innerHTML is faster than .html()
            $twin[0].innerHTML = textareaContent + '&nbsp;';

            // reset twin's width to be the same as textarea's, this is because in IE after it copied the mimics, it changed the width to 0px so it was tall and skinny.
            $twin.width($textarea.width());
            var twinHeight = $twin.height();

            // Change textarea height if twin plus the height of one line differs more than 3 pixel from textarea height
            if(Math.abs(twinHeight + lineHeight - $textarea.height()) > 3){

              var goalheight = twinHeight + lineHeight;
              if(goalheight >= maxheight) {
                setHeightAndOverflow(maxheight,'auto');
              } else if(goalheight <= minheight) {
                setHeightAndOverflow(minheight,'hidden');
              } else {
                setHeightAndOverflow(goalheight,'hidden');
              }

              if ($.isFunction(opts.callback)) {
                opts.callback();
              }
            }
          }
        }

        $textarea
          // Hide scrollbars
          .css({'overflow':'hidden'})
          // Update textarea size on keyup
          .bind('keyup change cut paste', update)
          // And this line is to catch the browser paste event
          .bind('input paste',function(e){ setTimeout( update, 250); });

        // Run update once when elastic is initialized
        update();
      });
    }
  });
});
