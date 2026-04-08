import json
import iris

# Patient用の変換クラス
# 引数：レコードマップで作ったメッセージ
# 戻り：Patientテンプレートのインスタンス
def transform_patient(record):
    # レコードマップの内容をJSONに変換
    ## JSON文字にする場合
    #jsonmoji=iris.ref()
    #record._JSONExportToString(jsonmoji)
    ## dictに変換：JSON文字の場合、jsonmoji.valueでとれる
    #inputdict=json.loads(jsonmoji.value)
    
    #ストリームに変換する場合（JSON文字がストリームに格納される）
    stream=iris.ref()
    record._JSONExportToStream(stream)
    #dictに変換：ストリームの場合、JSON文字はstream.value.Read()でとれる
    inputdict=json.loads(stream.value.Read())

    #入力された誕生日を内部日付に変換
    inputdict["DOB"]=iris.system.SQL.TODATE(inputdict["DOB"],"YYYYMMDD")
    #性別の変更（M→1、F→2）
    if inputdict["Gender"] == "M":
        inputdict["Gender"] = 1
    elif inputdict["Gender"] == "F":
        inputdict["Gender"] = 2
    
    # IRISに戻すため、ダイナミックオブジェクトに再度変換
    input=iris._Library.DynamicObject._FromJSON(json.dumps(inputdict))
    # Patientテンプレートのインスタンスを作成
    patient=iris.FHIRTemplate.Patient._New(input)
    #Addressテンプレートクラスのインスタンス化
    address=iris.FHIRTemplate.DataType.Address._New(input)
    patient.Address=address    

    return patient


# Obseravation用の変換クラス
# 引数1：レコードマップで作ったメッセージ
# 引数2：PatientIdとリソースIDの関連
#  例） pidresult = {
#    "123": "Patient/1",
#    "456": "Patient/2"
#}
# 戻り：Observationテンプレートのインスタンス
def transform_observation(record,map):
    # レコードマップのインスタンス→ストリーム→Dict
    stream=iris.ref()
    record._JSONExportToStream(stream)
    inputdict=json.loads(stream.value.Read())
    # ストリーム→ダイナミックオブジェクト
    input_dynamic=iris._Library.DynamicObject._FromJSON(stream.value)

    # Observationテンプレートクラスのインスタンス
    observation=iris.FHIRCustom.ObservationBodyMeasurement._New()
    # Categoryのセット（exam）
    catgory=iris.FHIRCustom.CodeableConcept.ObservationCategory.GetByCode("exam")
    observation.Category.Insert(catgory)
    # Codeの作成
    code=iris.FHIRCustom.CodeableConcept.BodyMeasurementCode._New(input_dynamic)
    observation.Code=code
    # EffectiveDateTimeのセット
    observation.EffectiveDateTime=iris.system.SQL.TODATE(inputdict["EffectiveDateTime"],"YYYY-MM-DD")
    # ValueQuantityのセット
    valueQuantity=iris.FHIRTemplate.DataType.Quantity._New(input_dynamic)
    observation.ValueQuantity=valueQuantity
    # reference（Observation.subject に Patient のリソース ID をセット）
    patient_id = inputdict.get("PatientId")
    observation.PatientResourceId = map.get(
        patient_id,
        f"Patient/{patient_id}" if patient_id else None
    )

    return observation