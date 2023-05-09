#!/usr/bin/env ruby

require 'fileutils'
require 'etc'

APP_ROOT = "/home/webapp/webapp/current"
FOREMAN_BIN = "RBENV_ROOT=/home/webapp/.rbenv exec /home/webapp/.rbenv/libexec/rbenv exec foreman"
PROCFILE = "#{APP_ROOT}/Procfile"
PIDFILE = "/home/webapp/webapp/shared/foreman.pid"
LOG_DIR = "/home/webapp/webapp/current/logs"
RUN_AS_USER = "webapp"
DAEMON_PIDFILE = "/home/webapp/webapp/foreman_daemon.pid"
FOREMAN_START_COMMAND = "#{FOREMAN_BIN} start -f #{PROCFILE} -d #{APP_ROOT} -r /home/webapp/webapp/shared > #{LOG_DIR}/foreman.log 2>&1"

system(FOREMAN_START_COMMAND)