#!/usr/bin/env bash
set -eu
bundle exec jekyll serve --livereload --config _config.yml,_config_dev.yml
