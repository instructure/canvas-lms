(function() {
  /*
  requires:
    - js!vendor/jquery-1.6.4.js
  */  define('compiled/widget/courseList', ['compiled/widget/CustomList', 'jst/courseList/wrapper', 'jst/courseList/content'], function(CustomList, wrapper, content) {
    return {
      init: function() {
        return jQuery(function() {
          var $menu, $menuDrop, loadCourses;
          $menu = jQuery('#menu_enrollments');
          $menuDrop = $menu.closest('.menu-item-drop');
          if ($menu.length === 0) {
            return;
          }
          return jQuery.subscribe('menu/hovered', loadCourses = function(elem) {
            var autoOpen;
            if (!$(elem).find($menu).find('.customListOpen').length) {
              return;
            }
            jQuery.unsubscribe('menu/hovered', loadCourses);
            autoOpen = false;
            $menu.delegate('.customListOpen', 'click', function() {
              return autoOpen = true;
            });
            return jQuery.getJSON('/all_menu_courses', function(enrollments) {
              var courseList;
              return courseList = new CustomList('#menu_enrollments', enrollments, {
                appendTarget: '#menu_enrollments',
                autoOpen: autoOpen,
                wrapper: wrapper,
                content: content,
                onToggle: function(state) {
                  return $menuDrop.toggleClass('menuCustomListEditing', state);
                }
              });
            });
          });
        });
      }
    };
  });
}).call(this);
