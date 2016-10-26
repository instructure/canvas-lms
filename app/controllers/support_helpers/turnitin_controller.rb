module SupportHelpers
  class TurnitinController < ApplicationController
    include SupportHelpers::ControllerHelpers

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
  end
end
