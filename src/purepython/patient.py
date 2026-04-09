# CSVからPatientリソースを作成しFHIRリポジトリに更新する流れ

from utils import post
from printfhirresource import print_fhir_resource
from fhir.resources.patient import Patient

class Patients:
    def __init__(self):
        # CSVファイルから入力した患者情報格納用Dictionary。PatientIdをキーとする
        self.patients = {}
        # CSV読込
        self.load_patients("/data/Step2/InputDataPatient.csv")

    def load_patients(self, file_path: str) -> None:
        """
        患者情報が登録されたCSVファイルをロードする
        列は以下の通り。
        PatientId,HospitalID,LastName,FirstName,LastNameKana,FirstNameKana,DOB,Gender,postalCode,state,city,line,Phone

        - PatientId
            FHIRリソースにする場合、identifier.system は　urn:oid:1.2.392.100495.20.3.51.11311234567 とする

        生成された患者リソースは、identifier.value をキーとして self.patients に格納されます。
        """
        gender_map = {
            "M": "male",
            "F": "female",
            "O": "other",
            "U": "unknown",
        }
        with open(file_path, 'r') as file:
            for line in file:
                line = line.strip()
                if not line:
                    continue

                parts = line.split(',')
                if len(parts) < 13:
                    print(f"不正な行をスキップします: {line}")
                    continue

                # フィールド抽出
                pid=parts[0].strip()
                hospid=parts[1].strip()
                lastname=parts[2].strip()
                firstname=parts[3].strip()
                kanafirst=parts[4].strip()
                kanalast=parts[5].strip()
                dob=parts[6].strip()
                gender=parts[7].strip()
                postalCode=parts[8].strip()
                state=parts[9].strip()
                city=parts[10].strip()
                line=parts[11].strip()
                phone=parts[12].strip()

                # FHIRのPatientリソースの構造を使ってPatientディクショナリ作成
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

                # Patientリソースの作成
                patient_resource = Patient(**patient_data)
                # PatientIDをキーにリソースを保存
                self.patients[pid] = patient_resource


# 利用例
if __name__ == "__main__":
    patients = Patients()
    responses=[]
    for pid, patient in patients.patients.items():
        name = patient.name[0]
        print(f"Identifier: {pid}, Given: {name.given[0]}, Family: {name.family}")
        print_fhir_resource(patient)

        #1件ずつPOST
        responses.append(post(patient.json(),"Patient").json())

    print(responses)