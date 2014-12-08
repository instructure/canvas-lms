define(['INST', 'jquery'], function(INST, $) {
  var dummy = $('<div/>');

  function SafeString(string) {
    this.string = (typeof string === 'string' ? string : "" + string);
  }
  SafeString.prototype.toString = function() {
    return this.string;
  };

  var htmlEscape = function(str) {
    // ideally we should wrap this in a SafeString, but this is how it has
    // always worked :-/
    return dummy.text(str).html();
  }

  // Escapes HTML tags from string, or object string props of `strOrObject`.
  // returns the new string, or the object with escaped properties
  var escape = function(strOrObject) {
    if (typeof strOrObject === 'string') {
      return htmlEscape(strOrObject);
    } else if (strOrObject instanceof SafeString) {
      return strOrObject;
    }

    var k, v;
    for (k in strOrObject) {
      v = strOrObject[k];
      if (typeof v === "string") {
        strOrObject[k] = htmlEscape(v);
      }
    }
    return strOrObject;
  };
  escape.SafeString = SafeString;

  // tinymce plugins use this and they need it global :(
  INST.htmlEscape = escape;

  return escape;
});

