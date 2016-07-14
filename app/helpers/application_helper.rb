module ApplicationHelper
  def full_title(title="")
    page_title="Ruby on rails"
    if title.empty?
      page_title
    else
      title+" | "+page_title
    end

  end
end
