class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # SSEを使用するために必要
  before_action :set_cache_headers

  private

  def set_cache_headers
    # SSEのためのキャッシュヘッダを設定
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.now.httpdate
  end
end
