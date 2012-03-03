// this is just to turn spin.js into a jquery plugin
define(['jquery', 'vendor/spin'], function($, Spinner) {
$.fn.spin = function(opts) {
  return this.each(function() {
    var $this = $(this),
        data = $this.data();

    if (data.spinner) {
      data.spinner.stop();
      delete data.spinner;
    }
    if (opts !== false) {
      var oldDisplay = $.css(this, 'display');
      // need to show() it so it knows width and height to position spinner
      $this.show();
      data.spinner = new Spinner($.extend({color: $this.css('color')}, opts)).spin(this);
      $this.css('display', oldDisplay);
    }
  });
};
});
