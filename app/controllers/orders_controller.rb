require 'encryption_new_pg'
class OrdersController < ApplicationController
  include EncryptionNewPG
  skip_before_action :verify_authenticity_token, only: :check_paytm

  def express
    @course = Course.find(params[:id])
    response = EXPRESS.setup_purchase( @course.amount * 100,
      :ip => request.remote_ip,
      :return_url => payment_course_orders_url(@course),
      :cancel_return_url => root_url,
      :allow_note => true,
      :items => @course.courese_details
    )
    redirect_to EXPRESS.redirect_url_for(response.token)
  end

  def new
    @course = Course.find(params[:course_id])
    @order = Order.new(:express_token => params[:token])
  end

  def payment
    @course = Course.find(params[:course_id])
    @order = Order.create(express_token: params[:token], user_id: @current_user, course_id: @course.id)
    if @order.purchase && @order.status == "Success"
      redirect_to "#{request.domain}/courses/#{@course.id}"
    else
      redirect_to '/'
    end
  end


  def paytm_integration
    @course = Course.find params[:course_id]
    order_id = rand(100000)

    @paramList = Hash.new

    @paramList["MID"] = MID
    @paramList["ORDER_ID"] = "a_#{order_id}"
    @paramList["CUST_ID"] = "a-#{@course.id}"
    @paramList["INDUSTRY_TYPE_ID"] = INDUSTRY_TYPE_ID
    @paramList["CHANNEL_ID"] = CHANNEL_ID
    @paramList["TXN_AMOUNT"] =  @course.amount
    @paramList["MSISDN"] = '7009417976'
    @paramList["EMAIL"] = 'jagtar.lakhyan@gmail.com'
    @paramList["WEBSITE"] = WEBSITE
    @paramList["CALLBACK_URL"] = "#{request.domain}/courses/#{@course.id}/orders/check_paytm"

    @checksum_hash = new_pg_checksum(@paramList, PAYTM_MERCHANT_KEY).gsub("\n",'')
    #staging Url
    @payment_url = "#{PAYTM_PAY_URL}?order_id='a_#{@course.id}'"
    @order= Order.new()
  end

  def check_paytm
    puts "Checksum matched and following are the transaction details:";
    if request.params["STATUS"] == "TXN_SUCCESS"
      Order.create(mid: request.params["MID"],
        order_id: request.params["ORDERID"],
        txn_amount: request.params["TXNAMOUNT"],
        currency: request.params["CURRENCY"],
        txn_id: request.params["TXNID"],
        bank_txn_id: request.params["BANKTXNID"],
        status: request.params["STATUS"],
        resp_code: request.params["RESPCODE"],
        resp_msg: request.params["RESPMSG"],
        txn_date: request.params["TXNDATE"],
        gateway_name: request.params["GATEWAYNAME"],
        bank_name: request.params["BANKNAME"],
        payment_mode: request.params["PAYMENTMODE"],
        checksum_hash: request.params["CHECKSUMHASH"],
        course_id: request.params["course_id"],
        user_id: @current_user.id )
      redirect_to "/courses/#{request.params["course_id"]}"
    else
      redirect_to root_path
    end
  end

  private

  def params_order
    params.require(:order).permit!
  end

end
