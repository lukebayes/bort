class UsersController < ApplicationController
  include UsersHelper
  
  skip_before_filter :verify_authenticity_token, :only => [:create, :edit, :update]
  
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    if using_open_id?
      required_fields = ['http://axschema.org/contact/email', 'email', 'nickname', 'fullname']
      authenticate_with_open_id(params[:openid_url], :return_to => open_id_create_url, :required => required_fields) do |result, identity_url, registration|
        if result.successful?
          options = get_options_from_openid_params(params, identity_url)
          create_new_openid_user(options)
        else
          @user = User.new
          failed_creation(result.message || "Sorry, something went wrong with the OpenID services")
        end
      end
    else
      create_new_user(params[:user])
    end
  end

  # TODO: only admins or same users should be able to edit:
  def edit
    @user = User.find_by_id(params[:id])
  end
  
  # TODO: only admins or same users should be able to update:
  def update
    @user = User.find_by_id(params[:id])
    if @user.update_attributes(params[:user])
      if(@user.save)
        if(!@user.active?)
          update_openid_user(@user, params)
          return
        else
          flash[:notice] = "Your account has been saved"
          redirect_to root_url
          return
        end
      end
    end
    # flash[:error] = "There was a problem updating your account"
    render :action => 'edit', :id => @user
  end
  
  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Signup complete!"
      self.current_user = user
      redirect_back_or_default(root_path)
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default(root_path)
    else 
      flash[:error]  = "We couldn't find a user with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default(root_path)
    end
  end
  
  protected
  
  def openid_user_exists?(user)
    !User.find_by_identity_url(user.identity_url).nil?
  end
  
  def create_new_openid_user(attributes)
    user = User.new(attributes)
    if(openid_user_exists?(user))
      flash[:error] = "We already have an account for that user, please try Signing in."
      redirect_to new_session_path
      return
    end
    # user.update_attributes(attributes)
    user.save(false)
    self.current_user = user
    flash[:notice] = "You are now signed in, let's finish creating your account."
    return redirect_to(:controller => 'users', :action => 'edit', :id => user)
  end
  
  def update_openid_user(user, attributes)
    user.update_attributes(attributes)
    if(user.valid? && user.register_openid!)
      finish_creation(user)
    else
      flash[:error] = "There was a problem creating your account"
      render :action => 'edit', :id => user
    end
  end
  
  def create_new_user(attributes)
    @user = User.new(attributes)
    if @user && @user.valid? && @user.not_using_openid?
      @user.register!
    end
    
    finish_creation(@user)
  end
  
  def finish_creation(user)
    if user.errors.empty?
      successful_creation(user)
    else
      failed_creation
    end
  end
  
  def successful_creation(user)
    flash[:notice] = "Thanks for signing up!"
    if user.not_using_openid?
      flash[:notice] << " We're sending you an email with your activation code."
    else
      self.current_user = user
    end
    redirect_back_or_default(root_path)
  end
  
  def failed_creation(message = 'Sorry, there was an error creating your account')
    flash[:error] = message
    @user = User.new
    render :controller => 'users', :action => 'new'
  end
end
