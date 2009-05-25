class ApplicationController < ActionController::Base
  include ExceptionNotifiable
  include AuthenticatedSystem
  include RoleRequirementSystem
  
  helper :all # include all helpers, all the time

  # TODO: deprecated in Rails 2.3.2, find out where to now set this:
  # protect_from_forgery :secret => 'b0a876313f3f9195e9bd01473bc5cd06'

  filter_parameter_logging :password, :password_confirmation
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  # before_filter :set_facebook_session
  # helper_method :facebook_session
  
  def current_user
    return nil if session[:user_id].nil?
    @current_user ||= load_current_user
  end
  
  def current_user=(user)
    session[:user_id] = user.id unless user.nil?
    @current_user = user
  end
  
  def load_current_user
    User.find_by_id(session[:user_id])
  end
  
  def login_required
    if session[:user_id]
      return current_user
    end
    
    redirect_to login_path
    return false
  end
  
  protected
  
  def access_denied
    alias new_session_path login_path
    super
  end

  # Automatically respond with 404 for ActiveRecord::RecordNotFound
  def record_not_found
    render :file => File.join(RAILS_ROOT, 'public', '404.html'), :status => 404
  end
end

