class CartsController < ApplicationController
  def show; end

  def add
    product = Product.find_by(slug: params[:slug])
    if product.nil?
      redirect_to(cart_path, alert: "That product does not exist.") and return
    end

    added = current_cart.add(product, params.fetch(:quantity, 1))

    notice =
      if added.positive?
        "#{added} × #{product.name} added to your cart."
      elsif product.in_stock?
        "You already have every #{product.name} we can ship you."
      else
        "#{product.name} is sold out."
      end

    redirect_to safe_return_to, notice: notice
  end

  def update_item
    product = Product.find_by(slug: params[:slug])
    redirect_to(cart_path) and return if product.nil?

    requested = params[:quantity].to_i
    applied   = current_cart.set(product, requested)

    if requested.positive? && applied.to_i < requested
      redirect_to(cart_path, alert: "Only #{applied} × #{product.name} available.") and return
    end

    redirect_to cart_path
  end

  def remove_item
    product = Product.find_by(slug: params[:slug])
    redirect_to(cart_path) and return if product.nil?

    current_cart.remove(product)
    redirect_to cart_path, notice: "#{product.name} removed."
  end

  private

  # Only same-site paths. "//evil.example.com" also starts with a slash but
  # browsers read it as a protocol-relative URL.
  def safe_return_to
    candidate = params[:return_to].to_s
    return cart_path unless candidate.start_with?("/")
    return cart_path if candidate.match?(%r{\A/[/\\]})

    candidate
  end
end
