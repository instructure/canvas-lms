define('helpers/loadFixture', ['vendor/jquery-1.6.4'], function(_){
  var $body = jQuery('body'),
      $fixtures = jQuery('#fixtures'),
      // object to store fixtures on so we don't query to dom to find them again
      fixtures = {},
      fixtureId = 1;

  return function(fixture) {
    var id = fixture + fixtureId++,
        path = 'fixtures/' + fixture + '.html';
    
    jQuery.ajax({
      async: false,
      cache: false,
      dataType: 'html',
      url: path,
      success: function (html) {
        fixtures[id] = jQuery('<div/>', {
          html: html,
          id: id
        }).appendTo($fixtures)
      },
      error: function () {
        console.error('Failed to load fixture', path);
      }
    });
    return fixtures[id];
  }

});
