(function() {
  this.Template = (function() {
    function Template(name, locals) {
      this.name = name;
      this.locals = locals;
      if (this instanceof Template !== true) {
        return new Template(name, locals).toHTML();
      }
    }
    Template.prototype.toHTML = function(locals) {
      if (locals == null) {
        locals = this.locals;
      }
      return Handlebars.templates[this.name](locals);
    };
    Template.prototype.toElement = function(locals) {
      var html;
      html = this.toHTML(locals);
      return jQuery('<div/>').html(html);
    };
    return Template;
  })();
}).call(this);
