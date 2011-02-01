#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

class ShortMessagesController < ApplicationController
  before_filter :require_context
  include Twitter
  
  def index
    if authorized_action(@context, @current_user, :read)
      @associations = @context.short_message_associations
      @hashtag = @context.hashtag_model rescue nil
      found = []
      @associations += @hashtag.short_message_associations if @hashtag
      @associations.map! do |a|
        res = (found.include?(a.short_message_id) || !a.short_message) ? nil : a
        found << a.short_message_id
        res
      end
      @associations = @associations.compact.sort_by{|m| m.short_message.created_at}.reverse
    end
  end
  
  def create
    @association = @context.short_message_associations.new
    if authorized_action(@association, @current_user, :create)
      @association = @context.short_message_associations.create
      @message = ShortMessage.new(params[:short_message])
      @message.user = @current_user
      @message.save
      @association.short_message = @message
      @association.save
      # Don't add an association to the hashtags, since this will happen
      # via twitter_searcher if the twitterer wants it to be public
      send_twitter = params.delete(:send_twitter) == "1"
      respond_to do |format|
        if @association.valid? && @message.valid?
          if send_twitter && @current_user
#            begin
              res = twitter_send @message.message
              @message.service = "twitter"
              @message.service_message_id = res["id"]
              @message.service_user_name = res["user"]["screen_name"] rescue nil
              @message.save
#            rescue
#            end
          end
          format.json { render :json => @association.to_json(:include => :short_message, :permissions => {:user => @current_user, :session => session}) }
        elsif !@association.valid?
          format.json { render :json => @association.errors.to_json, :status => :bad_request }
        else
          format.json { render :json => @message.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def destroy
    @association = @context.short_message_associations.find_by_short_message_id(params[:id])
    if authorized_action(@association, @current_user, :delete)
      respond_to do |format|
        if @association.destroy
          format.json { render :json => @association.to_json(:include => :short_message) }
        else
          format.json { render :json => @association.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
end
