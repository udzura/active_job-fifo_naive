class TodoJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "TodoJob started: #{Time.current.rfc3339}, args: #{args.inspect}"
    # Running very log job
    job_going_to_elapse = rand(5..10)
    Rails.logger.info "TodoJob will take: #{job_going_to_elapse} seconds"
    sleep job_going_to_elapse
    Rails.logger.info "TodoJob finished: #{Time.current.rfc3339}"
  end
end
