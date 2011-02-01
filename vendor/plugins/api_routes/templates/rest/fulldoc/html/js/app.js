
function fixBoxInfoHeights() {
    $('dl.box dd.r1, dl.box dd.r2').each(function() {
       $(this).prev().height($(this).height()); 
    });
}
function searchFrameLinks() {
  $('#topic_list_link').click(function() {
    toggleSearchFrame(this, relpath + 'topic_list.html');
  });

  $('#resource_list_link').click(function() {
    toggleSearchFrame(this, relpath + 'resource_list.html');
  });

  $('#file_list_link').click(function() {
    toggleSearchFrame(this, relpath + 'file_list.html');
  });
}

function toggleSearchFrame(id, link) {
  var frame = $('#search_frame');
  $('#search a').removeClass('active').addClass('inactive');
  if (frame.attr('src') == link && frame.css('display') != "none") {
    frame.slideUp(100);
    $('#search a').removeClass('active inactive');
  }
  else {
    $(id).addClass('active').removeClass('inactive');
    frame.attr('src', link).slideDown(100);
  }
}

function linkSummaries() {
  $('.summary_signature').click(function() {
    document.location = $(this).find('a').attr('href');
  });
}

$(fixBoxInfoHeights);
$(searchFrameLinks);
$(linkSummaries);
