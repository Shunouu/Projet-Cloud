import os
from datetime import datetime, timezone

from azure.storage.blob import BlobServiceClient
from flask import Flask, abort, jsonify, request, send_file
from werkzeug.utils import secure_filename


def _env(name: str, default: str | None = None) -> str:
    val = os.getenv(name, default)
    if val is None or val.strip() == "":
        raise RuntimeError(f"Missing required env var: {name}")
    return val


def _get_container_client():
    conn = _env("AZURE_STORAGE_CONNECTION_STRING")
    container = os.getenv("AZURE_STORAGE_CONTAINER", "fichiers").strip() or "fichiers"
    svc = BlobServiceClient.from_connection_string(conn)
    return svc.get_container_client(container)


app = Flask(__name__)


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/files")
def list_files():
    cc = _get_container_client()
    blobs = []
    for b in cc.list_blobs():
        blobs.append(
            {
                "name": b.name,
                "size": getattr(b, "size", None),
                "last_modified": getattr(b, "last_modified", None),
            }
        )

    blobs.sort(key=lambda x: x["name"])
    return jsonify({"files": blobs})


@app.get("/")
def root():
    return jsonify(
        {
            "service": "cloud-backend",
            "endpoints": {
                "health": "/health",
                "list_files": "/files",
                "upload": "/upload (multipart field: file)",
                "download": "/download/<blob_name>",
                "delete": "/delete/<blob_name> (POST)",
            },
        }
    )


@app.post("/upload")
def upload():
    if "file" not in request.files:
        abort(400, "missing file field")
    f = request.files["file"]
    if not f or not f.filename:
        abort(400, "missing filename")

    filename = secure_filename(f.filename)
    if not filename:
        abort(400, "invalid filename")

    prefix = os.getenv("BLOB_PREFIX", "").strip().lstrip("/")
    blob_name = f"{prefix}/{filename}" if prefix else filename

    cc = _get_container_client()
    cc.upload_blob(name=blob_name, data=f.stream, overwrite=True)
    return jsonify({"uploaded": blob_name})


@app.get("/download/<path:blob_name>")
def download(blob_name: str):
    cc = _get_container_client()
    blob_client = cc.get_blob_client(blob_name)

    try:
        data = blob_client.download_blob().readall()
    except Exception as e:
        abort(404, f"blob not found: {e}")

    tmp_dir = "/tmp"
    os.makedirs(tmp_dir, exist_ok=True)
    safe = secure_filename(os.path.basename(blob_name)) or "file"
    ts = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    path = os.path.join(tmp_dir, f"{ts}-{safe}")
    with open(path, "wb") as fh:
        fh.write(data)

    return send_file(path, as_attachment=True, download_name=safe)


@app.post("/delete/<path:blob_name>")
def delete(blob_name: str):
    cc = _get_container_client()
    blob_client = cc.get_blob_client(blob_name)
    try:
        blob_client.delete_blob()
    except Exception:
        abort(404, "blob not found")
    return jsonify({"deleted": blob_name})


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=False)