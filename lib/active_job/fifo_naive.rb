# frozen_string_literal: true

require_relative "fifo_naive/version"
require "timeout"

module ActiveJob
  module QueueAdapters
    class FifoNaiveAdapter < AbstractAdapter
      def initialize(fifo_path: "/tmp/active_job_fifo_naive.fifo")
        @fifo = File.open("/tmp/mypipe", File::Constants::WRONLY|File::Constants::NONBLOCK)
        Timeout.timeout(30) do
          @fifo.write("\n") # Ensure the FIFO is created and ready for writing
          @fifo.flush
        end
      rescue Timeout::Error
        raise "Failed to write to FIFO within the timeout period."
      end

      attr_reader :fifo

      def enqueue(job)
        begin
          @fifo.write(job.serialize.to_json + "\n")
          @fifo.flush
        rescue IOError => e
          raise "Failed to enqueue job: #{e.message}"
        end
      end

      def enqueue_at(job, timestamp)
        raise NotImplementedError, "enqueue_at is not supported by FifoNaiveAdapter"
      end
    end
  end

  module FifoNaive
    class Consumer
      def initialize(fifo_path: "/tmp/active_job_fifo_naive.fifo")
        unless File.exist?(fifo_path)
          Rails.logger.info("Creating FIFO at #{fifo_path}")
          File.mkfifo(fifo_path, 0o600)
        end

        if File.stat(fifo_path).ftype != "fifo"
          raise "The specified path #{fifo_path} is not a FIFO. Please ensure it is a named pipe."
        end

        @fifo = File.open(fifo_path, File::Constants::RDONLY|File::Constants::NONBLOCK)
        @threads = []
      end

      attr_reader :fifo, :threads

      def start
        begin
          loop do
            line = @fifo.gets
            if line
              consume_one_job(line)
            end
            cleanup_threads
          end
        rescue EOFError
          Rails.logger.info("FIFO closed, consumer exiting.")
        rescue StandardError => e
          Rails.logger.error("Error consuming job: #{e.message}")
        rescue Interrupt
          Rails.logger.info("Consumer interrupted, gracefully shutting down.")

          while line = @fifo.gets
            consume_one_job(line)
          end
          @fifo.close unless @fifo.closed?

          threads.each do |thread|
            thread.join
          end
          Rails.logger.info("Finishing consumer process.")
        ensure
          @fifo.close if @fifo && !@fifo.closed?
        end
      end

      def self.start(fifo_path: "/tmp/active_job_fifo_naive.fifo")
        consumer = new(fifo_path: fifo_path)
        consumer.start
      end

      private

      def consume_one_job(line)
        job_data = JSON.parse(line)
        job = ActiveJob::Base.deserialize(job_data)
        Railties.logger.info("Consuming job: #{job.inspect}")
        threads << Thread.new do
          job.perform_now
        end
      end

      def cleanup_threads
        @threads.each do |thread|
          thread.join(0.01) # Wait for the thread to finish, but don't block indefinitely
        end
        @threads.select!(&:alive?)
      end
    end
  end
end
