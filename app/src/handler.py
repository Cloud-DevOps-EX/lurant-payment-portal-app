import json
import os

import boto3
import pg8000.native

_secrets_client = boto3.client("secretsmanager")
_cached_secret = None


def _get_db_secret():
    global _cached_secret
    if _cached_secret is None:
        response = _secrets_client.get_secret_value(SecretId=os.environ["DB_SECRET_ARN"])
        _cached_secret = json.loads(response["SecretString"])
    return _cached_secret


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _health():
    return _response(200, {"status": "ok"})


def _db_check():
    secret = _get_db_secret()
    try:
        conn = pg8000.native.Connection(
            user=secret["username"],
            password=secret["password"],
            host=secret["host"],
            port=secret["port"],
            database=secret["dbname"],
            ssl_context=True,
            timeout=5,
        )
        conn.run("SELECT 1")
        conn.close()
        return _response(200, {"status": "ok", "db": "reachable"})
    except Exception:
        return _response(503, {"status": "error", "db": "unreachable"})


def handler(event, context):
    path = event.get("rawPath", "")
    if path == "/health":
        return _health()
    if path == "/db-check":
        return _db_check()
    return _response(404, {"status": "error", "message": "not found"})
