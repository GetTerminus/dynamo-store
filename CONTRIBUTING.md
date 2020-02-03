## Pushing Code

Ensure the following are successful before pushing:

* `bundle exec appraisal install`
* `bundle exec appraisal rpsec`

If specs and `bundle exec appraisal install` pass locally, but `bundle install` commands fail on CI, comment out the `restore_cache` CI steps and the `--path vendor/bundle` flag from the `bundle install` command. This will bust the cache. Add those back in once you have a green CI build.