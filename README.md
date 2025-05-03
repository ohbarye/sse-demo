# Rails Server-Sent Events (SSE) デモアプリケーション

このアプリケーションは、Rails で Server-Sent Events (SSE) を実装するデモです。クライアントがリクエストを送信し、サーバーが 5 秒後に処理結果を通知する仕組みを実装しています。

## デモ

実際の動作は[demo.mov](./demo.mov)ファイルを確認してください。

デモ動画では以下の機能が確認できます：

- 複数の SSE 接続の同時実行
- Puma スレッドの使用状況のリアルタイム表示
- 接続の開始と完了のライフサイクル
- スレッド数の制限による同時接続数の制御

_注: 実際に動かすには以下の手順に従ってください。_

## 特徴

- ActionController::Live を使用した SSE の実装
- 複数の同時接続の可視化
- Puma サーバーのスレッド使用状況のリアルタイム表示
- クライアントからの接続・切断制御

## 技術スタック

- Ruby 3.5.0-preview1
- Rails 8.0.2
- Puma 6.6.0 (スレッド制限付き)
- JavaScript (EventSource API)

## セットアップ

```bash
# リポジトリのクローン
git clone https://github.com/your-username/sse-demo.git
cd sse-demo

# 依存関係のインストール
bundle install

# サーバーの起動
bin/rails server
```

## 動作説明

1. デフォルトでは Puma は 3 スレッドに制限されています
2. 各 SSE 接続は 1 つのスレッドを使用します
3. 各接続は処理に 5 秒かかります（sleep で模擬）
4. UI では接続状態とスレッド使用状況をリアルタイムに確認できます

## 使い方

1. ブラウザで `http://localhost:3000` にアクセス
2. 「接続開始」ボタンをクリックして SSE 接続を開始
3. 「すべての接続を開始」ボタンで複数の SSE 接続を同時に開始
4. 上部のスレッドインジケーターで使用中のスレッド数を確認

## アプリケーション構造

主要なファイル:

- `app/controllers/events_controller.rb`: SSE を処理するコントローラー
- `app/views/events/index.html.erb`: フロントエンド UI と JavaScript
- `config/puma.rb`: Puma サーバーの設定

## コントローラー実装

```ruby
# app/controllers/events_controller.rb
class EventsController < ApplicationController
  include ActionController::Live

  def index
    render :index
  end

  def stream
    # 接続開始ログ
    logger.info "SSE connection started at #{Time.now.strftime('%H:%M:%S.%L')} [Thread: #{Thread.current.object_id}]"

    # SSE ヘッダー設定
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'

    # 接続成功イベント送信
    response.stream.write("event: connected\n")
    response.stream.write("data: #{JSON.dump({message: 'connected', thread_id: Thread.current.object_id})}\n\n")

    # 5秒間処理
    start_time = Time.now
    sleep 5
    end_time = Time.now
    processing_time = ((end_time - start_time) * 1000).to_i

    # 処理完了ログ
    logger.info "SSE connection completed at #{end_time.strftime('%H:%M:%S.%L')} [Thread: #{Thread.current.object_id}] (Duration: #{processing_time}ms)"

    # 結果イベント送信
    response.stream.write("event: result\n")
    response.stream.write("data: #{JSON.dump({
      message: 'Process completed successfully!',
      timestamp: Time.now.to_i,
      thread_id: Thread.current.object_id,
      processing_time: processing_time
    })}\n\n")

  rescue IOError
    # クライアント切断時
    logger.info "Client disconnected [Thread: #{Thread.current.object_id}]"
  ensure
    response.stream.close
  end
end
```

## フロントエンド実装

フロントエンドでは EventSource API を使用して SSE 接続を管理します。以下の機能があります:

- 個別の接続開始/停止
- 全接続の一括開始/停止
- スレッド使用状況のリアルタイム表示
- 接続状態の表示

## テスト

RSpec を使用して、以下のテストを実装しています:

```bash
# テストの実行
bundle exec rspec
```

- コントローラーテスト: SSE の機能をユニットテスト
- システムテスト: ブラウザ UI の動作をテスト

## スレッド制限と同時接続

このデモの主な目的は、Puma のスレッド制限と SSE 接続の関係を示すことです:

1. デフォルトでは 3 スレッドに制限されているため、同時に 3 つまでの SSE 接続しか処理できません
2. 4 つ目以降の接続はスレッドが空くまで待機状態になります
3. 各接続が完了するとスレッドが解放され、待機中の接続が処理されます

## トラブルシューティング

- Ruby/Rails のバージョンが合わない場合は、`.ruby-version` ファイルを確認してください
- テストが失敗する場合は、必要な gem がインストールされているか確認してください
- ブラウザが EventSource API をサポートしていることを確認してください

## ライセンス

MIT
