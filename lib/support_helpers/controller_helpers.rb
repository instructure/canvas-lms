module SupportHelpers
  module ControllerHelpers

    private

    def require_site_admin
      require_site_admin_with_permission(:update)
    end

    def run_fixer(fixer_klass, *args)
      params[:after_time] &&= Time.zone.parse(params[:after_time])
      fixer = fixer_klass.new(@current_user.email, params[:after_time], *args)
      fixer.send_later_if_production(:monitor_and_fix)

      render text: "Enqueued #{fixer.fixer_name}..."
    end
  end
end
