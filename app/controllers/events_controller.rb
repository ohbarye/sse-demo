class EventsController < ApplicationController
  include ActionController::Live

  def index
    # HTMLページを表示するアクション
    render :index
  end

  def stream
    # 新しい接続をログに記録
    logger.info "SSE connection started at #{Time.now.strftime('%H:%M:%S.%L')} [Thread: #{Thread.current.object_id}]"

    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'

    # クライアントに接続成功メッセージを送信
    response.stream.write("event: connected\n")
    response.stream.write("data: #{JSON.dump({message: 'connected', thread_id: Thread.current.object_id})}\n\n")

    # 開始時刻を記録
    start_time = Time.now

    # 5秒後に結果を送信
    sleep 5

    # 完了時刻を記録
    end_time = Time.now
    processing_time = ((end_time - start_time) * 1000).to_i

    # 処理完了を記録
    logger.info "SSE connection completed at #{end_time.strftime('%H:%M:%S.%L')} [Thread: #{Thread.current.object_id}] (Duration: #{processing_time}ms)"

    response.stream.write("event: result\n")
    response.stream.write("data: #{JSON.dump({
      message: 'Process completed successfully!',
      timestamp: Time.now.to_i,
      thread_id: Thread.current.object_id,
      processing_time: processing_time
    })}\n\n")

  rescue IOError
    # クライアントが切断した場合
    logger.info "Client disconnected [Thread: #{Thread.current.object_id}]"
  ensure
    response.stream.close
  end
end
