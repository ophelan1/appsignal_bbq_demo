# Stands in for the email you would really send. Exists so there is a genuine
# Active Job trace in AppSignal on every checkout.
class OrderConfirmationJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.includes(order_items: :product).find(order_id)

    # Pretend to render and deliver a confirmation email.
    sleep(rand(0.05..0.25))

    Rails.logger.info(
      "Confirmation for #{order.reference} to #{order.email} " \
      "(#{order.item_count} items, #{order.total_cents} cents)"
    )

    Appsignal.increment_counter("confirmations_sent", 1) if defined?(Appsignal)
  end
end
