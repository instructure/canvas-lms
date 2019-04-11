
## To trigger a DEBUG build, replace AUTH_TOKEN and JOB_ID with your values

curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token AUTH_TOKEN" \
  -d "{\"quiet\": true}" \
  https://api.travis-ci.org/job/JOB_ID/debug

## Easier copy/paste

curl -s -X POST   -H "Content-Type: application/json"   -H "Accept: application/json"   -H "Travis-API-Version: 3"   -H "Authorization: token AUTH_TOKEN"   -d "{\"quiet\": true}"   https://api.travis-ci.org/job/JOB_ID/debug


## Help commands when at command line on debug build VM

- travis_run_before_install
- travis_run_install
- travis_run_before_script
- travis_run_script
- travis_run_after_success
- travis_run_after_failure
- travis_run_after_script


## Chrome binary is at
    google-chrome-stable


## To scroll in tmux when on debug build VM, will see lil yellow box in top-right corner
    ctrl+b, [

## To exit scroll
    esc


## CI User Agent
    Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/73.0.3683.103 Safari/537.36


## Read More
[https://docs.travis-ci.com/user/running-build-in-debug-mode/#things-to-do-once-you-are-inside-the-debug-vm](https://docs.travis-ci.com/user/running-build-in-debug-mode/#things-to-do-once-you-are-inside-the-debug-vm)

## Stuff
Local User Agent
Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36
