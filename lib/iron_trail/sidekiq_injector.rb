# frozen_string_literal: true

module IronTrail
  class SidekiqInjector
    attr_accessor :config

    def self.install_sidekiq_middleware
      Sidekiq.configure_server do |config|
        config.server_middleware do |chain|
          chain.add ::IronTrail::SidekiqInjector
        end
      end
    end

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
