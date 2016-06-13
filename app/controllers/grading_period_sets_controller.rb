class GradingPeriodSetsController < ApplicationController
  include ::Filters::GradingPeriods

  before_action :require_user
  before_action :get_context
  before_action :check_feature_flag
  before_action :check_manage_rights, except: [:index]
  before_action :check_read_rights, except: [:update, :create, :destroy]

  def index
    paginated_sets = Api.paginate(
      GradingPeriodGroup.for(@context),
      self,
      api_v1_account_grading_period_sets_url
    )
    meta = Api.jsonapi_meta(paginated_sets, self, api_v1_account_grading_period_sets_url)

    respond_to do |format|
      format.json { render json: serialize_json_api(paginated_sets, meta) }
    end
  end

  def create
    grading_period_sets = GradingPeriodGroup.for(@context)
    grading_period_set = grading_period_sets.build(set_params)
    grading_period_set.enrollment_terms = enrollment_terms

    respond_to do |format|
      if grading_period_set.save
        serialized_set = GradingPeriodSetSerializer.new(
          grading_period_set,
          controller: self,
          scope: @current_user,
          root: true
        )

        format.json { render json: serialized_set, status: :created }
      else
        format.json { render json: grading_period_set.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    grading_period_set.enrollment_terms = enrollment_terms

    respond_to do |format|
      if grading_period_set.update(set_params)
        format.json { head :no_content }
      else
        format.json { render json: grading_period_set.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    grading_period_set.destroy
    respond_to do |format|
      format.json { head :no_content }
    end
  end

  private

  def enrollment_terms
    return [] unless params[:enrollment_term_ids]
    @context.enrollment_terms.active.find(params[:enrollment_term_ids])
  end

  def grading_period_set
    @grading_period_set ||= GradingPeriodGroup
      .for(@context)
      .find(params[:id])
  end

  def set_params
    strong_params.require(:grading_period_set).permit(:title)
  end

  def check_read_rights
    render_json_unauthorized and return unless @context.grants_right?(@current_user, :read)
  end

  def check_manage_rights
    render_json_unauthorized and return unless @context.root_account?
    render_json_unauthorized and return unless @context.grants_right?(@current_user, :manage)
  end

  def paginate_for(grading_period_sets)
    paginated_sets, meta = Api.jsonapi_paginate(
      grading_period_sets,
      self,
      api_v1_account_grading_period_sets_url
    )
    meta[:primaryCollection] = 'grading_period_sets'
    [paginated_sets, meta]
  end

  def serialize_json_api(grading_period_sets, meta = {})
    Canvas::APIArraySerializer.new(grading_period_sets, {
      each_serializer: GradingPeriodSetSerializer,
      controller: self,
      root: :grading_period_sets,
      meta: meta,
      scope: @current_user,
      include_root: false
    })
  end
end
