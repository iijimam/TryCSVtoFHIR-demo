# CSVからObservationリソースを作成する

from printfhirresource import print_fhir_resource
from fhir.resources.observation import Observation

# FHIRの日付時刻用関数
def normalize_fhir_datetime(dt_str: str) -> str:
    dt_str = dt_str.strip()

    # すでに Z または ±hh:mm が付いていればそのまま返す
    if dt_str.endswith("Z"):
        return dt_str

    time_part = dt_str[10:] if len(dt_str) > 10 else ""
    if "+" in time_part or "-" in time_part:
        return dt_str

    # タイムゾーンが無ければ日本時間を付与
    return dt_str + "+09:00"

class Observations:
    def __init__(self):
        # CSVファイルから入力した患者情報格納用Dictionary。PatientIdをキーとする
        self.observations = {}
        # CSV読込
        self.load_observations("/data/Step2/InputDataLabTest.csv")

    def load_observations(self, file_path: str) -> None:
        """
        患者ごとの検査情報が登録されたCSVファイルをロードする
        列は以下の通り。
        PatientId,code,display,value,unit,EffectiveDateTime

        observationsには、PatientId、codeをキーにobservationの情報を設定します。
        """
        with open(file_path, 'r') as file:
            for line in file:
                line = line.strip()
                if not line:
                    continue

                parts = line.split(',')
                if len(parts) < 6:
                    print(f"不正な行をスキップします: {line}")
                    continue

                # フィールド抽出
                pid=parts[0].strip()
                code=parts[1].strip()
                display=parts[2].strip()
                value=parts[3].strip()
                unit=parts[4].strip()
                effectivedt=normalize_fhir_datetime(parts[5].strip())

                # FHIRのObservationリソースの構造を使ってObservationディクショナリ作成
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
                # Observationリソースの作成
                observation_resource = Observation(**observation_data)
                # PatientIDをキーにリソースを保存
                self.observations[(pid,code)] = observation_resource


# 利用例
if __name__ == "__main__":
    observations = Observations()
    responses=[]
    for key, observation in observations.observations.items():
        print_fhir_resource(observation)

        #1件ずつPOST
        #responses.append(post(observation.json(),"Observation").json())

    #print(responses)