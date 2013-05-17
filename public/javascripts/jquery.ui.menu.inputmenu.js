/*
 * jQuery UI Input Menu Extension
 *
 * Copyright 2010, Kris Borchers
 * Dual licensed under the MIT or GPL Version 2 licenses.
 *
 * http://github.com/kborchers/jquery-ui-extensions
 */
define([
  'jquery',
  'jqueryui/menu'
], function( $ ) {

var proto = $.ui.menu.prototype,
	originalRefresh = proto.refresh;

$.extend( proto, {
	refresh: function() {
		originalRefresh.call( this );
		var that = this;
		var items = this.element.find( "li.ui-menu-item" );
		var inputGroupLabeled = false;

		this.element.bind( "click.menu", function( event ) {
			if( !new RegExp(/^a$/i).test(event.target.tagName) ) event.preventDefault();
		});

		var inputIDCount = 0;
		this.element.find( "input[type='checkbox'], input[type='radio']" ).each( function() {
			var labelElement = $( this ).closest( "label" );
			if( labelElement.length ) {
				$( this ).insertBefore( labelElement );

				if( !$( this ).attr( "id" ) ) {
					$( this ).attr( "id", "ui-input-" + inputIDCount++ );
				}

				labelElement.attr( "for", $( this ).attr( "id" ) );
			}
		});
		this.element.bind( "menufocus", function( event ) {
			var textInput = $( event.target ).find( "a.ui-state-focus" ).children( "input[type='text']" );
			if ( textInput.length )
				textInput[0].focus();
		})
		.bind( "menublur", function( event ) {
			var textInput = $( event.target ).find( "input[type='text']:focus" );
			if ( textInput.length )
				textInput[0].blur();
		});

		items.children( "a" ).each( function( index, item ) {
			var current = $( item ), parent = current.parent();

			if( current.children().is( "input[type='checkbox'], input[type='radio']" ) ) {
				current.closest( "ul" ).addClass( "ui-menu-icons" );

				if( current.children( "input[type='checkbox']" ).is( ":checked" ) ) {
					current.prepend( '<span class="ui-icon ui-icon-check"></span>' );
					parent.attr({
						role: "menuitemcheckbox",
						"aria-checked": "true"
					});
				} else if( current.children( "input[type='radio']" ).is( ":checked" ) ) {
					current.prepend( '<span class="ui-icon ui-icon-radio-on"></span>' );
					parent.attr({
						role: "menuitemradio",
						"aria-checked": "true"
					});
				} else if( current.children( "input[type='radio']" ).length ) {
					current.prepend( '<span class="ui-icon ui-icon-radio-off"></span>' );
					parent.attr({
						role: "menuitemradio",
						"aria-checked": "false"
					});
				} else {
					parent.attr({
						role: "menuitemcheckbox",
						"aria-checked": "false"
					});
				}

				if( current.children().is( "input[type='radio']" ) ) {
					parent.attr( "radio-group", current.children( "input[type='radio']" ).attr( "name" ) );
				}

				if( parent.prev().length && !parent.prev().children( "a" ).length ) {
					parent.prev()
						.addClass( "ui-state-disabled" )
						.html( "<span class='ui-menu-input-group'>" + parent.prev().text() + "</span>" )
						.bind( "click.menu", function( event ) {
							return false;
						}).after( "<li><hr /></li>" );
					inputGroupLabeled = true;
				}
				else if( parent.prev().length && !parent.prev().children( "a" ).children().is( "input[type='checkbox'], input[type='radio']" ) ) {
					parent.before( "<li><hr /></li>" );
				}

				if( inputGroupLabeled && parent.next().length && !parent.next().children( "a" ).children().is( "input[type='checkbox'], input[type='radio']" ) ) {
					parent.after( "<li><hr /></li>" );
					inputGroupLabeled = false;
				}
				else if( parent.next().length && !parent.next().children( "a" ).children().is( "input[type='checkbox'], input[type='radio']" ) ) {
					parent.after( "<li><hr /></li>" );
				}

				current.children( "input[type='checkbox'], input[type='radio']" ).hide();
			}
		});

		items.bind( "keydown.menu", function( event ) {
			if( event.keyCode === $.ui.keyCode.SPACE ) {
				if ( that.active.children( "a" ).children().is( "input[type='checkbox'], input[type='radio']" ) ) {
					that.select( event );
					event.stopImmediatePropagation();
				}
				event.preventDefault();
			}
		});

		items.find( "input[type='text']" ).bind( "keydown", function( event ) {
			event.stopPropagation();
			if( event.keyCode === $.ui.keyCode.UP ) {
				that.element.trigger( "focus" );
				this.blur();
				that.focus( event, $( this ).closest( ".ui-menu-item").prev() );
			}
			if( event.keyCode === $.ui.keyCode.DOWN ) {
				that.element.trigger( "focus" );
				this.blur();
				that.focus( event, $( this ).closest( ".ui-menu-item").next() );
			}
		})
		.bind( "click", function( event ) {
			event.stopPropagation();
		});
	},
	select: function( event ) {
		// Save active reference before collapseAll triggers blur
		var ui = {
			// Selecting a menu item removes the active item causing multiple clicks to be missing an item
			item: this.active || $( event.target ).closest( ".ui-menu-item" )
		};

		if( ui.item.children( "a" ).children().is( "input[type='checkbox']" ) ) {
			if( ui.item.attr( "aria-checked" ) === "false" ) {
				ui.item.children( "a" ).prepend( '<span class="ui-icon ui-icon-check"></span>' );
				ui.item.attr( "aria-checked", "true" );
				ui.item.children( "a" ).children( "input[type='checkbox']" ).prop( "checked", "checked" ).trigger('change');
			} else if( ui.item.attr( "aria-checked") === "true" ) {
				ui.item.children( "a" ).children( "span.ui-icon-check" ).remove();
				ui.item.attr( "aria-checked", "false" );
				ui.item.children( "a" ).children( "input[type='checkbox']" ).removeAttr( "checked" ).trigger('change');
			}
		}

		if( ui.item.children( "a" ).children().is( "input[type='radio']" ) ) {
			if( ui.item.attr( "aria-checked" ) === "false" ) {
				ui.item.children( "a" ).children( "span.ui-icon-radio-off" ).toggleClass( "ui-icon-radio-on ui-icon-radio-off" );
				ui.item.attr( "aria-checked", "true" );
				ui.item.children( "a" ).children( "input[type='radio']" ).prop( "checked", "checked" ).trigger('change');
				ui.item.siblings( "[radio-group=" + $( ui.item ).attr( "radio-group" ) + "]" ).each( function() {
					$( this ).attr( "aria-checked", "false" );
					$( this ).children( "a" ).children( "span.ui-icon-radio-on" ).toggleClass( "ui-icon-radio-on ui-icon-radio-off" );
					$( this ).children( "a" ).children( "input[type='radio']" ).removeAttr( "checked" );
				});
			}
		}

		if( !ui.item.children( "a" ).children().is( "input[type='checkbox'], input[type='radio']" ) ) this.collapseAll();
		this._trigger( "select", event, ui );
	}
});

});
