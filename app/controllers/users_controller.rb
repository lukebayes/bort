class UsersController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    if using_open_id?
      # Would like:
      # First Name
      # Last Name
      # Nick Name
      # Email
      
      required_fields = ['http://axschema.org/contact/email', 'email', 'nickname', 'fullname']
      authenticate_with_open_id(params[:openid_url], :return_to => open_id_create_url, :required => required_fields) do |result, identity_url, registration|
        if result.successful?
          
          # Google email response:
          email = params['openid.ext1.value.email']
          email ||= params['openid.ext1.value.ext0']
          email ||= params['openid.sreg.email']
          
          if(email.nil?)
            flash[:error] = "We were unable to determine a valid email address from that provider, please try a different one"
            redirect_to signup_path
            return
          end

          login = registration['nickname']
          name = params['openid.sreg.fullname'] || email.split('@').first

          puts "----------------"
          puts "FINAL VALUE: #{email}"
          puts "login: #{login}"
          puts "name: #{name}"
          puts "----------------"

          create_new_user(:identity_url => identity_url, :login => login, :email => email, :name => name)
        else
          @user = User.new
          failed_creation(result.message || "Sorry, something went wrong")
        end
      end
    else
      create_new_user(params[:user])
    end
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
  
  def create_new_user(attributes)
    @user = User.new(attributes)
    if @user && @user.valid?
      if @user.not_using_openid?
        @user.register!
      else
        @user.register_openid!
      end
    end
    
    if @user.errors.empty?
      successful_creation(@user)
    else
      failed_creation
    end
  end
  
  def successful_creation(user)
    flash[:notice] = "Thanks for signing up!"
    if @user.not_using_openid?
      flash[:notice] << " We're sending you an email with your activation code."
    else
      self.current_user = user unless user.not_using_openid?
    end
    redirect_back_or_default(root_path)
  end
  
  def failed_creation(message = 'Sorry, there was an error creating your account')
    flash[:error] = message
    # redirect_to :controller => 'users', :action => :new
    render :controller => 'users', :action => :new
  end
end
