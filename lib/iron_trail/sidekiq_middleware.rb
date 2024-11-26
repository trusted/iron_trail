# frozen_string_literal: true

module IronTrail
  class SidekiqMiddleware
    def call(job, _job_hash, queue)
      md = {
        jid: job.jid,
        class: job.class.to_s,
        queue:
      }

      md[:bid] = job.bid if job.bid.present?

      IronTrail.store_metadata(:job, md)

      yield
    end
  end
end
