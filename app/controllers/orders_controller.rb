require 'encryption_new_pg'
class OrdersController < ApplicationController
  include EncryptionNewPG
  skip_before_action :verify_authenticity_token, only: :check_paytm

  def express
    @course = Course.find(params[:id])
    response = EXPRESS.setup_purchase(20 * 100,
      :ip => request.remote_ip,
      :return_url => new_course_order_url(@course),
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

  def create
    @course = Course.find(params[:course_id])
    @order = Order.new(params_order.merge(user_id: @current_user, course_id: @course.id))
    if @order.purchase && @order.status == true
      redirect_to '/'
    else
      render :action => "new"
    end
  end

  PAYTM_MERCHANT_KEY = "5cjAqbssNYunuMjV"
  WEBSITE = "WEB_STAGING"
  MID = "IITIAN94490226667854"
  INDUSTRY_TYPE_ID = "Retail"
  CHANNEL_ID = "WEB"


  def paytm_integration
    @course = Course.find params[:course_id]
    order_id = rand(100000)

    @paramList = Hash.new

    @paramList["MID"] = MID
    @paramList["ORDER_ID"] = "a_#{order_id}"
    @paramList["CUST_ID"] = "a-#{@course.id}"
    @paramList["INDUSTRY_TYPE_ID"] = INDUSTRY_TYPE_ID
    @paramList["CHANNEL_ID"] = CHANNEL_ID
    @paramList["TXN_AMOUNT"] = 12
    @paramList["MSISDN"] = '7799565116'
    @paramList["EMAIL"] = 'kapilkumar660@gmail.com'
    @paramList["WEBSITE"] = WEBSITE
    @paramList["CALLBACK_URL"] = "http://localhost:3000/courses/#{@course.id}/orders/check_paytm"

    @checksum_hash = new_pg_checksum(@paramList, PAYTM_MERCHANT_KEY).gsub("\n",'')
    #staging Url
    @payment_url = "https://pguat.paytm.com/oltp-web/processTransaction?order_id='a_#{@course.id}'"
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
