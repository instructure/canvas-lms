# Dummy class to let us log page view actions that don't necessarily correspond with
# anything in canvas itself (eg, joining a chat)
class BocceController < ApplicationController
  def join_chat
    # Has to respond as HTML to trigger the logging
    respond_to do |format|
      format.html { render :inline => "success" }
    end
  end
end
