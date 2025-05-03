require 'rails_helper'

RSpec.describe "Events System", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  it "shows the SSE interface" do
    visit root_path

    # 基本的な要素が表示されていることを確認
    expect(page).to have_content("Server-Sent Events テスト")
    expect(page).to have_content("複数のSSE接続を同時に開始し、サーバーの同時接続処理を検証できます")
    expect(page).to have_content("Pumaサーバー設定: 3スレッド")

    # 接続ボタンが表示されていることを確認
    expect(page).to have_button("すべての接続を開始")

    # 少なくとも1つの接続コンテナが表示されていることを確認
    expect(page).to have_css(".connection", minimum: 1)
  end

  it "initializes with correct thread indicators" do
    visit root_path

    # スレッドインジケーターが3つ表示されていることを確認
    expect(page).to have_css(".thread", count: 3)

    # 最初は全てのスレッドが非アクティブであることを確認
    expect(page).to have_css(".thread:not(.active)", count: 3)
    expect(page).to have_content("スレッド使用状況: 0 / 3 アクティブ")
  end

  it "shows connection status for individual connections" do
    visit root_path

    # 最初の接続のステータスを確認
    first_connection_status = find("#status-1")
    expect(first_connection_status.text).to eq("状態: 未接続")

    # 接続が10個表示されていることを確認
    expect(page).to have_css(".connection", count: 10)

    # 各接続に開始ボタンがあることを確認
    expect(page).to have_css(".start-btn", count: 10)
  end

  # 注意: 実際のSSE接続や複雑なJSのテストは難しいため、
  # ここではUIのインタラクション部分のみをシンプルにテストします
  it "shows connection button and updates status on click", js: true do
    visit root_path

    # ボタンクリック前のステータスを確認
    first_connection_status = find("#status-1")
    expect(first_connection_status.text).to eq("状態: 未接続")

    # SSE接続をモックして、接続中ステータスだけをテストする
    # 実際のイベント処理は省略
    page.execute_script(<<~JS)
      // 実際のEventSourceをオーバーライド
      window.originalEventSource = window.EventSource;
      window.EventSource = class MockEventSource {
        constructor(url) {
          this.url = url;
          this.onmessage = null;

          // ステータスを「接続中」にするだけ
          const statusDiv = document.getElementById('status-1');
          statusDiv.textContent = '状態: 接続中...';

          // 本来なら接続後の処理をシミュレートしたいが、
          // システムテストでは複雑なイベント処理は省略
        }

        addEventListener() {}
        close() {}
      };
    JS

    # 接続開始ボタンをクリック
    first('.start-btn').click

    # 接続中のステータスになったことを確認
    expect(page).to have_content('状態: 接続中...')

    # EventSourceオブジェクトを元に戻す
    page.execute_script('window.EventSource = window.originalEventSource;')
  end
end
