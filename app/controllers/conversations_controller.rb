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

class ConversationsController < ApplicationController
  before_filter :require_user
  before_filter :get_conversation, :only => [:show, :update, :destroy, :workflow_event, :add_recipients, :add_message, :remove_messages]
  before_filter :load_all_contexts, :only => [:find_recipients, :add_recipients]
  add_crumb("Messages") { |c| c.send :conversations_url }

  def index
    @conversations = case params[:scope]
      when 'unread'
        add_crumb 'Unread', messages_unread_url
        @current_user.conversations.unread
      when 'archived'
        add_crumb 'Archived', messages_archived_url
        @current_user.conversations.archived
      else
        @current_user.conversations.default
    end
  end

  def create
    @conversation = @current_user.initiate_conversation(params[:recipient_ids])
    @conversation.add_message(params[:body])
  end

  def show
  end

  def update
    if @conversation.update_attributes(params[:conversation])
      render :json => @conversation.to_json
    else
      render :json => @conversation.errors.to_json, :status => :bad_request
    end
  end

  def workflow_event
    event = params[:event].to_sym
    @conversation.send(event) if [:mark_as_read, :mark_as_unread, :archive, :unarchive].include?(event)
  end

  def destroy
    @conversation.messages.clear
    @conversation.update_last_message_at
  end

  def add_recipients
    recipient_ids = []
    if params[:users]
      recipient_ids = matching_participants(:ids => params[:users].map(&:to_i)).map{ |p| p[:id] }
    elsif params[:context]
      recipient_ids = matching_participants(:context => params[:context]).map{ |p| p[:id] }
    end
    @conversation.add_participants(recipient_ids) if recipient_ids.present?
  end

  def add_message
    if params[:body]
      @conversation.add_message(params[:body])
    end
  end

  def remove_messages
    if params[:remove]
      still_has_messages = false
      to_delete = []
      @conversation.messages.each do |message|
        to_delete << message if params[:remove].include?(message.id)
      end
      @conversation.messages.delete(*to_delete)
      # if the only messages left are generated ones, e.g. "added
      # bob to the conversation", delete those too
      @conversation.messages.clear if @conversation.messages.all?(&:generated?)
      @conversation.update_last_message_at
    end
  end

  def find_recipients
    max_results = 20
    recipients = []
    if params[:context]
      recipients = matching_participants(:search => params[:search], :context => params[:context], :limit => max_results)
    elsif params[:search]
      recipients = matching_contexts(params[:search]) + matching_participants(:search => params[:search], :limit => max_results)
    end
    render :json => recipients[0, max_results]
  end

  private

  def load_all_contexts
    @contexts = {:courses => {}, :groups => {}}
    @current_user.courses.active.each do |course|
      @contexts[:courses][course.id] = course
    end
    @current_user.groups.active.each do |group|
      @contexts[:groups][group.id] = group
    end
  end

  def matching_contexts(search)
    @contexts.values.map(&:values).flatten.
      select{ |context| context.name.downcase.include?(search.downcase) }.
      sort_by(&:name).
      map{ |context| {:id => context.is_a?(Course) ? "course_#{context.id}" : "group_#{context.id}", :type => :context, :name => context.name } }
  end

  def matching_participants(options)
    @current_user.messageable_users(options).map { |user|
      data = {:id => user.id, :type => :user, :name => user.name}
      unless options[:context]
        data[:contexts] =
          user.course_ids.to_s.split(/,/).map { |id| @contexts[:courses][id.to_i].name } +
          user.group_ids.to_s.split(/,/).map { |id| @contexts[:groups][id.to_i].name }
      end
      data
    }
  end

  def get_conversation
    @conversation = @current_user.conversations.find(params[:id] || params[:conversation_id])
  end
end