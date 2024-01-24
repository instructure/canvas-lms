# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

# TODO: eliminate this controller in favor of the generic ReactContentController
# once the legacy grading_periods sub tab is reworked to not need the .scss
# bundles included below with css_bundle

class LearnerPassportController < ApplicationController
  CACHE_EXPIRATION = 1.day
  before_action :require_context
  before_action :require_user
  before_action :require_learner_passport_feature_flag

  def merge_skills_from_achievements(achievements)
    skills = []
    achievements.each do |achievement|
      skills += achievement[:skills] if achievement[:skills].present?
    end
    skills.uniq! { |s| s[:name] }
    skills
  end

  def learner_passport_current_achievements
    [
      {
        id: "1",
        isNew: true,
        title: "Product Management Short Course",
        issuer: {
          name: "General Assembly",
          url: "https://generalassemb.ly/education/product-management/new-york-city",
          iconUrl:
            "data:image/png;base64,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"
        },
        issuedOn: "2023-10-30",
        expiresOn: "2033-10-30",
        type: "Certificate of Completion",
        criteria:
          "To earn this badge, participants must complete 50 yours of study over 10 weeks, and complete a case study project.",
        skills: [
          { name: "Product Management", verified: true, url: "https://generalassemb.ly/education/product-management" },
          { name: "Product Strategy", verified: false },
          { name: "Market Research", verified: false },
          { name: "User Research", verified: false }
        ],
        imageUrl: nil,
        verifiedBy: "Open Badges"
      },
      {
        id: "2",
        isNew: false,
        title: "B.S. in Computer Science",
        issuer: {
          name: "The Ohio State University",
          url: "https://www.osu.edu/"
        },
        issuedOn: "2020-05-03",
        expiresOn: nil,
        type: "Bachelor of Science",
        skills: [
          { name: "JavaScript", verified: true },
          { name: "SQL", verified: true },
          { name: "React", verified: true },
          { name: "KPIs", verified: true },
        ],
        imageUrl: "https://www.osu.edu/images/osu-logo-blocko.svg",
        verifiedBy: "Open Badges"
      },
      {
        id: "3",
        isNew: false,
        title: "National Merit Scholar",
        issuer: {
          name: "NMSC",
          url: "https://www.nationalmerit.org/"
        },
        issuedOn: "2016-10-03",
        expiresOn: nil,
        imageUrl: "https://www.nationalmerit.org/s/1758/images/logo.png",
        verifiedBy: nil
      },
      {
        id: "4",
        isNew: false,
        title: "CPS High School Diploma",
        issuer: {
          name: "Walnut Hills High School",
          url: "http://www.walnuthillseagles.com/",
          iconUrl: "http://www.walnuthillseagles.com/images/walnut-hills-logo.png"
        },
        issuedOn: "2016-05-27",
        expiresOn: nil,
        imageUrl: "http://www.walnuthillseagles.com/images/walnut-hills-logo.png",
        verifiedBy: nil
      }
    ]
  end

  def learner_passport_project_sample
    {
      id: "1",
      title: "Project 1",
      heroImageUrl: "https://images.unsplash.com/photo-1464802686167-b939a6910659?q=80&w=3500&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      description: %(
        Over the last four months, we had the opportunity to collaborate with 99P Labs for our graduate program’s
        (<a href="https;//wikipedia.com">Master of Science in Product Management</a>) semester-long capstone project. We were delighted to work on a
        really exciting problem that helped us hone some of the key concepts that we had learned as a part of our curriculum,
        such as analyzing KPIs, writing user stories, conducting user research, and prototyping. Our problem statement
        was to increase organic engagement for the developer portal of 99P Labs (<a href="https://developer.99plabs.io/home/">
        https://developer.99plabs.io/home/</a>).
      ).html_safe,
      skills: merge_skills_from_achievements(Rails.cache.fetch(current_achievements_key) { learner_passport_current_achievements }),
      attachments: [
        {
          id: "1",
          filename: "99b+White+Paper.pdf",
          display_name: "99b White Paper.pdf",
          size: "1234567",
          contentType: "application/pdf",
          url: "http://localhost:3000/courses/2/files/11",
        },
        {
          id: "2",
          filename: "plain+text.txt",
          display_name: "plain text.txt",
          size: "5432",
          contentType: "text/plain",
          url: "https://filesamples.com/samples/document/txt/sample3.txt"
        }
      ],
      links: %w[https://linkedin.com/in/eschiebel https://www.nspe.org https://eschiebel.github.io/],
      achievements: Rails.cache.fetch(current_achievements_key) { learner_passport_current_achievements }.first(1).clone,
    }
  end

  def learner_passport_project_template
    {
      id: "",
      title: "",
      heroImageUrl: "",
      description: "",
      skills: [],
      attachments: [],
      links: [],
      achievements: [],
    }
  end

  def learner_passport_portfolio_sample
    {
      id: "1",
      title: "A portfolio of my work",
      blurb: "A generally groovy person you want to know",
      city: "Columbus",
      state: "OH",
      phone: "888-555-1212",
      email: "me@example.com",
      heroImageUrl:
        "https://images.unsplash.com/photo-1464802686167-b939a6910659?q=80&w=3500&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      about: %(
            I am a recent computer science graduate from Ohio State University, and have also completed a General Assembly certification
          in Product Management. I bring a strong technical foundation from my computer science degree and have a deep passion for product
            management. My unique blend of technical skills and product management knowledge allows me to bridge the gap between
            technology and business strategy. I am eager to grow and contribute in my first role as a product manager and am committed to
            continuous learning.
        ),
      skills: merge_skills_from_achievements(learner_passport_current_achievements),
      links: %w[https://linkedin.com/in/eschiebel https://www.nspe.org https://eschiebel.github.io/],
      education: [
        {
          id: "1",
          title: "Product Management Certificate",
          city: "Raleigh",
          state: "NC",
          institution: "General Assembly",
          from_date: "2023-04",
          to_date: "2023-10",
          gpa: "3.8"
        },
        {
          id: "2",
          title: "Bachelor's in Computer Science",
          institution: "The Ohio State University",
          city: "Columbus",
          state: "OH",
          from_date: "2018-09",
          to_date: "2022-05",
          gpa: "3.8"
        },
        {
          id: "3",
          title: "High School Diploma",
          institution: "Walnut Hills High School",
          city: "Cincinnati",
          state: "OH",
          from_date: "2004-09",
          to_date: "2018-05",
          gpa: "3.7"
        }
      ],
      experience: [
        {
          id: "1",
          where: "Pendo",
          title: "Software Engineering Team",
          from_date: "2023-08",
          to_date: "2023-10",
          description: %(
                  <div style="font-weight: bold">Feature Development</div>
                  <ul>
                  <li>
                  Collaborate with the engineering team to create and maintain customer-facing features using technologies like Vue, Vuex, Highcharts, Jest, and Cypress.
                  </li><li>
                  Work on various aspects of Pendo's Guide product, including Guide Building, Guide Management, Guide Analytics, and Guide Display.
                  </li>
                  </ul>
                  <div style="font-weight: bold">Technical Stack</div>
                  <ul><li>
                  Utilize technologies such as Vue2, Cypress, Jest, and JavaScript to develop and maintain features.
                  </li><li>
                  Focus on ensuring a high-quality product through unit testing and automation.
                  </li></ul>
                  <div style="font-weight: bold">Process Imaprovement</div>
                  <ul><li>
                  Contribute to enhancing the Continuous Integration/Continuous Delivery (CI/CD) processes, reducing manual effort for releases.
                  </li></ul>
                  <div style="font-weight: bold">Collaboration and Code Review</div>
                  <ul><li>
                  Collaborate closely with other team members through activities like pair programming and code reviews.
                  </li><li>
                  Provide technical guidance to teammates through code and design reviews.
                  </li></ul>
                  <div style="font-weight: bold">Problem Solving</div>
                  <ul><li>
                  Help diagnose and troubleshoot customer issues in real-time during customer calls.
                  </li><li>
                  Participate in cross-team initiatives aimed at improving technology and work culture.
                  </li></ul>
                ).html_safe,
        },
        {
          id: "2",
          where: "Instructure",
          title: "Software Engineering Intern",
          from_date: "2022-08",
          to_date: "2023-08",
          description: %(
                  <p>I did some cool stuff here.</p>
                ).html_safe,
        },
      ],
      projects: [learner_passport_project_sample.clone],
      achievements: learner_passport_current_achievements.first(2).clone
    }
  end

  def learner_passport_portfolio_template
    {
      id: "",
      title: "",
      blurb: "",
      city: "",
      state: "",
      phone: "",
      email: "",
      heroImageUrl: "",
      about: "",
      skills: merge_skills_from_achievements(learner_passport_current_achievements),
      links: [],
      education: learner_passport_portfolio_sample[:education].clone,
      experience: learner_passport_portfolio_sample[:experience].clone,
      projects: learner_passport_portfolio_sample[:projects].clone,
      achievements: [],
    }
  end

  # ------------- pathways -------------

  def learner_passport_learner_groups
    [
      {
        id: "1",
        name: "2022-23 Business Foundations",
        memberCount: 63,
      },
      {
        id: "2",
        name: "2022-23 Business Foundations Cohort 1",
        memberCount: 27,
      },
      {
        id: "3",
        name: "2022-23 Business Foundations Cohort 2",
        memberCount: 36,
      },
      {
        id: "4",
        name: "Marketing Test Group",
        memberCount: 12,
      }
    ]
  end

  def learner_passport_pathway_achievements
    [
      {
        id: "1",
        title: "Business Foundations Specialization Badge",
        image: "data:image/jpeg;base64,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",
        issuer: {
          name: "Wharton University of Pennsylvania",
          url: "https://www.wharton.upenn.edu/"
        },
        type: "Canvas Course Assessment Completion",
        criteria:
          "To earn this certificate, participants must complete 5 milestones and 10 requirements outlined in the Business Foundations Specialization pathway.",
        skills: [
          "Financial Accountint",
          "Marketing Strategy",
          "Operations Management",
          "Change Management",
          "Decision Making"
        ]
      },
      {
        id: "2",
        title: "Product Management Certification",
        image: "data:image/jpeg;base64,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",
        issuer: {
          name: "Wharton University of Pennsylvania",
          url: "https://www.wharton.upenn.edu/"
        },
        type: "Canvas Course Assessment Completion",
        criteria: "To earn this certificate, parcipants must pass the course",
        skills: []
      },
      {
        id: "3",
        title: "English 101",
        image: "data:image/jpeg;base64,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",
        issuer: {
          name: "Wharton University of Pennsylvania",
          url: "https://www.wharton.upenn.edu/"
        },
        type: "Canvas Course Assessment Completion",
        criteria: "To earn this certificate, parcipants must pass the course",
        skills: []
      },
      {
        id: "4",
        title: "Pre-Med",
        image: "data:image/jpeg;base64,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",
        issuer: {
          name: "Wharton University of Pennsylvania",
          url: "https://www.wharton.upenn.edu/"
        },
        type: "Canvas Course Assessment Completion",
        criteria: "To earn this certificate, parcipants must pass the course",
        skills: []
      }
    ]
  end

  # A pathway is a tree of milestones
  # The pathway is at the root, with first_milestones containing the id's of its children
  # Then each milestone has its data plus next_milestones containing the id's of its children
  def learner_passport_pathway_template
    {
      id: "",
      title: "",
      description: "",
      published: nil,
      is_private: false,
      enrolled_student_count: 0,
      started_count: 0,
      completed_count: 0,
      first_milestones: [],
      milestones: [],
      completion_award: nil, # id of entry in learner_passport_pathway_achievements
      learner_groups: [],
      shares: [],
    }
  end

  def learner_passport_pathway_sample
    {
      id: "1",
      title: "Business Foundations Specialization",
      description: "Solve Real Business Problems. Build a foundation of core business skills in marketing, finance, accounting and operations.",
      published: "2024-01-03",
      is_private: false,
      enrolled_student_count: 63,
      started_count: 42,
      completed_count: 15,
      completion_award: "1",
      first_milestones: ["1", "2"],
      milestones: [
        {
          id: "1",
          title: "Introduction to Marketing",
          description: "Taught by three of Warton's top faculty in the marketing department, consistently raked as the #1 business school in the world, this course covers three core topics in customer loyalty: branding, customer centricity, and practical, go-to-market strategies.",
          required: true,
          completion_award: nil,
          requirements: [
            {
              id: "1",
              name: "Create a marketing plan",
              description: "Create a marketing plan for a product or service and present it in a professional format, with marketing research, strategy, and budget.",
              required: true,
              type: "project",
            },
            {
              id: "2",
              name: "Complete a marketing analysis",
              description: "Complete a marketing analysis of a product or service, compile the analysis into a professional format, and present the analysis with recommendations for future action.",
              required: true,
              type: "project"
            },
          ],
          next_milestones: ["3", "4"]
        },
        {
          id: "2",
          title: "Introduction to Financial Accounting",
          description: "Master the technical skills needed to analyze financial statements and disclosures for use in financial analysis.",
          required: false,
          completion_award: nil,
          requirements: [{ id: "3" }],
          next_milestones: []
        },
        {
          id: "3",
          title: "Marketing Strategy and Brand Positioning",
          description: "Professor Kahn starts us off with the first of two Branding modules: Marketing Strategy and Brand Positioning. Then, you'll move on to the second Branding module where we'll teach you to analyze end line data and develop insights to guide your brand strategy.",
          required: true,
          completion_award: nil,
          requirements: [{ id: "4" }, { id: "5" }],
          next_milestones: []
        },
        {
          id: "4",
          title: "The Limits of Product-Centric Thinking & The Opportunities and Challenges of Customer Centricity",
          description: "Module 2 of our class features Professor Peter Fader, who will focus on concepts related to Customer Centric Marketing. In an economy that is increasingly responsive to customer behaviors, it is imperative to focus on the right customers for strategic advantages. You will learn how to acquire and retain the right customers, generate more profits from them and evaluate the effectiveness of your marketing activities.",
          required: true,
          completion_award: nil,
          requirements: [{ id: "6" }, { id: "7" }],
          next_milestones: ["5"]
        },
        {
          id: "5",
          title: "Communications Strategy & Fundamentals of Pricing",
          description: "Complte this course as part of the Wharton's Business Foundations Specialization, and you'll have the opportunity to learn the essentials of marketing management while earning an online certificate from The Wharton School!",
          required: true,
          completion_award: nil,
          requirements: [],
          next_milestones: []
        }
      ],
      learning_outcomes: [],
      achievements_earned: [],
      learner_groups: ["2", "3"],
      shares: [
        {
          id: "rs1",
          name: "Mick Jagger",
          sortable_name: "Jagger, Mick",
          avatar_url: "/images/messages/avatar-50.png",
          role: "collaborator",
        },
        {
          id: "rs2",
          name: "Keith Richards",
          sortable_name: "Richards, Keith",
          avatar_url: "/images/messages/avatar-50.png",
          role: "collaborator",
        },
        {
          id: "rs3",
          name: "Charlie Watts",
          sortable_name: "Watts, Charlie",
          avatar_url: "/images/messages/avatar-50.png",
          role: "viewer",
        },
        {
          id: "rs4",
          name: "Ronnie Wood",
          sortable_name: "Wood, Ronnie",
          avatar_url: "/images/messages/avatar-50.png",
          role: "reviewer",
        },
      ],
    }
  end

  def learner_passport_current_portfolios
    [learner_passport_portfolio_sample.clone]
  end

  def learner_passport_current_projects
    [learner_passport_project_sample.clone]
  end

  def learner_passport_current_pathways
    [learner_passport_pathway_sample.clone]
  end

  def current_achievements_key
    "learner_passport_current_achievements #{@current_user.global_id}"
  end

  def portfolio_sample_key
    "learner_passport_portfolio_sample #{@current_user.global_id}"
  end

  def portfolio_template_key
    "learner_passport_portfolio_template #{@current_user.global_id}"
  end

  def current_portfolios_key
    "learner_passport_current_portfolios #{@current_user.global_id}"
  end

  def project_template_key
    "learner_passport_project_template #{@current_user.global_id}"
  end

  def project_sample_key
    "learner_passport_project_sample #{@current_user.global_id}"
  end

  def current_projects_key
    "learner_passport_current_projects #{@current_user.global_id}"
  end

  def current_pathways_key
    "lerner_passport_current_pathways #{@current_user.global_id}"
  end

  def pathway_template_key
    "learner_passport_pathway_template #{@current_user.global_id}"
  end

  def pathway_sample_key
    "learner_passport_pathway_sample #{@current_user.global_id}"
  end

  def index
    js_env[:FEATURES][:learner_passport] = @domain_root_account.feature_enabled?(:learner_passport)
    js_env[:FEATURES][:learner_passport_r2] = @domain_root_account.feature_enabled?(:learner_passport_r2)

    # hide the breadcrumbs application.html.erb renders
    render html: "<style>.ic-app-nav-toggle-and-crumbs.no-print {display: none;}</style>".html_safe,
           layout: true
  end

  def skills_index
    render json: merge_skills_from_achievements(Rails.cache.fetch(current_achievements_key) { learner_passport_current_achievements })
  end

  def achievements_index
    render json: Rails.cache.fetch(current_achievements_key) { learner_passport_current_achievements }
  end

  ######## Portfolios ########

  def portfolios_index
    render json: Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }.map { |p| p.slice(:id, :title, :heroImageUrl) }
  end

  def portfolio_create
    new_portfolio = Rails.cache.fetch(portfolio_template_key) { learner_passport_portfolio_template }.clone
    new_portfolio[:id] = (Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }.length + 1).to_s
    new_portfolio[:title] = params[:title]
    new_portfolio[:phone] = @current_user.phone || ""
    new_portfolio[:email] = @current_user.email || ""
    current_portfolios = Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }
    current_portfolios << new_portfolio
    Rails.cache.write(current_portfolios_key, current_portfolios, expires_in: CACHE_EXPIRATION)
    render json: new_portfolio
  end

  def portfolio_update
    current_portfolios = Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }
    portfolio = current_portfolios.find { |p| p[:id] == params[:portfolio_id] }
    return render json: { message: "Portfolio not found" }, status: :not_found if portfolio.nil?

    portfolio[:skills] = []
    portfolio.each_key do |key|
      next if params[key].nil?

      case key
      when :skills
        params[key].each do |skill|
          portfolio[:skills] << JSON.parse(skill)
        end
      when :education
        portfolio[:education] = JSON.parse(params[:education])
      when :experience
        portfolio[:experience] = JSON.parse(params[:experience])
      when :achievements
        portfolio[:achievements] = Rails.cache.fetch(current_achievements_key) { learner_passport_current_achievements }.select { |a| params[key].include?(a[:id]) }
      when :projects
        portfolio[:projects] = Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }.select { |a| params[key].include?(a[:id]) }
      else
        portfolio[key] = params[key]
      end
    end
    Rails.cache.write(current_portfolios_key, current_portfolios, expires_in: CACHE_EXPIRATION)

    render json: portfolio
  end

  def portfolio_show
    portfolio = Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }.find { |p| p[:id] == params[:portfolio_id] }
    return render json: { message: "Portfolio not found" }, status: :not_found if portfolio.nil?

    render json: portfolio
  end

  def portfolio_duplicate
    current_portfolios = Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }
    portfolio = current_portfolios.find { |p| p[:id] == params[:portfolio_id] }
    new_portfolio = portfolio.clone
    new_portfolio[:id] = (current_portfolios.length + 1).to_s

    new_portfolio[:title] = make_copy_title(portfolio[:title])
    current_portfolios << new_portfolio
    Rails.cache.write(current_portfolios_key, current_portfolios, expires_in: CACHE_EXPIRATION)
    render json: new_portfolio
  end

  def portfolio_delete
    current_portfolios = Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }
    current_portfolios.reject! { |p| p[:id] == params[:portfolio_id] }
    Rails.cache.write(current_portfolios_key, current_portfolios, expires_in: CACHE_EXPIRATION)
    render json: { message: "Portfolio deleted" }, status: :accepted
  end

  def portfolio_edit
    portfolio = Rails.cache.fetch(current_portfolios_key) { learner_passport_current_portfolios }.find { |p| p[:id] == params[:portfolio_id] }
    return render json: { message: "Portfolio not found" }, status: :not_found if portfolio.nil?

    render json: portfolio
  end

  ###### Projects ######
  def projects_index
    render json: Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }.map do |p|
      p.slice(:id, :title, :heroImageUrl, :skills, :attachments, :achievements)
    end
  end

  def project_create
    current_projects = Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }
    new_project = Rails.cache.fetch(project_template_key) { learner_passport_project_template }.clone
    new_project[:id] = (current_projects.length + 1).to_s
    new_project[:title] = params[:title]
    current_projects << new_project
    Rails.cache.write(current_projects_key, current_projects, expires_in: CACHE_EXPIRATION)
    render json: new_project
  end

  def project_update
    current_projects = Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }
    project = current_projects.find { |p| p[:id] == params[:project_id] }
    return render json: { message: "Project not found" }, status: :not_found if project.nil?

    project[:skills] = []
    project[:attachments] = []
    project.each_key do |key|
      next if params[key].nil?

      case key
      when :skills
        params[key].each do |skill|
          project[:skills] << JSON.parse(skill)
        end
      when :attachments
        params[key].each do |attachment|
          project[:attachments] << JSON.parse(attachment)
        end
      when :achievements
        project[:achievements] = Rails.cache.fetch(current_achievements_key) { learner_passport_current_achievements }.select { |a| params[key].include?(a[:id]) }
      else
        project[key] = params[key]
      end
    end
    Rails.cache.write(current_projects_key, current_projects, expires_in: CACHE_EXPIRATION)

    render json: project
  end

  def project_show
    project = Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }.find { |p| p[:id] == params[:project_id] }
    return render json: { message: "Project not found" }, status: :not_found if project.nil?

    render json: project
  end

  def project_duplicate
    current_projects = Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }
    project = current_projects.find { |p| p[:id] == params[:project_id] }
    return render json: { message: "Project not found" }, status: :not_found if project.nil?

    new_project = project.clone
    new_project[:id] = (current_projects.length + 1).to_s
    new_project[:title] = make_copy_title(project[:title])
    current_projects << new_project
    Rails.cache.write(current_projects_key, current_projects, expires_in: CACHE_EXPIRATION)
    render json: new_project
  end

  def project_delete
    current_projects = Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }
    current_projects.reject! { |p| p[:id] == params[:project_id] }
    Rails.cache.write(current_projects_key, current_projects, expires_in: CACHE_EXPIRATION)
    render json: { message: "Project deleted" }, status: :accepted
  end

  def project_edit
    project = Rails.cache.fetch(current_projects_key) { learner_passport_current_projects }.find { |p| p[:id] == params[:project_id] }
    return render json: { message: "Project not found" }, status: :not_found if project.nil?

    render json: project
  end

  ###### Pathways ######

  def pathway_learner_groups_index
    render json: learner_passport_learner_groups
  end

  def pathway_badges_index
    render json: learner_passport_pathway_achievements
  end

  def pathway_canvas_requirements_index
    search_string = params[:search_string] || ""
    return render json: [], status: :no_content if search_string.blank?

    type = params[:type] || "course"

    results = case type
              when "assignment"
                Assignment.where("title LIKE ?", "%#{search_string}%").limit(10).map { |a| { id: a.id, name: a.title, url: "/#{a.context_type}s/#{a.context_id}/assignments/#{a.id}", lo_count: 0 } }
              when "course"
                Course.where("name LIKE ?", "%#{search_string}%").select("id, name, (select count(1) from #{LearningOutcome.quoted_table_name} where learning_outcomes.context_id = courses.id AND learning_outcomes.context_type = 'Course') AS lo_count").limit(10).map { |c| { id: c.id, name: c.name, url: "/courses/#{c.id}", learning_outcome_count: c.lo_count } }
              when "module"
                ContextModule.where("name LIKE ?", "%#{search_string}%").limit(10).map { |m| { id: m.id, name: m.name, url: "/courses/#{m.context_id}/modules/#{m.id}", lo_count: 0 } }
              else
                return render json: { message: "Invalid type" }, status: :bad_request
              end

    render json: results
  end

  def pathways_index
    # return render json: { message: "Permission denied" }, status: :unauthorized unless @current_user.roles.include?("admin")

    pathways = Rails.cache.fetch(current_pathways_key) { learner_passport_current_pathways }.map do |p|
      pw = {
        id: p[:id],
        title: p[:title],
        milestoneCount: p[:milestones].length,
        requirementCount: p[:milestones].reduce(0) { |sum, m| sum + m.with_indifferent_access[:requirements].length },
        enrolled_student_count: p[:enrolled_student_count],
        started_count: p[:started_count],
        completed_count: p[:completed_count],
      }
      pw[:published] = p[:published] if p[:published].present?
      pw
    end
    render json: pathways
  end

  def pathway_create
    new_pathway = Rails.cache.fetch(pathway_template_key) { learner_passport_pathway_template }.clone
    new_pathway[:id] = (Rails.cache.fetch(current_pathways_key) { learner_passport_current_pathways }.length + 1).to_s
    new_pathway[:title] = params[:title]
    current_pathways = Rails.cache.fetch(current_pathways_key) { learner_passport_current_pathways }
    current_pathways << new_pathway
    Rails.cache.write(current_pathways_key, current_pathways, expires_in: CACHE_EXPIRATION)
    render json: new_pathway
  end

  def pathway_update
    current_pathways = Rails.cache.fetch(current_pathways_key) { learner_passport_current_pathways }
    pathway = current_pathways.find { |p| p[:id] == params[:pathway_id] }
    return render json: { message: "Pathway not found" }, status: :not_found if pathway.nil?

    pathway.replace(JSON.parse(params[:pathway]).transform_keys(&:to_sym))
    pathway[:published] = (params[:draft] == "true") ? nil : Date.today.to_s
    Rails.cache.write(current_pathways_key, current_pathways, expires_in: CACHE_EXPIRATION)

    render json: pathway
  end

  def pathway_show
    pathway = if params[:pathway_id] == "new"
                Rails.cache.fetch(pathway_template_key) { learner_passport_pathway_template }.clone
              else
                Rails.cache.fetch(current_pathways_key) { learner_passport_current_pathways }.find { |p| p[:id] == params[:pathway_id] }
              end
    return render json: { message: "Pathway not found" }, status: :not_found if pathway.nil?

    render json: pathway
  end

  def pathway_share_users
    search_term = params[:search_term] || ""
    return render json: [{ message: "search term must be at least 2 characters long" }], status: :bad_request if search_term.blank? || search_term.length < 2

    results = User.where("LOWER(name) LIKE ?", "%#{search_term.downcase}%")
                  .and(User.where(TeacherEnrollment.where("user_id=users.id").arel.exists).or(User.where(AccountUser.where("user_id=users.id").arel.exists)))
                  .order("sortable_name")
                  .limit(10)
                  .map { |u| { id: u.id, name: u.name, sortable_name: u.sortable_name, avatar_url: u.avatar_url, role: "viewer" } }

    # results = UserSearch.for_user_in_context(search_term,
    #                                          Account.default,
    #                                          @current_user,
    #                                          session,
    #                                          {
    #                                            order: "asc",
    #                                            sort: "sortable_name",
    #                                            enrollment_type: "teacher_enrollment",
    #                                            include_deleted_users: false
    #                                          })
    render json: results
  end

  def reset
    if params.key? :empty
      Rails.cache.write(current_portfolios_key, [], expires_in: CACHE_EXPIRATION)
      Rails.cache.write(current_projects_key, [], expires_in: CACHE_EXPIRATION)
      Rails.cache.write(current_pathways_key, [], expires_in: CACHE_EXPIRATION)
    else
      sample_portfolio = Rails.cache.fetch(portfolio_sample_key) { learner_passport_portfolio_sample }
      Rails.cache.write(current_portfolios_key, [sample_portfolio.clone], expires_in: CACHE_EXPIRATION)
      sample_project = Rails.cache.fetch(project_sample_key) { learner_passport_project_sample }
      Rails.cache.write(current_projects_key, [sample_project.clone], expires_in: CACHE_EXPIRATION)
      sample_pathway = Rails.cache.fetch(pathway_sample_key) { learner_passport_pathway_sample }
      Rails.cache.write(current_pathways_key, [sample_pathway.clone], expires_in: CACHE_EXPIRATION)
    end
    render json: { message: "Portfolios reset" }, status: :accepted
  end

  private

  def require_learner_passport_feature_flag
    unless @domain_root_account.feature_enabled?(:learner_passport)
      render status: :not_found, template: "shared/errors/404_message"
    end
  end

  def make_copy_title(title)
    md = (/copy(\d*)$/.match title)
    return "#{title} - copy" if md.nil?

    new_count = md.captures[0].blank? ? 1 : md.captures[0].to_i + 1
    title.sub(/copy\d*$/, "copy#{new_count}")
  end
end
