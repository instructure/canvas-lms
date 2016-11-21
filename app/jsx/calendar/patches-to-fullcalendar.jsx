define([
	'bower/fullcalendar/dist/fullcalendar',
	'str/htmlEscape'
], function(fullCalendar, htmlEscape) {

	// set up a custom view for the agendaWeek day/date header row
	const _originalHeadCellHtml = fullCalendar.Grid.prototype.headCellHtml;

	// duplicate var from vender fullcalendar.js so can access here
  const dayIDs = [ 'sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat' ];

  fullCalendar.Grid.prototype.headCellHtml = function(cell) {
		if (this.view.name === 'agendaWeek') {
			const date = cell.start;
  		return `
  			<th class="fc-day-header ${htmlEscape(this.view.widgetHeaderClass)} fc-${htmlEscape(dayIDs[date.day()])}">
        	<div class="fc-day-header__week-number">${htmlEscape(date.format('D'))}</div>
        	<div class="fc-day-header__week-day">${htmlEscape(date.format('ddd'))}</div>
        </th>`;
		} else {
			return _originalHeadCellHtml.apply(this, arguments);
		}
	};
})