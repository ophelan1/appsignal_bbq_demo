class HealthController < ApplicationController
  def show
    render json: {
      status: "ok",
      products: Product.count,
      orders: Order.count,
      appsignal_active: defined?(Appsignal) ? Appsignal.active? : false
    }
  end
end
