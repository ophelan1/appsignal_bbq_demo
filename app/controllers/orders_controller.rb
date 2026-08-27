class OrdersController < ApplicationController
  def index
    @orders = Order.includes(order_items: :product).order(created_at: :desc).limit(50)
  end

  def new
    redirect_to(cart_path) and return if current_cart.empty?

    @order = Order.new
  end

  def create
    redirect_to(cart_path) and return if current_cart.empty?

    @order = Order.new(order_params)
    current_cart.lines.each do |line|
      @order.order_items.build(
        product: line.product,
        quantity: line.quantity,
        unit_cents: line.product.price_cents
      )
    end
    @order.recalculate_totals!

    if @order.save
      # A real Active Job trace in AppSignal, without needing Redis.
      OrderConfirmationJob.perform_later(@order.id)

      if defined?(Appsignal)
        Appsignal.add_tags(order_reference: @order.reference)
        Appsignal.increment_counter("orders_placed", 1)
        Appsignal.add_distribution_value("order_value_cents", @order.total_cents)
      end

      current_cart.clear
      redirect_to order_path(@order.reference), notice: "Order #{@order.reference} is in the pit."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order = Order.includes(order_items: :product).find_by!(reference: params[:reference])
  rescue ActiveRecord::RecordNotFound
    @message = "No order with the reference #{params[:reference].inspect}"
    render "shared/not_found", status: :not_found
  end

  private

  def order_params
    params.expect(order: [:customer_name, :email, :address, :postcode, :city, :country, :notes])
  end
end
