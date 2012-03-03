/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
define([
  'jquery' /* $ */,
  'instructure-jquery.ui.draggable-patch' /* /\.draggable/ */,
  'jqueryui/droppable' /* /\.droppable/ */
], function($) {
  $.fn.instTree = function(options) {
    return $(this).each(function() {
      var binded = false;
      var tree = $(this);
      var it = this;
      var ddover = null;

      it.options = {
        autoclose: true,
        overrideEvents: false,
        multi: true,
        dragdrop: true,
        onClick: false,
        onDblClick: false,
        onExpand: false,
        onCollapse: false,
        onAddNode: false,
        onEditNode: false,
        onDeleteNode: false,
        onDrag: false,
        onDrop: false
      };
      it.opts = $.extend({}, it.options, options);

      $.fn.instTree.InitInstTree = function(obj) {
        tree = $(obj);

        var sep = '<li class="separator"></li>';

        tree.find('li:not(.separator)').filter(function() {
          return !(($(this).prev('li.separator').get(0)) || ($(this).parents('ul.non-instTree').get(0)));
        })
        .each(function() {
          $(this).before(sep);
        });

        tree.find('li > span').not('.sign').not('.clr').addClass('text').attr('unselectable', 'on');

        tree.find('li:not(.separator)').
          filter(function() {
            return !($(this).parents('ul.non-instTree').get(0));
          })
          .filter(':has(ul)').addClass('node')
          .end()
          .filter(':not(.node)').addClass('leaf');

        it.IeSetStyles();

        it.Clean();

        it.AddSigns();

        if (!binded) {
          it.BindEvents(obj);
        }

        //dragdrop
        if (it.opts.dragdrop) {
          it.CancelDragDrop(obj);
          it.InitDragDrop(obj);
        }//if (it.opts.dragdrop)
      };//InitInstTree
      it.InitDragDrop = function(obj) {
        tree = $(obj);

        tree.find('span.text').draggable({
          cursor: ($.browser.msie) ? 'default': 'move',
          distance: 3,
          helper: function() {
            return $('<div id="instTree-drag"><span>' + $(this).text() + '</span></div>');
          },
          appendTo: tree
        });

        tree.find('li.separator').droppable({
          accept: 'span.text',
          hoverClass: 'dd-hover'
        });

        tree.find('span.text').bind('dragstart', function(event, ui) {
          tree = $(this).parents('ul.instTree:first');

          var li = $(this).parent('li');
          var dd = $('div#instTree-drag');

          if ($.browser.msie) {
            tree.find('li.separator').removeClass('dd-hover');
          }

          if ($.browser.opera) {
            dd.css('margin-top', '10px');
          }

          if (li.is('.leaf')) {
            dd.addClass('leaf');

            if ($.browser.msie) {
            dd.css('background', '#C3E1FF url(' + it.opts.imgFolder + 'leaf-drag.gif) left 3px no-repeat');
            }
          }//if (li.is('.leaf'))
          else if (li.is('.node')) {
            dd.addClass('node');
          }

          li.prev('li.separator').addClass('alt').end().addClass('alt');

          if (typeof(it.opts.onDrag) == 'function') {
            it.opts.onDrag(event, li);
          }
        });

        tree.find('li.separator').bind('dropover', function(event, ui) {
          ddover = $(this);
        });

        tree.find('li.separator').bind('dropout', function(event, ui) {
          ddover = null;
        });

        tree.find('span.text').bind('dragstop', function(event, ui) {
          var lvlok = true;

          if (ddover) {
            var ali = tree.find('li.alt:not(.separator):eq(0)');
            var hli = ddover.parents('li.node:eq(0)');

            if ((ali.is('.node')) && (hli.is('.fixedLevel'))) {
              lvlok = false;
            }
          }//if (ddover)
          if ((ddover) && (lvlok)) {
            ddover.before(tree.find('li.alt').remove().removeClass('alt'));

            ddover = null;

            if (typeof(it.opts.onDrop) == 'function')
            {
            it.opts.onDrop(event, ali);
            }

            $.fn.instTree.InitInstTree(obj);
          }//if (ddover)
          else {
            tree.find('li.alt').removeClass('alt');
          }
        });
      };//InitDragDrop
      it.CancelDragDrop = function(obj) {
        tree = $(obj);

        tree.find('span.text').draggable('destroy');
        tree.find('li.separator').droppable('destroy');
        tree.find('li.separator').unbind();
        tree.find('span.text').unbind();
      };
  
      $.fn.instTree.AddNode = function(obj, type) {
        tree = $(obj);

        var activeElement = tree.find('span.active').get(0);

        if (activeElement) {
          var li = $(activeElement).parents('li:first');
          var lin = $(activeElement).parents('li.node:first');

          if ((!lin.is('.fixedLevel')) || (type != 'node')) {
          var cn = (type == 'leaf') ? '': ' class="node"';

          var sep = '<li class="separator"></li>';
          var nli = '<li' + cn + '><span class="text">&nbsp;</span><input type="text" value="New item" /></li>';
          var ncont = sep + nli;

          var ok = false;
          var node, childul, iprnt;

          if (li.is('.leaf')) {
            li.after(ncont);

            node = li.nextAll('li:not(.separator):first');

            iprnt = li.parent();

            ok = true;
          }//if (li.is('.leaf'))
          else if (li.is('.node')) {
            childul = li.children('ul').get(0);

            if (childul) {
              $(childul).append(ncont);

              node = $(childul).children('li:not(.separator):last');
            }//if (childul)
            else {
              li.append('<ul>' + ncont + '</ul>');

              childul = li.children('ul').get(0);

              node = $(childul).children('li:not(.separator):last');
            }//else
            it.ExpandNode(obj, li);

            iprnt = li;

            ok = true;
          }//else if ( ...
          if (ok) {
            $(activeElement).removeClass('active');

            iprnt.find('input:text').focus().select().blur(function() {
              it.SaveInput(obj, $(this));
            });
          }//if (ok)
          $.fn.instTree.InitInstTree(obj);

          if (typeof(it.opts.onAddNode) == 'function') {
            it.opts.onAddNode(node);
          }
          }//if ((!li.is('.fixedLevel')) || (type != 'node'))
        }//if (activeElement)
      };//AddNode
      $.fn.instTree.EditNode = function(obj) {
        tree = $(obj);
        var activeElement = tree.find('span.active').get(0);
        if (activeElement) {
          var li = $(activeElement).parents('li:first');

          $(activeElement).replaceWith('<span class="text">&nbsp;</span><input type="text" value="' + $(activeElement).text() + '" />');

          li.find('input:text').focus().select().blur(function() {
            it.SaveInput(obj, $(this));
          });

          if (typeof(it.opts.onEditNode) == 'function') {
            it.opts.onEditNode(li);
          }
        }
        //if (activeElement)
      };//EditNode
      $.fn.instTree.DeleteNode = function(obj) {
        tree = $(obj);

        var activeElement = tree.find('span.active').get(0);

        if (activeElement) {
          var li = $(activeElement).parents('li:first');
          var prnt = li.parents('li.node:first');

          li.prev('li.separator').remove().end().remove();

          $.fn.instTree.InitInstTree(obj);

          if (typeof(it.opts.onDeleteNode) == 'function') {
            it.opts.onDeleteNode(li, prnt);
          }
        }//if (activeElement)
      };//DeleteNode
      it.SaveInput = function(obj, input) {
        input.prev('span.text').remove();

        var val = ($.trim(input.get(0).value) !== '') ? input.get(0).value: '_____';

        input.replaceWith('<span class="active text">' + val + '</span>');

        $.fn.instTree.InitInstTree(obj);
      };//SaveInput
      it.IeSetStyles = function() {
        if ($.browser.msie) {
          tree.find('li.node:not(.open) > ul').hide();
          tree.find('li.node.open > ul').css('margin-bottom', '1px');
        }
      };//IeSetStyles
      it.Clean = function() {
        tree.find('li:not(.separator)').each(function() {
          $(this).removeClass("last");
          
          if ((!$(this).next('li').length) || ($(this).find('ul').length)) {
            $(this).addClass("last");
          }

        });
      };//Clean
      it.AddSigns = function() {
        tree.find('li.node').each(function() {
          if ($(this).hasClass('open')) {
            $(this).find('span.sign').remove().end().append('<span class="sign minus"></span>');
          }
          else {
            $(this).find('span.sign').remove().end().append('<span class="sign plus"></span>');
          }
        });
      };//AddSigns
      it.BindEvents = function(obj) {
        tree.click(function(e) {
          var tree = $(this).closest(".instTree");
          var clicked = $(e.target);
          var node;
          
          if (clicked.is('span.sign')) {
            node = clicked.parents('li:eq(0)');
            it.ToggleNode(obj, node);
          }
          else if (clicked.is('span.text')) {
            node = clicked.closest('li');

            if (typeof(it.opts.onClick) == 'function') {
              if (!it.opts.overrideEvents) {
                if(!it.opts.multi || !e.ctrlKey) {
                  tree.find('.active').removeClass('active').end()
                    .find('.active-leaf').removeClass('active-leaf').end()
                    .find('.active-node').removeClass('active-node');
                }
                clicked.addClass('active');
                if(node.hasClass('leaf')) {
                  node.addClass('active-leaf');
                } else {
                  node.addClass('active-node');
                }
              }
              it.opts.onClick.call(node, e, node);
            }
            else {
              if(!it.opts.multi || !e.ctrlKey) {
                tree.find('.active').removeClass('active').end()
                  .find('.active-leaf').removeClass('active-leaf').end()
                  .find('.active-node').removeClass('active-node');
              }
              clicked.addClass('active');
              if(node.hasClass('leaf')) {
                node.addClass('active-leaf');
              } else {
                node.addClass('active-node');
              }
            }
          }
        });
        
        tree.dblclick(function(e) {
          var clicked = $(e.target);

          if (clicked.is('span.text')) {
            var node = clicked.parents('li:eq(0)');

            if (typeof(it.opts.onDblClick) == 'function') {
              if ((!it.opts.overrideEvents) && (node.is('.node'))) {
                it.ToggleNode(obj, node);
              }
              it.opts.onDblClick.call(node, e, node);
            }
            else if (node.is('.node')) {
              it.ToggleNode(obj, node);
            }
          }//if (clicked.is('span.text'))
        });

        binded = true;
      };//BindEvents
      it.ToggleNode = function(obj, node) {
        if (node.hasClass('open')) {
          it.CollapseNode(node);
        } 
        else {
          it.ExpandNode(obj, node);
        }

        it.Clean();
      };//ToggleNode
      it.ExpandNode = function(obj, node) {
        node.addClass('open');

        if (it.opts.autoclose) {
          node.siblings('.open').each(function() {
            it.CollapseNode($(this));
          });
        }
        //if (opts.autoclose)
        if ($.browser.msie) {
          node.children('ul').show().css({
            'margin-bottom': '1px',
            'visibility': 'visible'
          });

          node.children('ul').find('li.node:not(.open) > ul').each(function() {
            $(this).css('visibility', 'hidden');
          });
        }//if ($.browser.msie)
        var sign = node.find('span.sign:last');

        sign.removeClass('plus').addClass('minus');

        if (it.opts.multi) {
          $.fn.instTree.InitInstTree(obj);
        }

        if (typeof(it.opts.onExpand) == 'function') {
          it.opts.onExpand(node);
        }
      };//ExpandNode
  
      it.CollapseNode = function(node) {
        node.removeClass('open');

        if ($.browser.msie) {
          node.children('ul').hide();
        }

        var sign = node.find('span.sign:last');

        sign.removeClass('minus').addClass('plus');

        if (typeof(it.opts.onCollapse) == 'function') {
          it.opts.onCollapse(node);
        }
      };//CollapseNode
  
      if ($(this).is('ul')) {
        tree = $(this);
        tree.addClass('instTree');
        $.fn.instTree.InitInstTree(it);
      }//if ($(this).is('ul'))
    });
  };
});
