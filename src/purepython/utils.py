import config
import requests
# CSVからFHIRリソースへの変換で使用するユーティリティ関数群

ENDPOINT = config.ENDPOINT
AUTH = config.AUTH

# エンドポイントにパスを追加する関数
def join_url(base: str, path: str) -> str:
    return base.rstrip("/") + "/" + path.lstrip("/")

# POST要求を実行しHTTP応答を戻り値で返す
def post(payload,resourceName) :
    headers = {
    "Accept": "*/*",
    "content-type": "application/fhir+json;charset=utf-8",
    "Accept-Encoding": "gzip, deflate, br",
    "Prefer": "return=representation"
    }

    URL=join_url(ENDPOINT,resourceName)
    # POST要求
    response = requests.post(URL, data=payload, headers=headers, auth=AUTH)

    # HTTPステータスチェック：エラーなら情報出力
    if response.status_code not in (200, 201):
        print(f"HTTP要求失敗。ステータスコード： {response.status_code}")
        print("Response:", response.text)

    return response

# GET要求を実行しHTTP応答を戻り値で返す
def get(resourceName,queryparams):
    headers = {
    "Accept": "*/*",
    "content-type": "application/fhir+json;charset=utf-8",
    "Accept-Encoding": "gzip, deflate, br",
    "Prefer": "return=representation"
    }
    URL=join_url(ENDPOINT,f"{resourceName}?{queryparams}") 
    # GET要求
    response = requests.get(URL, headers=headers, auth=AUTH)

    # HTTPステータスチェック：エラーなら情報出力
    if response.status_code not in (200, 201):
        print(f"HTTP要求失敗。ステータスコード： {response.status_code}")
        print("Response:", response.text)

    return response
