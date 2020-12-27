require 'dotenv'
Dotenv.load

env :PATH, ENV['PATH']

set :chronic_options, hours24: true
set :output, "cron_log.log"
set :job_template, "/bin/ash -l -c ':job'"

every 1.day, at: "#{ENV['CRON_TIME']}" do
    command "cd #{Dir.pwd} && ruby LMEEvenFec.rb"
end