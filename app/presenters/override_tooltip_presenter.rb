class OverrideTooltipPresenter < OverrideListPresenter

  DEFAULT_MAX_DATES = 10

  def initialize(assignment=nil, user=nil, opts={})
    super(assignment, user)
    @opts = opts
  end

  def default_link_text
    I18n.t('#assignments.multiple_due_dates', 'Multiple Due Dates')
  end

  def link_text
    @opts[:text] || default_link_text
  end

  def link_href
    @opts[:href]
  end

  def more_message
    return '' unless dates_hidden > 0
    I18n.t('#tooltips.vdd.more_message', 'and %{count} more...', :count => dates_hidden)
  end

  # Pass in a :max_dates option to adjust how many dates are shown
  # before "and # more..." is shown at the bottom
  def max_dates
    @opts[:max_dates] || self.class::DEFAULT_MAX_DATES
  end

  def total_dates
    visible_due_dates.length
  end

  def dates_visible
    [total_dates, max_dates].min
  end

  def dates_hidden
    total_dates - dates_visible
  end

  def selector
    "#{assignment.class.to_s.demodulize.downcase}_#{assignment.id}"
  end

  def due_date_summary
    visible_due_dates[0...dates_visible].map do |date|
      {:due_for => date[:due_for], :due_at => date[:due_at]}
    end
  end

  def as_json
    {
      :selector  => selector,
      :link_text => link_text,
      :link_href => link_href,
      :due_dates => due_date_summary,
      :more_message => more_message
    }
  end

end
