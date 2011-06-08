(function() {
  var $conversation_list, $conversations, $form, $message_list, $messages, $scope, $selected_conversation, MessageInbox;
  $conversations = [];
  $conversation_list = [];
  $messages = [];
  $message_list = [];
  $form = [];
  $selected_conversation = null;
  $scope = null;
  MessageInbox = {};
  I18n.scoped('conversations', function(I18n) {
    var add_conversation, build_message, close_menus, html_name_for_user, inbox_action, inbox_action_url_for, open_menu, remove_conversation, reposition_conversation, reset_message_form, select_conversation, set_conversation_state, show_message_form, update_conversation;
    show_message_form = function() {
      var newMessage;
      newMessage = !($selected_conversation != null);
      $form.find('#recipient_info').showIf(newMessage);
      $('#action_compose_message').toggleClass('active', newMessage);
      if (newMessage) {
        $form.find('.audience').html(I18n.t('headings.new_message', 'New Message'));
        $form.attr({
          action: '/messages'
        });
      } else {
        $form.find('.audience').html($selected_conversation.find('.audience').html());
        $form.attr({
          action: $selected_conversation.find('a').attr('add_url')
        });
      }
      reset_message_form();
      if (!$form.is(':visible')) {
        $form.parent().show();
        return $form.hide().slideDown('fast', function() {
          return $form.find('#recipients').focus();
        });
      }
    };
    reset_message_form = function() {
      return $form.find('input, textarea').val('');
    };
    select_conversation = function($conversation) {
      var $c;
      if ($selected_conversation && $selected_conversation.attr('id') === ($conversation != null ? $conversation.attr('id') : void 0)) {
        $selected_conversation.removeClass('inactive');
        $message_list.find('li.selected').removeClass('selected');
        return;
      }
      $message_list.hide().html('');
      if ($selected_conversation) {
        $selected_conversation.removeClass('selected inactive');
        if ($scope === 'unread') {
          $selected_conversation.fadeOut('fast', function() {
            $(this).remove();
            return $('#no_messages').showIf(!$conversation_list.find('li').length);
          });
        }
        $selected_conversation = null;
      }
      if ($conversation) {
        $selected_conversation = $conversation.addClass('selected');
      }
      if ($selected_conversation || $('#action_compose_message').length) {
        show_message_form();
      } else {
        $form.parent().hide();
      }
      $('#menu_actions').triggerHandler('prepare_menu');
      $('#menu_actions').toggleClass('disabled', !$('#menu_actions').parent().find('ul[style*="block"]').length);
      if ($selected_conversation) {
        location.hash = $selected_conversation.attr('id').replace('conversation_', '/messages/');
      } else {
        location.hash = '';
        return;
      }
      $form.loadingImage();
      $c = $selected_conversation;
      return $.ajaxJSON($selected_conversation.find('a').attr('href'), 'GET', {}, function(data) {
        var message, user, _i, _j, _len, _len2, _ref, _ref2;
        if ($c !== $selected_conversation) {
          return;
        }
        _ref = data.participants;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          user = _ref[_i];
          if (!MessageInbox.user_cache[user.id]) {
            MessageInbox.user_cache[user.id] = user;
            user.html_name = html_name_for_user(user);
          }
        }
        $messages.show();
        _ref2 = data.messages;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          message = _ref2[_j];
          $message_list.append(build_message(message.conversation_message));
        }
        $form.loadingImage('remove');
        $message_list.hide().slideDown('fast');
        if ($selected_conversation.hasClass('unread')) {
          return set_conversation_state($selected_conversation, 'read');
        }
      }, function() {
        return $form.loadingImage('remove');
      });
    };
    html_name_for_user = function(user) {
      var course, course_id, group, group_id, shared_contexts;
      shared_contexts = ((function() {
        var _i, _len, _ref, _results;
        _ref = user.course_ids;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          course_id = _ref[_i];
          if (course = MessageInbox.contexts.courses[course_id]) {
            _results.push(course.name);
          }
        }
        return _results;
      })()).concat((function() {
        var _i, _len, _ref, _results;
        _ref = user.group_ids;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          group_id = _ref[_i];
          if (group = MessageInbox.contexts.groups[group_id]) {
            _results.push(group.name);
          }
        }
        return _results;
      })());
      return $.htmlEscape(user.name) + (shared_contexts.length ? " <em>" + $.htmlEscape(shared_contexts.join(", ")) + "</em>" : void 0);
    };
    build_message = function(data) {
      var $message, avatar, user, _ref;
      $message = $("#message_blank").clone(true).attr('id', 'message_' + data.id);
      user = MessageInbox.user_cache[data.author_id];
      if (avatar = user != null ? user.avatar : void 0) {
        $message.prepend($('<img />').attr('src', avatar).addClass('avatar'));
      }
      if (user) {
                if ((_ref = user.html_name) != null) {
          _ref;
        } else {
          user.html_name = html_name_for_user(user);
        };
      }
      $message.find('.audience').html((user != null ? user.html_name : void 0) || I18n.t('unknown_user', 'Unknown user'));
      $message.find('span.date').text($.parseFromISO(data.created_at).datetime_formatted);
      $message.find('p').text(data.body);
      return $message;
    };
    inbox_action_url_for = function($action) {
      return $.replaceTags($action.attr('href'), 'id', $selected_conversation.attr('id').replace('conversation_', ''));
    };
    inbox_action = function($action, options) {
      var defaults, _ref;
      defaults = {
        loading_node: $selected_conversation,
        url: inbox_action_url_for($action),
        method: 'POST',
        data: {}
      };
      options = $.extend(defaults, options);
      if (typeof options.before === "function") {
        options.before(options.loading_node);
      }
      if ((_ref = options.loading_node) != null) {
        _ref.loadingImage();
      }
      return $.ajaxJSON(options.url, options.method, options.data, function(data) {
        var _ref2;
        if ((_ref2 = options.loading_node) != null) {
          _ref2.loadingImage('remove');
        }
        return typeof options.success === "function" ? options.success(options.loading_node, data) : void 0;
      }, function(data) {
        var _ref2;
        if ((_ref2 = options.loading_node) != null) {
          _ref2.loadingImage('remove');
        }
        return typeof options.error === "function" ? options.error(options.loading_node, data) : void 0;
      });
    };
    add_conversation = function(data, no_move) {
      var $conversation;
      $conversation = $("#conversation_blank").clone(true).attr('id', 'conversation_' + data.id);
      if (data.avatar_url) {
        $conversation.prepend($('<img />').attr('src', data.avatar_url).addClass('avatar'));
      }
      update_conversation($conversation, data, no_move);
      return $conversation.appendTo($conversation_list).click(function(e) {
        e.preventDefault();
        return select_conversation($(this));
      });
    };
    update_conversation = function($conversation, data, no_move) {
      var $a, $p, flag, move_direction;
      $a = $conversation.find('a');
      $a.attr('href', $.replaceTags($a.attr('href'), 'id', data.id));
      $a.attr('add_url', $.replaceTags($a.attr('add_url'), 'id', data.id));
      if (data.audience) {
        $conversation.find('.audience').html(data.audience);
      }
      $conversation.find('span.date').text($.parseFromISO(data.last_message_at).datetime_formatted);
      move_direction = $conversation.data('last_message_at') < data.last_message_at ? 'up' : 'down';
      $conversation.data('last_message_at', data.last_message_at);
      $p = $conversation.find('p');
      $p.text(data.last_message);
      if (data.flags.length) {
        $p.prepend(((function() {
          var _i, _len, _ref, _results;
          _ref = data.flags;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            flag = _ref[_i];
            _results.push("<i class=\"flag_" + flag + "\"></i> ");
          }
          return _results;
        })()).join(''));
      }
      if (data['private']) {
        $conversation.addClass('private');
      }
      if (!data.subscribed) {
        $conversation.addClass('unsubscribed');
      }
      $conversation.addClass(data.workflow_state);
      if (!no_move) {
        return reposition_conversation($conversation, move_direction);
      }
    };
    reposition_conversation = function($conversation, move_direction) {
      var $dummy_conversation, $n, last_message;
      last_message = $conversation.data('last_message_at');
      $n = $conversation;
      if (move_direction === 'up') {
        while ($n.prev() && $n.prev().data('last_message_at') < last_message) {
          $n = $n.prev();
        }
      } else {
        while ($n.next() && $n.next().data('last_message_at') > last_message) {
          $n = $n.next();
        }
      }
      if ($n === $conversation) {
        return;
      }
      $dummy_conversation = $conversation.clone().insertAfter($conversation);
      $conversation.detach()[move_direction === 'up' ? 'insertBefore' : 'insertAfter']($n).animate({
        opacity: 'toggle',
        height: 'toggle'
      }, 0);
      $dummy_conversation.animate({
        opacity: 'toggle',
        height: 'toggle'
      }, 200, function() {
        return $(this).remove();
      });
      return $conversation.animate({
        opacity: 'toggle',
        height: 'toggle'
      }, 200);
    };
    remove_conversation = function($conversation) {
      select_conversation();
      return $conversation.fadeOut('fast', function() {
        $(this).remove();
        return $('#no_messages').showIf(!$conversation_list.find('li').length);
      });
    };
    set_conversation_state = function($conversation, state) {
      return $conversation.removeClass('read unread archived').addClass(state);
    };
    close_menus = function() {
      return $('#actions .menus > li').removeClass('selected');
    };
    open_menu = function($menu) {
      var $div;
      close_menus();
      if (!$menu.hasClass('disabled')) {
        $div = $menu.parent('li').addClass('selected').find('div');
        $menu.triggerHandler('prepare_menu');
        return $div.css('margin-left', '-' + ($div.width() / 2) + 'px');
      }
    };
    $.extend(window, {
      MessageInbox: MessageInbox
    });
    return $(document).ready(function() {
      var conversation, match, _i, _len, _ref;
      $conversations = $('#conversations');
      $conversation_list = $conversations.find("ul");
      $messages = $('#messages');
      $message_list = $messages.find('ul').last();
      $form = $('#create_message_form');
      $scope = $('#menu_views').attr('class');
      $form.find("textarea").elastic();
      $form.formSubmit({
        beforeSubmit: function() {
          return $(this).loadingImage();
        },
        success: function(data) {
          var $conversation;
          $(this).loadingImage('remove');
          build_message(data.message.conversation_message).prependTo($message_list).slideDown('fast');
          $conversation = $('#conversation_' + data.conversation.id);
          if ($conversation.length) {
            update_conversation($conversation, data.conversation);
          } else {
            add_conversation(data.conversation);
          }
          return reset_message_form();
        },
        error: function() {
          return $(this).loadingImage('remove');
        }
      });
      $message_list.click(function(e) {
        var $message;
        $message = $(e.target).closest('li');
        $selected_conversation.addClass('inactive');
        return $message.toggleClass('selected');
      });
      $('#action_compose_message').click(function() {
        return select_conversation();
      });
      $('#actions .menus > li > a').click(function(e) {
        e.preventDefault();
        return open_menu($(this));
      }).focus(function() {
        return open_menu($(this));
      });
      $(document).bind('mousedown', function(e) {
        if (!$(e.target).closest("span.others").find('ul').length) {
          $('span.others ul').hide();
        }
        if (!$(e.target).closest(".menus > li").length) {
          return close_menus();
        }
      });
      $('#menu_views').parent().find('li a').click(function(e) {
        close_menus();
        return $('#menu_views').text($(this).text());
      });
      $('#menu_actions').bind('prepare_menu', function() {
        var $container, $groups;
        $container = $('#menu_actions').parent().find('div');
        $container.find('ul').removeClass('first last').hide();
        $container.find('li').hide();
        if ($selected_conversation) {
          $('#action_mark_as_read').parent().showIf($selected_conversation.hasClass('unread'));
          $('#action_mark_as_unread').parent().showIf($selected_conversation.hasClass('read'));
          if ($selected_conversation.hasClass('private')) {
            $('#action_add_recipients, #action_subscribe, #action_unsubscribe').parent().hide();
          } else {
            $('#action_unsubscribe').parent().showIf(!$selected_conversation.hasClass('unsubscribed'));
            $('#action_subscribe').parent().showIf($selected_conversation.hasClass('unsubscribed'));
          }
          $('#action_forward').parent().show();
          $('#action_archive').parent().showIf($scope !== 'archived');
          $('#action_unarchive').parent().showIf($scope === 'archived');
          $('#action_delete').parent().showIf($selected_conversation.hasClass('inactive') && $message_list.find('.selected').length);
          $('#action_delete_all').parent().showIf(!$selected_conversation.hasClass('inactive') || !$message_list.find('.selected').length);
        }
        $('#action_mark_all_as_read').parent().showIf($scope === 'unread' && $conversation_list.find('.unread').length);
        $container.find('li[style*="list-item"]').parent().show();
        $groups = $container.find('ul[style*="block"]');
        if ($groups.length) {
          $($groups[0]).addClass('first');
          return $($groups[$groups.length - 1]).addClass('last');
        }
      }).parent().find('li a').click(function(e) {
        e.preventDefault();
        return close_menus();
      });
      $('#action_mark_as_read').click(function() {
        return inbox_action($(this), {
          before: function($node) {
            if ($scope !== 'unread') {
              return set_conversation_state($node, 'read');
            }
          },
          success: function($node) {
            if ($scope === 'unread') {
              return remove_conversation($node);
            }
          },
          error: function($node) {
            if ($scope !== 'unread') {
              return set_conversation_state($node('unread'));
            }
          }
        });
      });
      $('#action_mark_all_as_read').click(function() {
        return inbox_action($(this), {
          url: $(this).attr('href'),
          success: function() {
            return $conversations.fadeOut('fast', function() {
              $(this).find('li').remove();
              $(this).show();
              $('#no_messages').show();
              return select_conversation();
            });
          }
        });
      });
      $('#action_mark_as_unread').click(function() {
        return inbox_action($(this), {
          before: function($node) {
            return set_conversation_state($node, 'unread');
          },
          error: function($node) {
            return set_conversation_state($node, 'read');
          }
        });
      });
      $('#action_subscribe').click(function() {
        return inbox_action($(this), {
          method: 'PUT',
          data: {
            subscribed: 1
          },
          success: function($node) {
            return $node.removeClass('unsubscribed');
          }
        });
      });
      $('#action_unsubscribe').click(function() {
        return inbox_action($(this), {
          method: 'PUT',
          data: {
            subscribed: 0
          },
          success: function($node) {
            return $node.addClass('unsubscribed');
          }
        });
      });
      $('#action_archive, #action_unarchive').click(function() {
        return inbox_action($(this), {
          success: remove_conversation
        });
      });
      $('#action_delete_all').click(function() {
        if (confirm(I18n.t('confirm.delete_conversation', "Are you sure you want to delete your copy of this conversation? This action cannot be undone."))) {
          return inbox_action($(this), {
            method: 'DELETE',
            success: remove_conversation
          });
        }
      });
      $('#action_delete').click(function() {
        var $selected_messages, message;
        $selected_messages = $message_list.find('.selected');
        message = $selected_messages.length > 1 ? I18n.t('confirm.delete_messages', "Are you sure you want to delete your copy of these messages? This action cannot be undone.") : I18n.t('confirm.delete_message', "Are you sure you want to delete your copy of this message? This action cannot be undone.");
        if (confirm(message)) {
          $selected_messages.fadeOut('fast');
          return inbox_action($(this), {
            data: {
              remove: (function() {
                var _i, _len, _results;
                _results = [];
                for (_i = 0, _len = $selected_messages.length; _i < _len; _i++) {
                  message = $selected_messages[_i];
                  _results.push(parseInt(message.id.replace(/message_/, '')));
                }
                return _results;
              })()
            },
            success: function($node, data) {
              if ($message_list.find('li').not('.selected, .generated').length) {
                update_conversation($node, data);
                return $selected_messages.remove();
              } else {
                return remove_conversation($node);
              }
            },
            error: function() {
              return $selected_messages.show();
            }
          });
        }
      });
      $('#conversation_blank .audience, #create_message_form .audience').click(function(e) {
        var $others;
        if (($others = $(e.target).closest('span.others').find('ul')).length) {
          if (!$(e.target).closest('span.others ul').length) {
            $('span.others ul').not($others).hide();
            $others.toggle();
            $others.css('left', $others.parent().position().left);
          }
          e.preventDefault();
          return false;
        }
      });
      _ref = MessageInbox.initial_conversations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        conversation = _ref[_i];
        add_conversation(conversation, true);
      }
      if (match = location.hash.match(/^#\/messages\/(\d+)$/)) {
        return $('#conversation_' + match[1]).click();
      } else {
        return $('#action_compose_message').click();
      }
    });
  });
}).call(this);
