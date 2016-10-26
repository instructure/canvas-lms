module SupportHelpers
  class CrocodocController < ApplicationController
    include SupportHelpers::ControllerHelpers

    before_filter :require_site_admin

    protect_from_forgery with: :exception

    def shard
      run_fixer(SupportHelpers::Crocodoc::ShardFixer)
    end

    def submission
      if params[:assignment_id] && params[:user_id]
        run_fixer(SupportHelpers::Crocodoc::SubmissionFixer,
                  params[:assignment_id].to_i, params[:user_id].to_i)
      else
        render text: "Missing either assignment and/or user id parameters", status: 400
      end
    end
  end
end
