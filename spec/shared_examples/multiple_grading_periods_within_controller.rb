shared_context "grading periods within controller" do
  let(:root_account) { course.root_account }

  it "injects grading periods into the JS ENV if grading periods exist" do
    group = root_account.grading_period_groups.create!
    group.enrollment_terms << course.enrollment_term
    user_session(teacher)
    get(*request_params)
    expect(assigns[:js_env]).to have_key(:active_grading_periods)
  end

  it "includes 'last' and 'closed' data on each grading period " do
    group = root_account.grading_period_groups.create!
    group.enrollment_terms << course.enrollment_term
    group.grading_periods.create!(title: "hi", start_date: 3.days.ago, end_date: 3.days.from_now)
    user_session(teacher)
    get(*request_params)
    period = assigns[:js_env][:active_grading_periods].first
    expect(period.keys).to include("is_closed", "is_last")
  end

  it "does not inject grading periods into the JS ENV if there are no grading periods" do
    user_session(teacher)
    get(*request_params)
    expect(assigns[:js_env]).not_to have_key(:active_grading_periods)
  end
end
