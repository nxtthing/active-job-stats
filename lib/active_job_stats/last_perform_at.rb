module ActiveJobStats
  module LastPerformAt
    extend ActiveSupport::Concern

    included do
      after_perform do # |job|
        RedisConnection.with { |conn| conn.setex(self.class.last_performed_at_key, 6.months.to_i, Time.current.iso8601) }
      end
    end

    class_methods do
      def last_performed_at_key
        "active_job_last_performed_at_#{name}"
      end

      def last_performed_at
        last_performed_at_str = RedisConnection.with { |conn| conn.get(last_performed_at_key) }
        last_performed_at_str ? Time.zone.parse(last_performed_at_str) : nil
      end
    end
  end
end
