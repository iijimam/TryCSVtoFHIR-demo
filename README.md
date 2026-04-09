# CSV から FHIR リソースへの変換（IRIS / Python 比較付き）

このリポジトリでは、CSV などの 非 FHIR データを FHIR リソースへ変換する方法だけでなく、実装パターンの違いによる設計や運用の考え方も理解することができます。

## 確認できること

- CSV → FHIR 変換の実装方法
- Python と IRIS の違い
- 実運用での設計判断

## 📘 読み方

- まずは [[1] IRIS を利用した標準的な実装](./README_IRIS.md)（推奨）

    IRIS の Interoperability（相互運用性）機能を利用して、変換やFHIRリポジトリへのREST要求の流れを見通しよく開発する方法を確認できます。

    FHIR リソースの作成には、JSONTemplate を利用することで、FHIR リソースの JSON 構造に不慣れな状況でも実装しやすくなります。

- Pythonでの実装に興味がある場合は [[2] Python のみで実装する例](./README_PYTHON.md) を参照してください。

    PythonだけでCSVからFHIRリソースへの変換とFHIRリポジトリへのREST要求を行う方法を確認できます。

    fhir.resources を利用することで、FHIR R4 の標準スキーマに沿ったFHIRオブジェクトの操作が行えますが、FHIR 構造を理解した上での実装が必要になります。

- 設計の違いや使い分けを理解したい場合は、[[3] 設計の比較と考え方](./README_COMPARISON.md)を参照してください。

    [1] [2] それぞれの実装の違いと使い分けを確認できます。
