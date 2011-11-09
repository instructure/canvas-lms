(function() {
  var $conversation_list, $conversations, $form, $last_label, $message_list, $messages, $selected_conversation, MessageInbox, TokenInput, TokenSelector, page;
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
  $last_label = null;
  page = {};
  MessageInbox = {};
  TokenInput = (function() {
    function TokenInput(node, options) {
      var type, _ref;
      this.node = node;
      this.options = options;
      this.node.data('token_input', this);
      this.fake_input = $('<div />').css('font-family', this.node.css('font-family')).insertAfter(this.node).addClass('token_input').click(__bind(function() {
        return this.input.focus();
      }, this));
      this.node_name = this.node.attr('name');
      this.node.removeAttr('name').hide().change(__bind(function() {
        this.tokens.html('');
        return typeof this.change === "function" ? this.change(this.token_values()) : void 0;
      }, this));
      this.added = this.options.added;
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
            $token.remove();
            return typeof this.change === "function" ? this.change(this.token_values()) : void 0;
          }
        }
      }, this));
      this.tokens.maxTokenWidth = __bind(function() {
        return (parseInt(this.tokens.css('width').replace('px', '')) - 150) + 'px';
      }, this);
      this.tokens.resizeTokens = __bind(function(tokens) {
        return tokens.find('div.ellipsis').css('max-width', this.tokens.maxTokenWidth());
      }, this);
      $(window).resize(__bind(function() {
        return this.tokens.resizeTokens(this.tokens);
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
            if (this.selector.browse(this.browser.data)) {
              return this.fake_input.addClass('browse');
            }
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
      var $close, $text, $token, id, new_token, text, val, _ref, _ref2, _ref3;
      val = (_ref = data != null ? data.value : void 0) != null ? _ref : this.val();
      id = 'token_' + val;
      $token = this.tokens.find('#' + id);
      new_token = $token.length === 0;
      if (new_token) {
        $token = $('<li />');
        text = (_ref2 = data != null ? data.text : void 0) != null ? _ref2 : this.val();
        $token.attr('id', id);
        $text = $('<div />').addClass('ellipsis');
        $text.attr('title', text);
        $text.text(text);
        $token.append($text);
        $close = $('<a />');
        $token.append($close);
        $token.append($('<input />').attr('type', 'hidden').attr('name', this.node_name + '[]').val(val));
        this.tokens.resizeTokens($token);
        this.tokens.append($token);
      }
      if (!(data != null ? data.no_clear : void 0)) {
        this.val('');
      }
      this.placeholder.hide();
      if (data) {
        if (typeof this.added === "function") {
          this.added(data.data, $token, new_token);
        }
      }
      if (typeof this.change === "function") {
        this.change(this.token_values());
      }
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
      if (typeof this.change === "function") {
        this.change(this.token_values());
      }
      return (_ref2 = this.selector) != null ? _ref2.reposition() : void 0;
    };
    TokenInput.prototype.remove_last_token = function(data) {
      var _ref;
      this.tokens.find('li').last().remove();
      if (typeof this.change === "function") {
        this.change(this.token_values());
      }
      return (_ref = this.selector) != null ? _ref.reposition() : void 0;
    };
    TokenInput.prototype.input_keydown = function(e) {
      var _ref, _ref2, _ref3;
      this.keyup_action = false;
      if (this.selector) {
        if ((_ref = this.selector) != null ? _ref.capture_keydown(e) : void 0) {
          e.preventDefault();
          return false;
        } else {
          this.fake_input.removeClass('browse');
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
    TokenInput.prototype.selector_closed = function() {
      return this.fake_input.removeClass('browse');
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
      if (!this.ui_locked) {
        this.input.val('');
        this.close();
        this.fetch_list({
          data: data
        });
        return true;
      }
    };
    TokenSelector.prototype.new_list = function() {
      var $list;
      $list = $('<div class="list"><ul class="heading"></ul><ul></ul></div>');
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
          } else {
            if (this.selection_expanded()) {
              this.collapse();
            } else if (this.selection_expandable()) {
              this.expand_selection();
            } else {
              this.toggle_selection(true);
              this.clear();
              this.close();
            }
          }
        }
        return this.input.focus();
      }, this));
      $list.body = $list.find('ul').last();
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
            } else if (this.menu.is(":visible")) {
              this.close();
            } else {
              this.input.remove_last_token();
            }
            return true;
          }
          break;
        case 'Tab':
        case 'U+0009':
        case 9:
          if (this.selection && (this.selection_toggleable() || !this.selection_expandable())) {
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
          if (this.selection_expanded()) {
            this.collapse();
            return true;
          } else if (this.selection_expandable() && !this.selection_toggleable()) {
            this.expand_selection();
            return true;
          } else if (this.selection) {
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
        if (post_data.search === '' && !this.list_expanded() && !options.data) {
          this.ui_locked = false;
          this.close();
          return;
        }
        if (this_query === this.last_applied_query) {
          this.ui_locked = false;
          return;
        } else if (this.query_cache[this_query]) {
          this.last_applied_query = this_query;
          this.last_search = post_data.search;
          this.clear_loading();
          this.render_list(this.query_cache[this_query], options, post_data);
          return;
        }
        this.set_loading();
        return $.ajaxJSON(this.url, 'POST', $.extend({}, post_data), __bind(function(data) {
          var _ref2;
          this.query_cache[this_query] = data;
          this.clear_loading();
          if (JSON.stringify(this.prepare_post((_ref2 = options.data) != null ? _ref2 : {})) === this_query) {
            this.last_applied_query = this_query;
            this.last_search = post_data.search;
            if (this.menu.is(":visible")) {
              return this.render_list(data, options, post_data);
            }
          } else {
            return this.ui_locked = false;
          }
        }, this), __bind(function(data) {
          this.ui_locked = false;
          return this.clear_loading();
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
      this.list.find('ul').html('');
      this.stack = [];
      this.menu.css('left', 0);
      this.select(null);
      return this.input.selector_closed();
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
    TokenSelector.prototype.selection_toggleable = function($node) {
      var _ref;
      if ($node == null) {
        $node = this.selection;
      }
      return ((_ref = $node != null ? $node.hasClass('toggleable') : void 0) != null ? _ref : false) && !this.selection_expanded();
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
    TokenSelector.prototype.toggle_selection = function(state, $node, toggle_only) {
      var id, _ref;
      if ($node == null) {
        $node = this.selection;
      }
      if (toggle_only == null) {
        toggle_only = false;
      }
      if (!((state != null) || this.selection_toggleable($node))) {
        return false;
      }
      id = $node.data('id');
      if (state == null) {
        state = !$node.hasClass('on');
      }
      if (state) {
        if (this.selection_toggleable($node) && !toggle_only) {
          $node.addClass('on');
        }
        this.input.add_token({
          value: id,
          text: (_ref = $node.data('text')) != null ? _ref : $node.text(),
          no_clear: true,
          data: $node.data('user_data')
        });
      } else {
        if (!toggle_only) {
          $node.removeClass('on');
        }
        this.input.remove_token({
          value: id
        });
      }
      if (!toggle_only) {
        return this.update_select_all($node);
      }
    };
    TokenSelector.prototype.update_select_all = function($node, offset) {
      var $list, $nodes, $on_nodes, $parent_node, $select_all, select_all_toggled;
      if (offset == null) {
        offset = 0;
      }
      select_all_toggled = $node.data('user_data').select_all;
      $list = offset ? this.stack[this.stack.length - offset][1] : this.list;
      $select_all = $list.select_all;
      if (!$select_all) {
        return;
      }
      $nodes = $list.body.find('li.toggleable').not($select_all);
      if (select_all_toggled) {
        if ($select_all.hasClass('on')) {
          $nodes.addClass('on').each(__bind(function(i, node) {
            return this.toggle_selection(false, $(node), true);
          }, this));
        } else {
          $nodes.removeClass('on').each(__bind(function(i, node) {
            return this.toggle_selection(false, $(node), true);
          }, this));
        }
      } else {
        $on_nodes = $nodes.filter('.on');
        if ($on_nodes.length < $nodes.length && $select_all.hasClass('on')) {
          $select_all.removeClass('on');
          this.toggle_selection(false, $select_all, true);
          $on_nodes.each(__bind(function(i, node) {
            return this.toggle_selection(true, $(node), true);
          }, this));
        } else if ($on_nodes.length === $nodes.length && !$select_all.hasClass('on')) {
          $select_all.addClass('on');
          this.toggle_selection(true, $select_all, true);
          $on_nodes.each(__bind(function(i, node) {
            return this.toggle_selection(false, $(node), true);
          }, this));
        }
      }
      if (offset < this.stack.length) {
        offset++;
        $parent_node = this.stack[this.stack.length - offset][0];
        if (this.selection_toggleable($parent_node)) {
          if ($select_all.hasClass('on')) {
            $parent_node.addClass('on');
          } else {
            $parent_node.removeClass('on');
          }
          return this.update_select_all($parent_node, offset);
        }
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
      var _ref;
      if (preserve_mode == null) {
        preserve_mode = false;
      }
      this.select(this.selection ? this.selection.next().length ? this.selection.next() : this.selection.parent('ul').next().length ? this.selection.parent('ul').next().find('li').first() : null : this.list.find('li:first'), preserve_mode);
      if ((_ref = this.selection) != null ? _ref.hasClass('message') : void 0) {
        return this.select_next(preserve_mode);
      }
    };
    TokenSelector.prototype.select_prev = function() {
      var _ref, _ref2;
      this.select(this.selection ? ((_ref = this.selection) != null ? _ref.prev().length : void 0) ? this.selection.prev() : this.selection.parent('ul').prev().length ? this.selection.parent('ul').prev().find('li').last() : null : this.list.find('li:last'));
      if ((_ref2 = this.selection) != null ? _ref2.hasClass('message') : void 0) {
        return this.select_prev();
      }
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
    TokenSelector.prototype.set_loading = function() {
      if (!this.menu.is(":visible")) {
        this.open();
        this.list.find('ul').last().append($('<li class="message first last"></li>'));
      }
      return this.list.find('li').first().loadingImage();
    };
    TokenSelector.prototype.clear_loading = function() {
      return this.list.find('li').first().loadingImage('remove');
    };
    TokenSelector.prototype.render_list = function(data, options, post_data) {
      var $body, $heading, $li, $list, $message, $uls, i, parent, row, _base, _base2, _len, _ref, _ref2, _ref3;
      if (options == null) {
        options = {};
      }
      if (post_data == null) {
        post_data = {};
      }
      this.open();
      if (options.expand) {
        $list = this.new_list();
      } else {
        $list = this.list;
      }
      $list.select_all = null;
      this.selection = null;
      $uls = $list.find('ul');
      $uls.html('');
      $heading = $uls.first();
      $body = $uls.last();
      if (data.length) {
        parent = this.stack.length ? this.stack[this.stack.length - 1][0] : null;
        if (!data.prepared) {
          if (typeof (_base = this.options).preparer === "function") {
            _base.preparer(post_data, data, parent);
          }
          data.prepared = true;
        }
        for (i = 0, _len = data.length; i < _len; i++) {
          row = data[i];
          $li = $('<li />').addClass('selectable');
          this.populate_row($li, row, {
            level: this.stack.length,
            first: i === 0,
            last: i === data.length - 1,
            parent: parent
          });
          if (row.select_all) {
            $list.select_all = $li;
          }
          if ($li.hasClass('toggleable') && this.input.has_token($li.data('id'))) {
            $li.addClass('on');
          }
          $body.append($li);
        }
        if (((_ref = $list.select_all) != null ? typeof _ref.hasClass === "function" ? _ref.hasClass('on') : void 0 : void 0) || this.stack.length && (typeof (_base2 = this.stack[this.stack.length - 1][0]).hasClass === "function" ? _base2.hasClass('on') : void 0)) {
          $list.body.find('li.toggleable').addClass('on');
        }
      } else {
        $message = $('<li class="message first last"></li>');
        $message.text((_ref2 = (_ref3 = this.options.messages) != null ? _ref3.no_results : void 0) != null ? _ref2 : '');
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
        if (!options.loading) {
          this.select_next(true);
        }
        return this.ui_locked = false;
      }
    };
    TokenSelector.prototype.prepare_post = function(data) {
      var post_data, _base, _ref, _ref2;
      post_data = $.extend(data, {
        search: this.input.val()
      }, (_ref = this.options.base_data) != null ? _ref : {});
      post_data.exclude = this.input.base_exclude.concat(this.stack.length ? [] : this.input.token_values());
      if (this.list_expanded()) {
        post_data.context = this.stack[this.stack.length - 1][0].data('id');
      }
      if ((_ref2 = post_data.per_page) == null) {
        post_data.per_page = typeof (_base = this.options).limiter === "function" ? _base.limiter({
          level: this.stack.length
        }) : void 0;
      }
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
    var add_conversation, build_attachment, build_media_object, build_message, build_submission, build_submission_comment, can_add_notes_for, close_menus, formatted_message, html_audience_for_conversation, html_name_for_user, inbox_action, inbox_action_url_for, inbox_resize, is_selected, open_conversation_menu, open_menu, parse_query_string, remove_conversation, reposition_conversation, reset_message_form, select_conversation, select_unloaded_conversation, set_conversation_state, set_hash, set_last_label, show_message_form, toggle_message_actions, update_conversation;
    show_message_form = function() {
      var newMessage;
      newMessage = !($selected_conversation != null);
      $form.find('#recipient_info').showIf(newMessage);
      $form.find('#group_conversation_info').hide();
      $('#action_compose_message').toggleClass('active', newMessage);
      if (newMessage) {
        $form.find('.audience').html(I18n.t('headings.new_message', 'New Message'));
        $form.addClass('new');
        $form.find('#action_add_recipients').hide();
        $form.attr({
          action: '/conversations'
        });
      } else {
        $form.find('.audience').html($selected_conversation.find('.audience').html());
        $form.removeClass('new');
        $form.find('#action_add_recipients').showIf(!$selected_conversation.hasClass('private'));
        $form.attr({
          action: $selected_conversation.find('a.details_link').attr('add_url')
        });
      }
      reset_message_form();
      $form.find('#user_note_info').hide().find('input').attr('checked', false);
      return $form.show().find(':input:visible:first').focus();
    };
    reset_message_form = function() {
      if ($selected_conversation != null) {
        $form.find('.audience').html($selected_conversation.find('.audience').html());
      }
      $form.find('input[name!=authenticity_token], textarea').val('').change();
      $form.find(".attachment:visible").remove();
      $form.find(".media_comment").hide();
      $form.find("#action_media_comment").show();
      return inbox_resize();
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
    select_unloaded_conversation = function(conversation_id, params) {
      return $.ajaxJSON('/conversations/' + conversation_id, 'GET', {}, function(data) {
        add_conversation(data.conversation, true);
        $("#conversation_" + conversation_id).hide();
        return select_conversation($("#conversation_" + conversation_id), $.extend(params, {
          data: data
        }));
      });
    };
    select_conversation = function($conversation, params) {
      var $c, completion;
      if (params == null) {
        params = {};
      }
      toggle_message_actions(false);
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
        if (MessageInbox.scope === 'unread') {
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
        if (params.message) {
          $form.find('#body').val(params.message);
        }
      } else {
        $form.parent().hide();
      }
      if ($selected_conversation) {
        $selected_conversation.scrollIntoView();
      } else {
        if (params.user_id && params.user_name) {
          $('#recipients').data('token_input').add_token({
            value: params.user_id,
            text: params.user_name,
            data: {
              id: params.user_id,
              name: params.user_name,
              can_add_notes: params.can_add_notes
            }
          });
          $('#from_conversation_id').val(params.from_conversation_id);
        }
        return;
      }
      $form.loadingImage();
      $c = $selected_conversation;
      completion = function(data) {
        var i, j, message, submission, user, _i, _len, _ref, _ref2;
        if (!is_selected($c)) {
          return;
        }
        _ref = data.participants;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          user = _ref[_i];
          if (!((_ref2 = MessageInbox.user_cache[user.id]) != null ? _ref2.avatar_url : void 0)) {
            MessageInbox.user_cache[user.id] = user;
            user.html_name = html_name_for_user(user);
          }
        }
        if (data['private'] && (user = ((function() {
          var _j, _len2, _ref3, _results;
          _ref3 = data.participants;
          _results = [];
          for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
            user = _ref3[_j];
            if (user.id !== MessageInbox.user_id) {
              _results.push(user);
            }
          }
          return _results;
        })())[0] && can_add_notes_for(user))) {
          $form.find('#user_note_info').show();
        }
        inbox_resize();
        $messages.show();
        i = j = 0;
        message = data.messages[0];
        submission = data.submissions[0];
        while (message || submission) {
          if (message && (!submission || $.parseFromISO(message.created_at).datetime > $.parseFromISO(submission.updated_at).datetime)) {
            $message_list.append(build_message(message));
            message = data.messages[++i];
          } else {
            $message_list.append(build_submission(submission));
            submission = data.submissions[++j];
          }
        }
        $form.loadingImage('remove');
        $message_list.hide().slideDown('fast');
        if ($selected_conversation.hasClass('unread')) {
          return set_conversation_state($selected_conversation, 'read');
        }
      };
      if (params.data) {
        return completion(params.data);
      } else {
        return $.ajaxJSON($selected_conversation.find('a.details_link').attr('href'), 'GET', {}, function(data) {
          return completion(data);
        }, function() {
          return $form.loadingImage('remove');
        });
      }
    };
    MessageInbox.context_list = function(contexts, limit) {
      var course, course_id, group, group_id, roles, shared_contexts;
      if (limit == null) {
        limit = 2;
      }
      shared_contexts = ((function() {
        var _ref, _results;
        _ref = contexts.courses;
        _results = [];
        for (course_id in _ref) {
          roles = _ref[course_id];
          if (course = this.contexts.courses[course_id]) {
            _results.push(course.name);
          }
        }
        return _results;
      }).call(this)).concat((function() {
        var _ref, _results;
        _ref = contexts.groups;
        _results = [];
        for (group_id in _ref) {
          roles = _ref[group_id];
          if (group = this.contexts.groups[group_id]) {
            _results.push(group.name);
          }
        }
        return _results;
      }).call(this));
      return $.toSentence(shared_contexts.sort(function(a, b) {
        a = a.toLowerCase();
        b = b.toLowerCase();
        if (a < b) {
          return -1;
        } else if (a > b) {
          return 1;
        } else {
          return 0;
        }
      }).slice(0, limit));
    };
    html_name_for_user = function(user, contexts) {
      var _ref, _ref2;
      if (contexts == null) {
        contexts = {
          courses: user.common_courses,
          groups: user.common_groups
        };
      }
      return $.h(user.name) + (((_ref = contexts.courses) != null ? _ref.length : void 0) || ((_ref2 = contexts.groups) != null ? _ref2.length : void 0) ? " <em>" + $.h(MessageInbox.context_list(contexts)) + "</em>" : '');
    };
    can_add_notes_for = function(user) {
      var course_id, roles, _ref, _ref2;
      if (!MessageInbox.notes_enabled) {
        return false;
      }
      if (user.can_add_notes) {
        return true;
      }
      _ref = user.common_courses;
      for (course_id in _ref) {
        roles = _ref[course_id];
        if (__indexOf.call(roles, 'StudentEnrollment') >= 0 && (MessageInbox.can_add_notes_for_account || ((_ref2 = MessageInbox.contexts.courses[course_id]) != null ? _ref2.can_add_notes : void 0))) {
          return true;
        }
      }
      return false;
    };
    formatted_message = function(message) {
      var idx, line, link_placeholder, link_re, links, placeholder_blocks, processed_lines, quote_block, quote_clump, quotes_added, _ref;
      link_placeholder = "LINK_PLACEHOLDER";
      link_re = /\b((?:https?:\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))|(LINK_PLACEHOLDER)/gi;
      links = [];
      placeholder_blocks = [];
      message = message.replace(link_re, function(match, i) {
        var link;
        placeholder_blocks.push(match === link_placeholder ? link_placeholder : (link = match, link.slice(0, 4) === 'www' ? link = "http://" + link : void 0, link = encodeURI(link).replace(/'/g, '%27'), links.push(link), "<a href='" + ($.h(link)) + "'>" + ($.h(match)) + "</a>"));
        return link_placeholder;
      });
      message = $.h(message);
      message = message.replace(new RegExp(link_placeholder, 'g'), function(match, i) {
        return placeholder_blocks.shift();
      });
      message = message.replace(/\n/g, '<br />\n');
      processed_lines = [];
      quote_block = [];
      quotes_added = 0;
      quote_clump = function(lines) {
        quotes_added += 1;
        return "<div class='quoted_text_holder'>        <a href='#' class='show_quoted_text_link'>" + (I18n.t("quoted_text_toggle", "show quoted text")) + "</a>        <div class='quoted_text' style='display: none;'>          " + (lines.join("\n")) + "        </div>      </div>";
      };
      _ref = message.split("\n");
      for (idx in _ref) {
        line = _ref[idx];
        if (line.match(/^(&gt;|>)/)) {
          quote_block.push(line);
        } else {
          if (quote_block.length) {
            processed_lines.push(quote_clump(quote_block));
          }
          quote_block = [];
          processed_lines.push(line);
        }
      }
      if (quote_block.length) {
        processed_lines.push(quote_clump(quote_block));
      }
      return message = processed_lines.join("\n");
    };
    build_message = function(data) {
      var $attachment_blank, $media_object_blank, $message, $pm_action, $ul, attachment, avatar, pm_url, submessage, user, user_name, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      $message = $("#message_blank").clone(true).attr('id', 'message_' + data.id);
      $message.data('id', data.id);
      $message.addClass(data.generated ? 'generated' : data.author_id === MessageInbox.user_id ? 'self' : 'other');
      user = MessageInbox.user_cache[data.author_id];
      if (avatar = user != null ? user.avatar_url : void 0) {
        $message.prepend($('<img />').attr('src', avatar).addClass('avatar'));
      }
      if (user) {
        if ((_ref = user.html_name) == null) {
          user.html_name = html_name_for_user(user);
        }
      }
      user_name = (_ref2 = user != null ? user.name : void 0) != null ? _ref2 : I18n.t('unknown_user', 'Unknown user');
      $message.find('.audience').html((user != null ? user.html_name : void 0) || $.h(user_name));
      $message.find('span.date').text($.parseFromISO(data.created_at).datetime_formatted);
      $message.find('p').html(formatted_message(data.body));
      $message.find("a.show_quoted_text_link").click(function(event) {
        var $text;
        $text = $(this).parents(".quoted_text_holder").children(".quoted_text");
        if ($text.length) {
          event.stopPropagation();
          event.preventDefault();
          $text.show();
          return $(this).hide();
        }
      });
      $pm_action = $message.find('a.send_private_message');
      pm_url = $.replaceTags($pm_action.attr('href'), {
        user_id: data.author_id,
        user_name: encodeURIComponent(user_name),
        from_conversation_id: $selected_conversation.data('id')
      });
      $pm_action.attr('href', pm_url).click(function(e) {
        return e.stopPropagation();
      });
      if ((_ref3 = data.forwarded_messages) != null ? _ref3.length : void 0) {
        $ul = $('<ul class="messages"></ul>');
        _ref4 = data.forwarded_messages;
        for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
          submessage = _ref4[_i];
          $ul.append(build_message(submessage));
        }
        $message.append($ul);
      }
      $ul = $message.find('ul.message_attachments').detach();
      $media_object_blank = $ul.find('.media_object_blank').detach();
      $attachment_blank = $ul.find('.attachment_blank').detach();
      if ((data.media_comment != null) || ((_ref5 = data.attachments) != null ? _ref5.length : void 0)) {
        $message.append($ul);
        if (data.media_comment != null) {
          $ul.append(build_media_object($media_object_blank, data.media_comment));
        }
        if (data.attachments != null) {
          _ref6 = data.attachments;
          for (_j = 0, _len2 = _ref6.length; _j < _len2; _j++) {
            attachment = _ref6[_j];
            $ul.append(build_attachment($attachment_blank, attachment));
          }
        }
      }
      return $message;
    };
    build_media_object = function(blank, data) {
      var $media_object;
      $media_object = blank.clone(true).attr('id', 'media_comment_' + data.media_id);
      $media_object.find('span.title').html($.h(data.display_name));
      $media_object.find('span.media_comment_id').html($.h(data.media_id));
      return $media_object;
    };
    build_attachment = function(blank, data) {
      var $attachment, $link;
      $attachment = blank.clone(true).attr('id', 'attachment_' + data.id);
      $attachment.data('id', data.id);
      $attachment.find('span.title').html($.h(data.display_name));
      $link = $attachment.find('a');
      $link.attr('href', data.url);
      $link.click(function(e) {
        return e.stopPropagation();
      });
      return $attachment;
    };
    build_submission = function(data) {
      var $comment_blank, $header, $inline_more, $more_link, $submission, $ul, comment, href, index, initially_shown, score, user, user_name, _i, _len, _ref, _ref2, _ref3, _ref4;
      $submission = $("#submission_blank").clone(true).attr('id', 'submission_' + data.id);
      $submission.data('id', data.id);
      $ul = $submission.find('ul');
      $header = $ul.find('li.header');
      href = $.replaceTags($header.find('a').attr('href'), {
        course_id: data.course_id,
        assignment_id: data.assignment_id,
        id: data.author_id
      });
      $header.find('a').attr('href', href);
      user = MessageInbox.user_cache[data.author_id];
      if (user) {
        if ((_ref = user.html_name) == null) {
          user.html_name = html_name_for_user(user);
        }
      }
      user_name = (_ref2 = user != null ? user.name : void 0) != null ? _ref2 : I18n.t('unknown_user', 'Unknown user');
      $header.find('.title').html($.h(data.title));
      if (data.created_at) {
        $header.find('span.date').text($.parseFromISO(data.created_at).datetime_formatted);
      }
      $header.find('.audience').html((user != null ? user.html_name : void 0) || $.h(user_name));
      score = (_ref3 = data.score) != null ? _ref3 : I18n.t('not_scored', 'no score');
      $header.find('.score').html(score);
      $comment_blank = $ul.find('.comment').detach();
      index = 0;
      initially_shown = 4;
      _ref4 = data.recent_comments;
      for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
        comment = _ref4[_i];
        index++;
        comment = build_submission_comment($comment_blank, comment);
        if (index > initially_shown) {
          comment.hide();
        }
        $ul.append(comment);
      }
      $more_link = $ul.find('.more').detach();
      if (data.recent_comments.length > initially_shown) {
        $inline_more = $more_link.clone(true);
        $inline_more.find('.hidden').text(data.comment_count - initially_shown);
        $inline_more.attr('title', $.h(I18n.t('titles.expand_inline', "Show more comments")));
        $inline_more.click(function() {
          var submission;
          submission = $(this).closest('.submission');
          submission.find('.more:hidden').show();
          $(this).hide();
          submission.find('.comment:hidden').slideDown('fast');
          inbox_resize();
          return false;
        });
        $ul.append($inline_more);
      }
      if (data.comment_count > data.recent_comments.length) {
        $more_link.find('a').attr('href', href).attr('target', '_blank');
        $more_link.find('.hidden').text(data.comment_count - data.recent_comments.length);
        $more_link.attr('title', $.h(I18n.t('titles.view_submission', "Open submission in new window.")));
        if (data.recent_comments.length > initially_shown) {
          $more_link.hide();
        }
        $ul.append($more_link);
      }
      return $submission;
    };
    build_submission_comment = function(blank, data) {
      var $comment, avatar, user, user_name, _ref, _ref2;
      $comment = blank.clone(true).attr('id', 'submission_comment_' + data.id);
      $comment.data('id', data.id);
      user = MessageInbox.user_cache[data.author_id];
      if (avatar = user != null ? user.avatar_url : void 0) {
        $comment.prepend($('<img />').attr('src', avatar).addClass('avatar'));
      }
      if (user) {
        if ((_ref = user.html_name) == null) {
          user.html_name = html_name_for_user(user);
        }
      }
      user_name = (_ref2 = user != null ? user.name : void 0) != null ? _ref2 : I18n.t('unknown_user', 'Unknown user');
      $comment.find('.audience').html((user != null ? user.html_name : void 0) || $.h(user_name));
      $comment.find('span.date').text($.parseFromISO(data.created_at).datetime_formatted);
      $comment.find('p').html($.h(data.body).replace(/\n/g, '<br />'));
      return $comment;
    };
    inbox_action_url_for = function($action, $conversation) {
      return $.replaceTags($action.attr('href'), 'id', $conversation.data('id'));
    };
    inbox_action = function($action, options) {
      var $loading_node, defaults, _ref, _ref2, _ref3;
      $loading_node = (_ref = options.loading_node) != null ? _ref : $action.closest('ul.conversations li');
      if (!$loading_node.length) {
        $loading_node = $('#conversation_actions').data('selected_conversation');
      }
      defaults = {
        loading_node: $loading_node,
        url: inbox_action_url_for($action, $loading_node),
        method: 'POST',
        data: {}
      };
      options = $.extend(defaults, options);
      if (!((_ref2 = typeof options.before === "function" ? options.before(options.loading_node, options) : void 0) != null ? _ref2 : true)) {
        return;
      }
      if ((_ref3 = options.loading_node) != null) {
        _ref3.loadingImage();
      }
      return $.ajaxJSON(options.url, options.method, options.data, function(data) {
        var _ref4;
        if ((_ref4 = options.loading_node) != null) {
          _ref4.loadingImage('remove');
        }
        return typeof options.success === "function" ? options.success(options.loading_node, data) : void 0;
      }, function(data) {
        var _ref4;
        if ((_ref4 = options.loading_node) != null) {
          _ref4.loadingImage('remove');
        }
        return typeof options.error === "function" ? options.error(options.loading_node, data) : void 0;
      });
    };
    add_conversation = function(data, append) {
      var $conversation;
      $('#no_messages').hide();
      $conversation = $("#conversation_" + data.id);
      if ($conversation.length) {
        $conversation.show();
      } else {
        $conversation = $("#conversation_blank").clone(true).attr('id', 'conversation_' + data.id);
      }
      $conversation.data('id', data.id);
      if (data.avatar_url) {
        $conversation.prepend($('<img />').attr('src', data.avatar_url).addClass('avatar'));
      }
      $conversation[append ? 'appendTo' : 'prependTo']($conversation_list).click(function(e) {
        e.preventDefault();
        return set_hash('#/conversations/' + $(this).data('id'));
      });
      update_conversation($conversation, data, null);
      if (!append) {
        $conversation.hide().slideDown('fast');
      }
      $conversation_list.append($("#conversations_loader"));
      return $conversation;
    };
    html_audience_for_conversation = function(conversation, cutoff) {
      var audience, context_info, id, id_or_array;
      if (cutoff == null) {
        cutoff = 2;
      }
      audience = conversation.audience;
      if (audience.length === 0) {
        return "<span>" + ($.h(I18n.t('notes_to_self', 'Monologue'))) + "</span>";
      }
      context_info = "<em>" + ($.h(MessageInbox.context_list(conversation.audience_contexts))) + "</em>";
      if (audience.length === 1) {
        return "<span>" + ($.h(MessageInbox.user_cache[audience[0]].name)) + "</span> " + context_info;
      }
      if (audience.length > cutoff) {
        audience = audience.slice(0, cutoff).concat([audience.slice(cutoff, audience.length)]);
      }
      return $.toSentence((function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = audience.length; _i < _len; _i++) {
          id_or_array = audience[_i];
          _results.push(typeof id_or_array === 'number' ? "<span>" + ($.h(MessageInbox.user_cache[id_or_array].name)) + "</span>" : "<span class='others'>\n  " + ($.h(I18n.t('other_recipients', "other", {
            count: id_or_array.length
          }))) + "\n  <span>\n    <ul>\n      " + (((function() {
            var _j, _len2, _results2;
            _results2 = [];
            for (_j = 0, _len2 = id_or_array.length; _j < _len2; _j++) {
              id = id_or_array[_j];
              _results2.push("<li>" + ($.h(MessageInbox.user_cache[id].name)) + "</li>");
            }
            return _results2;
          })()).join('')) + "\n    </ul>\n  </span>\n</span>");
        }
        return _results;
      })()) + " " + context_info;
    };
    update_conversation = function($conversation, data, move_mode) {
      var $a, $p, move_direction, property, user, _i, _j, _len, _len2, _ref, _ref2;
      if (move_mode == null) {
        move_mode = 'slide';
      }
      toggle_message_actions(false);
      $a = $conversation.find('a.details_link');
      $a.attr('href', $.replaceTags($a.attr('href'), 'id', data.id));
      $a.attr('add_url', $.replaceTags($a.attr('add_url'), 'id', data.id));
      if (data.participants) {
        _ref = data.participants;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          user = _ref[_i];
          if (!MessageInbox.user_cache[user.id]) {
            MessageInbox.user_cache[user.id] = user;
          }
        }
      }
      if (data.audience) {
        $conversation.data('audience', data.audience.concat([MessageInbox.user_id]));
        $conversation.find('.audience').html(html_audience_for_conversation(data));
      }
      $conversation.find('.actions a').click(function(e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        close_menus();
        return open_conversation_menu($(this));
      }).focus(function() {
        close_menus();
        return open_conversation_menu($(this));
      });
      if (data.message_count != null) {
        $conversation.find('.count').text(data.message_count);
        $conversation.find('.count').showIf(data.message_count > 1);
      }
      $conversation.find('span.date').text($.friendlyDatetime($.parseFromISO(data.last_message_at).datetime));
      move_direction = $conversation.data('last_message_at') > data.last_message_at ? 'down' : 'up';
      $conversation.data('last_message_at', data.last_message_at);
      $conversation.data('label', data.label);
      $p = $conversation.find('p');
      $p.text(data.last_message);
      if (data.properties.length) {
        _ref2 = data.properties;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          property = _ref2[_j];
          $conversation.addClass(property);
        }
      }
      if (data['private']) {
        $conversation.addClass('private');
      }
      if (data['label']) {
        $conversation.addClass('labeled').addClass(data['label']);
      }
      if (!data.subscribed) {
        $conversation.addClass('unsubscribed');
      }
      set_conversation_state($conversation, data.workflow_state);
      if (move_mode) {
        return reposition_conversation($conversation, move_direction, move_mode);
      }
    };
    reposition_conversation = function($conversation, move_direction, move_mode) {
      var $dummy_conversation, $n, last_message;
      $conversation.show();
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
      if (move_mode === 'immediate') {
        return $conversation.detach()[move_direction === 'up' ? 'insertBefore' : 'insertAfter']($n).scrollIntoView();
      } else {
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
        }, 200, function() {
          return $conversation.scrollIntoView();
        });
      }
    };
    remove_conversation = function($conversation) {
      var deselect;
      deselect = is_selected($conversation);
      return $conversation.fadeOut('fast', function() {
        $(this).remove();
        $('#no_messages').showIf(!$conversation_list.find('li').length);
        if (deselect) {
          return set_hash('');
        }
      });
    };
    set_conversation_state = function($conversation, state) {
      return $conversation.removeClass('read unread archived').addClass(state);
    };
    $('#conversations').delegate('.actions a', 'blur', function(e) {
      return $(window).one('keyup', function(e) {
        if (e.shiftKey) {
          return close_menus();
        }
      });
    });
    open_conversation_menu = function($node) {
      var $container, $conversation, elements, offset;
      elements = {
        node: $node,
        container: $('#conversation_actions'),
        conversation: $node.closest('li'),
        parent: $node.parent(),
        lists: $('#conversation_actions ul'),
        listElements: $('#conversation_actions li'),
        focusable: $('a, input, select, textarea'),
        actions: {
          markAsRead: $('#action_mark_as_read').parent(),
          markAsUnread: $('#action_mark_as_unread').parent(),
          unsubscribe: $('#action_unsubscribe').parent(),
          subscribe: $('#action_subscribe').parent(),
          forward: $('#action_forward').parent(),
          archive: $('#action_archive').parent(),
          unarchive: $('#action_unarchive').parent(),
          "delete": $('#action_delete').parent(),
          deleteAll: $('#action_delete_all').parent()
        },
        labels: {
          group: $('#conversation_actions .label_group'),
          icon: $('#conversation_actions .label_icon')
        }
      };
      page.activeActionMenu = elements.node;
      elements.parent.addClass('selected');
      elements.container.addClass('selected');
      elements.conversation.addClass('menu_active');
      $container = elements.container;
      $conversation = elements.conversation;
      elements.container.data('selected_conversation', elements.conversation);
      elements.lists.removeClass('first last').hide();
      elements.listElements.hide();
      if (elements.conversation.hasClass('unread')) {
        elements.actions.markAsRead.show();
      }
      if (elements.conversation.hasClass('read')) {
        elements.actions.markAsUnread.show();
      }
      elements.labels.group.show();
      elements.labels.icon.removeClass('checked');
      elements.container.find('.label_icon.' + ($conversation.data('label') || 'none')).addClass('checked');
      if (elements.conversation.hasClass('private')) {
        elements.actions.subscribe.hide();
        elements.actions.unsubscribe.hide();
      } else {
        if (!elements.conversation.hasClass('unsubscribed')) {
          elements.actions.unsubscribe.show();
        }
        if (elements.conversation.hasClass('unsubscribed')) {
          elements.actions.subscribe.show();
        }
      }
      elements.actions.forward.show();
      elements.actions["delete"].show();
      elements.actions.deleteAll.show();
      if (MessageInbox.scope === 'archived') {
        elements.actions.unarchive.show();
      } else {
        elements.actions.archive.show();
      }
      $(window).one('keydown', function(e) {
        if (e.keyCode !== 9 || e.shiftKey) {
          return;
        }
        return elements.focusable.one('focus.actions_menu', function(e) {
          page.nextElement = $(e.target);
          elements.focusable.unbind('.actions_menu');
          elements.container.find('a:visible:first').focus();
          elements.container.find('a:visible:first').bind('blur.actions_menu', e, function() {
            return $(window).one('keyup', function(e) {
              var actionMenuActive;
              actionMenuActive = elements.container.find('a:focus').length;
              if (!actionMenuActive) {
                elements.container.find('a.visible').unbind('.actions_menu');
                return page.activeActionMenu.focus();
              }
            });
          });
          return elements.container.find('a:visible:last').bind('blur.actions_menu', e, function() {
            return $(window).one('keyup', function(e) {
              var actionMenuActive;
              actionMenuActive = elements.container.find('a:focus').length;
              if (!actionMenuActive) {
                elements.container.find('a.visible').unbind('.actions_menu');
                page.nextElement.focus();
                return close_menus();
              }
            });
          });
        });
      });
      elements.container.find('li[style*="list-item"]').parent().show();
      elements.groups = elements.container.find('ul[style*="block"]');
      if (elements.groups.length) {
        elements.groups.first().addClass('first');
        elements.groups.last().addClass('last');
      }
      offset = elements.node.offset();
      return elements.container.css({
        left: offset.left + (elements.node.width() / 2) - elements.container.offsetParent().offset().left - (elements.container.width() / 2),
        top: offset.top + (elements.node.height() * 0.9) - elements.container.offsetParent().offset().top
      });
    };
    close_menus = function() {
      $('#actions .menus > li, #conversation_actions, #conversations .actions').removeClass('selected');
      return $('#conversations li.menu_active').removeClass('menu_active');
    };
    open_menu = function($menu) {
      var $div, offset;
      close_menus();
      if (!$menu.hasClass('disabled')) {
        $div = $menu.parent('li, span').addClass('selected').find('div');
        offset = -($div.parent().position().left + $div.parent().outerWidth() / 2) + 6;
        if (offset < -($div.outerWidth() / 2)) {
          offset = -($div.outerWidth() / 2);
        }
        return $div.css('margin-left', offset + 'px');
      }
    };
    inbox_resize = function() {
      var available_height;
      available_height = $(window).height() - $('#header').outerHeight(true) - ($('#wrapper-container').outerHeight(true) - $('#wrapper-container').height()) - ($('#main').outerHeight(true) - $('#main').height()) - $('#breadcrumbs').outerHeight(true) - $('#footer').outerHeight(true);
      if (available_height < 425) {
        available_height = 425;
      }
      $('#inbox').height(available_height);
      $message_list.height(available_height - $form.outerHeight(true));
      return $conversation_list.height(available_height - $('#actions').outerHeight(true));
    };
    toggle_message_actions = function(state) {
      if (state != null) {
        $message_list.find('> li').removeClass('selected');
        $message_list.find('> li :checkbox').attr('checked', false);
      } else {
        state = !!$message_list.find('li.selected').length;
      }
      if (state) {
        $("#message_actions").slideDown(100);
      } else {
        $("#message_actions").slideUp(100);
      }
      return $form[state ? 'addClass' : 'removeClass']('disabled');
    };
    set_last_label = function(label) {
      $conversation_list.removeClass('red orange yellow green blue purple').addClass(label);
      $.cookie('last_label', label);
      return $last_label = label;
    };
    set_hash = function(hash) {
      if (hash !== location.hash) {
        location.hash = hash;
        return $(document).triggerHandler('document_fragment_change', hash);
      }
    };
    $.extend(window, {
      MessageInbox: MessageInbox
    });
    return $(document).ready(function() {
      var $add_form, $forward_form, conversation, nextAttachmentIndex, token_input, _i, _len, _ref, _ref2;
      $conversations = $('#conversations');
      $conversation_list = $conversations.find("ul.conversations");
      set_last_label((_ref = $.cookie('last_label')) != null ? _ref : 'red');
      $messages = $('#messages');
      $message_list = $messages.find('ul.messages');
      $form = $('#create_message_form');
      $add_form = $('#add_recipients_form');
      $forward_form = $('#forward_message_form');
      $('#help_crumb').click(function(e) {
        e.preventDefault();
        return $.conversationsIntroSlideshow();
      });
      $('#create_message_form, #forward_message_form').find('textarea').elastic().keypress(function(e) {
        if (e.which === 13 && e.shiftKey) {
          e.preventDefault();
          $(this).closest('form').submit();
          return false;
        }
      });
      $form.submit(function(e) {
        var valid;
        valid = !!($form.find('#body').val() && ($form.find('#recipient_info').filter(':visible').length === 0 || $form.find('.token_input li').length > 0));
        if (!valid) {
          e.stopImmediatePropagation();
        }
        return valid;
      });
      $form.formSubmit({
        fileUpload: function() {
          return $(this).find(".file_input:visible").length > 0;
        },
        beforeSubmit: function() {
          return $(this).loadingImage();
        },
        success: function(data) {
          var $conversation, conversation, _i, _len, _ref2;
          $(this).loadingImage('remove');
          if (data.length > 1) {
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              conversation = data[_i];
              $conversation = $('#conversation_' + conversation.id);
              if ($conversation.length) {
                update_conversation($conversation, conversation, 'immediate');
              }
            }
            $.flashMessage(I18n.t('messages_sent', 'Messages Sent'));
          } else {
            conversation = (_ref2 = data[0]) != null ? _ref2 : data;
            $conversation = $('#conversation_' + conversation.id);
            if ($conversation.length) {
              if (is_selected($conversation)) {
                build_message(conversation.messages[0]).prependTo($message_list).slideDown('fast');
              }
              update_conversation($conversation, conversation);
            } else {
              add_conversation(conversation);
              set_hash('#/conversations/' + conversation.id);
            }
            $.flashMessage(I18n.t('message_sent', 'Message Sent'));
          }
          return reset_message_form();
        },
        error: function(data) {
          $form.find('.token_input').errorBox(I18n.t('recipient_error', 'The course or group you have selected has no valid recipients'));
          $('.error_box').filter(':visible').css('z-index', 10);
          return $(this).loadingImage('remove');
        }
      });
      $form.click(function() {
        return toggle_message_actions(false);
      });
      $add_form.submit(function(e) {
        var valid;
        valid = !!($(this).find('.token_input li').length);
        if (!valid) {
          e.stopImmediatePropagation();
        }
        return valid;
      });
      $add_form.formSubmit({
        beforeSubmit: function() {
          return $(this).loadingImage();
        },
        success: function(data) {
          $(this).loadingImage('remove');
          build_message(data.messages[0]).prependTo($message_list).slideDown('fast');
          update_conversation($selected_conversation, data);
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
        if ($(e.target).closest('a.instructure_inline_media_comment').length) {} else {
          $message = $(e.target).closest('#messages > ul > li');
          if (!($message.hasClass('generated') || $message.hasClass('submission'))) {
            if ($selected_conversation != null) {
              $selected_conversation.addClass('inactive');
            }
            $message.toggleClass('selected');
            $message.find('> :checkbox').attr('checked', $message.hasClass('selected'));
          }
          return toggle_message_actions();
        }
      });
      $('.menus > li > a').click(function(e) {
        e.preventDefault();
        return open_menu($(this));
      }).focus(function() {
        return open_menu($(this));
      });
      $(document).bind('mousedown', function(e) {
        if (!$(e.target).closest("span.others").find('> span').length) {
          $('span.others > span').hide();
        }
        if (!$(e.target).closest(".menus > li, #conversation_actions, #conversations .actions").length) {
          return close_menus();
        }
      });
      $('#menu_views').parent().find('li a').click(function(e) {
        close_menus();
        return $('#menu_views').text($(this).text());
      });
      $('#message_actions').find('a').click(function(e) {
        return e.preventDefault();
      });
      $('#conversation_actions').find('li a').click(function(e) {
        e.preventDefault();
        return close_menus();
      });
      $('.action_mark_as_read').click(function(e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return inbox_action($(this), {
          method: 'PUT',
          before: function($node) {
            if (MessageInbox.scope !== 'unread') {
              set_conversation_state($node, 'read');
            }
            return true;
          },
          success: function($node) {
            if (MessageInbox.scope === 'unread') {
              return remove_conversation($node);
            }
          },
          error: function($node) {
            if (MessageInbox.scope !== 'unread') {
              return set_conversation_state($node('unread'));
            }
          }
        });
      });
      $('.action_mark_as_unread').click(function(e) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return inbox_action($(this), {
          method: 'PUT',
          before: function($node) {
            return set_conversation_state($node, 'unread');
          },
          error: function($node) {
            return set_conversation_state($node, 'read');
          }
        });
      });
      $('.action_remove_label').click(function(e) {
        var current_label;
        e.preventDefault();
        e.stopImmediatePropagation();
        current_label = null;
        return inbox_action($(this), {
          method: 'PUT',
          before: function($node) {
            current_label = $node.data('label');
            if (current_label) {
              $node.removeClass('labeled ' + current_label);
            }
            return current_label;
          },
          success: function($node, data) {
            update_conversation($node, data);
            if (MessageInbox.scope === 'labeled') {
              return remove_conversation($node);
            }
          },
          error: function($node) {
            return $node.addClass('labeled ' + current_label);
          }
        });
      });
      $('.action_add_label').click(function(e) {
        var current_label, label;
        e.preventDefault();
        e.stopImmediatePropagation();
        label = null;
        current_label = null;
        return inbox_action($(this), {
          method: 'PUT',
          before: function($node, options) {
            current_label = $node.data('label');
            label = options.url.match(/%5Blabel%5D=(.*)/)[1];
            if (label === 'last') {
              label = $last_label;
              options.url = options.url.replace(/%5Blabel%5D=last/, '%5Blabel%5D=' + label);
            }
            $node.removeClass('red orange yellow green blue purple').addClass('labeled').addClass(label);
            return label !== current_label;
          },
          success: function($node, data) {
            update_conversation($node, data);
            set_last_label(label);
            if (MessageInbox.label_scope && MessageInbox.label_scope !== label) {
              return remove_conversation($node);
            }
          },
          error: function($node) {
            $node.removeClass('labeled ' + label);
            if (current_label) {
              return $node.addClass('labeled ' + current_label);
            }
          }
        });
      });
      $('#action_add_recipients').click(function(e) {
        e.preventDefault();
        return $add_form.attr('action', inbox_action_url_for($(this), $selected_conversation)).dialog('close').dialog({
          width: 420,
          title: I18n.t('title.add_recipients', 'Add Recipients'),
          buttons: [
            {
              text: I18n.t('buttons.add_people', 'Add People'),
              click: function() {
                return $(this).submit();
              }
            }, {
              text: I18n.t('#buttons.cancel', 'Cancel'),
              click: function() {
                return $(this).dialog('close');
              }
            }
          ],
          open: function() {
            var token_input;
            token_input = $('#add_recipients').data('token_input');
            token_input.base_exclude = $selected_conversation.data('audience');
            return $(this).find("input[name!=authenticity_token]").val('').change();
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
          method: 'PUT',
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
            loading_node: $selected_conversation,
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
              if ($message_list.find('> li').not('.selected, .generated, .submission').length) {
                $selected_messages.remove();
                return update_conversation($node, data);
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
      $('#action_forward').click(function() {
        var $preview;
        $forward_form.find("input[name!=authenticity_token], textarea").val('').change();
        $preview = $forward_form.find('ul.messages').first();
        $preview.html('');
        $preview.html($message_list.find('> li.selected').clone(true).removeAttr('id').removeClass('self'));
        $preview.find('> li').removeClass('selected odd').find('> :checkbox').attr('checked', true).attr('name', 'forwarded_message_ids[]').val(function() {
          return $(this).closest('li').data('id');
        });
        $preview.find('> li').last().addClass('last');
        return $forward_form.css('max-height', ($(window).height() - 300) + 'px').dialog('close').dialog({
          position: 'center',
          height: 'auto',
          width: 510,
          title: I18n.t('title.forward_messages', 'Forward Messages'),
          buttons: [
            {
              text: I18n.t('buttons.send_message', 'Send'),
              click: function() {
                return $(this).submit();
              }
            }, {
              text: I18n.t('#buttons.cancel', 'Cancel'),
              click: function() {
                return $(this).dialog('close');
              }
            }
          ],
          close: function() {
            return $('#forward_recipients').data('token_input').input.blur();
          }
        });
      });
      $forward_form.submit(function(e) {
        var valid;
        valid = !!($(this).find('#forward_body').val() && $(this).find('.token_input li').length);
        if (!valid) {
          e.stopImmediatePropagation();
        }
        return valid;
      });
      $forward_form.formSubmit({
        beforeSubmit: function() {
          return $(this).loadingImage();
        },
        success: function(data) {
          var $conversation, conversation;
          conversation = data[0];
          $(this).loadingImage('remove');
          $conversation = $('#conversation_' + conversation.id);
          if ($conversation.length) {
            if (is_selected($conversation)) {
              build_message(conversation.messages[0]).prependTo($message_list).slideDown('fast');
            }
            update_conversation($conversation, conversation);
          } else {
            add_conversation(conversation);
          }
          set_hash('#/conversations/' + conversation.id);
          reset_message_form();
          return $(this).dialog('close');
        },
        error: function(data) {
          $(this).loadingImage('remove');
          return $(this).dialog('close');
        }
      });
      $('#cancel_bulk_message_action').click(function() {
        return toggle_message_actions(false);
      });
      $('#conversation_blank .audience, #create_message_form .audience').click(function(e) {
        var $others;
        if (($others = $(e.target).closest('span.others').find('> span')).length) {
          if (!$(e.target).closest('span.others > span').length) {
            $('span.others > span').not($others).hide();
            $others.toggle();
            $others.css('left', $others.parent().position().left);
            $others.css('top', $others.parent().height() + $others.parent().position().top);
          }
          e.preventDefault();
          return false;
        }
      });
      nextAttachmentIndex = 0;
      $('#action_add_attachment').click(function(e) {
        var $attachment;
        e.preventDefault();
        $attachment = $("#attachment_blank").clone(true);
        $attachment.attr('id', null);
        $attachment.find("input[type='file']").attr('name', 'attachments[' + (nextAttachmentIndex++) + ']');
        $('#attachment_list').append($attachment);
        $attachment.slideDown("fast", function() {
          return inbox_resize();
        });
        return false;
      });
      $("#attachment_blank a.remove_link").click(function(e) {
        e.preventDefault();
        $(this).parents(".attachment").slideUp("fast", function() {
          inbox_resize();
          return $(this).remove();
        });
        return false;
      });
      $('#action_media_comment').click(function(e) {
        e.preventDefault();
        return $("#create_message_form .media_comment").mediaComment('create', 'audio', function(id, type) {
          $("#media_comment_id").val(id);
          $("#media_comment_type").val(type);
          $("#create_message_form .media_comment").show();
          return $("#action_media_comment").hide();
        });
      });
      $('#create_message_form .media_comment a.remove_link').click(function(e) {
        e.preventDefault();
        $("#media_comment_id").val('');
        $("#media_comment_type").val('');
        $("#create_message_form .media_comment").hide();
        return $("#action_media_comment").show();
      });
      _ref2 = MessageInbox.initial_conversations;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        conversation = _ref2[_i];
        add_conversation(conversation, true);
      }
      $('#no_messages').showIf(!$conversation_list.find('li:not([id=conversations_loader])').length);
      $('.recipients').tokenInput({
        placeholder: I18n.t('recipient_field_placeholder', "Enter a name, course, or group"),
        added: function(data, $token, new_token) {
          var $details, current_data, _ref3;
          if (new_token && data.type) {
            $token.addClass(data.type);
            if (data.user_count != null) {
              $token.addClass('details');
              $details = $('<span />');
              $details.text(I18n.t('people_count', 'person', {
                count: data.user_count
              }));
              $token.append($details);
            }
          }
          if (!(data.id && ("" + data.id).match(/^(course|group)_/))) {
            data = $.extend({}, data);
            delete data.avatar_url;
            current_data = (_ref3 = MessageInbox.user_cache[data.id]) != null ? _ref3 : {};
            return MessageInbox.user_cache[data.id] = $.extend(current_data, data);
          }
        },
        selector: {
          messages: {
            no_results: I18n.t('no_results', 'No results found')
          },
          populator: function($node, data, options) {
            var $b, $context_name, $img, $name, $span, context_name, text;
            if (options == null) {
              options = {};
            }
            if (data.avatar_url) {
              $img = $('<img class="avatar" />');
              $img.attr('src', data.avatar_url);
              $node.append($img);
            }
            context_name = data.context_name ? data.context_name : '';
            context_name = context_name.length < 40 ? context_name : context_name.substr(0, 40) + '...';
            $context_name = data.context_name ? $('<span />', {
              "class": 'context_name'
            }).text("(" + context_name + ")") : '';
            $b = $('<b />');
            $b.text(data.name);
            $name = $('<span />', {
              "class": 'name'
            });
            $name.append($b, $context_name);
            $span = $('<span />', {
              "class": 'details'
            });
            if (data.common_courses != null) {
              $span.text(MessageInbox.context_list({
                courses: data.common_courses,
                groups: data.common_groups
              }));
            } else if (data.type && (data.user_count != null)) {
              $span.text(I18n.t('people_count', 'person', {
                count: data.user_count
              }));
            } else if (data.item_count != null) {
              if (data.id.match(/_groups$/)) {
                $span.text(I18n.t('groups_count', 'group', {
                  count: data.item_count
                }));
              } else if (data.id.match(/_sections$/)) {
                $span.text(I18n.t('sections_count', 'section', {
                  count: data.item_count
                }));
              }
            }
            $node.append($name, $span);
            $node.attr('title', data.name);
            text = data.name;
            if (options.parent) {
              if (data.select_all && data.no_expand) {
                text = options.parent.data('text');
              } else if ((data.id + '').match(/_\d+_/)) {
                text = I18n.beforeLabel(options.parent.data('text')) + " " + text;
              }
            }
            $node.data('text', text);
            $node.data('id', data.id);
            $node.data('user_data', data);
            $node.addClass(data.type ? data.type : 'user');
            if (options.level > 0) {
              $node.prepend('<a class="toggle"><i></i></a>');
              if (!data.item_count) {
                $node.addClass('toggleable');
              }
            }
            if (data.type === 'context' && !data.no_expand) {
              $node.prepend('<a class="expand"><i></i></a>');
              return $node.addClass('expandable');
            }
          },
          limiter: function(options) {
            if (options.level > 0) {
              return -1;
            } else {
              return 5;
            }
          },
          preparer: function(post_data, data, parent) {
            var context;
            context = post_data.context;
            if (!post_data.search && context && data.length > 1) {
              if (context.match(/^(course|section)_\d+$/)) {
                return data.unshift({
                  id: "" + context + "_all",
                  name: I18n.t('enrollments_everyone', "Everyone"),
                  user_count: parent.data('user_data').user_count,
                  type: 'context',
                  avatar_url: parent.data('user_data').avatar_url,
                  select_all: true
                });
              } else if (context.match(/^((course|section)_\d+_.*|group_\d+)$/) && !context.match(/^course_\d+_(groups|sections)$/)) {
                return data.unshift({
                  id: context,
                  name: I18n.t('select_all', "Select All"),
                  user_count: parent.data('user_data').user_count,
                  type: 'context',
                  avatar_url: parent.data('user_data').avatar_url,
                  select_all: true,
                  no_expand: true
                });
              }
            }
          },
          base_data: {
            synthetic_contexts: 1
          },
          browser: {
            data: {
              per_page: -1,
              type: 'context'
            }
          }
        }
      });
      token_input = $('#recipients').data('token_input');
      token_input.fake_input.css('width', '100%');
      token_input.change = function(tokens) {
        var user, _ref3;
        if (tokens.length > 1 || ((_ref3 = tokens[0]) != null ? _ref3.match(/^(course|group)_/) : void 0)) {
          if (!$form.find('#group_conversation_info').is(':visible')) {
            $form.find('#group_conversation').attr('checked', true);
          }
          $form.find('#group_conversation_info').show();
          $form.find('#user_note_info').hide();
        } else {
          $form.find('#group_conversation').attr('checked', true);
          $form.find('#group_conversation_info').hide();
          $form.find('#user_note_info').showIf((user = MessageInbox.user_cache[tokens[0]]) && can_add_notes_for(user));
        }
        return inbox_resize();
      };
      $(window).resize(inbox_resize);
      setTimeout(inbox_resize);
      setTimeout(function() {
        return $conversation_list.pageless({
          totalPages: Math.ceil(MessageInbox.initial_conversations_count / MessageInbox.conversation_page_size),
          container: $conversation_list,
          params: {
            format: 'json',
            per_page: MessageInbox.conversations_per_page
          },
          loader: $("#conversations_loader"),
          scrape: function(data) {
            var conversation, _j, _len2;
            if (typeof data === 'string') {
              try {
                data = JSON.parse(data);
              } catch (error) {
                data = [];
              }
              for (_j = 0, _len2 = data.length; _j < _len2; _j++) {
                conversation = data[_j];
                add_conversation(conversation, true);
              }
            }
            $conversation_list.append($("#conversations_loader"));
            return false;
          }
        }, 1);
      });
      return $(window).bind('hashchange', function() {
        var $c, hash, match, params;
        hash = location.hash;
        if (match = hash.match(/^#\/conversations\/(\d+)(\?(.*))?/)) {
          params = match[3] ? parse_query_string(match[3]) : {};
          if (($c = $('#conversation_' + match[1])) && $c.length) {
            return select_conversation($c, params);
          } else {
            return select_unloaded_conversation(match[1], params);
          }
        } else if ($('#action_compose_message').length) {
          params = {};
          if (match = hash.match(/^#\/conversations\?(.*)$/)) {
            params = parse_query_string(match[1]);
          }
          return select_conversation(null, params);
        }
      }).triggerHandler('hashchange');
    });
  });
}).call(this);
