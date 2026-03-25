# If you could not download the model from the official site, you can use the mirror site.
# Just remove the comment of the following line .
# 如果你无法从官方网站下载模型，你可以使用镜像网站。
# 只需要移除下面一行的注释即可。

# export HF_ENDPOINT=https://hf-mirror.com

# streamlit run ./webui/Main.py --browser.serverAddress="127.0.0.1" --server.enableCORS=True --browser.gatherUsageStats=False
#!/usr/bin/env bash

APP_PORT=8501

STREAMLIT_PID_FILE=".streamlit.pid"
NGROK_PID_FILE=".ngrok.pid"

require_auth() {
  if [ -z "$AUTH" ]; then
    echo "❌ AUTH chưa được set!"
    echo "👉 Ví dụ:"
    echo "   export AUTH=admin:123456"
    exit 1
  fi
}

start() {
  echo "🚀 Starting services..."

  require_auth

  # Streamlit
  if [ -f "$STREAMLIT_PID_FILE" ] && kill -0 $(cat $STREAMLIT_PID_FILE) 2>/dev/null; then
    echo "⚠️ Streamlit already running"
  else
    nohup .venv/bin/streamlit run ./webui/Main.py \
      --server.port=$APP_PORT \
      --browser.serverAddress="127.0.0.1" \
      --server.enableCORS=True \
      --browser.gatherUsageStats=False \
      > streamlit.log 2>&1 &

    echo $! > $STREAMLIT_PID_FILE
    echo "✔ Streamlit started (PID $(cat $STREAMLIT_PID_FILE))"
  fi

  sleep 3

  # ngrok
  if [ -f "$NGROK_PID_FILE" ] && kill -0 $(cat $NGROK_PID_FILE) 2>/dev/null; then
    echo "⚠️ ngrok already running"
  else
    nohup ngrok http $APP_PORT \
      --basic-auth="$AUTH" \
      > ngrok.log 2>&1 &

    echo $! > $NGROK_PID_FILE
    echo "✔ ngrok started (PID $(cat $NGROK_PID_FILE))"
  fi

  sleep 2

  echo "🌍 Public URL:"
  curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*'
}

stop() {
  echo "🛑 Stopping services..."

  if [ -f "$STREAMLIT_PID_FILE" ]; then
    kill $(cat $STREAMLIT_PID_FILE) 2>/dev/null
    rm -f $STREAMLIT_PID_FILE
    echo "✔ Stopped Streamlit"
  fi

  if [ -f "$NGROK_PID_FILE" ]; then
    kill $(cat $NGROK_PID_FILE) 2>/dev/null
    rm -f $NGROK_PID_FILE
    echo "✔ Stopped ngrok"
  fi

  pkill -f "streamlit run" 2>/dev/null
  pkill -f "ngrok http" 2>/dev/null

  echo "✅ Done"
}

status() {
  echo "📊 Status:"

  if [ -f "$STREAMLIT_PID_FILE" ] && kill -0 $(cat $STREAMLIT_PID_FILE) 2>/dev/null; then
    echo "✔ Streamlit running (PID $(cat $STREAMLIT_PID_FILE))"
  else
    echo "❌ Streamlit not running"
  fi

  if [ -f "$NGROK_PID_FILE" ] && kill -0 $(cat $NGROK_PID_FILE) 2>/dev/null; then
    echo "✔ ngrok running (PID $(cat $NGROK_PID_FILE))"
  else
    echo "❌ ngrok not running"
  fi

  echo "🌍 Public URL:"
  curl -s http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^"]*'
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  restart)
    stop
    sleep 2
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart}"
    exit 1
    ;;
esac
