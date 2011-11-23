var $body = jQuery('body'),
    $fixtures = jQuery('#fixtures'),
    // object to store fixtures on so we don't query to dom to find them again
    fixtures = {},
    // set noCleanup to true to keep fixtures around after tests
    noCleanup = false;

function simulateClick (element){
  if (!document.createEvent){
    element.click(); // IE
    return;
  }

  var e = document.createEvent("MouseEvents");
  e.initEvent("click", true, true);
  element.dispatchEvent(e);
}

function loadFixture (fixture) {
  var path = 'fixtures/' + fixture + '.html';
  jQuery.ajax({
    async: false,
    cache: false,
    dataType: 'html',
    url: path,
    success: function (html) {
      fixtures[fixture] = jQuery('<div/>', {
        html: html,
        id: fixture
      }).appendTo($fixtures)
    },
    error: function () {
      console.error('Failed to load fixture', path);
    }
  });
}

function removeFixture (id) {
  fixtures[id].detach();
}

