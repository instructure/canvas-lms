require File.expand_path(File.dirname(__FILE__) + '/../common')



  def build_assignment_with_type(type, opts={})
    driver.execute_script %{$('.header_content .add_assignment_link:first').addClass('focus');}
    f(".header_content .add_assignment_link").click
    wait_for_ajaximations

    edit_assignment({:type => type}.merge(opts))
  end

  def edit_assignment(opts={})
    if opts[:type]
      click_option(".assignment_submission_types", opts[:type])
    end

    if opts[:name]
      f('#assignment_title').clear
      f('#assignment_title').send_keys opts[:name]
    end

    if opts[:points]
      f('#assignment_points_possible').clear
      f('#assignment_points_possible').send_keys opts[:points]
    end

    if opts[:submit]
      submit_form("#add_assignment_form")
      wait_for_ajaximations
    end
  end
