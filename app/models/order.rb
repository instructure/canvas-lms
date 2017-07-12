class Order < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
  serialize :params


  def purchase
    begin
      process_payment
    rescue => e
      logger.error("Order failed with error message #{e} ")
      self.update_attributes(:txn_amount => price, :status => "Failure", :message => e)
    end
    save
  end

  def express_token=(token)
    self[:express_token] = token
    if new_record? && !token.blank?
      details = EXPRESS.details_for(token)
      self.express_player_id = details.payer_id
      self.first_name = details.params["first_name"]
      self.last_name = details.params["last_name"]
    end
  end

  def price
    self.course.amount
  end

  protected

  def process_payment
    ActiveMerchant::Billing::Base.mode = :test
    response = process_purchase
    self.update_attributes(:txn_amount => price, :status => "Success", :authorization => response.authorization, :message => response.message, :params => response.params)
  end

  private

    def process_purchase
      EXPRESS.purchase(price*100, express_purchase_options)
    end

    def express_purchase_options
      {
        :ip => ip_address,
        :token => express_token,
        :payer_id => express_player_id
      }
    end


end

