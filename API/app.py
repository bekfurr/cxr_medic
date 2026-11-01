import os
import io
import time
import uuid
import json
import base64
import logging
import numpy as np
import cv2
from PIL import Image
import matplotlib.cm as cm

import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision
from flask import Flask, request, jsonify, render_template_string, send_file

cv2.setNumThreads(0)
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("BMI_CXR_API")

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 16 * 1024 * 1024  # Maksimal rasm hajmi: 16 MB

# --- CORS Middleware (Web va Mobil ilovalar uchun) ---
@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, X-API-Key"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    return response

# --- 14 ta Patologiya lug'ati (O'zbekcha nomlari va klinik izohlari bilan) ---
PATHOLOGY_INFO = {
    "Atelectasis":        {"uz": "Atelektaz",            "desc": "O'pka bo'lagi yoki segmentining puchayishi (havo0sizlanishi)."},
    "Cardiomegaly":       {"uz": "Kardiomegaliya",       "desc": "Yurak soyasi o'lchamlarining kengayishi (KTI > 0.50)."},
    "Effusion":           {"uz": "Plevral effuziya",     "desc": "Plevra bo'shlig'ida suyuqlik to'planishi (gidrotoraks)."},
    "Infiltration":       {"uz": "Infiltratsiya",        "desc": "O'pka parenximasida yallig'lanish yoki suyuqlik hisobiga zichlashish."},
    "Mass":               {"uz": "Hajmli hosila (Mass)", "desc": "O'pka to'qimasida diametri 30 mm dan katta bo'lgan o'choqli soya."},
    "Nodule":             {"uz": "Tugun (Nodule)",       "desc": "O'pka maydonida diametri 30 mm gacha bo'lgan yumaloq mayda o'choq."},
    "Pneumonia":          {"uz": "Pnevmoniya",           "desc": "O'pka to'qimasining infeksion-yallig'lanishli konsolidatsiyasi."},
    "Pneumothorax":       {"uz": "Pnevmotoraks",         "desc": "Plevra bo'shlig'ida erkin havo to'planishi (shoshilinch holat!)."},
    "Consolidation":      {"uz": "Konsolidatsiya",       "desc": "Alveolalar havo o'rniga eksudat bilan to'lishi natijasida zichlashish."},
    "Edema":              {"uz": "O'pka shishi (Edema)", "desc": "Interstitsial va alveolar bo'shliqlarda suyuqlik dimlanishi."},
    "Emphysema":          {"uz": "Emfizema",             "desc": "Alveola devorlari yemirilishi va o'pka shaffofligining ortishi."},
    "Fibrosis":           {"uz": "Fibroz",               "desc": "O'pka biriktiruvchi to'qimasining chandiqli qalinlashishi."},
    "Pleural_Thickening": {"uz": "Plevra qalinlashishi", "desc": "Plevra varaqlarining fibroz yoki kalsifikatsiyali qalinlashishi."},
    "Hernia":             {"uz": "Diafragmal churra",    "desc": "Qorin bo'shlig'i a'zolarining diafragma orqali ko'krak qafasiga chiqishi."},
}

MEDICAL_DISCLAIMER = {
    "uz": "Eslatma: Ushbu tizim faqat klinik qaror qabul qilishga ko'maklashish (CDSS) uchun mo'ljallangan. Yakuniy tashxis malakali shifokor-rentgenolog tomonidan qo'yiladi.",
    "ru": "Примечание: Данная система предназначена исключительно для поддержки принятия врачебных решений (CDSS). Окончательный диагноз ставится врачом-рентгенологом.",
    "en": "Disclaimer: This AI system is intended solely for Clinical Decision Support (CDSS) and educational use. Final diagnosis must be made by a qualified radiologist."
}

# --- Model Arxitekturasi (BatchNorm1d va LayerNorm checkpointlariga avtomatik moslashadi) ---
class CXRNetV2(nn.Module):
    def __init__(self, n_labels=14, backbone="xrv", use_meta=True, n_meta=3, use_layernorm=False):
        super().__init__()
        self.backbone_name = backbone
        self.use_meta = use_meta

        if backbone in ("xrv", "xrv_chex"):
            import torchxrayvision as xrv
            m = xrv.models.DenseNet(weights=None)
            self.features = m.features
        else:
            self.features = torchvision.models.densenet121(weights=None).features
            self.register_buffer("mean", torch.tensor([0.485, 0.456, 0.406]).view(1, 3, 1, 1))
            self.register_buffer("std",  torch.tensor([0.229, 0.224, 0.225]).view(1, 3, 1, 1))

        if self.use_meta:
            norm_layer = nn.LayerNorm(16) if use_layernorm else nn.BatchNorm1d(16)
            self.meta_net = nn.Sequential(
                nn.Linear(n_meta, 16),
                norm_layer,
                nn.SiLU(),
            )
            in_dim = 1024 + 16
        else:
            self.meta_net = None
            in_dim = 1024

        self.head = nn.Sequential(
            nn.Dropout(0.25),
            nn.Linear(in_dim, n_labels)
        )
        self.register_buffer("temperature", torch.ones(1, n_labels))

    def norm(self, x):
        if self.backbone_name in ("xrv", "xrv_chex"):
            return (x * 2.0 - 1.0) * 1024.0
        return (x.repeat(1, 3, 1, 1) - self.mean) / self.std

    def forward_cam(self, x, meta=None):
        fmap = F.relu(self.features(self.norm(x)))
        pooled = F.adaptive_avg_pool2d(fmap, 1).flatten(1)
        if self.use_meta:
            if meta is None:
                meta = torch.zeros(x.size(0), 3, device=x.device, dtype=pooled.dtype)
            m_feat = self.meta_net(meta.to(pooled.dtype))
            feat = torch.cat([pooled, m_feat], dim=1)
        else:
            feat = pooled
        logits = self.head(feat)
        return logits, fmap

    def forward(self, x, meta=None):
        return self.forward_cam(x, meta)[0]

    def calibrated_probs(self, x, meta=None):
        logits = self.forward(x, meta)
        return torch.sigmoid(logits / self.temperature.clamp(min=0.05))


# --- Global Model & Sozlamalarni Yuklash ---
MODEL_DIR = os.environ.get("MODEL_DIR", "/content/drive/MyDrive/BMI_CXR_Model_v2")
API_KEY_SECRET = os.environ.get("CXR_API_KEY", "")  # Agar bo'sh bo'lsa, ochiq ishlaydi; aks holda X-API-Key tekshiriladi
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

DEFAULT_META = {
    "version": "BMI_CXR_multilabel_v2",
    "labels": [
        "Atelectasis", "Cardiomegaly", "Effusion", "Infiltration", "Mass", "Nodule", "Pneumonia",
        "Pneumothorax", "Consolidation", "Edema", "Emphysema", "Fibrosis", "Pleural_Thickening", "Hernia"
    ],
    "thresholds": [0.44, 0.29, 0.48, 0.45, 0.39, 0.42, 0.25, 0.41, 0.40, 0.33, 0.46, 0.28, 0.36, 0.13],
    "temperatures": [0.9653, 0.9496, 0.9729, 0.9887, 0.9535, 0.9591, 0.9433, 0.9672, 0.9547, 0.947, 0.959, 0.9447, 0.9535, 0.9427],
    "img_size": 320,
    "use_clahe": True,
    "use_meta": True,
    "backbone": "xrv",
    "test_macro_auroc": 0.7766,
    "test_macro_auroc_ci95": [0.7515, 0.7976],
    "test_macro_auprc": 0.2058,
    "test_macro_f1": 0.2313
}

meta_path = os.path.join(MODEL_DIR, "model_meta.json")
if os.path.exists(meta_path):
    with open(meta_path, "r", encoding="utf-8") as f:
        META = json.load(f)
    logger.info(f"model_meta.json yuklandi: {meta_path}")
else:
    META = DEFAULT_META
    logger.warning(f"model_meta.json topilmadi ({meta_path}), standart v2 metama'lumotlari ishlatilmoqda.")

LABELS = META["labels"]
THR = np.array(META["thresholds"], dtype=np.float32)
IMG_SIZE = int(META.get("img_size", 320))
USE_CLAHE = bool(META.get("use_clahe", True))
USE_META = bool(META.get("use_meta", True))

ckpt_path = os.path.join(MODEL_DIR, "best_model.pt")
MODEL = None

def load_engine():
    global MODEL
    if os.path.exists(ckpt_path):
        sd = torch.load(ckpt_path, map_location=DEVICE)
        use_ln = ("meta_net.1.running_mean" not in sd)
        MODEL = CXRNetV2(
            n_labels=len(LABELS),
            backbone=META.get("backbone", "xrv"),
            use_meta=USE_META,
            use_layernorm=use_ln
        ).to(DEVICE)
        MODEL.load_state_dict(sd, strict=False)
        if "temperatures" in META and "temperature" not in sd:
            MODEL.temperature.copy_(torch.tensor([META["temperatures"]], dtype=torch.float32, device=DEVICE))
        MODEL.eval()
        logger.info(f"Model muvaffaqiyatli yuklandi: {ckpt_path} ({DEVICE})")
    else:
        logger.warning(f"Diqqat: {ckpt_path} topilmadi! MODEL_DIR yo'lini tekshiring.")

load_engine()


# --- Yordamchi funksiyalar: Preprocessing va Grad-CAM++ ---
def make_anatomical_mask(h, w, border_frac=0.06):
    vy = np.ones(h, dtype=np.float32)
    vx = np.ones(w, dtype=np.float32)
    b = max(2, int(border_frac * min(h, w)))
    ramp = np.linspace(0.15, 1.0, b, dtype=np.float32)
    vy[:b], vy[-b:] = ramp, ramp[::-1]
    vx[:b], vx[-b:] = ramp, ramp[::-1]
    return np.outer(vy, vx)

def preprocess_pil_image(pil_img):
    im = pil_img.convert("L").resize((IMG_SIZE, IMG_SIZE), Image.LANCZOS)
    arr = np.asarray(im, dtype=np.uint8)
    if USE_CLAHE:
        arr = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)).apply(arr)
    x = torch.from_numpy(arr.astype(np.float32) / 255.0)[None, None]  # [1, 1, H, W]
    return x, arr.astype(np.float32) / 255.0

def compute_gradcam_pp(model, x, meta_vec, k, apply_anat_mask=True):
    model.eval()
    with torch.enable_grad():
        x_in = x.to(DEVICE).requires_grad_(False)
        m_in = meta_vec.to(DEVICE) if meta_vec is not None else None
        logits, fmap = model.forward_cam(x_in, m_in)
        fmap.retain_grad()
        score = logits[0, k]
        model.zero_grad(set_to_none=True)
        score.backward(retain_graph=False)

    grads = fmap.grad[0]
    acts = fmap.detach()[0]
    grads_pos = F.relu(grads)
    grads_2 = grads_pos ** 2
    grads_3 = grads_2 * grads_pos
    sum_acts = acts.sum(dim=(1, 2), keepdim=True)
    alpha = grads_2 / (2.0 * grads_2 + sum_acts * grads_3 + 1e-7)
    weights = (alpha * grads_pos).sum(dim=(1, 2), keepdim=True)

    cam = F.relu((weights * acts).sum(dim=0, keepdim=True).unsqueeze(0))
    cam = F.interpolate(cam, size=x.shape[-2:], mode="bilinear", align_corners=False)[0, 0]
    cam_np = cam.detach().cpu().numpy()

    if apply_anat_mask:
        cam_np = cam_np * make_anatomical_mask(*cam_np.shape)

    cam_np = (cam_np - cam_np.min()) / (cam_np.max() - cam_np.min() + 1e-8)
    model.zero_grad(set_to_none=True)
    return cam_np

def encode_png_base64(rgb_or_rgba_uint8):
    pil_out = Image.fromarray(rgb_or_rgba_uint8)
    buf = io.BytesIO()
    pil_out.save(buf, format="PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("utf-8")

def create_cam_visuals(img01, cam, alpha=0.42):
    jet_rgba = cm.get_cmap("jet")(cam)  # [H, W, 4], 0..1
    jet_rgb = jet_rgba[..., :3]
    base_rgb = np.stack([img01] * 3, axis=-1)
    overlay_rgb = np.clip((1.0 - alpha) * base_rgb + alpha * jet_rgb, 0.0, 1.0)
    overlay_u8 = (overlay_rgb * 255.0).astype(np.uint8)

    # Mobil ilovada interaktiv slider uchun shaffof (RGBA) issiqlik xaritasi
    heatmap_rgba = np.zeros((*cam.shape, 4), dtype=np.uint8)
    heatmap_rgba[..., :3] = (jet_rgb * 255.0).astype(np.uint8)
    heatmap_rgba[..., 3] = (np.clip(cam * 1.15, 0.0, 1.0) * 235).astype(np.uint8)

    return encode_png_base64(overlay_u8), encode_png_base64(heatmap_rgba)

def compute_lung_focus_ratio(cam):
    h, w = cam.shape
    y1, y2 = int(0.10 * h), int(0.88 * h)
    x1, x2 = int(0.10 * w), int(0.90 * w)
    return float(cam[y1:y2, x1:x2].sum() / (cam.sum() + 1e-8))

def extract_image_and_params(req):
    """Multipart form-data yoki JSON (Base64) so'rovdan tasvir va metama'lumotlarni ajratib oladi."""
    if req.is_json:
        data = req.get_json(force=True)
        b64_str = data.get("image_base64", "")
        if "," in b64_str:
            b64_str = b64_str.split(",", 1)[1]
        img_bytes = base64.b64decode(b64_str)
        pil_img = Image.open(io.BytesIO(img_bytes))
        view_pos = str(data.get("view_pos", "PA")).upper()
        age = float(data.get("age", 45))
        gender = str(data.get("gender", "M")).upper()
        top_k = int(data.get("top", 3))
        with_cam = bool(data.get("with_cam", True))
        target_label = data.get("target_label", None)
        lang = str(data.get("lang", "uz")).lower()
    else:
        if "image" not in req.files:
            raise ValueError("So'rovda 'image' fayli yoki 'image_base64' maydoni topilmadi.")
        pil_img = Image.open(req.files["image"].stream)
        view_pos = str(req.form.get("view_pos", "PA")).upper()
        age = float(req.form.get("age", 45))
        gender = str(req.form.get("gender", "M")).upper()
        top_k = int(req.form.get("top", 3))
        with_cam = str(req.form.get("with_cam", "true")).lower() in ("true", "1", "yes")
        target_label = req.form.get("target_label", None)
        lang = str(req.form.get("lang", "uz")).lower()

    view_pos = "AP" if view_pos.startswith("AP") else "PA"
    age = float(np.clip(age, 1.0, 95.0))
    gender = "F" if gender.startswith("F") or gender.startswith("A") else "M"
    lang = lang if lang in ("uz", "ru", "en") else "uz"
    return pil_img, view_pos, age, gender, top_k, with_cam, target_label, lang


# --- REST API Endpointlar ---

@app.route("/api/v1/health", methods=["GET"])
def api_health():
    return jsonify({
        "status": "ok",
        "model_loaded": MODEL is not None,
        "version": META.get("version", "BMI_CXR_multilabel_v2"),
        "device": DEVICE,
        "img_size": IMG_SIZE,
        "use_clahe": USE_CLAHE,
        "use_meta": USE_META,
        "test_macro_auroc": META.get("test_macro_auroc", 0.7766),
        "test_macro_auroc_ci95": META.get("test_macro_auroc_ci95", [0.7515, 0.7976]),
        "labels": [
            {
                "index": i,
                "label": l,
                "name_uz": PATHOLOGY_INFO.get(l, {}).get("uz", l),
                "description_uz": PATHOLOGY_INFO.get(l, {}).get("desc", ""),
                "threshold": round(float(THR[i]), 4)
            }
            for i, l in enumerate(LABELS)
        ],
        "disclaimer": MEDICAL_DISCLAIMER
    })


@app.route("/api/v1/predict", methods=["POST", "OPTIONS"])
def api_predict():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200

    if API_KEY_SECRET and request.headers.get("X-API-Key") != API_KEY_SECRET:
        return jsonify({"status": "error", "message": "Invalid or missing X-API-Key header"}), 401

    if MODEL is None:
        return jsonify({"status": "error", "message": f"Model fayli yuklanmagan ({ckpt_path})"}), 503

    t0 = time.time()
    try:
        pil_img, view_pos, age, gender, top_k, with_cam, target_label, lang = extract_image_and_params(request)
        x, img01 = preprocess_pil_image(pil_img)
        meta_vec = torch.tensor([[
            1.0 if view_pos == "AP" else 0.0,
            age / 100.0,
            1.0 if gender == "M" else 0.0
        ]], dtype=torch.float32)

        with torch.no_grad():
            p = MODEL.calibrated_probs(x.to(DEVICE), meta_vec.to(DEVICE)).float()
            # Test-Time Augmentation (TTA: markaziy zoom)
            h, w = x.shape[-2:]
            d = int(0.03 * h)
            x_zoom = F.interpolate(x[:, :, d:h-d, d:w-d], size=(h, w), mode="bilinear", align_corners=False)
            p_zoom = MODEL.calibrated_probs(x_zoom.to(DEVICE), meta_vec.to(DEVICE)).float()
            probs = (0.70 * p + 0.30 * p_zoom)[0].cpu().numpy()

        findings = []
        for j in np.argsort(-probs):
            prob, thr = float(probs[j]), float(THR[j])
            is_pos = bool(prob >= thr)
            ratio = prob / max(0.01, thr)
            if ratio >= 1.25:
                risk_code, risk_uz = "HIGH", "Yuqori (Musbat)"
            elif ratio >= 1.0:
                risk_code, risk_uz = "MODERATE_HIGH", "O'rta-Yuqori (Musbat)"
            elif ratio >= 0.75:
                risk_code, risk_uz = "BORDERLINE", "Shubhali (Chegaraviy — nazorat tavsiya etiladi)"
            else:
                risk_code, risk_uz = "LOW", "Past (Me'yorda)"

            lbl = LABELS[j]
            findings.append({
                "index": int(j),
                "label": lbl,
                "name_uz": PATHOLOGY_INFO.get(lbl, {}).get("uz", lbl),
                "description_uz": PATHOLOGY_INFO.get(lbl, {}).get("desc", ""),
                "prob": round(prob, 4),
                "prob_percent": round(prob * 100.0, 1),
                "threshold": round(thr, 4),
                "positive": is_pos,
                "risk_code": risk_code,
                "risk_level": risk_uz
            })

        pos_list = [f for f in findings if f["positive"]]
        no_finding_conf = float(np.prod([1.0 - f["prob"] for f in findings[:5]]))
        no_finding_conf = round(max(no_finding_conf, 1.0 - findings[0]["prob"]), 4)
        is_normal = (len(pos_list) == 0)

        if is_normal:
            overall_risk = "LOW"
            summary_uz = f"Patologiya aniqlanmadi (Norma / No Finding, ishonchlilik ~{no_finding_conf*100:.1f}%)."
        else:
            urgent = any(f["label"] in ("Pneumothorax", "Edema", "Mass", "Pneumonia") for f in pos_list)
            overall_risk = "HIGH" if (urgent or len(pos_list) >= 2) else "MODERATE"
            pos_names = ", ".join([f"{f['name_uz']} ({f['prob_percent']}%)" for f in pos_list])
            summary_uz = f"Diqqat: {len(pos_list)} ta ehtimoliy patologiya aniqlandi — {pos_names}. Shifokor-rentgenolog ko'rigi tavsiya etiladi."

        cam_data = None
        if with_cam:
            if target_label and target_label in LABELS:
                cam_k = LABELS.index(target_label)
            else:
                cam_k = int(np.argmax(probs))
            cam_np = compute_gradcam_pp(MODEL, x, meta_vec, cam_k, apply_anat_mask=True)
            overlay_b64, heatmap_b64 = create_cam_visuals(img01, cam_np, alpha=0.42)
            orig_u8 = np.stack([(img01 * 255.0).astype(np.uint8)] * 3, axis=-1)
            cam_data = {
                "target_label": LABELS[cam_k],
                "target_name_uz": PATHOLOGY_INFO.get(LABELS[cam_k], {}).get("uz", LABELS[cam_k]),
                "lung_focus_ratio": round(compute_lung_focus_ratio(cam_np), 4),
                "original_clahe_base64": encode_png_base64(orig_u8),
                "overlay_base64": overlay_b64,
                "heatmap_only_base64": heatmap_b64
            }

        elapsed_ms = int((time.time() - t0) * 1000)
        return jsonify({
            "status": "success",
            "request_id": str(uuid.uuid4())[:8],
            "inference_ms": elapsed_ms,
            "is_normal": is_normal,
            "no_finding_confidence": no_finding_conf,
            "overall_risk": overall_risk,
            "clinical_summary": summary_uz,
            "patient_meta": {"view_pos": view_pos, "age": int(age), "gender": gender},
            "positive_findings": pos_list,
            "top_findings": findings[:top_k],
            "all_findings": findings,
            "gradcam": cam_data,
            "disclaimer": MEDICAL_DISCLAIMER.get(lang, MEDICAL_DISCLAIMER["uz"])
        })

    except Exception as e:
        logger.exception("Predict xatoligi:")
        return jsonify({"status": "error", "message": str(e)}), 400


@app.route("/", methods=["GET"])
def index_dashboard():
    dashboard_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cxr_cdss_dashboard.html")
    if os.path.exists(dashboard_file):
        return send_file(dashboard_file)
    return jsonify({"message": "BMI CXR Multimodal API v2 ishlamoqda. /api/v1/health yoki /api/v1/predict ga murojaat qiling."})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
