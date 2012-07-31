class ExternalFeedsController < ApplicationController
  include Api::V1::ExternalFeeds

  before_filter :require_context, :except => :public_feed

  # @API List external feeds
  #
  # Returns the list of External Feeds this course or group.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/external_feeds \ 
  #          -H 'Authorization: Bearer <token>'
  #
  def index
    if authorized_action(@context, @current_user, :read)
      render :json => external_feeds_api_json(@context.external_feeds.for('announcements'), @context, @current_user, session)
    end
  end

  # @API Create a new external feed
  #
  # Create a new external feed for the course or group.
  #
  # @argument url
  # @argument header_match you can only include posts that have a specific phrase in title by passing the phrase here.
  # @argument verbosity options are:  full, truncate, or link_only
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/external_feeds \ 
  #         -F title='http://example.com/rss.xml' \ 
  #         -F header_match='news flash!' \ 
  #         -F verbosity='full' \ 
  #         -H 'Authorization: Bearer <token>'
  #
  def create
    if authorized_action(@context.announcements.new, @current_user, :create)
      @feed = create_api_external_feed(@context, params, @current_user)
      if @feed.save
        render :json => external_feed_api_json(@feed, @context, @current_user, session)
      else
        render :json => @feed.errors.to_json, :response => :bad_request
      end
    end
  end

  # @API Delete an external feed
  #
  # Deletes the external feed.
  #
  # @example_request
  #     curl -X DELETE https://<canvas>/api/v1/courses/<course_id>/external_feeds/<feed_id> \ 
  #          -H 'Authorization: Bearer <token>'
  def destroy
    if authorized_action(@context.announcements.new, @current_user, :create)
      @feed = @context.external_feeds.find(params[:external_feed_id])
      if @feed.destroy
        render :json => external_feed_api_json(@feed, @context, @current_user, session)
      else
        render :json => @feed.errors.to_json, :response => :bad_request
      end
    end
  end

end
