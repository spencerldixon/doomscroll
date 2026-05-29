module FlashHelper
  def flash_css_class(key)
    case key.to_sym
    when :alert
      "alert-destructive border-red-500"
    else
      "alert"
    end
  end
end
