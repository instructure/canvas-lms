require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'nokogiri'

describe PlannerHelper do
  include PlannerHelper

  it 'should create errors for bad dates' do
    formatted_planner_date('start_date', '123-456-789')
    formatted_planner_date('end_date', '9876-5-4321')
    expect(@errors['start_date']).to eq 'Invalid date or invalid datetime for start_date'
    expect(@errors['end_date']).to eq 'Invalid date or invalid datetime for end_date'
  end
end
