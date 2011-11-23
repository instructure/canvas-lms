(function() {
  /*
  js!requires:
    - vendor/jquery-1.6.4.js
    - compiled/Template.js
    - jQuery.ajaxJSON
  */
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  define('compiled/widget/CustomList', ['compiled/util/objectCollection', 'compiled/Template'], function(objectCollection, Template) {
    var CustomList;
    return CustomList = (function() {
      CustomList.prototype.options = {
        animationDuration: 200,
        model: 'Course',
        dataAttribute: 'id',
        wrapper: 'courseList/wrapper',
        content: 'courseList/content',
        url: '/favorites',
        appendTarget: 'body',
        resetCount: 12,
        onToggle: false
      };
      function CustomList(selector, items, options) {
        this.options = jQuery.extend({}, this.options, options);
        this.appendTarget = jQuery(this.options.appendTarget);
        this.element = jQuery(selector);
        this.targetList = this.element.find('> ul');
        this.wrapper = jQuery(Template(this.options.wrapper, {}));
        this.sourceList = this.wrapper.find('> ul');
        this.contentTemplate = new Template(this.options.content);
        this.ghost = jQuery('<ul/>').addClass('customListGhost');
        this.requests = {
          add: {},
          remove: {}
        };
        this.doc = jQuery(document.body);
        this.attach();
        this.setItems(items);
        if (this.options.autoOpen) {
          this.open();
        }
      }
      CustomList.prototype.open = function() {
        this.wrapper.appendTo(this.appendTarget).show();
        return setTimeout(__bind(function() {
          var _base;
          this.element.addClass('customListEditing');
          return typeof (_base = this.options).onToggle === "function" ? _base.onToggle(true) : void 0;
        }, this), 1);
      };
      CustomList.prototype.close = function() {
        var _base;
        this.wrapper.hide(0, __bind(function() {
          return this.teardown();
        }, this));
        this.element.removeClass('customListEditing');
        if (typeof (_base = this.options).onToggle === "function") {
          _base.onToggle(false);
        }
        if (this.pinned.length === 0) {
          return this.resetList();
        }
      };
      CustomList.prototype.attach = function() {
        this.element.delegate('.customListOpen', 'click', jQuery.proxy(this, 'open'));
        this.wrapper.delegate('.customListClose', 'click', jQuery.proxy(this, 'close'));
        this.wrapper.delegate('.customListRestore', 'click', jQuery.proxy(this, 'reset'));
        this.wrapper.delegate('a', 'click.customListTeardown', function(event) {
          return event.preventDefault();
        });
        return this.wrapper.delegate('.customListItem', 'click.customListTeardown', jQuery.proxy(this, 'sourceClickHandler'));
      };
      CustomList.prototype.teardown = function() {
        return this.wrapper.detach();
      };
      CustomList.prototype.add = function(id, element) {
        var clone, index, item, target;
        item = this.items.findBy('id', id);
        clone = element.clone().hide();
        item.element = clone;
        element.addClass('on');
        this.pinned.push(item);
        this.pinned.sortBy('shortName');
        index = this.pinned.indexOf(item) + 1;
        target = this.targetList.find("li:nth-child(" + index + ")");
        if (target.length !== 0) {
          clone.insertBefore(target);
        } else {
          clone.appendTo(this.targetList);
        }
        clone.slideDown(this.options.animationDuration);
        this.animateGhost(element, clone);
        return this.onAdd(item);
      };
      CustomList.prototype.animateGhost = function(fromElement, toElement) {
        var clone, from, to;
        from = fromElement.offset();
        to = toElement.offset();
        clone = fromElement.clone();
        from.position = 'absolute';
        this.ghost.append(clone);
        return this.ghost.appendTo(this.doc).css(from).animate(to, this.options.animationDuration, __bind(function() {
          return this.ghost.detach().empty();
        }, this));
      };
      CustomList.prototype.remove = function(item, element) {
        element.removeClass('on');
        this.animating = true;
        this.onRemove(item);
        return item.element.slideUp(this.options.animationDuration, __bind(function() {
          item.element.remove();
          this.pinned.eraseBy('id', item.id);
          return this.animating = false;
        }, this));
      };
      CustomList.prototype.abortAll = function() {
        var id, req, _ref, _ref2, _results;
        _ref = this.requests.add;
        for (id in _ref) {
          req = _ref[id];
          req.abort();
        }
        _ref2 = this.requests.remove;
        _results = [];
        for (id in _ref2) {
          req = _ref2[id];
          _results.push(req.abort());
        }
        return _results;
      };
      CustomList.prototype.reset = function() {
        var callback;
        this.abortAll();
        callback = __bind(function() {
          return delete this.requests.reset;
        }, this);
        this.requests.reset = jQuery.ajaxJSON(this.options.url + '/' + this.options.model, 'DELETE', {}, callback, callback);
        return this.resetList();
      };
      CustomList.prototype.resetList = function() {
        var defaultItems, html;
        defaultItems = this.items.slice(0, this.options.resetCount);
        html = this.contentTemplate.toHTML({
          items: defaultItems
        });
        this.targetList.empty().html(html);
        return this.setPinned();
      };
      CustomList.prototype.onAdd = function(item) {
        var data, error, req, success;
        if (this.requests.remove[item.id]) {
          this.requests.remove[item.id].abort();
          return;
        }
        success = __bind(function() {
          var args;
          args = [].slice.call(arguments);
          args.unshift(item.id);
          return this.addSuccess.apply(this, args);
        }, this);
        error = __bind(function() {
          var args;
          args = [].slice.call(arguments);
          args.unshift(item.id);
          return this.addError.apply(this, args);
        }, this);
        data = {
          favorite: {
            context_type: this.options.model,
            context_id: item.id
          }
        };
        req = jQuery.ajaxJSON(this.options.url, 'POST', data, success, error);
        return this.requests.add[item.id] = req;
      };
      CustomList.prototype.onRemove = function(item) {
        var error, req, success, url;
        if (this.requests.add[item.id]) {
          this.requests.add[item.id].abort();
          return;
        }
        success = __bind(function() {
          var args;
          args = [].slice.call(arguments);
          args.unshift(item.id);
          return this.removeSuccess.apply(this, args);
        }, this);
        error = __bind(function() {
          var args;
          args = [].slice.call(arguments);
          args.unshift(item.id);
          return this.removeError.apply(this, args);
        }, this);
        url = this.options.url + '/' + item.id;
        req = jQuery.ajaxJSON(url, 'DELETE', {
          context_type: this.options.model
        }, success, error);
        return this.requests.remove[item.id] = req;
      };
      CustomList.prototype.addSuccess = function(id) {
        return delete this.requests.add[id];
      };
      CustomList.prototype.addError = function(id) {
        return delete this.requests.add[id];
      };
      CustomList.prototype.removeSuccess = function(id) {
        return delete this.requests.remove[id];
      };
      CustomList.prototype.removeError = function(id) {
        return delete this.requests.remove[id];
      };
      CustomList.prototype.setItems = function(items) {
        var html;
        this.items = objectCollection(items);
        this.items.sortBy('shortName');
        html = this.contentTemplate.toHTML({
          items: this.items
        });
        this.sourceList.html(html);
        return this.setPinned();
      };
      CustomList.prototype.setPinned = function() {
        var item, match, _i, _len, _ref, _results;
        this.pinned = objectCollection([]);
        this.element.find('> ul > li').each(__bind(function(index, element) {
          var id, item;
          element = jQuery(element);
          id = element.data('id');
          item = this.items.findBy('id', id);
          if (!item) {
            return;
          }
          item.element = element;
          return this.pinned.push(item);
        }, this));
        this.wrapper.find('ul > li').removeClass('on');
        _ref = this.pinned;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          match = this.wrapper.find("ul > li[data-id=" + item.id + "]");
          _results.push(match.addClass('on'));
        }
        return _results;
      };
      CustomList.prototype.sourceClickHandler = function(event) {
        return this.checkElement(jQuery(event.currentTarget));
      };
      CustomList.prototype.checkElement = function(element) {
        var id, item;
        if (this.animating || this.requests.reset) {
          return;
        }
        id = element.data('id');
        item = this.pinned.findBy('id', id);
        if (item) {
          return this.remove(item, element);
        } else {
          return this.add(id, element);
        }
      };
      return CustomList;
    })();
  });
}).call(this);
