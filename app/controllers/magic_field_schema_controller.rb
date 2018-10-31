class MagicFieldSchemaController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :verify_api_token

  def update
    @mfs = MagicFieldSchema.for_key(params[:id])
    res = {}
    res["old"] = @mfs.schema_json
    @mfs.schema_json = params[:schema_json]
    @mfs.save
    res["result"] = "updated"
    res["new"] = @mfs.schema_json
    render :json => res
  end

  def create
    # this doesn't quite obey the normal create things - it can take a whole array
    # and create as many as it needs, not just one at a time.
    old = []
    got = JSON.parse(params[:schema_json])
    got.each do |obj|
      mfs = MagicFieldSchema.for_key(obj["field_key"])
      mfs.schema_json = obj.to_json
      mfs.save
      old << JSON.parse(mfs.schema_json)
    end

    res = {}
    res["old"] = old
    res["new"] = got
    res["result"] = "bulk updated"
    render :json => res
  end

  def show
    @mfs = MagicFieldSchema.for_key(params[:id])
    render :json => @mfs.schema_json
  end

  def destroy
    @mfs = MagicFieldSchema.for_key(params[:id])
    @mfs.destroy
    res = {}
    res["old"] = @mfs.schema_json
    res["result"] = "deleted"
    render :json => res
  end

  def index
    # lists all in json
    json = "["
    first = true
    MagicFieldSchema.all.each do |mfs|
      if first
        first = false
      else
        json += ","
      end

      json += "\"#{mfs.field_key}\":#{mfs.schema_json}"
    end
    json += "]"
    render :json => json
  end



  def verify_api_token
    access_token = AccessToken.authenticate(params[:access_token])
    if access_token.nil?
      raise Exception.new "Access denied"
    end

    requesting_user = access_token.user
    # we should prolly allow designer accounts to access too, but
    # for now i just want to use the admin access token for myself
    if requesting_user.id != 1
      raise Exception.new "Not admin"
    end
  end

  def new
    # irrelevant; this is only used by api and thus needs no ui
    raise Exception.new "only access from api"
  end

  def edit
    # irrelevant too
    raise Exception.new "only access from api"
  end
end
