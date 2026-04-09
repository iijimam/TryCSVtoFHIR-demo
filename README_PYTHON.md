# CSV から FHIR リソースへの変換 -- Python編
- [CSV から FHIR リソースへの変換 -- Python編](#csv-から-fhir-リソースへの変換----python編)
  - [この章の位置づけ](#この章の位置づけ)
  - [1. 変換の流れ](#1-変換の流れ)
    - [1-1. 患者基本情報が含まれるCSVからPatientリソースを作成する流れ](#1-1-患者基本情報が含まれるcsvからpatientリソースを作成する流れ)
    - [1-2. 身長・体重が含まれるCSVからObservationリソースを登録する流れ（複数一括登録）](#1-2-身長体重が含まれるcsvからobservationリソースを登録する流れ複数一括登録)
      - [1-2-1. Observationリソースの作成](#1-2-1-observationリソースの作成)
      - [1-2-2. PatientId に関連する Patient リソースの id を入手する](#1-2-2-patientid-に関連する-patient-リソースの-id-を入手する)
      - [1-2-3. Bundle の組み立て](#1-2-3-bundle-の組み立て)
  - [2. 実行方法](#2-実行方法)
    - [2-1. Patient リソースへの変換](#2-1-patient-リソースへの変換)
    - [2-2. Observation リソースへの変換と登録](#2-2-observation-リソースへの変換と登録)
  - [まとめ](#まとめ)

## この章の位置づけ

この章では、IRIS を使用せず、純粋な Python のみで FHIR リソースを作成・登録する方法を説明します。

IRIS 版との違いとして、以下の特徴があります：

- すべての処理を Python コードで実装する必要があります
- FHIR リソースの構造を明示的に組み立てる必要があります
- 柔軟性が高い一方で、実装負荷が高くなります

> [fhir.resources](https://pypi.org/project/fhir.resources/) は、[pydantic](https://pydantic-docs.helpmanual.io/) V2 を基盤としているため、FHIRオブジェクトを作成することで、FHIRリソースの必須項目や文字長の精査などを行うことができます。
> 
> 💡注意：fhir.resources による検証は「基本的な構造チェック」に限られます。FHIR プロファイルに基づく厳密な検証（StructureDefinition）は行われません。
>
> FHIR R4用の fhir.resources のインストールバージョンについては、[requirements.txt](./src/requirements.txt)をご参照ください。 

コード一式は、[purepython](./src/purepython/) 以下にあります。

> メモ：FHIR リソースの JSON 構造にあまりなじみのない方でも読みやすいように記載しています。

## 1. 変換の流れ

変換の流れはとてもシンプルです。

CSV をロードし、作成したいFHIRリソースの構造に合わせた Python ディクショナリを作ります。

作成したディクショナリの中に、CSV から読み込んだデータを当てはめ、FHIR オブジェクト化します。

FHIR オブジェクト化できる＝基本的な精査は通過できているので、後は、JSON に変換し、POST 要求をするだけです。

以下の図は、CSV から FHIR リソース作成〜 POST までの全体の流れを示しています。

![](./assets/CSVtoFHIR-purePython-flow.png)


### 1-1. 患者基本情報が含まれるCSVからPatientリソースを作成する流れ

Patient リソースを作成する流れをコードサンプルを含めながら解説します。

コード全体はこちら👉[patient.py](./src/purepython/patient.py)

使用する CSV のイメージは以下の通りです（[サンプルCSV](./data/Step2/Example-InputDataPatient.csv)）。

```
PatientId,HospitalID,LastName,FirstName,LastNameKana,FirstNameKana,DOB,Gender,postalCode,state,city,line,Phone
191922,GENHOSP,鈴木,太郎,スズキ,タロウ,19560129,M,1600023,東京,新宿区,西新宿,(900)485-5344
```

ファイルを読み込んだ後、以下のような Python ディクショナリを作成し、CSV から読み込んだ情報を当てはめています。

```python
patient_data = {
    "resourceType": "Patient",
    "name": [
    {
        "extension": [
        {
            "url": "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation",
            "valueCode": "IDE"
        }
        ],
        "use": "official",
        "text": f"{lastname} {firstname}",
        "family": lastname,
        "given": [
        firstname
        ]
    },
    {
        "extension": [
        {
            "url": "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation",
            "valueCode": "SYL"
        }
        ],
        "use": "official",
        "text": f"{kanalast} {kanafirst}",
        "family": kanalast,
        "given": [
        kanafirst
        ]
    }],
    "address": [{
        "line": [line],
        "city": city,
        "state": state,
        "postalCode": postalCode,
        "text": state + city + line
    }],
    "birthDate": dob,
    "gender": gender_map.get(gender, "unknown"),
    "telecom": [{
        "system": "phone",
        "use": "home",
        "value": phone,
    }],
    "identifier": [{
        "system": "urn:oid:1.2.392.100495.20.3.51.11311234567",
        "value": pid,
    }]
}
```

次に、ディクショナリから fhir.resources を使用して FHIR Patient リソースに対応する FHIR Patient オブジェクトを作成します。

実行には、以下インポートが必要です。
```python
from fhir.resources.patient import Patient
```
変換は、ディクショナリを引数に渡すだけです。
```python
patient_resource = Patient(**patient_data)
```
ここで、FHIR オブジェクト化が失敗する＝基本の精査が失敗したことになります。

後は、POST 要求で FHIR リポジトリにリクエストを送信するだけです。

以下の関数は、[utils.py](./src/purepython/utils.py) にあります。
```python
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
```


### 1-2. 身長・体重が含まれるCSVからObservationリソースを登録する流れ（複数一括登録）

複数の Observation リソースを作成し、Bundle の "type":"transaction" で POST 要求を送信する流れをコードサンプルを含めながら解説します。

- Observation リソースへの変換を行っているコード全体は、こちら👉[observation.py](./src/purepython/observation.py)

- Bundle リソースに作成した Observation リソースを設定し POST 要求を行うコード全体は、こちら👉[observationpost.py](./src/purepython/observationpost.py)



使用するCSVのイメージは以下の通りです（[サンプルCSV](./data/Step2/Example-InputDataLabTest.csv)）。
```
PatientId,code,display,value,unit,EffectiveDateTime
191922,bw,体重,62,kg,2026-01-30 8:45
191922,bh,身長,170,cm,2026-01-30 8:45
```

サンプルCSVにあるように、一人の患者に複数の検査結果が登録されているファイルをロードします。

Observation 登録時、どの Patient リソースと関連した検査結果かを示す必要があるため、患者を示す `PatientId` に関連する FHIR リポジトリのリソース ID を取得してから Observation リソースを作成する必要があります。

処理の流れは以下の通りです。

![](./assets/CSVtoFHIR-purePython-Observationflow.png)

#### 1-2-1. Observationリソースの作成

まずは、Observation リソースを作成するための変換処理です。この部分は Patient リソース作成の流れと同様です。

CSV から取得した情報を、FHIR Observation リソースの構造と合わせたディクショナリを用意し、そこに当てはめます。

```python
observation_data = {
    "resourceType": "Observation",

    "meta": {
        "profile": [
            "http://hl7.org/fhir/StructureDefinition/vitalsigns"
        ]
    },
    "identifier": [
        {
            "system": "http://example.org/observation-id",
            "value": f"{pid}-{code}"
        }
    ],
    "status": "final",
    "category": [
        {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                    "code": "vital-signs",
                    "display": "Vital Signs"
                }
            ],
            "text": "Vital Signs"
        }
    ],
    "code": {
        "coding": [
            {
                "system": "http://www.isjhospital.com/Observation_Code",
                "code": code,
                "display": display,
            },
        ]
    },
    "valueQuantity":{
        "value":float(value),
        "unit":unit
    },
    "effectiveDateTime":effectivedt
}
```

作成したディクショナリから、Observation リソースに対応する Observation オブジェクトを作成します。

実行には、以下のインポートが必要です。
```python
from fhir.resources.observation import Observation
```
```python
# Observationリソースの作成
observation_resource = Observation(**observation_data)
```
複数の Observation が作成できるため、PatientId と検査コードをキー保存しておきます。
```python
# PatientIdをキーにリソースを保存
self.observations[(pid,code)] = observation_resource
```

#### 1-2-2. PatientId に関連する Patient リソースの id を入手する

次は、PatientId に対する Patient リソースの id を取得するため、GET 要求を実行します。

コード全体は、[observationpost.py](./src/purepython/observationpost.py) にあります。 

以下のコードの `observations` は、`{(PatientId,code):Observationオブジェクト}` の構造で Observationオブジェクトが格納されています。

```python
class FindPatient:
    def __init__(self,observations):
        # GET後のBundle格納用
        self.bundle = {}
        # 検査結果に関連したPatientリソース情報
        self.find_patient_resource_id(observations)

    def find_patient_resource_id(self,observations) -> None:
        """
        第2引数のobservationsから、PatientIdを入手し、リポジトリにあるPatientのリソースIDを特定する
        Patient.identifier.system は　urn:oid:1.2.392.100495.20.3.51.11311234567 とする
        """
        identifier_system="urn:oid:1.2.392.100495.20.3.51.11311234567"

        # PatientIdだけ取り出してユニーク化
        unique_pids = {pid for pid, _ in observations.observations.keys()}
        # クエリパラメータ用のカンマ区切り文字列にする
        pid_string = ",".join(sorted(unique_pids))
        # クエリパラメータ
        params=f"identifier={identifier_system}|{pid_string}"
        # GET要求実行
        response=get("Patient",params)
        bundle_data=response.json()
        # bundleリソースの作成
        self.bundle = Bundle(**bundle_data)

    def build_pid_map(self):
        pid_map={}
        if not self.bundle.entry:
            return pid_map
        
        for entry in self.bundle.entry:
            patient=entry.resource
            if not patient.identifier:
                continue
            pid = patient.identifier[0].value
            resource_id = f"Patient/{patient.id}"
            pid_map[pid] = resource_id
        return pid_map
```

GET 要求の応答で入手できる Bundle から `build_pid_map()` を呼び出し `例：pid_map[12345]="Patient/1"` の形式でディクショナリを作成しています。

#### 1-2-3. Bundle の組み立て

最後に、作成した Observation オブジェクトに、入手した Patient リソースの id をリファレンスとして設定し、Bundle.entry に設定します。

コード全体は、[observationpost.py](./src/purepython/observationpost.py) にあります。 

処理に必要なインポートは、以下の通りです。
```python
from fhir.resources.bundle import (
    Bundle,
    BundleEntry,
    BundleEntryRequest
)
from fhir.resources.reference import Reference
```

```python
class ObservationPoster:
    def __init__(self,observations,pid_map):
        self.observations = observations
        self.pid_map = pid_map
        self.bundle = self.build_bundle()

    def build_bundle(self):
        """
        Bundleリソースを組み立てる
        """
        entries=[]

        for (pid,code),observation in self.observations.observations.items():
            patient_ref=self.pid_map.get(pid)
            if not patient_ref:
                print(f"Patientが見つからないためスキップ: pid={pid}, code={code}")
                continue
            # subject.reference を設定
            observation.subject = Reference(reference=patient_ref)
            # request作成
            request = BundleEntryRequest(
                method="POST",
                url="Observation"                
            )
            # entry作成
            entry = BundleEntry(
                fullUrl=f"urn:uuid:{uuid.uuid4()}",
                resource=observation,
                request=request
            )
            entries.append(entry)

        bundle = Bundle(
            type="transaction",
            entry=entries
        )
        return bundle
```
後は、POST 要求を実行するだけです。

```python
poster = ObservationPoster(observations, pid_map)
response = post(poster.bundle.json(),"/")
```

## 2. 実行方法

コンテナにログインしてから実行します。

```
docker exec -it trycsvtofhir-demo-csvtofhir-1 bash
```

コンテナ内の以下ディレクトリに移動し、実行します。
```
irisowner@49efa230c4be:/opt/src$ cd /src/purepython/
irisowner@49efa230c4be:/src/purepython$ 
```
### 2-1. Patient リソースへの変換

[patient.py](./src/purepython/patient.py) を実行します。

[InputDataPatient.csv](./data/Step2/InputDataPatient.csv) を読み込んでいます。

```
python3 patient.py
```
実行例は以下の通りです（変換したリソースに含まれる値を一覧した後、POST要求の応答JSONを画面に表示しています）。
```
irisowner@8d9f9a48ce5f:/src/purepython$ python3 patient.py
Identifier: 191922, Given: 太郎, Family: 鈴木
address.[0].city: 新宿区
address.[0].line.[0]: 西新宿
address.[0].postalCode: 1600023
address.[0].state: 東京
address.[0].text: 東京新宿区西新宿
birthDate: 1970-08-15
gender: male
identifier.[0].system: urn:oid:1.2.392.100495.20.3.51.11311234567
identifier.[0].value: 191922
name.[0].extension.[0].url: http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation
name.[0].extension.[0].valueCode: IDE
name.[0].family: 鈴木
name.[0].given.[0]: 太郎
<表示省略>
name.[1].text: ハナコ サトウ
name.[1].use: official
telecom.[0].system: phone
telecom.[0].use: home
telecom.[0].value: (900)999-9999
resourceType: Patient
[{'address': [{'city': '新宿区', 'line': ['西新宿'], 'postalCode': '1600023', 'state': '東京', 'text': '東京新宿区西新宿'}], 'birthDate': '1970-08-15', 'gender': 'male', 'identifier': [{'system': 'urn:oid:1.2.392.100495.20.3.51.11311234567', 'value': '191922'}], 'name': [{'extension': [{'url': 'http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation', 'valueCode': 'IDE'}], 'family': '鈴木', 'given': ['太郎'], 'text': '鈴木 太郎', 'use': 'official'}, {'extension': [{'url': 'http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation', 'valueCode': 'SYL'}], 'family': 'タロウ', 'given': ['スズキ'], 'text': 'タロウ スズキ', 'use': 'official'}], 'telecom': [{'system': 'phone', 'use': 'home', 'value': '(900)485-5344'}], 'resourceType': 'Patient', 'id': '1', 'meta': {'lastUpdated': '2026-04-09T08:22:14Z', 'versionId': '1'}}, {'address': [{'city': '北区', 'line': ['堂島'], 'postalCode': '5300003', 'state': '大阪', 'text': '大阪北区堂島'}], 'birthDate': '1970-08-17', 'gender': 'female', 'identifier': [{'system': 'urn:oid:1.2.392.100495.20.3.51.11311234567', 'value': '498374'}], 'name': [{'extension': [{'url': 'http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation', 'valueCode': 'IDE'}], 'family': '佐藤', 'given': ['花子'], 'text': '佐藤 花子', 'use': 'official'}, {'extension': [{'url': 'http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation', 'valueCode': 'SYL'}], 'family': 'ハナコ', 'given': ['サトウ'], 'text': 'ハナコ サトウ', 'use': 'official'}], 'telecom': [{'system': 'phone', 'use': 'home', 'value': '(900)999-9999'}], 'resourceType': 'Patient', 'id': '2', 'meta': {'lastUpdated': '2026-04-09T08:22:14Z', 'versionId': '1'}}]
irisowner@8d9f9a48ce5f:/src/purepython$
```


### 2-2. Observation リソースへの変換と登録

[observationpost.py](./src/purepython/observationpost.py) を実行します。

[InputDataLabTest.csv](./data/Step2/InputDataLabTest.csv) を読み込んでいます。

PatientId 条件に得られた Patient リソースの id を表示した後、
変換した Observation リソースのJSONが表示されます（一部省略しています）。

その後、Bundle の POST 要求の応答 JSON が表示されます。
```
irisowner@8d9f9a48ce5f:/src/purepython$ python3 observationpost.py 
{'191922': 'Patient/1', '498374': 'Patient/2'}
{
  "entry": [
    {
      "fullUrl": "urn:uuid:cb81b5c9-2173-4545-b704-1c121d9d3382",
      "request": {
        "method": "POST",
        "url": "Observation"
      },
      "resource": {
        "meta": {
          "profile": [
            "http://hl7.org/fhir/StructureDefinition/vitalsigns"
          ]
        },
        "category": [
          {
            "coding": [
              {
                "code": "vital-signs",
                "display": "Vital Signs",
                "system": "http://terminology.hl7.org/CodeSystem/observation-category"
              }
            ],
            "text": "Vital Signs"
          }
        ],
        "code": {
          "coding": [
            {
              "code": "bw",
              "display": "体重",
              "system": "http://www.isjhospital.com/Observation_Code"
            }
          ]
        },
        "effectiveDateTime": "2020-01-30T08:45:00+09:00",
        "identifier": [
          {
            "system": "http://example.org/observation-id",
            "value": "191922-bw"
          }
        ],
        "status": "final",
        "subject": {
          "reference": "Patient/1"
        },
        "valueQuantity": {
          "unit": "kg",
          "value": 62.0
        },
        "resourceType": "Observation"
      }
    },
《一部省略》
  ],
  "type": "transaction",
  "resourceType": "Bundle"
}
POST対象件数: 4
{'resourceType': 'Bundle', 'id': 'a4682c0b-33ed-11f1-a7b7-5616d358ebcc', 'type': 'transaction-response', 'timestamp': '2026-04-09T08:25:18Z', 'entry': [{'fullUrl': 'urn:uuid:cb81b5c9-2173-4545-b704-1c121d9d3382', 'response': {'status': '201', 'location': 'http://wgcsvtofhir/csp/healthshare/r4fhirnamespace/fhir/r4/Observation/3', 'etag': 'W/"1"', 'lastModified': '2026-04-09T08:25:18Z'}, 'resource': {'meta': {'profile': ['http://hl7.org/fhir/StructureDefinition/vitalsigns'], 'lastUpdated': '2026-04-09T08:25:18Z', 'versionId': '1'}, 'category': [{'coding': [{'code': 'vital-signs', 'display': 'Vital Signs', 'system': 'http://terminology.hl7.org/CodeSystem/observation-category'}], 'text': 'Vital Signs'}], 'code': {'coding': [{'code': 'bw', 'display': '体重', 'system': 'http://www.isjhospital.com/Observation_Code'}]}, 'effectiveDateTime': '2020-01-30T08:45:00+09:00', 'identifier': [{'system': 'http://example.org/observation-id', 'value': '191922-bw'}], 'status': 'final', 'subject': {'reference': 'Patient/1'}, 'valueQuantity': {'unit': 'kg', 'value': 62.0}, 'resourceType': 'Observation', 'id': '3'}}, {'fullUrl': 'urn:uuid:b25f2677-ad69-49fc-a0ee-d3281db1b9b7', 'response': {'status': '201', 'location': 'http://wgcsvtofhir/csp/healthshare/r4fhirnamespace/fhir/r4/Observation/4', 'etag': 'W/"1"', 'lastModified': '2026-04-09T08:25:18Z'}, 'resource': {'meta': {'profile': ['http://hl7.org/fhir/StructureDefinition/vitalsigns'], 'lastUpdated': '2026-04-09T08:25:18Z', 'versionId': '1'}, 'category': [{'coding': [{'code': 'vital-signs', 'display': 'Vital Signs', 'system': 'http://terminology.hl7.org/CodeSystem/observation-category'}], 'text': 'Vital Signs'}], 'code': {'coding': [{'code': 'bh', 'display': '身長', 'system': 'http://www.isjhospital.com/Observation_Code'}]}, 'effectiveDateTime': '2020-01-30T08:45:00+09:00', 'identifier': [{'system': 'http://example.org/observation-id', 'value': '191922-bh'}], 'status': 'final', 'subject': {'reference': 'Patient/1'}, 'valueQuantity': {'unit': 'cm', 'value': 170.0}, 'resourceType': 'Observation', 'id': '4'}}, {'fullUrl': 'urn:uuid:0ce9bc2b-1337-4c05-8cee-820f6f130f15', 'response': {'status': '201', 'location': 'http://wgcsvtofhir/csp/healthshare/r4fhirnamespace/fhir/r4/Observation/5', 'etag': 'W/"1"', 'lastModified': '2026-04-09T08:25:18Z'}, 'resource': {'meta': {'profile': ['http://hl7.org/fhir/StructureDefinition/vitalsigns'], 'lastUpdated': '2026-04-09T08:25:18Z', 'versionId': '1'}, 'category': [{'coding': [{'code': 'vital-signs', 'display': 'Vital Signs', 'system': 'http://terminology.hl7.org/CodeSystem/observation-category'}], 'text': 'Vital Signs'}], 'code': {'coding': [{'code': 'bw', 'display': '体重', 'system': 'http://www.isjhospital.com/Observation_Code'}]}, 'effectiveDateTime': '2020-02-07T08:55:00+09:00', 'identifier': [{'system': 'http://example.org/observation-id', 'value': '498374-bw'}], 'status': 'final', 'subject': {'reference': 'Patient/2'}, 'valueQuantity': {'unit': 'kg', 'value': 62.5}, 'resourceType': 'Observation', 'id': '5'}}, {'fullUrl': 'urn:uuid:dba9da0e-dc03-4b0a-8c9e-b43205425a09', 'response': {'status': '201', 'location': 'http://wgcsvtofhir/csp/healthshare/r4fhirnamespace/fhir/r4/Observation/6', 'etag': 'W/"1"', 'lastModified': '2026-04-09T08:25:18Z'}, 'resource': {'meta': {'profile': ['http://hl7.org/fhir/StructureDefinition/vitalsigns'], 'lastUpdated': '2026-04-09T08:25:18Z', 'versionId': '1'}, 'category': [{'coding': [{'code': 'vital-signs', 'display': 'Vital Signs', 'system': 'http://terminology.hl7.org/CodeSystem/observation-category'}], 'text': 'Vital Signs'}], 'code': {'coding': [{'code': 'bh', 'display': '身長', 'system': 'http://www.isjhospital.com/Observation_Code'}]}, 'effectiveDateTime': '2020-02-07T08:55:00+09:00', 'identifier': [{'system': 'http://example.org/observation-id', 'value': '498374-bh'}], 'status': 'final', 'subject': {'reference': 'Patient/2'}, 'valueQuantity': {'unit': 'cm', 'value': 170.1}, 'resourceType': 'Observation', 'id': '6'}}]}
irisowner@8d9f9a48ce5f:/src/purepython$
```

## まとめ

この方法では、Python のみで FHIR リソースの作成から登録までを実装できます。

- 柔軟に処理を書ける
- ライブラリで基本検証ができる

一方で：

- Patient 検索や関連付けなどもすべて自前で実装が必要
- プロファイル検証などは別途考慮が必要

次章では、IRIS を使用した場合との違いや設計の考え方について比較します。