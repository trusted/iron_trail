# frozen_string_literal: true

module IronTrail
  class SidekiqMiddleware
    def call(job, _job_hash, queue)
      md = {
        jid: job.jid,
        class: job.class.to_s,
        queue:
      }

      # Job batch ID. Requires sidekiq-pro
      md[:bid] = job.bid if job.respond_to?(:bid) && job.bid.present?

      IronTrail.store_metadata(:job, md)

      yield
    end
  end
end
