# Fails roughly a third of the time, on purpose, so the Background namespace in
# AppSignal has both successful and failing job samples to look at.
class StockReconciliationJob < ApplicationJob
  class SupplierFeedError < StandardError; end

  queue_as :default
  retry_on SupplierFeedError, attempts: 2, wait: 1.second

  def perform(index)
    Appsignal.add_tags(job_index: index) if defined?(Appsignal)

    sleep(rand(0.1..0.6))

    product = Product.order(Arel.sql("RANDOM()")).first
    raise SupplierFeedError, "Supplier feed returned no stock line for #{product&.slug || "unknown"}" if (index % 3).zero?

    Appsignal.increment_counter("stock_reconciled", 1) if defined?(Appsignal)
    Rails.logger.info("Reconciled stock for #{product&.slug}")
  end
end
