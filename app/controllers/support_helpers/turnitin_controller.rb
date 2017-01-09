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

    def lti_attachment
      param_keys = %w[submission_id attachment_id]
      if (params.keys & param_keys).present?
        ids = param_keys.map do |key|
          error = {text:"Missing `#{key}` parameter", status: 400}
          render error and return unless params[key]
          params[key].to_i
        end
        run_fixer(SupportHelpers::Tii::LtiAttachmentFixer, *ids)
      else
        error = {text:"Missing attachment_id and submission_id parameters", status: 400}
        render error and return
      end
    end

  end
end
