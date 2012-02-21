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
define([
  'i18n!instructure',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'vendor/jquery.spin' /* /\.spin/ */
], function(I18n, $) {

  $.fn.disableWhileLoading = function(deferred, options) {
    return this.each(function() {
      var opts = $.extend(true, {}, $.fn.disableWhileLoading.defaults, options),
          $this            = $(this),
          dataKey          = 'disabled_' + $.guid++,
          $disabledArea    = $this.add($this.next('.ui-dialog-buttonpane')),
          $inputsToDisable = $disabledArea.find('*').andSelf().filter(':input').not(':disabled').prop('disabled', true),
          $foundSpinHolder = $this.find('.spin_holder'),
          $spinHolder = $foundSpinHolder.length ? $foundSpinHolder : $this,
          previousSpinHolderDisplay = $spinHolder.css('display');

      $spinHolder.show().spin(options);
      $disabledArea.css('opacity', function(i, currentOpacity){
        $(this).data(dataKey+'opacityBefore', this.style.opacity);
        return opts.opacity;
      });
      $.each(opts.buttons, function(selector, text) {
        //if you pass an array to $.each the first arg is indexInArray, we need second arg
        if ($.isArray(opts.buttons)){ selector = text, text = null }
        $disabledArea.find(selector).text(function(i, currentText) {
          $(this).data(dataKey, currentText);
          return text || 
                 $(this).data('textWhileLoading') || 
                 ( $(this).is('.ui-button-text') && $(this).closest('.ui-button').data('textWhileLoading') ) || 
                 // if nothing was passed in as the text value or if they pass an array for opts.buttons,
                 // just use a default loading... text.
                 I18n.t('loading', 'Loading...');
        });
      });
    
      $.when(deferred).always(function(){
        $spinHolder.css('display', previousSpinHolderDisplay).spin(false); // stop spinner
        $disabledArea.css('opacity', function(){ return $(this).data(dataKey+'opacityBefore') });
        $inputsToDisable.prop('disabled', false);
        $.each(opts.buttons, function() {
          $disabledArea.find(''+this).text(function() { return $(this).data(dataKey) });
        });
      });
    
    });
  };
  $.fn.disableWhileLoading.defaults = { 
    opacity: 0.5, 
    buttons: ['button[type="submit"], .ui-dialog-buttonpane .ui-button .ui-button-text'] 
  };
});
