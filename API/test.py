import requests, base64, io, json
import matplotlib.pyplot as plt
from PIL import Image
import numpy as np

# Sinov uchun sun'iy yoki mavjud rentgen tasvirini yuboramiz
test_img = Image.fromarray(np.random.randint(40, 200, (320, 320), dtype=np.uint8))
buf = io.BytesIO()
test_img.save(buf, format="PNG")
buf.seek(0)

resp = requests.post(
    "http://127.0.0.1:5000/api/v1/predict",
    files={"image": ("sample_cxr.png", buf, "image/png")},
    data={"view_pos": "PA", "age": "52", "gender": "M", "with_cam": "true"}
).json()

print("Status:", resp["status"], "| Vaqt:", resp["inference_ms"], "ms")
print("Klinik xulosa:", resp["clinical_summary"])
print("Top 3 natija:", json.dumps(resp["top_findings"], indent=2, ensure_ascii=False))

if resp.get("gradcam"):
    b64_ov = resp["gradcam"]["overlay_base64"].split(",", 1)[1]
    im_ov = Image.open(io.BytesIO(base64.b64decode(b64_ov)))
    plt.figure(figsize=(4.5, 4.5)); plt.imshow(im_ov); plt.axis("off")
    plt.title(f"API Grad-CAM++ ({resp['gradcam']['target_name_uz']})"); plt.show()
