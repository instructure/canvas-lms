### Run Canvas Spec(s)
    bundle                                                   # make sure Canvas bundle is setup
    bin/rspec spec/selenium/add_people/add_people_spec.rb    # run Canvas core specs

### Run StrongMind Spec(s)
    STRONGMIND_SPEC=1 bundle                                 # make sure your StrongMind bundle is setup
    STRONGMIND_SPEC=1 bundle exec rspec spec_strongmind/     # run StrongMind specs with bundle
    HEADLESS=1 STRONGMIND_SPEC=1 bundle exec rspec spec_strongmind/features     # run feature specs headless

### You can get faster test runs using Spring
Use **bin/rspec** instead of **bundle exec rspec**

Warning! For some unknown reason Feature specs hang with bin/rspec.
So make sure you filter the
specs you run with it.