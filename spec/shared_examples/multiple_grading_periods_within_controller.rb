shared_context "multiple grading periods within controller" do
  let(:root_account) { course.root_account }

  it "injects grading periods into the JS ENV if Multiple Grading Periods is enabled" do
    root_account.enable_feature!(:multiple_grading_periods)
    user_session(teacher)
    get(*request_params)
    expect(assigns[:js_env]).to have_key(:active_grading_periods)
  end

  it "includes 'last' and 'closed' data on each grading period " do
    root_account.enable_feature!(:multiple_grading_periods)
    group = root_account.grading_period_groups.create!
    group.enrollment_terms << course.enrollment_term
    group.grading_periods.create!(title: "hi", start_date: 3.days.ago, end_date: 3.days.from_now)
    user_session(teacher)
    get(*request_params)
    period = assigns[:js_env][:active_grading_periods].first
    expect(period.keys).to include("is_closed", "is_last")
  end

  it "does not inject grading periods into the JS ENV if Multiple Grading Periods is disabled" do
    user_session(teacher)
    get(*request_params)
    expect(assigns[:js_env]).not_to have_key(:active_grading_periods)
  end
end
