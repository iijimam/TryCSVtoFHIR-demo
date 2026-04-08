/// 
Class CSVtoFHIR.EP.BP.PatientProcess Extends Ens.BusinessProcess [ ClassType = persistent ]
{

/// 情報送付先コンポーネント名指定
Property TargetConfigName As %String(MAXLEN = 255);

/// FHIRエンドポイントのパスを指定します（必須）
Property FHIREndpoint As %String(MAXLEN = 512);

Parameter SETTINGS = "FHIREndpoint:CSVFHIR 変換用設定:selector?context={HS.FHIRServer.Util.ContextSearch/FHIRServerEndpoints},TargetConfigName:CSVFHIR 変換用設定:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

/// See <a href="https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=EGDV_busproc#EGDV_busproc_onrequest">the documentation</a>
/// for tips on how to implement this method.
Method OnRequest(pRequest As CSVtoFHIR.RM.Patient.Record, Output pResponse As HS.FHIRServer.Interop.Response) As %Status
{
  #dim ex As %Exception.AbstractException
  set status=$$$OK
  try {
    set sys=##class(%SYS.Python).Import("sys")
    do sys.path.append("/src")
    set process=##class(%SYS.Python).Import("p_process")
    // PatientリソースPOST用メッセージ作成
    set result=process."create_patient"(pRequest,..FHIREndpoint)
    // resultはタプルで返ってくるので、応答メッセージとステータスに分ける
    set fhirrequest=result."__getitem__"(0)
    $$$ThrowOnError(result."__getitem__"(1))
    set status=..SendRequestSync(..TargetConfigName,fhirrequest,.pResponse)
    if pResponse.Response.Status'="201" {
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

Storage Default
{
<Data name="PatientProcessDefaultData">
<Subscript>"PatientProcess"</Subscript>
<Value name="1">
<Value>TargetConfigName</Value>
</Value>
<Value name="2">
<Value>FHIREndpoint</Value>
</Value>
</Data>
<DefaultData>PatientProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
