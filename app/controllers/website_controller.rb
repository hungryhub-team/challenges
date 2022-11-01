class WebsiteController < ApplicationController
  def index
    @token = nil
  end

  def donate
    if params[:omise_token].present? && params[:charity].present?
      unless params[:amount].blank? || params[:amount].to_i <= 20
        charity = params[:charity] == "random" ? @app.get_random_charity : Charity.find_by(id: params[:charity])
        unless !charity
          if Rails.env.test?
            charge = OpenStruct.new({
              amount: params[:amount].to_i * 100,
              paid: (params[:amount].to_i != 999),
            })
          else
            charge = Omise::Charge.create({
              amount: params[:amount].to_i * 100,
              currency: "THB",
              card: params[:omise_token],
              description: "Donation to #{charity.name} [#{charity.id}]",
            })
          end

          if charge.paid
            charity.credit_amount(charge.amount)
            flash.notice = t(".success")
            redirect_to root_path
          else
            @token = nil
            flash.now.alert = t(".failure")
            render :index
            return
          end
        else
          @token = retrieve_token(params[:omise_token])
          flash.now.alert = t(".failure")
          render :index
          return
        end
      else
        @token = retrieve_token(params[:omise_token])
        flash.now.alert = t(".failure")
        render :index
        return
      end
    else
      @token = nil
      flash.now.alert = t(".failure")
      render :index
      return
    end
  end

  private

  def retrieve_token(token)
    if Rails.env.test?
      OpenStruct.new({
        id: "tokn_X",
        card: OpenStruct.new({
          name: "J DOE",
          last_digits: "4242",
          expiration_month: 10,
          expiration_year: 2020,
          security_code_check: false,
        }),
      })
    else
      Omise::Token.retrieve(token)
    end
  end
end