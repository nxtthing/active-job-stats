module ActiveJobStats
  module LastPerformAt
    extend ActiveSupport::Concern

    included do
      class_attribute :ajs_last_perform_at_expire_in, instance_accessor: false
      class_attribute :ajs_last_perform_at_prefix, instance_accessor: false
    end

    class_methods do
      def track_last_performed_at(expire_in: 6.months)
        self.ajs_last_perform_at_prefix = self.name
        self.ajs_last_perform_at_expire_in = expire_in.to_i
        after_perform do # |job|
          RedisConnection.with { |conn| conn.setex(last_performed_at_key, 6.months.to_i, Time.current.iso8601) }
        end
      end

      def last_performed_at
        last_performed_at_str = RedisConnection.with { |conn| conn.get(last_performed_at_key) }
        last_performed_at_str ? Time.zone.parse(last_performed_at_str) : nil
      end

      private

      def last_performed_at_key
        "active_job_last_performed_at_#{self.ajs_last_perform_at_prefix || raise("not tracked")}"
      end
    end
  end
end
