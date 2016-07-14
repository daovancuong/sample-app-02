module SessionsHelper
  def login(user)
    session[:user_id]=user.id
  end

  def current_user
    if user_id=session[:user_id]
      @current_user=User.find_by(id: user_id)
    else
      if user_id=cookies[:user_id]
        user=User.find_by(id: user_id)
        if user && user.authenticated?(:remember, cookies[:remember_token])
          @current_user=user
          login user
        end
      end
    end

  end

  def logged_in?
    !current_user.nil?
  end

  def log_out

    session[:user_id]=nil
    @current_user=nil
  end

  def forget(user)
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
    user.forget

  end

  def remember(user)
    user.remember
    cookies.signed[:user_id]=user.id
    cookies.signed[:remember_token]=user.remember_token
  end

  def current_user?(user)
    user == current_user
  end

  def rollback_page(default)
    redirect_to(session[:current_path]||default)
    session.delete(:current_path)

  end

  def savecurrentpath
    session[:current_path]=request.original_url if request.get?
  end

end
