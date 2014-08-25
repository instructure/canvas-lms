define(['jquery', 'str/htmlEscape', 'jqueryui/dialog-unpatched'], function($, h, returnValOfUnpatchedDialog) {
  
  // have UI dialogs default to modal:true
  $.ui.dialog.prototype.options.modal = true

  // based on d209434 and 83639ec, htmlEscape string titles by default, and
  // support jquery object titles
  function fixTitle(title) {
    if (!title) return title;
    return title.jquery ?
      $('<div />').append(title.eq(0).clone()).html() :
      h('' + title);
  }

  var create = $.ui.dialog.prototype._create,
      setOption = $.ui.dialog.prototype._setOption;

  $.extend($.ui.dialog.prototype, {
    _create: function() {
      if (!this.options.title) {
        this.options.title = this.element.attr("title");
        if (typeof this.options.title !== "string")
          this.options.title = '';
      }
      this.options.title = fixTitle(this.options.title);
      this._on({
        dialogopen: function() {
          $('#application').attr('aria-hidden', 'true');
        },
        dialogclose: function() {
          $('#application').attr('aria-hidden', 'false');
        }
      });
      return create.apply(this, arguments);
    },

    _setOption: function(key, value) {
      if (key == "title") value = fixTitle(value);
      return setOption.call(this, key, value);
    }
  });

  return returnValOfUnpatchedDialog;

});
