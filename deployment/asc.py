"""Minimal App Store Connect API client shared by the deployment scripts."""
import json
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

KEY_ID = "V8FBWK55MT"
ISSUER = "196f43aa-4520-4178-a7df-68db3cf7ee76"
APP_ID = "6755891772"
BASE = "https://api.appstoreconnect.apple.com"
PRIVATE_KEY = (Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{KEY_ID}.p8").read_text()

_token = {"value": None, "exp": 0}


def token():
    now = int(time.time())
    if now > _token["exp"] - 60:
        _token["value"] = jwt.encode(
            {"iss": ISSUER, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
            PRIVATE_KEY, algorithm="ES256", headers={"kid": KEY_ID, "typ": "JWT"},
        )
        _token["exp"] = now + 900
    return _token["value"]


def request(method, path, body=None):
    """Returns (status, json). Never raises on HTTP errors."""
    req = urllib.request.Request(
        path if path.startswith("http") else BASE + path,
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            data = r.read()
            return r.status, (json.loads(data) if data else {})
    except urllib.error.HTTPError as e:
        data = e.read()
        try:
            return e.code, json.loads(data)
        except ValueError:
            return e.code, {"raw": data.decode(errors="replace")}


def call(method, path, body=None):
    """Like request() but exits on any non-2xx."""
    status, data = request(method, path, body)
    if status >= 300:
        raise SystemExit(f"{method} {path} -> HTTP {status}\n{json.dumps(data, indent=2)[:2000]}")
    return data


def paginate(path):
    out = []
    while path:
        data = call("GET", path)
        out.extend(data["data"])
        path = data.get("links", {}).get("next")
    return out


def patch(kind, obj_id, attributes=None, relationships=None):
    data = {"type": kind, "id": obj_id}
    if attributes:
        data["attributes"] = attributes
    if relationships:
        data["relationships"] = relationships
    return call("PATCH", f"/v1/{kind}/{obj_id}", {"data": data})


def en_us(items):
    return next(i for i in items if i["attributes"]["locale"] == "en-US")


def rel(kind, obj_id):
    return {"data": {"type": kind, "id": obj_id}}
