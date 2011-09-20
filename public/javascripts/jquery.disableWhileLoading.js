/* 
will make the element semi-transparent and disable any :inputs untill a defferred completes.
example:

$('#some_form').disableWhileLoading($.ajaxJSON(...), {buttons: ['.send_button' : 'Sending...'}});

or

var promise = $.ajaxJSON(...);
$('#form').disableWhileLoading(promise, {
  buttons: {
    '.send_button' : 'Sending...'
  }
});

*/
I18n.scoped('instructure', function(I18n) {
  $.fn.disableWhileLoading = function(deferred, options) {
    return this.each(function() {
      var opts = $.extend(true, { opacity: 0.5, buttons: ['button[type="submit"]'] }, options),
          $this            = $(this),
          dataKey          = 'disabled_' + $.guid++,
          $disabledArea    = $this.add($this.next('.ui-dialog-buttonpane')),
          $inputsToDisable = $disabledArea.find('*').andSelf().filter(':input').not(':disabled').prop('disabled', true);

      $this.spin(options);
      $disabledArea.css('opacity', function(i, currentOpacity){
        $(this).data(dataKey+'opacityBefore', this.style.opacity);
        return opts.opacity;
      });
      $.each(opts.buttons, function(selector, text) {
        //if you pass an array to $.each the first arg is indexInArray, we need second arg
        if ($.isArray(opts.buttons)){ selector = text, text = null }
        $disabledArea.find(selector).text(function(i, currentText) {
          $(this).data(dataKey, currentText);
          // if nothing was passed in as the text value or if they pass an array for opts.buttons,
          // just use a default loading... text.
          return text || I18n.t('loading', 'Loading...');
        });
      });
    
      $.when(deferred).then(function(){
        $this.spin(false); // stop spinner
        $disabledArea.css('opacity', function(){ return $(this).data(dataKey+'opacityBefore') });
        $inputsToDisable.prop('disabled', false);
        $.each(opts.buttons, function() {
          $disabledArea.find(''+this).text(function() { return $(this).data(dataKey) });
        });
      });
    
    });
  };
});