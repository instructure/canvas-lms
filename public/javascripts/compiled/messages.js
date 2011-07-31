(function() {
  var $conversation_list, $conversations, $form, $message_list, $messages, $scope, $selected_conversation, MessageInbox, TokenInput, TokenSelector;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  $conversations = [];
  $conversation_list = [];
  $messages = [];
  $message_list = [];
  $form = [];
  $selected_conversation = null;
  $scope = null;
  MessageInbox = {};
  TokenInput = (function() {
    function TokenInput(node, options) {
      var type, _ref;
      this.node = node;
      this.options = options;
      this.node.data('token_input', this);
      this.fake_input = $('<div />').css('font-family', this.node.css('font-family')).insertAfter(this.node).addClass('token_input').bind('selectstart', false).click(__bind(function() {
        return this.input.focus();
      }, this));
      this.node_name = this.node.attr('name');
      this.node.removeAttr('name').hide().change(__bind(function() {
        return this.tokens.html('');
      }, this));
      this.placeholder = $('<span />');
      this.placeholder.text(this.options.placeholder);
      if (this.options.placeholder) {
        this.placeholder.appendTo(this.fake_input);
      }
      this.tokens = $('<ul />').appendTo(this.fake_input);
      this.tokens.click(__bind(function(e) {
        var $close, $token;
        if ($token = $(e.target).closest('li')) {
          $close = $(e.target).closest('a');
          if ($close.length) {
            return $token.remove();
          }
        }
      }, this));
      this.input = $('<input />').appendTo(this.fake_input).css('width', '20px').css('font-size', this.fake_input.css('font-size')).autoGrowInput({
        comfortZone: 20
      }).focus(__bind(function() {
        this.placeholder.hide();
        this.active = true;
        return this.fake_input.addClass('active');
      }, this)).blur(__bind(function() {
        this.active = false;
        return setTimeout(__bind(function() {
          var _ref;
          if (!this.active) {
            this.fake_input.removeClass('active');
            this.placeholder.showIf(this.val() === '' && !this.tokens.find('li').length);
            return (_ref = this.selector) != null ? typeof _ref.blur === "function" ? _ref.blur() : void 0 : void 0;
          }
        }, this), 50);
      }, this)).keydown(__bind(function(e) {
        return this.input_keydown(e);
      }, this)).keyup(__bind(function(e) {
        return this.input_keyup(e);
      }, this));
      if (this.options.selector) {
        type = (_ref = this.options.selector.type) != null ? _ref : TokenSelector;
        delete this.options.selector.type;
        if (this.browser = this.options.selector.browser) {
          delete this.options.selector.browser;
          $('<a class="browser">browse</a>').click(__bind(function() {
            return this.selector.browse(this.browser.data);
          }, this)).prependTo(this.fake_input);
        }
        this.selector = new type(this, this.node.attr('finder_url'), this.options.selector);
      }
      this.base_exclude = [];
      this.resize();
    }
    TokenInput.prototype.resize = function() {
      return this.fake_input.css('width', this.node.css('width'));
    };
    TokenInput.prototype.add_token = function(data) {
      var $close, $text, $token, id, text, val, _ref, _ref2, _ref3;
      if (!this.tokens.find('#' + id).length) {
        $token = $('<li />');
        val = (_ref = data != null ? data.value : void 0) != null ? _ref : this.val();
        id = 'token_' + val;
        text = (_ref2 = data != null ? data.text : void 0) != null ? _ref2 : this.val();
        $token.attr('id', id);
        $text = $('<div />');
        $text.text(text);
        $token.append($text);
        $close = $('<a />');
        $token.append($close);
        $token.append($('<input />').attr('type', 'hidden').attr('name', this.node_name + '[]').val(val));
        this.tokens.append($token);
      }
      if (!(data != null ? data.no_clear : void 0)) {
        this.val('');
      }
      this.placeholder.hide();
      return (_ref3 = this.selector) != null ? _ref3.reposition() : void 0;
    };
    TokenInput.prototype.has_token = function(data) {
      var _ref;
      return this.tokens.find('#token_' + ((_ref = data != null ? data.value : void 0) != null ? _ref : data)).length > 0;
    };
    TokenInput.prototype.remove_token = function(data) {
      var id, _ref, _ref2;
      id = 'token_' + ((_ref = data != null ? data.value : void 0) != null ? _ref : data);
      this.tokens.find('#' + id).remove();
      return (_ref2 = this.selector) != null ? _ref2.reposition() : void 0;
    };
    TokenInput.prototype.remove_last_token = function(data) {
      var _ref;
      this.tokens.find('li').last().remove();
      return (_ref = this.selector) != null ? _ref.reposition() : void 0;
    };
    TokenInput.prototype.input_keydown = function(e) {
      var _ref, _ref2, _ref3;
      this.keyup_action = false;
      if (this.selector) {
        if ((_ref = this.selector) != null ? _ref.capture_keydown(e) : void 0) {
          e.preventDefault();
          return false;
        }
      } else if ((_ref2 = (_ref3 = e.which, __indexOf.call(this.delimiters, _ref3) >= 0)) != null ? _ref2 : []) {
        this.keyup_action = this.add_token;
        e.preventDefault();
        return false;
      }
      return true;
    };
    TokenInput.prototype.token_values = function() {
      var input, _i, _len, _ref, _results;
      _ref = this.tokens.find('input');
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        input = _ref[_i];
        _results.push(input.value);
      }
      return _results;
    };
    TokenInput.prototype.input_keyup = function(e) {
      return typeof this.keyup_action === "function" ? this.keyup_action() : void 0;
    };
    TokenInput.prototype.bottom_offset = function() {
      var offset;
      offset = this.fake_input.offset();
      offset.top += this.fake_input.height() + 2;
      return offset;
    };
    TokenInput.prototype.focus = function() {
      return this.input.focus();
    };
    TokenInput.prototype.val = function(val) {
      var _ref;
      if (val != null) {
        if (val !== this.input.val()) {
          this.input.val(val).change();
          return (_ref = this.selector) != null ? _ref.reposition() : void 0;
        }
      } else {
        return this.input.val();
      }
    };
    TokenInput.prototype.caret = function() {
      var end, range, start, val;
      if (this.input[0].selectionStart != null) {
        start = this.input[0].selectionStart;
        end = this.input[0].selectionEnd;
      } else {
        val = this.val();
        range = document.selection.createRange().duplicate();
        range.moveEnd("character", val.length);
        start = range.text === "" ? val.length : val.lastIndexOf(range.text);
        range = document.selection.createRange().duplicate();
        range.moveStart("character", -val.length);
        end = range.text.length;
      }
      if (start === end) {
        return start;
      } else {
        return -1;
      }
    };
    return TokenInput;
  })();
  $.fn.tokenInput = function(options) {
    return this.each(function() {
      return new TokenInput($(this), $.extend(true, {}, options));
    });
  };
  TokenSelector = (function() {
    function TokenSelector(input, url, options) {
      this.input = input;
      this.url = url;
      this.options = options != null ? options : {};
      this.stack = [];
      this.query_cache = {};
      this.container = $('<div />').addClass('autocomplete_menu');
      this.menu = $('<div />').append(this.list = this.new_list());
      this.container.append($('<div />').append(this.menu));
      this.container.css('top', 0).css('left', 0);
      this.mode = 'input';
      $('body').append(this.container);
      this.reposition = __bind(function() {
        var offset;
        offset = this.input.bottom_offset();
        this.container.css('top', offset.top);
        return this.container.css('left', offset.left);
      }, this);
      $(window).resize(this.reposition);
      this.close();
    }
    TokenSelector.prototype.browse = function(data) {
      if (!(this.ui_locked || this.menu.is(":visible") || this.input.val())) {
        return this.fetch_list({
          data: data
        });
      }
    };
    TokenSelector.prototype.new_list = function() {
      var $list;
      $list = $('<div><ul class="heading"></ul><ul></ul></div>');
      $list.find('ul').mousemove(__bind(function(e) {
        var $li;
        if (this.ui_locked) {
          return;
        }
        $li = $(e.target).closest('li');
        if (!$li.hasClass('selectable')) {
          $li = null;
        }
        return this.select($li);
      }, this)).mousedown(__bind(function(e) {
        return setTimeout(__bind(function() {
          return this.input.focus();
        }, this), 0);
      }, this)).click(__bind(function(e) {
        var $li;
        if (this.ui_locked) {
          return;
        }
        $li = $(e.target).closest('li');
        if (!$li.hasClass('selectable')) {
          $li = null;
        }
        this.select($li);
        if (this.selection) {
          if ($(e.target).closest('a.expand').length) {
            if (this.selection_expanded()) {
              this.collapse();
            } else {
              this.expand_selection();
            }
          } else if (this.selection_toggleable() && $(e.target).closest('a.toggle').length) {
            this.toggle_selection();
          } else if (!this.selection.hasClass('expanded')) {
            this.toggle_selection(true);
            this.clear();
            this.close();
          }
        }
        return this.input.focus();
      }, this));
      return $list;
    };
    TokenSelector.prototype.capture_keydown = function(e) {
      var _ref, _ref2;
      if (this.ui_locked) {
        return true;
      }
      switch ((_ref = (_ref2 = e.originalEvent) != null ? _ref2.keyIdentifier : void 0) != null ? _ref : e.which) {
        case 'Backspace':
        case 'U+0008':
        case 8:
          if (this.input.val() === '') {
            if (this.list_expanded()) {
              this.collapse();
            } else {
              this.input.remove_last_token();
            }
            return true;
          }
          break;
        case 'Tab':
        case 'U+0009':
        case 9:
          if (this.selection && !this.selection.hasClass('expanded')) {
            this.toggle_selection(true);
          }
          this.clear();
          this.close();
          if (this.selection) {
            return true;
          }
          break;
        case 'Enter':
        case 13:
          if (this.selection && !this.selection.hasClass('expanded')) {
            this.toggle_selection(true);
            this.clear();
          }
          this.close();
          return true;
        case 'Shift':
        case 16:
          return false;
        case 'Esc':
        case 'U+001B':
        case 27:
          if (this.menu.is(":visible")) {
            this.close();
            return true;
          } else {
            return false;
          }
          break;
        case 'U+0020':
        case 32:
          if (this.selection_toggleable() && this.mode === 'menu') {
            this.toggle_selection();
            return true;
          }
          break;
        case 'Left':
        case 37:
          if (this.list_expanded() && this.input.caret() === 0) {
            if (this.selection_expanded() || this.input.val() === '') {
              this.collapse();
            } else {
              this.select(this.list.find('li').first());
            }
            return true;
          }
          break;
        case 'Up':
        case 38:
          this.select_prev();
          return true;
        case 'Right':
        case 39:
          if (this.input.caret() === this.input.val().length && this.expand_selection()) {
            return true;
          }
          break;
        case 'Down':
        case 40:
          this.select_next();
          return true;
        case 'U+002B':
        case 187:
        case 107:
          if (this.selection_toggleable() && this.mode === 'menu') {
            this.toggle_selection(true);
            return true;
          }
          break;
        case 'U+002D':
        case 189:
        case 109:
          if (this.selection_toggleable() && this.mode === 'menu') {
            this.toggle_selection(false);
            return true;
          }
      }
      this.mode = 'input';
      this.fetch_list();
      return false;
    };
    TokenSelector.prototype.fetch_list = function(options, ui_locked) {
      if (options == null) {
        options = {};
      }
      this.ui_locked = ui_locked != null ? ui_locked : false;
      if (this.timeout != null) {
        clearTimeout(this.timeout);
      }
      return this.timeout = setTimeout(__bind(function() {
        var post_data, this_query, _ref;
        delete this.timeout;
        post_data = this.prepare_post((_ref = options.data) != null ? _ref : {});
        this_query = JSON.stringify(post_data);
        if (this_query === this.last_applied_query) {
          this.ui_locked = false;
          return;
        } else if (this.query_cache[this_query]) {
          this.last_applied_query = this_query;
          this.last_search = post_data.search;
          this.render_list(this.query_cache[this_query], options);
          return;
        }
        if (post_data.search === '' && !this.list_expanded() && !options.data) {
          return this.render_list([]);
        }
        return $.ajaxJSON(this.url, 'POST', $.extend({}, post_data), __bind(function(data) {
          var _ref2;
          this.query_cache[this_query] = data;
          if (JSON.stringify(this.prepare_post((_ref2 = options.data) != null ? _ref2 : {})) === this_query) {
            this.last_applied_query = this_query;
            this.last_search = post_data.search;
            return this.render_list(data, options);
          } else {
            return this.ui_locked = false;
          }
        }, this), __bind(function(data) {
          return this.ui_locked = false;
        }, this));
      }, this), 100);
    };
    TokenSelector.prototype.open = function() {
      this.container.show();
      return this.reposition();
    };
    TokenSelector.prototype.close = function() {
      var $list, $selection, i, query, search, _len, _ref, _ref2;
      this.ui_locked = false;
      this.container.hide();
      delete this.last_applied_query;
      _ref = this.stack;
      for (i = 0, _len = _ref.length; i < _len; i++) {
        _ref2 = _ref[i], $selection = _ref2[0], $list = _ref2[1], query = _ref2[2], search = _ref2[3];
        this.list.remove();
        this.list = $list.css('height', 'auto');
      }
      this.stack = [];
      this.menu.css('left', 0);
      return this.select(null);
    };
    TokenSelector.prototype.clear = function() {
      return this.input.val('');
    };
    TokenSelector.prototype.blur = function() {
      return this.close();
    };
    TokenSelector.prototype.list_expanded = function() {
      if (this.stack.length) {
        return true;
      } else {
        return false;
      }
    };
    TokenSelector.prototype.selection_expanded = function() {
      var _ref, _ref2;
      return (_ref = (_ref2 = this.selection) != null ? _ref2.hasClass('expanded') : void 0) != null ? _ref : false;
    };
    TokenSelector.prototype.selection_expandable = function() {
      var _ref, _ref2;
      return (_ref = (_ref2 = this.selection) != null ? _ref2.hasClass('expandable') : void 0) != null ? _ref : false;
    };
    TokenSelector.prototype.selection_toggleable = function() {
      var _ref, _ref2;
      return (_ref = (_ref2 = this.selection) != null ? _ref2.hasClass('toggleable') : void 0) != null ? _ref : false;
    };
    TokenSelector.prototype.expand_selection = function() {
      if (!(this.selection_expandable() && !this.selection_expanded())) {
        return false;
      }
      this.stack.push([this.selection, this.list, this.last_applied_query, this.last_search]);
      this.clear();
      this.menu.css('width', ((this.stack.length + 1) * 100) + '%');
      return this.fetch_list({
        expand: true
      }, true);
    };
    TokenSelector.prototype.collapse = function() {
      var $list, $selection, _ref;
      if (!this.list_expanded()) {
        return false;
      }
      _ref = this.stack.pop(), $selection = _ref[0], $list = _ref[1], this.last_applied_query = _ref[2], this.last_search = _ref[3];
      this.ui_locked = true;
      $list.css('height', 'auto');
      return this.menu.animate({
        left: '+=' + this.menu.parent().css('width')
      }, 'fast', __bind(function() {
        this.input.val(this.last_search);
        this.list.remove();
        this.list = $list;
        this.select($selection);
        return this.ui_locked = false;
      }, this));
    };
    TokenSelector.prototype.toggle_selection = function(state) {
      var id;
      if (!((state != null) || this.selection_toggleable())) {
        return false;
      }
      id = this.selection.data('id');
      if (state == null) {
        state = !this.input.has_token({
          value: id
        });
      }
      if (state) {
        if (this.selection_toggleable()) {
          this.selection.addClass('on');
        }
        return this.input.add_token({
          value: id,
          text: this.selection.find('b').text(),
          no_clear: true
        });
      } else {
        this.selection.removeClass('on');
        return this.input.remove_token({
          value: id
        });
      }
    };
    TokenSelector.prototype.select = function($node, preserve_mode) {
      var _ref, _ref2;
      if (preserve_mode == null) {
        preserve_mode = false;
      }
      if (($node != null ? $node[0] : void 0) === ((_ref = this.selection) != null ? _ref[0] : void 0)) {
        return;
      }
      if ((_ref2 = this.selection) != null) {
        _ref2.removeClass('active');
      }
      this.selection = ($node != null ? $node.length : void 0) ? ($node.addClass('active'), $node.scrollIntoView({
        ignore: {
          border: true
        }
      }), $node) : null;
      if (!preserve_mode) {
        return this.mode = ($node ? 'menu' : 'input');
      }
    };
    TokenSelector.prototype.select_next = function(preserve_mode) {
      if (preserve_mode == null) {
        preserve_mode = false;
      }
      return this.select(this.selection ? this.selection.next().length ? this.selection.next() : this.selection.parent('ul').next().length ? this.selection.parent('ul').next().find('li').first() : null : this.list.find('li:first'), preserve_mode);
    };
    TokenSelector.prototype.select_prev = function() {
      var _ref;
      return this.select(this.selection ? ((_ref = this.selection) != null ? _ref.prev().length : void 0) ? this.selection.prev() : this.selection.parent('ul').prev().length ? this.selection.parent('ul').prev().find('li').last() : null : this.list.find('li:last'));
    };
    TokenSelector.prototype.populate_row = function($node, data, options) {
      if (options == null) {
        options = {};
      }
      if (this.options.populator) {
        this.options.populator($node, data, options);
      } else {
        $node.data('id', data.text);
        $node.text(data.text);
      }
      if (options.first) {
        $node.addClass('first');
      }
      if (options.last) {
        return $node.addClass('last');
      }
    };
    TokenSelector.prototype.render_list = function(data, options) {
      var $body, $heading, $li, $list, $message, $uls, i, row, _len, _ref, _ref2;
      if (options == null) {
        options = {};
      }
      if (data.length || this.list_expanded()) {
        this.open();
      } else {
        this.ui_locked = false;
        this.close();
        return;
      }
      if (options.expand) {
        $list = this.new_list();
      } else {
        $list = this.list;
      }
      this.selection = null;
      $uls = $list.find('ul');
      $uls.html('');
      $heading = $uls.first();
      $body = $uls.last();
      if (data.length) {
        for (i = 0, _len = data.length; i < _len; i++) {
          row = data[i];
          $li = $('<li />').addClass('selectable');
          this.populate_row($li, row, {
            level: this.stack.length,
            first: i === 0,
            last: i === data.length - 1
          });
          if ($li.hasClass('toggleable') && this.input.has_token($li.data('id'))) {
            $li.addClass('on');
          }
          $body.append($li);
        }
      } else {
        $message = $('<li class="message first last"></li>');
        $message.text((_ref = (_ref2 = this.options.messages) != null ? _ref2.no_results : void 0) != null ? _ref : '');
        $body.append($message);
      }
      if (this.list_expanded()) {
        $li = this.stack[this.stack.length - 1][0].clone();
        $li.addClass('expanded').removeClass('active first last');
        $heading.append($li).show();
      } else {
        $heading.hide();
      }
      if (options.expand) {
        $list.insertAfter(this.list);
        return this.menu.animate({
          left: '-=' + this.menu.parent().css('width')
        }, 'fast', __bind(function() {
          this.list.animate({
            height: '1px'
          }, 'fast', __bind(function() {
            return this.ui_locked = false;
          }, this));
          this.list = $list;
          return this.select_next(true);
        }, this));
      } else {
        this.select_next(true);
        return this.ui_locked = false;
      }
    };
    TokenSelector.prototype.prepare_post = function(data) {
      var post_data, _base, _ref;
      post_data = $.extend(data, {
        search: this.input.val()
      });
      post_data.exclude = this.input.base_exclude.concat(this.stack.length ? [] : this.input.token_values());
      if (this.list_expanded()) {
        post_data.context = this.stack[this.stack.length - 1][0].data('id');
      }
            if ((_ref = post_data.limit) != null) {
        _ref;
      } else {
        post_data.limit = typeof (_base = this.options).limiter === "function" ? _base.limiter({
          level: this.stack.length
        }) : void 0;
      };
      return post_data;
    };
    return TokenSelector;
  })();
  $.fn.scrollIntoView = function(options) {
    var $container, containerBottom, containerTop, elemBottom, elemTop, _ref;
    if (options == null) {
      options = {};
    }
    $container = this.offsetParent();
    containerTop = $container.scrollTop();
    containerBottom = containerTop + $container.height();
    elemTop = this[0].offsetTop;
    elemBottom = elemTop + $(this[0]).outerHeight();
    if ((_ref = options.ignore) != null ? _ref.border : void 0) {
      elemTop += parseInt($(this[0]).css('border-top-width').replace('px', ''));
      elemBottom -= parseInt($(this[0]).css('border-bottom-width').replace('px', ''));
    }
    if (elemTop < containerTop) {
      return $container.scrollTop(elemTop);
    } else if (elemBottom > containerBottom) {
      return $container.scrollTop(elemBottom - $container.height());
    }
  };
  I18n.scoped('conversations', function(I18n) {
    var add_conversation, build_message, close_menus, html_name_for_user, inbox_action, inbox_action_url_for, is_selected, open_menu, parse_query_string, remove_conversation, reposition_conversation, reset_message_form, select_conversation, set_conversation_state, show_message_form, update_conversation;
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
          return $form.find(':input:visible:first').focus();
        });
      }
    };
    reset_message_form = function() {
      if ($selected_conversation != null) {
        $form.find('.audience').html($selected_conversation.find('.audience').html());
      }
      return $form.find('input, textarea').val('').change();
    };
    parse_query_string = function(query_string) {
      var hash, key, parts, value, _i, _len, _ref, _ref2;
      if (query_string == null) {
        query_string = window.location.search.substr(1);
      }
      hash = {};
      _ref = query_string.split(/\&/);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        parts = _ref[_i];
        _ref2 = parts.split(/\=/, 2), key = _ref2[0], value = _ref2[1];
        hash[decodeURIComponent(key)] = decodeURIComponent(value);
      }
      return hash;
    };
    is_selected = function($conversation) {
      return $selected_conversation && $selected_conversation.attr('id') === ($conversation != null ? $conversation.attr('id') : void 0);
    };
    select_conversation = function($conversation) {
      var $c, match, params;
      if (is_selected($conversation)) {
        $selected_conversation.removeClass('inactive');
        $message_list.find('li.selected').removeClass('selected');
        return;
      }
      $message_list.removeClass('private').hide().html('');
      if ($conversation != null ? $conversation.hasClass('private') : void 0) {
        $message_list.addClass('private');
      }
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
        location.hash = '/messages/' + $selected_conversation.data('id');
      } else {
        if (match = location.hash.match(/^#\/messages\?(.*)$/)) {
          params = parse_query_string(match[1]);
          if (params.user_id && params.user_name && params.from_conversation_id) {
            $('#recipients').data('token_input').add_token({
              value: params.user_id,
              text: params.user_name
            });
            $('#from_conversation_id').val(params.from_conversation_id);
          }
        }
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
    MessageInbox.shared_contexts_for_user = function(user) {
      var course, course_id, group, group_id, shared_contexts;
      shared_contexts = ((function() {
        var _i, _len, _ref, _results;
        _ref = user.course_ids;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          course_id = _ref[_i];
          if (course = this.contexts.courses[course_id]) {
            _results.push(course.name);
          }
        }
        return _results;
      }).call(this)).concat((function() {
        var _i, _len, _ref, _results;
        _ref = user.group_ids;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          group_id = _ref[_i];
          if (group = this.contexts.groups[group_id]) {
            _results.push(group.name);
          }
        }
        return _results;
      }).call(this));
      return shared_contexts.join(", ");
    };
    html_name_for_user = function(user) {
      var shared_contexts;
      shared_contexts = MessageInbox.shared_contexts_for_user(user);
      return $.htmlEscape(user.name) + (shared_contexts.length ? " <em>" + $.htmlEscape(shared_contexts) + "</em>" : '');
    };
    build_message = function(data) {
      var $message, $pm_action, avatar, pm_url, user, user_name, _ref, _ref2;
      $message = $("#message_blank").clone(true).attr('id', 'message_' + data.id);
      if (data.author_id !== MessageInbox.user_id) {
        $message.addClass('other');
      }
      if (data.generated) {
        $message.addClass('generated');
      }
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
      user_name = (_ref2 = user != null ? user.name : void 0) != null ? _ref2 : I18n.t('unknown_user', 'Unknown user');
      $message.find('.audience').html((user != null ? user.html_name : void 0) || $.h(user_name));
      $message.find('span.date').text($.parseFromISO(data.created_at).datetime_formatted);
      $message.find('p').text(data.body);
      $pm_action = $message.find('a.send_private_message');
      pm_url = $.replaceTags($pm_action.attr('href'), 'user_id', data.author_id);
      pm_url = $.replaceTags(pm_url, 'user_name', encodeURIComponent(user_name));
      pm_url = $.replaceTags(pm_url, 'from_conversation_id', $selected_conversation.data('id'));
      $pm_action.attr('href', pm_url).click(__bind(function() {
        return setTimeout(__bind(function() {
          return select_conversation();
        }, this));
      }, this));
      return $message;
    };
    inbox_action_url_for = function($action) {
      return $.replaceTags($action.attr('href'), 'id', $selected_conversation.data('id'));
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
    add_conversation = function(data, append) {
      var $conversation;
      $conversation = $("#conversation_blank").clone(true).attr('id', 'conversation_' + data.id);
      $conversation.data('id', data.id);
      if (data.avatar_url) {
        $conversation.prepend($('<img />').attr('src', data.avatar_url).addClass('avatar'));
      }
      $conversation[append ? 'appendTo' : 'prependTo']($conversation_list).click(function(e) {
        e.preventDefault();
        return select_conversation($(this));
      });
      update_conversation($conversation, data, true);
      if (!append) {
        $conversation.hide().slideDown('fast');
      }
      return $conversation;
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
      move_direction = $conversation.data('last_message_at') > data.last_message_at ? 'down' : 'up';
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
      $form.submit(function(e) {
        var valid;
        valid = !!($form.find('#body').val() && ($form.find('#recipient_info').filter(':visible').length === 0 || $form.find('.token_input li').length > 0));
        if (!valid) {
          e.stopImmediatePropagation();
        }
        return valid;
      });
      $form.formSubmit({
        beforeSubmit: function() {
          return $(this).loadingImage();
        },
        success: function(data) {
          var $conversation;
          $(this).loadingImage('remove');
          $conversation = $('#conversation_' + data.conversation.id);
          if ($conversation.length) {
            update_conversation($conversation, data.conversation);
            if (is_selected($conversation)) {
              build_message(data.message.conversation_message).prependTo($message_list).slideDown('fast');
            }
          } else {
            select_conversation(add_conversation(data.conversation));
          }
          return reset_message_form();
        },
        error: function(data) {
          $form.find('.token_input').errorBox(I18n.t('recipient_error', 'The course or group you have selected has no valid recipients'));
          $('.error_box').filter(':visible').css('z-index', 10);
          return $(this).loadingImage('remove');
        }
      });
      $('#add_recipients_form').submit(function(e) {
        var valid;
        valid = !!($(this).find('.token_input li').length);
        if (!valid) {
          e.stopImmediatePropagation();
        }
        return valid;
      });
      $('#add_recipients_form').formSubmit({
        beforeSubmit: function() {
          return $(this).loadingImage();
        },
        success: function(data) {
          $(this).loadingImage('remove');
          build_message(data.message.conversation_message).prependTo($message_list).slideDown('fast');
          update_conversation($selected_conversation, data.conversation);
          reset_message_form();
          return $(this).dialog('close');
        },
        error: function(data) {
          $(this).loadingImage('remove');
          return $(this).dialog('close');
        }
      });
      $message_list.click(function(e) {
        var $message;
        $message = $(e.target).closest('li');
        if (!$message.hasClass('generated')) {
          if ($selected_conversation != null) {
            $selected_conversation.addClass('inactive');
          }
          return $message.toggleClass('selected');
        }
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
            $('#action_add_recipients').parent().show();
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
      $('#action_add_recipients').click(function() {
        return $('#add_recipients_form').attr('action', inbox_action_url_for($(this))).dialog('close').dialog({
          width: 400,
          open: function() {
            var node, token_input;
            token_input = $('#add_recipients').data('token_input');
            token_input.base_exclude = (function() {
              var _i, _len, _ref, _results;
              _ref = $selected_conversation.find('.participant');
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                node = _ref[_i];
                _results.push($(node).data('id'));
              }
              return _results;
            })();
            token_input.resize();
            return $(this).find("input").val('').change().last().focus();
          },
          close: function() {
            return $('#add_recipients').data('token_input').input.blur();
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
      $('.recipients').tokenInput({
        placeholder: I18n.t('recipient_field_placeholder', "Enter a name, email, course, or group"),
        selector: {
          messages: {
            no_results: I18n.t('no_results', 'No results found')
          },
          populator: function($node, data, options) {
            var $b, $img, $span;
            if (options == null) {
              options = {};
            }
            if (data.avatar) {
              $img = $('<img />');
              $img.attr('src', data.avatar);
              $node.append($img);
            }
            $b = $('<b />');
            $b.text(data.name);
            $span = $('<span />');
            if (data.course_ids != null) {
              $span.text(MessageInbox.shared_contexts_for_user(data));
            }
            $node.append($b, $span);
            $node.data('id', data.id);
            if (options.level > 0) {
              $node.prepend('<a class="toggle"><i></i></a>');
              $node.addClass('toggleable');
            }
            if (data.type === 'context') {
              $node.prepend('<a class="expand"><i></i></a>');
              return $node.addClass('expandable');
            }
          },
          limiter: function(options) {
            if (options.level > 0) {
              return -1;
            }
          },
          browser: {
            data: {
              limit: -1,
              type: 'context'
            }
          }
        }
      });
      $('#recipients').data('token_input').fake_input.css('width', '100%');
      if (match = location.hash.match(/^#\/messages\/(\d+)$/)) {
        return $('#conversation_' + match[1]).click();
      } else {
        return $('#action_compose_message').click();
      }
    });
  });
}).call(this);
