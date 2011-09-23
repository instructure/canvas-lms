jQuery.widget('instructure.draggable', jQuery.ui.draggable, {
	_mouseDrag: function(event, noPropagation) {
		// code is copy/pasted from jqueryui source except for commented workaround.

		//Compute the helpers position
		this.position = this._generatePosition(event);
		this.positionAbs = this._convertPositionTo("absolute");

		//Call plugins and callbacks and use the resulting position if something is returned
		if (!noPropagation) {
			var ui = this._uiHash();
			if(this._trigger('drag', event, ui) === false) {
				this._mouseUp({});
				return false;
			}
			this.position = ui.position;
		}

		if(!this.options.axis || this.options.axis != "y") this.helper[0].style.left = this.position.left+'px';
		// Workaround-Instructure: this is a custom behavior added to jqueryUI draggable to make it work for resizing tiny.
		// look for instructureHackToNotAutoSizeTop in tinymce.editor_box.js to see where it is used.
		if(!this.options.axis || this.options.axis != "x" && !this.options.instructureHackToNotAutoSizeTop) this.helper[0].style.top = this.position.top+'px';
		if($.ui.ddmanager) $.ui.ddmanager.drag(this, event);

		return false;
	}
});