module SseHelper
  # ActionController::Live のテスト用ヘルパー
  
  # SSEレスポンスから個別のイベントデータをパースする
  def parse_sse_events(raw_data)
    events = []
    current_event = { type: nil, data: nil, id: nil }
    
    raw_data.split("\n").each do |line|
      if line.start_with?('event: ')
        current_event[:type] = line.sub('event: ', '')
      elsif line.start_with?('data: ')
        data_str = line.sub('data: ', '')
        begin
          current_event[:data] = JSON.parse(data_str)
        rescue JSON::ParserError
          current_event[:data] = data_str
        end
      elsif line.start_with?('id: ')
        current_event[:id] = line.sub('id: ', '')
      elsif line.empty? && current_event[:type]
        # イベントの区切り
        events << current_event.dup
        current_event = { type: nil, data: nil, id: nil }
      end
    end
    
    events
  end
  
  # SSEレスポンスをモックするためのヘルパー
  def mock_sse_response(controller)
    # レスポンスオブジェクトとストリームをモック
    mock_response = ActionDispatch::Response.new
    mock_stream = double('stream')
    mock_headers = {}
    
    allow(mock_response).to receive(:headers).and_return(mock_headers)
    allow(mock_response).to receive(:stream).and_return(mock_stream)
    allow(controller).to receive(:response).and_return(mock_response)
    
    # streamのwriteとcloseをモック
    allow(mock_stream).to receive(:write)
    allow(mock_stream).to receive(:close)
    
    # sleepをスタブして即座に返すようにする
    allow(controller).to receive(:sleep)
    
    { response: mock_response, stream: mock_stream, headers: mock_headers }
  end
  
  # SSEイベントが送信されたかどうかを確認するためのマッチャー
  RSpec::Matchers.define :send_sse_event do |event_type, data_pattern = nil|
    match do |stream|
      event_expectation = receive(:write).with("event: #{event_type}\n")
      data_expectation = if data_pattern.nil?
                           receive(:write).with(/data: .*\n\n/)
                         else
                           receive(:write).with(/data: .*#{data_pattern}.*\n\n/)
                         end
      
      RSpec::Mocks.space.proxy_for(stream).add_message_expectation(event_expectation)
      RSpec::Mocks.space.proxy_for(stream).add_message_expectation(data_expectation)
      true
    end
    
    failure_message do |stream|
      "expected that #{stream} would send an SSE event of type '#{event_type}'"
    end
  end
end

RSpec.configure do |config|
  config.include SseHelper, type: :request
  config.include SseHelper, type: :controller
end