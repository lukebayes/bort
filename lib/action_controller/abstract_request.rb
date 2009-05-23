# Work around found here: http://peterleonhardt.com/blog/2009/03/25/rails-23-mongrel-prefix/
# Fixes problems with Mongrel and Rails 2.3.2:
# module ActionController
#   class AbstractRequest
#     def relative_url_root=(path)
#       ActionController::Base.relative_url_root = path
#     end  
#     def relative_url_root
#       ActionController::Base.relative_url_root
#     end
#   end
# end
