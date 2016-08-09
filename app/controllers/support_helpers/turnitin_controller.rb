module SupportHelpers
  class TurnitinController < ApplicationController

    before_filter :require_site_admin

    protect_from_forgery with: :exception

    def md5
      run_fixer(SupportHelpers::Tii::MD5Fixer)
    end

    def error2305
      run_fixer(SupportHelpers::Tii::Error2305Fixer)
    end

    def shard
      run_fixer(SupportHelpers::Tii::ShardFixer)
    end

    def assignment
      if params[:id]
        run_fixer(SupportHelpers::Tii::AssignmentFixer, params[:id].to_i)
      else
        render text: "Missing assignment `id` parameter", status: 400
      end
    end

    def pending
      run_fixer(SupportHelpers::Tii::StuckInPendingFixer)
    end

    def expired
      run_fixer(SupportHelpers::Tii::ExpiredAccountFixer)
    end

    private

    def run_fixer(fixer_klass, *args)
      params[:after_time] &&= Time.parse(params[:after_time])
      fixer = fixer_klass.new(@current_user.email, params[:after_time], *args)
      fixer.send_later_if_production(:monitor_and_fix)

      render text: "Enqueued #{fixer.fixer_name}..."
    end

    def require_site_admin
      require_site_admin_with_permission(:update)
    end
  end
end
