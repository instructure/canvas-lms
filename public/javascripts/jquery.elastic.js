/**
*	@name							Elastic
*	@descripton						Elastic is Jquery plugin that grow and shrink your textareas automaticliy
*	@version						1.6.4
*	@requires						Jquery 1.2.6+
*
*	@author							Jan Jarfalk
*	@author-email					jan.jarfalk@unwrongest.com
*	@author-website					http://www.unwrongest.com
*
*	@licens							MIT License - http://www.opensource.org/licenses/mit-license.php
*/

(function(jQuery){ 
	jQuery.fn.extend({  
		elastic: function(options) {
		  var opts = jQuery.extend({}, options);
		
			//	We will create a div clone of the textarea
			//	by copying these attributes from the textarea to the div.
			var mimics = [
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
				'fontWeight'];
			
			return this.each( function() {
				
				// Elastic only works on textareas
				if ( this.type != 'textarea' ) {
					return false;
				}
				
				var $textarea	=	jQuery(this),
					$twin		=	jQuery('<div />').css({'position': 'absolute','display':'none','word-wrap':'break-word'}),
					lineHeight	=	parseInt($textarea.css('line-height'),10) || parseInt($textarea.css('font-size'),'10'),
					minheight	=	parseInt($textarea.css('height'),10) || lineHeight*3,
					maxheight	=	parseInt($textarea.css('max-height'),10) || Number.MAX_VALUE,
					goalheight	=	0,
					i 			=	0;
				
				// Opera returns max-height of -1 if not set
				if (maxheight < 0) { maxheight = Number.MAX_VALUE; }
					
				// Append the twin to the DOM
				// We are going to meassure the height of this, not the textarea.
				$twin.appendTo($textarea.parent());
				
				// Copy the essential styles (mimics) from the textarea to the twin
				var i = mimics.length;
				while(i--){
					$twin.css(mimics[i].toString(),$textarea.css(mimics[i].toString()));
				}				
				
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
					var textareaContent = $textarea.val().replace(/&/g,'&amp;').replace(/  /g, '&nbsp;').replace(/<|>/g, '&gt;').replace(/\n/g, '<br />');

					var twinContent = $twin.html();
					
					if(textareaContent+'&nbsp;' != twinContent){
					
						// Add an extra white space so new rows are added when you are at the end of a row.
            // using .innerHTML is faster than .html()
						$twin[0].innerHTML = textareaContent + '&nbsp;';
						
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
				
				// Hide scrollbars
				$textarea.css({'overflow':'hidden'});
				
				// Update textarea size on keyup
				$textarea.keyup(update);
				
				// And this line is to catch the browser paste event
				$textarea.live('input paste',function(e){ setTimeout( update, 250); });				
				
				// Run update once when elastic is initialized
				update();
				
			});		
    } 
  }); 
})(jQuery);