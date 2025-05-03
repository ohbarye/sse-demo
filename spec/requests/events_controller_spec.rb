require 'rails_helper'

RSpec.describe EventsController, type: :request do
  describe "GET /events/stream" do
    # Note: ActionController::Live を使用したストリーミングレスポンスをテストするのは難しいため、
    # ここではコントローラレベルでのテストに集中し、リクエストレベルでのテストは省略します

    context "controller unit tests" do
      let(:controller) { EventsController.new }
      let(:mock_response) { ActionDispatch::Response.new }
      let(:mock_headers) { {} }
      let(:mock_stream) { double("stream") }
      let(:mock_logger) { double("logger") }

      before do
        # レスポンスとストリームのセットアップ
        allow(mock_response).to receive(:headers).and_return(mock_headers)
        allow(mock_response).to receive(:stream).and_return(mock_stream)
        allow(controller).to receive(:response).and_return(mock_response)
        allow(controller).to receive(:logger).and_return(mock_logger)
        allow(mock_logger).to receive(:info)

        # スリープをスキップ
        allow(controller).to receive(:sleep)

        # ストリームの write と close をモック
        allow(mock_stream).to receive(:write)
        allow(mock_stream).to receive(:close)
      end

      it "sends connected event and then result after processing" do
        # 期待される書き込み順序
        expect(mock_stream).to receive(:write).with("event: connected\n").ordered
        expect(mock_stream).to receive(:write).with(/data: \{.*\"message\":\"connected\".*\}\n\n/).ordered
        expect(mock_stream).to receive(:write).with("event: result\n").ordered
        expect(mock_stream).to receive(:write).with(/data: \{.*\"message\":\"Process completed successfully!\".*\}\n\n/).ordered

        # アクションを実行
        controller.stream
      end

      it "logs connection start and completion" do
        # 接続開始と完了のログ出力を期待
        expect(mock_logger).to receive(:info).with(/SSE connection started at .* \[Thread: .*\]/).ordered
        expect(mock_logger).to receive(:info).with(/SSE connection completed at .* \[Thread: .*\] \(Duration: .*ms\)/).ordered

        # アクションを実行
        controller.stream
      end

      it "waits for 5 seconds before sending the result" do
        # 5秒間のスリープが呼ばれることを確認
        expect(controller).to receive(:sleep).with(5)

        # アクションを実行
        controller.stream
      end

      it "handles client disconnection and logs it" do
        # 最初の write 時に IOError を発生させる
        allow(mock_stream).to receive(:write).and_raise(IOError)

        # 切断ログが出力されることを確認
        expect(mock_logger).to receive(:info).with(/Client disconnected \[Thread: .*\]/)

        # ストリームが確実に閉じられることを確認
        expect(mock_stream).to receive(:close)

        # アクションを実行
        controller.stream
      end

      it "always closes the stream even after an error" do
        # エラーを発生させる
        allow(mock_stream).to receive(:write).and_raise(StandardError, "テストエラー")

        # ストリームが確実に閉じられることを確認
        expect(mock_stream).to receive(:close)

        # アクションを実行 (エラーは rescue されるはず)
        expect { controller.stream }.to raise_error(StandardError, "テストエラー")
      end
    end
  end

  describe "GET /events/index" do
    it "returns a successful response" do
      get root_path
      expect(response).to have_http_status(:success)
    end
    
    it "renders the index template" do
      get root_path
      expect(response).to render_template(:index)
    end
    
    it "includes necessary elements for SSE UI" do
      get root_path
      expect(response.body).to include("Server-Sent Events")
      expect(response.body).to include("Pumaサーバー設定")
      expect(response.body).to include("スレッド使用状況")
    end
  end
end
