class EventsController < ApplicationController
  include ActionController::Live

  def index
    # HTMLページを表示するアクション
    render :index
  end

  def stream
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    
    # クライアントに接続成功メッセージを送信
    response.stream.write("event: connected\n")
    response.stream.write("data: #{JSON.dump({message: 'connected'})}\n\n")
    
    # 5秒後に結果を送信
    sleep 5
    
    response.stream.write("event: result\n")
    response.stream.write("data: #{JSON.dump({message: 'Process completed successfully!', timestamp: Time.now.to_i})}\n\n")
    
  rescue IOError
    # クライアントが切断した場合
    logger.info "Client disconnected"
  ensure
    response.stream.close
  end
end