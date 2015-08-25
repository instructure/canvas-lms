define( function(){
  // based on this solution:
  // http://stackoverflow.com/questions/7394748/whats-the-right-way-to-decode-a-string-that-has-special-html-entities-in-it

  // javascript doesn't have a clean way to HTML decode a string, so we use a
  // round trip through a textarea to do it. this seems to be a best practice,
  // as far as we can tell.

  return function(encodedString){
    var textArea = document.createElement('textarea');
    textArea.innerHTML = encodedString;
    return textArea.value;
  }
});
