module ApplicationHelper
  
  # Sets the page title and outputs title if container is passed in.
  # eg. <%= title('Hello World', :h2) %> will return the following:
  # <h2>Hello World</h2> as well as setting the page title.
  def title(str, container = nil)
    @page_title = str
    content_tag(container, str) if container
  end
  
  # Outputs the corresponding flash message if any are set
  def flash_messages
    messages = []
    %w(notice warning error).each do |msg|
      messages << content_tag(:div, html_escape(flash[msg.to_sym]), :id => "flash-#{msg}", :class => 'flash') unless flash[msg.to_sym].blank?
    end
    messages
  end
  
  def image_url(name)
    return "/images/#{name}"
  end
  
  def openid_link_for(provider_url, name, label)
    %Q{<input name="commit" type="image" src="/images/openid/#{name.downcase}.png" alt="#{label}" onClick="authenticateWithOpenId('#{provider_url}'); return true;" />}
  end
  
end
