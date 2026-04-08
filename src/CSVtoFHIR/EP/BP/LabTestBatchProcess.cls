/// 
Class CSVtoFHIR.EP.BP.LabTestBatchProcess Extends Ens.BusinessProcess [ ClassType = persistent ]
{

/// 情報送付先コンポーネント名指定
Property TargetConfigName As %String(MAXLEN = 255);

/// FHIRエンドポイントのパスを指定します（必須）
Property FHIREndpoint As %String(MAXLEN = 512);

/// Patientリソースを検索するときのIdentifier.systemの値
Property IdentifierSystem As %String(MAXLEN = 512);

/// SETTINGSパラメータ
Parameter SETTINGS = "FHIREndpoint:CSVFHIR変換用設定:selector?context={HS.FHIRServer.Util.ContextSearch/FHIRServerEndpoints},TargetConfigName:CSVFHIR変換用設定:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},IdentifierSystem:CSVFHIR変換用設定";

/// See <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=EGDV_busproc#EGDV_busproc_onrequest">the documentation</a>
/// for tips on how to implement this method.
Method OnRequest(pRequest As CSVtoFHIR.RM.LabTestBatch, Output pResponse As HS.FHIRServer.Interop.Response) As %Status
{
  set status=$$$OK
  #dim ex As %Exception.AbstractException
  try {
    set sys=##class(%SYS.Python).Import("sys")
    do sys.path.append("/src")
    set process=##class(%SYS.Python).Import("p_process")
    // レコードマップに含まれる患者IDを利用した患者検索用メッセージ作成
    set result=process."patient_search"(pRequest,..FHIREndpoint,..IdentifierSystem)
    // resultはタプルで返ってくるので、応答メッセージとステータスに分ける
    set fhirrequest=result."__getitem__"(0)
    $$$ThrowOnError(result."__getitem__"(1))

    // 呼び出し
    set status=..SendRequestSync(..TargetConfigName,fhirrequest,.searchResponse)
    //検索エラーだった場合Catchへ移動
    if searchResponse.Response.Status'="200" {
    //ステータスエラーを作成してcatchへ移動
      set outcome=##class(HS.SDA3.QuickStream).%OpenId(searchResponse.QuickStreamId)
      throw ##class(%Exception.General).%New("FHIR OperationOutcome",,,outcome.Read())
    }

    // 検索結果から対象PatientのリソースIDを取り出し、BundlePOST用メッセージ作成
    set result=process."create_bundle"(pRequest,searchResponse.QuickStreamId,..FHIREndpoint)
    // resultはタプルで返ってくるので、応答メッセージとステータスに分ける
    set fhirrequest=result."__getitem__"(0)
    $$$ThrowOnError(result."__getitem__"(1))

    // 呼び出し
    set status=..SendRequestSync(..TargetConfigName,fhirrequest,.pResponse)
    //エラーだった場合Catchへ移動
    if pResponse.Response.Status'="200" {
    //ステータスエラーを作成してcatchへ移動
      set outcome=##class(HS.SDA3.QuickStream).%OpenId(pResponse.QuickStreamId)
      throw ##class(%Exception.General).%New("FHIR OperationOutcome",,,outcome.Read())
    } 
  }
  catch ex {
    set status=ex.AsStatus()
  }
  return status
}

ClassMethod setglo(list As %SYS.Python) [ Language = python ]
{
  g=iris.gref("^iijima")
  for reco in list:
    g[reco[0]]=reco[1]
}

Storage Default
{
<Data name="LabTestBatchProcessDefaultData">
<Subscript>"LabTestBatchProcess"</Subscript>
<Value name="1">
<Value>TargetConfigName</Value>
</Value>
<Value name="2">
<Value>FHIREndpoint</Value>
</Value>
<Value name="3">
<Value>IdentifierSystem</Value>
</Value>
</Data>
<DefaultData>LabTestBatchProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
