class Gradebook2Controller < ApplicationController
  before_filter :require_context
  add_crumb("Gradebook") { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grades_url }
  before_filter { |c| c.active_tab = "grades" }

  def show
    if authorized_action(@context, @current_user, :manage_grades)
    end
  end
end
