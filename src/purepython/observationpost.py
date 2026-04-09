# Observationリソースに関連する患者のリソースIDを確認後、全件一括POST要求を行う
from utils import post,get
from fhir.resources.bundle import (
    Bundle,
    BundleEntry,
    BundleEntryRequest
)
from fhir.resources.reference import Reference
from observation import Observations
import uuid


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

        

# 利用例
if __name__ == "__main__":
    # CSVにある検査結果の情報をObservationリソース変換
    observations = Observations()
    # Observationsリソースにある患者IDからFHIRリポジトリのリソースID取得
    finder = FindPatient(observations)
    pid_map = finder.build_pid_map()
    print(pid_map)

    # Observationを詰め込んだBundle作成
    poster = ObservationPoster(observations, pid_map)
    print(poster.bundle.json(indent=2,ensure_ascii=False))
    print(f"POST対象件数: {len(poster.bundle.entry)}")

    # POST要求 (transactionのPOSTなのでリソース名不要のため/を渡す)
    response = post(poster.bundle.json(),"/")
    print(response.json())