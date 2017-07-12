class FeePaymentController < ApplicationController
  before_action :require_user
  before_action :require_context
  before_action :check_course_amount

  def index
    @context = Course.find(params[:course_id])
    @active_tab = 'fee_payment'
    add_crumb(t('#crumbs.fee_payment', 'Fee Payment'),
                  named_context_url(@context, :course_fee_payment_index_url))
  end

  def check_course_amount
    @context = Course.find(params[:course_id])
    unless @context.amount
      redirect_to @context
    end
  end
end
