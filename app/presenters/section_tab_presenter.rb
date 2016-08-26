class SectionTabPresenter
  include Rails.application.routes.url_helpers

  def initialize(tab, context)
    @tab = OpenStruct.new(tab)
    @context = context
  end
  attr_reader :tab, :context
  delegate :css_class, :label, :screenreader, :target, to: :tab

  def active?(active_tab)
    active_tab == tab.css_class
  end

  def screenreader?
    tab.respond_to?(:screenreader)
  end

  def hide?
    tab.hidden || tab.hidden_unused
  end

  def target?
    !!(tab.respond_to?(:target) && tab.target)
  end

  def path
    tab.args.instance_of?(Hash) ? send(tab.href, tab.args) : send(tab.href, *path_args)
  end

  def path_args
    tab.args || (tab.no_args && []) || context
  end

  def to_h
    { css_class: tab.css_class, icon: tab.icon, hidden: hide?, path: path }.tap do |h|
      h[:screenreader] = tab.screenreader if screenreader?
    end
  end
end
