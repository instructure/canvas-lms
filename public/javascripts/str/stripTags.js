define(["jquery"], function() {

  /* Make an html snippet plain text.
   *
   * Removes tags, and converts entities to their character equivalents.
   * Because it uses a detached element, it's safe to use on untrusted
   * input.
   *
   * That said, the result is NOT an html-safe string, because it only
   * does a single pass. e.g.
   *
   * "<b>hi</b> &lt;script&gt;..." -> "hi <script>..."
   */
  var $stripDiv = $("<div />");

  return function(html) {
    return $stripDiv.html(html).text();
  }

  return stripTags;
});

