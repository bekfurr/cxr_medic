import subprocess, time, re, requests

# 1. Cloudflared binar faylini yuklab olish (bepul HTTPS tunnel uchun)
if not os.path.exists("/usr/local/bin/cloudflared"):
    !wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
    !chmod +x /usr/local/bin/cloudflared

# 2. Eski jarayonlarni tozalash va Flask serverni orqa fonda (background) yoqish
!pkill -f "python3 app.py" || true
!pkill -f "cloudflared" || true

server_proc = subprocess.Popen(
    ["python3", "app.py"],
    stdout=open("flask.log", "w"),
    stderr=subprocess.STDOUT,
    env={**os.environ, "MODEL_DIR": "/content/drive/MyDrive/BMI_CXR_Model_v2", "PORT": "5000"}
)

print("Flask API yuklanmoqda (model xotiraga olinmoqda)...")
for _ in range(30):
    time.sleep(1)
    try:
        r = requests.get("http://127.0.0.1:5000/api/v1/health", timeout=2)
        if r.status_code == 200:
            print("Flask API tayyor! Model:", r.json()["version"], "| Device:", r.json()["device"])
            break
    except Exception:
        pass

# 3. Cloudflare HTTPS tunnelni yoqish
tunnel_proc = subprocess.Popen(
    ["/usr/local/bin/cloudflared", "tunnel", "--url", "http://127.0.0.1:5000"],
    stdout=open("tunnel.log", "w"),
    stderr=subprocess.STDOUT
)

public_url = None
for _ in range(20):
    time.sleep(1)
    logs = open("tunnel.log").read()
    m = re.search(r"https://[-a-zA-Z0-9]+\.trycloudflare\.com", logs)
    if m:
        public_url = m.group(0)
        break

print("="*70)
print("PUBLIC HTTPS API URL (Mobil ilova va Web uchun):", public_url)
print("Health Check URL :", f"{public_url}/api/v1/health")
print("Predict Endpoint :", f"{public_url}/api/v1/predict")
print("="*70)
