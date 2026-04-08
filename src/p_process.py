# ビジネスプロセスから呼ばれる
import iris
import transform
import json

# 要求メッセージからPatientリソースPOST用要求メッセージを作る関数
# 第1引数：要求メッセージ（レコードマップ）
# 第2引数：FHIRエンドポイント
# 戻り値：応答メッセージ,ステータス
def create_patient(request,endpoint):
    # ステータスOKで初期化
    status=iris.system.Status.OK()
    try:
        # レコードマップ（要求メッセージ）をPatientテンプレートのインスタンスにセット
        patient=transform.transform_patient(request)
        # IRISのダイナミックオブジェクトに変換（参照渡しのためiris.refを使う）
        patient_dynamic=iris.ref()
        status=patient.OutputToDynamicObject(patient_dynamic)
        iris.check_status(status)

        # 検証
        status=iris.CSVtoFHIR.Utils.Validate(patient_dynamic.value)
        iris.check_status(status)

        # QuickStream に作成した Patient リソースを保存
        qs=iris.HS.SDA3.QuickStream._New()
        qsid=qs._Id()
        status=patient.OutputToStream(qs)
        # 先頭に戻す（これ大事）
        qs.Rewind()

        # FHIRリポジトリに送るためのメッセージ作成
        fhirrequest=iris.HS.FHIRServer.Interop.Request._New()
        fhirrequest.Request.RequestMethod="POST"
        fhirrequest.Request.RequestPath="Patient"
        fhirrequest.Request.RequestFormatCode="JSON"
        fhirrequest.Request.ResponseFormatCode="JSON"
        fhirrequest.Request.SessionApplication=endpoint
        fhirrequest.Request.BaseURL=endpoint
        fhirrequest.QuickStreamId=qsid

    except Exception as ex:
        return None,iris.system.Status.Error(5001, str(ex))
    
    return fhirrequest,status


# PatientIdから既存のリソースがあるかどうか検索に使うメッセー時作成
# 第1引数：レコードマップから作成されたメッセージ（CSVtoFHIR.RM.LabTestBatch）
# 第2引数：FHIRエンドポイント
# 第3引数：identifier
# 戻り値：検索処理用要求メッセージ,ステータス
def patient_search(request,endpoint,identifier):
    status = iris.system.Status.OK()
    try:
        # CSVtoFHIR.RM.LabTestBatchのRecordsに含まれる数だけループしながらPatientIdを取得
        recordcnt=request.Records.Count()
        seen_pids=set()
        pids=[]
        for i in range(1,recordcnt+1):
            pid=request.Records.GetAt(i).PatientId
            # 新規PIDかどうかチェック
            if pid not in seen_pids:
                seen_pids.add(pid)
                pids.append(str(pid))
        
        pidstring = ",".join(pids)

        # FHIRリポジトリに送るためのメッセージ作成
        fhirrequest=iris.HS.FHIRServer.Interop.Request._New()
        fhirrequest.Request.RequestMethod="GET"
        fhirrequest.Request.RequestPath="Patient"
        fhirrequest.Request.QueryString="identifier=" + identifier + "|" + pidstring
        fhirrequest.Request.RequestFormatCode="JSON"
        fhirrequest.Request.ResponseFormatCode="JSON"
        fhirrequest.Request.SessionApplication=endpoint
        fhirrequest.Request.BaseURL=endpoint

    except Exception as ex:
        return None,iris.system.Status.Error(5001, str(ex))
    
    return fhirrequest,status


# QuickStreamIdからPayloadを取得
# 引数：QuickStreamId
# 戻り値：JSON
def quickstream_to_json(qsid):
    payload = iris.HS.SDA3.QuickStream._OpenId(qsid)
    return json.loads(payload.Read())

# searchReponseにある情報からPatientIdとResourceIdの組み合わせを探す
# 引数：検索結果のBundle
# 戻り：以下dictionary
#  例） pidmap = {
#    "123": "Patient/1",
#    "456": "Patient/2"
#}
def extract_patient_id_map(search_bundle_json):
    pid_map = {}

    for entry in search_bundle_json.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") != "Patient":
            continue

        patient_id = None

        identifiers = resource.get("identifier") or []
        if identifiers and "value" in identifiers[0]:
            patient_id = identifiers[0]["value"]
        if patient_id and "id" in resource:
            pid_map[patient_id] = "Patient/" + resource["id"]

    return pid_map

# 要求メッセージからBundleリソースPOST用要求メッセージを作る関数
# 第1引数：要求メッセージ（レコードマップ）
# 第2引数：患者検索結果のQuickStreamIdが戻る
# 第3引数：FHIRエンドポイント
# 戻り値：応答メッセージ,ステータス
def create_bundle(request,qsid,endpoint):
    status = iris.system.Status.OK()
    try:
        # QuickStreamIdからPayloadを取得
        pat_json=quickstream_to_json(qsid)

        # searchReponseにある情報からPatientIdとResourceIdの組み合わせを探す
        pidresult=extract_patient_id_map(pat_json)
        #pidresult = []
        #seen_pids = set()
        #if patJSON.get("total", 0) > 0:
        #    for p in patJSON.get("entry", []):
        #        pid = p["resource"]["identifier"][0]["value"]
        #        rid = "Patient/" + p["resource"]["id"]

        #        if pid not in seen_pids:
        #            seen_pids.add(pid)
        #            pidresult.append({
        #                "PatientId": pid,
        #                "ResourceId": rid
        #            })

        # Bundle作成
        bundle=iris.FHIRCustom.BundleTransaction._New()

        # レコードマップのデータをObservationリソースに変換しbundleに格納
        recordcnt=request.Records.Count()
        for i in range(1,recordcnt+1):
            observation=transform.transform_observation(request.Records.GetAt(i),pidresult)
            iris.check_status(status)
            observation.requestMethod="POST"
            observation.requestUrl="Observation"
            # Bundle に Observation登録
            bundle.resource.Insert(observation)

        # IRISのダイナミックオブジェクトに変換（参照渡しのためiris.refを使う）
        bundle_dynamic=iris.ref()
        status=bundle.OutputToDynamicObject(bundle_dynamic)
        iris.check_status(status)

        # 検証
        status=iris.CSVtoFHIR.Utils.Validate(bundle_dynamic.value)
        iris.check_status(status)

        # QuickStream に作成した Bundle リソースを保存
        qs=iris.HS.SDA3.QuickStream._New()
        qsid=qs._Id()
        status=bundle.OutputToStream(qs)
        # 先頭に戻す（これ大事）
        qs.Rewind()

        # FHIRリポジトリに送るためのメッセージ作成
        fhirrequest=iris.HS.FHIRServer.Interop.Request._New()
        fhirrequest.Request.RequestMethod="POST"
        fhirrequest.Request.RequestPath="/"
        fhirrequest.Request.RequestFormatCode="JSON"
        fhirrequest.Request.ResponseFormatCode="JSON"
        fhirrequest.Request.SessionApplication=endpoint
        fhirrequest.Request.BaseURL=endpoint
        fhirrequest.QuickStreamId=qsid

    except Exception as ex:
        return None,iris.system.Status.Error(5001, str(ex))

    return fhirrequest,status